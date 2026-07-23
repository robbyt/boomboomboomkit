---
title: 'GH-167 item 2 — PCM ingress sanitize + trap-guard cluster'
type: 'bugfix'
created: '2026-07-22'
status: 'done'
baseline_commit: '6c52705'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not renegotiate without the human">

## Intent

**Problem:** Six validated defects share one theme — non-finite or extreme numeric input crossing an unguarded boundary. Decoded PCM is never sanitized (#122: NaN samples make `isSilent`'s `rms < threshold` compare false, poisoning the pipeline); the `clickRescore` sort comparator is undefined on NaN scores while its NaN-safe sibling sits 130 lines below (#121); in `confirmWithSubBandPeaks` a zero `hiHatBestBPM` survives to `60.0 * onsetRate / 0`, whose Inf lag traps at `Int(lag)` in `interpolateACF` (#120 — the division itself does not trap, the Int conversion does); `OnsetFeaturesBuilder` skips the `Int(sampleRate/100)` ceiling whose absence `BPMAnalyzer`'s own comment warns about (#119); `downsample`'s output-capacity conversion traps from public API at large `targetSampleRate` (#123, validation-rescoped to the `:437` half); `generateClickTrack` traps on non-finite/zero bpm and silently emits all-zeros on negative bpm (#125 — no hang; stride-by-zero traps).

**Approach:** One PR per the #167 item-2 plan. Sanitize once at the decode funnel; everywhere else copy the guard idiom that already exists in the same file or module. Closes #122, #121, #120, #119, #123, #125 and, as by-products of the ingress pass, deferred W4, 8-1-D4, and the file-path half of W62. Spec pre-hardened by Codex consult (thread `019f8c36-c0bf-76e1-b604-8572b55dc2df`, 17 findings folded in).

**Corruption policy (#122, explicit):** ANY count of non-finite samples — one, many, or a fully poisoned decode — is zeroed, silently. A fully poisoned file therefore reads as silence and takes the existing `isSilent` path. Rationale: bounded blast radius, no new error surface, mirrors the 8-1-D4 true-peak silence-floor behavior; rejecting would convert previously-analyzable partially-corrupt files into hard errors, a semantic change beyond this cluster.

## Boundaries & Constraints

**Always:** Byte-identical output for all-finite POST-MIXDOWN samples (the stereo `L+R` sum of two finite ~3.4e38 values can overflow to Inf before the sanitize point — the promise is scoped to what the sanitizer sees). Guards throw or return through EXISTING error paths. Each code-level fix carries a regression test proven to bite via temporary revert; where the pre-fix defect is a trap, the bite proof is the observed process crash, recorded during dev.

**Ask First:** Any new public API or new error enum case. Changing `downsample`'s upsampling semantics beyond trap-to-throw. Sanitizing anywhere other than the one decode funnel (`DecodedAudio.init` is the remaining W62 half, out of scope).

**Never:** No DSP behavior change on finite input — corpus floors untouched (not re-run; `make test` is the net). No removing the #121 comparator fix as "masked by #122" — it is independently necessary (`clickRescore` is internal-callable and the caller-constructed `DecodedAudio` path stays unsanitized). No exit test for #120 (no precondition there — the fix returns `winner` normally). No "improving" copied guards — divergence between siblings is the bug class being closed.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Poisoned WAV (#122) | Float32 WAV (format code 3) with NaN/Inf sample bytes | Non-finite samples read as 0.0; finite samples bit-exact | Silent sanitize |
| Fully poisoned decode (#122) | Every sample non-finite | All-zero buffer -> existing `isSilent` path | Silent sanitize, by policy |
| Clean file (#122) | Any existing fixture | Bit-identical to pre-fix (detect pass finds finite sum, no corrective pass) | N/A |
| NaN candidate score (#121) | `clickRescore` with NaN `cand.score`, envelope long enough to pass the `:2585` preflight | Deterministic order: NaN below all real scores, offset tiebreak; rescoring PROVABLY occurred | No trap |
| Dead hi-hat band (#120) | Crafted `subBandACFs`: fast-range values <= 0, negative at winner lag | `confirmWithSubBandPeaks` returns `winner` unchanged | Guard, no Int(Inf) trap |
| Huge finite rate (#119) | `DecodedAudio(sampleRate: 1e21)` (must exceed ~`Double(Int.max) * 100` to trap pre-fix) into `build` | Throws `featurizationFailed` | Thrown, not trapped |
| Ceiling boundary (#119) | Rates just under / over 768,000 | Under: proceeds; over: throws | Policy boundary test |
| Overflowing capacity (#123) | `inputFrames * ratio` such that `ceil(product) + 1 > UInt32.max` (computed in Double, +1 INCLUDED) | Throws `conversionFailed` | Thrown, not trapped |
| Large-but-sub-cap capacity (#123) | Capacity fits UInt32 but allocation fails | Existing `bufferAllocationFailed` (unchanged behavior, matrix records it honestly) | Existing path |
| Bad click-track input (#125) | Non-finite/zero/negative bpm; non-finite duration/rate; bpm > sampleRate*60; finite args whose PRODUCTS overflow `Int` | Documented `precondition` failure (all cases, including derived products) | Precondition |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` — `:209` private `readMonoSamples` is the single egress funnel; sanitize `mono` after the mixdown block (`:294-315`). Detect via a deterministic early-exit `contains {{ !$0.isFinite }}` scan — SUPERSEDED review-round decision: `vDSP_sve` sum propagation is mathematically airtight and Codex found no source-level miss class, but Edge Case Hunter OBSERVED the sum branch fail to fire once on a fresh build (1 of 11 runs); the corrective scalar replace-with-0 loop runs only when the scan finds a non-finite element. `:419` unreachable trap -> `clamping:` hygiene. `:437` fix: compute `ceil(Double(inputFrameCount) * ratio) + 1` entirely in `Double`, guard finite AND `<= Double(UInt32.max)`, then convert; throw `conversionFailed(url)` (already thrown at `:234`). EXTRACT the capacity computation into an internal pure static helper so the boundary is directly testable — a huge public-API rate may be rejected earlier by `AVAudioFormat` construction (`:404-413`) and never reach `:437`, so a public-API-only test cannot prove the bite.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — `:2684-2686` copy the NaN-safe comparator from `:2815-2819` verbatim (+ adapted comment). `:2280-2285` scan; add `guard hiHatBestBPM > 0 else { return winner }` immediately after it; make `confirmWithSubBandPeaks` (`:2260`) `internal` for the direct-call test — the `clickRescore` `:2566` precedent. Add a comment recording the invariants `subBandVote`'s divisions rely on (`winner.bpm >= 80`, guarded `hiHatBestBPM`). `:92` promote `maxOnsetSampleRate` from `private` to `internal` so the builder shares the constant (no drifting copies).
- `Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeaturesBuilder.swift:31` — guard `decoded.sampleRate <= BPMAnalyzer.maxOnsetSampleRate`, throw `FeatureSubstrateError.featurizationFailed(reason:)`.
- `Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift:4-18` — documented precondition set: finite rate > 0, finite bpm > 0, finite duration >= 0, `bpm <= sampleRate * 60`, AND the derived products `sampleRate * durationSeconds` / `sampleRate * 60 / bpm` finite and `<= Double(Int.max)` BEFORE either `Int(...)` (Codex 7: per-argument finiteness alone does not make the conversions safe). Sibling idiom: `synthesizeBoundaryBurstFixture:40-89`, nine documented preconditions.
- `Tests/BoomBoomBoomKitTests/PCMIngressGuardTests.swift` — new suite. Poisoned WAV: handcraft format-code-3 (WAVE_FORMAT_IEEE_FLOAT) bytes with correct block align/byte rate; the temporary-revert bite proof doubles as the AVFoundation-passes-NaN-through verification — if pre-fix reads come back finite, AVFoundation canonicalizes and #122's reachability claim is partly wrong: HALT and report, do not fake the proof. `clickRescore` test: concrete BPMs + envelope long enough that the `:2585` preflight passes; assert scores changed (rescoring occurred), not merely output order. #125 exit tests: `await #expect(processExitsWith: .failure)` inside the existing `#if compiler(>=6.2)` gate — repo precedent `ClickTrackAIFFBuilderTests.swift:119`; no "untestable" escape hatch.
- `_bmad-output/implementation-artifacts/deferred-work.md` — W4 / 8-1-D4 closed-by; W62 PARTIAL (file path closed, caller-constructed `DecodedAudio` remains); NEW deferred entries for the two adjacent hazards found by Codex and deliberately not fixed here: `extractTopPeaks` NaN comparator (`BPMAnalyzer.swift:2460`, reachable only via unsanitized internal paths) and `downsample` converter priming/tail sizing at extreme ratios (single-shot convert checks only `.error`, `:435-449`).

## Tasks & Acceptance

**Execution:**
- [x] `PCMBufferReader.swift` — ingress sanitize; `:419` hygiene; internal capacity helper + Double-domain guard at `:437`.
- [x] `BPMAnalyzer.swift` — comparator backport; `hiHatBestBPM` guard + `internal` seam + invariants comment; `maxOnsetSampleRate` to `internal`.
- [x] `OnsetFeaturesBuilder.swift` — shared-constant ceiling guard, thrown not trapped.
- [x] `TestSignalGenerators.swift` — precondition set including derived-product representability.
- [x] `Tests/BoomBoomBoomKitTests/PCMIngressGuardTests.swift` — poisoned/clean WAV, clickRescore-with-proof-of-rescoring, crafted-ACF #120 direct call, 1e21 + 768k-boundary builder tests, capacity-helper boundary test, #125 exit tests (compiler-gated).
- [x] `deferred-work.md` — closed-by + partial + two new deferred entries per Code Map.
- [x] [Review round 1] 9-patch batch per the Change Log entry (deterministic detect, negative-domain guard, clamp/copy revert, onsetRate guard, diagnostic reword, exit-test stderr observation + 3 new cases, Inf-only/downsample-path/stereo fixtures, comparator permutations, ledger/doc rewording).

**Acceptance Criteria:**
- Given each guard temporarily reverted, when its regression test runs, then it fails — or the process crashes where the defect is a trap — exactly as the pre-fix defect predicts; recorded per fix. The #123 proof runs against the internal helper (public-API reachability is not assumed); the #119 proof uses 1e21 (1e9 does NOT trap on 64-bit — Codex 8).
- Given `make test` post-fix, then all suites pass with every pre-existing suite byte-untouched.
- Given the poisoned WAV, when `readMonoSamples` reads it, then every returned sample is finite and finite samples are bit-identical to source bytes.
- Given `make fmt && make lint`, then clean, 0 serious.
- Given the PR, then `Fixes` closes #122 #121 #120 #119 #123 #125.

## Spec Change Log

- **2026-07-22, review round 1 (patches only — no loopback).** Three independent reviewers (Blind Hunter, Edge Case Hunter, Codex blind-hunter thread `019f8c55-c582-7d61-a58b-2257fff7824c`); all six fixes held, zero production-behavior defects, 9 patches applied. Production: (1) detection mechanism changed from `vDSP_sve` sum to a deterministic early-exit scan — ECH observed the sum branch fail to fire once on a fresh build despite the propagation argument being mathematically sound and probe-verified; the FROZEN matrix row's parenthetical "(detect pass finds finite sum)" describes the superseded mechanism, while its observable contract (clean bytes bit-identical, no corrective pass) is preserved exactly. (2) `downsampleOutputCapacity` rejects negative capacity (probe-confirmed trap, exit 133). (3) The `:419` `clamping:` rider REVERTED to guard-and-throw — clamped capacity + unclamped copy was a latent OOB heap write where the pre-fix code trapped safely (own-goal caught by both hunters). (4) `onsetRate` entry guard on the newly-internal `confirmWithSubBandPeaks` (widened visibility widened the input domain). (5) Honest over-ceiling diagnostic in the builder. Tests: exit tests observe `standardErrorContent` and assert the documented precondition fragment (Codex: five of six passed on baseline via generic traps — now all distinguish; removal-proof captured), + sampleRate 0/.nan and negative-duration cases, Inf-only fixture, downsample-path placement pin, stereo-poison fixture, comparator NaN permutations, `.featurizationFailed` pattern-match, negative-domain helper cases. Docs/ledger: silent-zeroing policy now in both public reader doc comments; W4 closure rescoped to file-decoded input; converter-tail entry symbol-anchored; derived-product doc states representability-not-allocatability. Rejected with rationale: compiler-gate CI omission (deliberate repo precedent), `beatStart+64` overflow (unrealizable), reachability-check test value (honestly disclaimed). KEEP: the six verbatim-idiom guards; the crafted-ACF #120 recipe; the stderr-fragment exit-test pattern; the do-not-trust-sum-propagation lesson.

- **2026-07-22, pre-approval Codex consult (thread `019f8c36-c0bf-76e1-b604-8572b55dc2df`).** 17 findings folded into this draft before first approval: #120 mechanism corrected (Int(Inf) trap at `interpolateACF:2149`, not a trapping division; no exit test; internal seam for direct-call test), #123 off-by-one (+1 inside the Double-domain guard), #123 test reachability (internal pure helper — `AVAudioFormat` may reject huge rates before `:437`), honest #123 error matrix (`bufferAllocationFailed` stays possible below the cap), #119 non-biting 1e9 replaced with 1e21 + 768k boundary + shared internal constant, #125 derived-product preconditions, byte-identity promise narrowed to post-mixdown, explicit any-count zeroing corruption policy, #121 anti-masking note + proof-of-rescoring test requirement, exit-test compiler gate per repo precedent, WAV format-code-3 fixture spec with bite-proof-as-passthrough-verification, `extractTopPeaks` + converter-tail deferred with rationale. Codex confirmed: `vDSP_sve` detection airtight; comparator/throw-site/visibility/nine-precondition line claims all check out.

## Design Notes

Detection before correction (#122): any non-finite element forces a non-finite `vDSP_sve` sum regardless of accumulation order; a false positive from finite overflow merely triggers a harmless corrective pass. Hot path stays one vDSP call.

#120's pathological input, craftable in the direct-call test: `winner.bpm` in 80-130; hi-hat ACF (band 3) with all fast-range (140-200 BPM lag) values <= 0 AND a negative value at the winner lag — then `hiHatBestStrength (0) > hiHatAtWinner (<0)` passes and pre-fix reaches `60.0 * onsetRate / 0`.

## Verification

**Commands:**
- `make test` — expected: all pass; count grows by the new suite only.
- `make fmt && make lint` — expected: clean, 0 serious.
- Bite proofs per fix (temporary revert; crash-as-bite where the defect traps), evidence captured.
- Corpus benchmarks NOT re-run: every guard inert on finite input; document in the PR.

## Suggested Review Order

**The ingress sanitize (#122 — start here)**

- The one sanitize point for both public readers: deterministic early-exit detect + corrective zeroing, with the do-not-trust-sum-propagation rationale.
  [`PCMBufferReader.swift:346`](../../Sources/BoomBoomBoomKit/PCMBufferReader.swift#L346)

**The trap guards, each mirroring an existing idiom**

- The NaN-safe comparator, byte-verbatim with its duration-hint sibling at :2850 (#121).
  [`BPMAnalyzer.swift:2716`](../../Sources/BoomBoomBoomKit/BPMAnalyzer.swift#L2716)

- The dead-band guard (#120) plus the onsetRate entry guard the internal-visibility widening required.
  [`BPMAnalyzer.swift:2282`](../../Sources/BoomBoomBoomKit/BPMAnalyzer.swift#L2282)

- The shared-constant rate ceiling, thrown not trapped (#119).
  [`OnsetFeaturesBuilder.swift:36`](../../Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeaturesBuilder.swift#L36)

- The Double-domain capacity helper (nil on non-finite, negative, or over-UInt32.max) and the guard-and-throw that replaced the clamp/copy own-goal (#123).
  [`PCMBufferReader.swift:431`](../../Sources/BoomBoomBoomKit/PCMBufferReader.swift#L431)

- Six documented preconditions incl. derived-product representability (#125).
  [`TestSignalGenerators.swift:5`](../../Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift#L5)

**The regression net (24 tests, every guard bite-proven)**

- Poisoned/clean/Inf-only/stereo/downsample-path WAV fixtures — the sanitize's placement and both non-finite classes pinned.
  [`PCMIngressGuardTests.swift:74`](../../Tests/BoomBoomBoomKitTests/PCMIngressGuardTests.swift#L74)

- Exit tests observing stderr and asserting the documented precondition fragment — distinguishes the fix from baseline generic traps (Codex finding).
  [`PCMIngressGuardTests.swift:467`](../../Tests/BoomBoomBoomKitTests/PCMIngressGuardTests.swift#L467)

**Ledger honesty**

- W4/8-1-D4 closures scoped to file-decoded input; W62 partial; two new deferred entries with re-open anchors.
  [`deferred-work.md:1001`](deferred-work.md#L1001)
