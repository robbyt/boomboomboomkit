---
title: 'GH-140 — fix the BNNS resample one-float OOB read (deferred 7-5-D1)'
type: 'bugfix'
created: '2026-07-21'
status: 'done'
baseline_commit: 'ad18462'
review_loop_iteration: 2
context: []
---

<frozen-after-approval reason="human-owned intent — do not renegotiate without the human">

## Intent

**Problem:** `BNNSTechnique.swift:625` clamps the last resample control entry one ULP below its own computed value, not below `F-1`. When `vDSP_vramp`'s float32 rounding lands that entry at or above `F-1`, `vDSP_vlint` reads `A[F]` — for mel bands 0-126 that silently contaminates the last output column with the next band's first element; for band 127 it reads one float past the `melMajor` heap allocation (undefined behavior, defeats tensor determinism). Probed on this machine: 201 of 480 upsampling F values in [32, 511] overshoot, AND — contradicting the issue record — 75,598 downsampling F values in [513, 200000] too (first at 584), so real FR-18-scale tracks hit it as well.

**Approach:** The one-line fix from the issue and the Python mirror: `controlVector[W-1] = min(controlVector[W-1], Float(F-1)).nextDown`, which forces `floor <= F-2` so `vDSP_vlint`'s `A[floor+1]` read stays in-bounds unconditionally. Add an always-on regression test that provably fails pre-fix via cross-band contamination detection at a runtime-probed overshooting F. For the value-invisible 1-ULP class (frac 0), guard with a debug-build `assert(controlVector[W - 1] < Float(F - 1))` after the clamp — zero release cost, bites in every debug test run. Keep an opt-in `make test-asan` target as defense-in-depth only, documented honestly: ASan cannot observe the over-read itself, which executes inside uninstrumented Accelerate code. [Renegotiated 2026-07-22 after review round 1 — the original "ASan catches the band-127 over-read" premise, inherited from the issue, was empirically disproven during the bite proof.]

## Boundaries & Constraints

**Always:** The fix must match the Python mirror's clamp semantics (`feature_substrate_v2.py:104-110`: `min(control[W-1], F-1)` then one ULP down) so Swift/Python last-column parity closes rather than diverges. Output values at non-overshooting F are byte-identical before and after (the `min` is a no-op there). The regression test must demonstrably fail on pre-fix code (verify during dev by temporarily reverting the clamp). Update the stale comment at `:617-620` that claims the current clamp keeps the read in-bounds.

**Ask First:** Any change beyond the clamp line and its comment inside `modelInputTensor` (e.g. restructuring the vlint loop, touching the short-clip guard, or changing `targetWidth`). Any edit to the Python mirror. Adding ASan to `make test` or CI (perf cost is a human call).

**Never:** No behavior change for in-bounds control values. No new public API — the test reaches `modelInputTensor` via `@_spi(FeatureParity) @testable import BoomBoomBoomKitML`, the existing seam. No rewriting the deferred-work 7-5-D1 history entries; append a resolution instead. No touching the DSP pipeline, corpus floors, or anything outside `Sources/BoomBoomBoomKitML` + tests + Makefile + trackers.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Non-overshooting F | `vDSP_vramp` last entry < F-1 | Byte-identical tensor to pre-fix | N/A |
| Overshooting F, bands 0-126 | Probed F where last entry >= F-1 (e.g. 445) | Last output column interpolated from band-local `A[F-2]`, `A[F-1]` only; never exceeds the band's own value range | N/A |
| Overshooting F, band 127 | Same F | No read past `melMajor.count`; clean under `--sanitize=address` | N/A |
| Exact-boundary F | `vDSP_vramp` last entry == F-1 exactly | `min` passes through, `.nextDown` puts it below F-1, floor = F-2 (pre-fix behavior preserved) | N/A |
| Short clip | frames < 32 | `nil` (existing DD #9 guard, unchanged) | N/A |
| Hardware without overshoot | No F in [32, 511] overshoots under that machine's vramp | Contamination test degrades to value-sanity assertions; ASan target still passes | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:612-654` — Step 3 resample; the bug is `:625`, the stale comment `:617-620`. `modelInputTensor` is `@_spi(FeatureParity) public static`, model-free (no `.mlmodelc` needed to test).
- `_bmad-output/ml-training/feature_substrate_v2.py:104-110` — the correct clamp to mirror (read-only reference).
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` — existing featurize tests; imports `@testable import BoomBoomBoomKitML` (add `@_spi(FeatureParity)` to the new file's import). `MLFeatureFrames(melBands:frames:tensorLayout:logMelData:...)` throwing init, `.nchw` = mel-major passthrough (skips the transpose, simplest for band-local reasoning).
- `Makefile` — add `test-asan` target near `test`; `_bmad-output/implementation-artifacts/deferred-work.md:~790-798` — 7-5-D1 + RECONFIRMED entries to mark resolved (append, don't rewrite).

## Tasks & Acceptance

**Execution:**
- [x] `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — replace `:625` with `controlVector[W - 1] = min(controlVector[W - 1], Float(F - 1)).nextDown`; rewrite the `:617-620` comment to state the two-step clamp and cite the Python mirror parity.
- [x] `Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift` — new file. (1) Runtime-probe `vDSP_vramp` with TWO predicates: `last.nextDown >= Float(F-1)` (OOB exists — the ASan case; F=32-class 1-ULP overshoots land exactly on F-1 with frac 0, value-invisible) vs `last.nextDown > Float(F-1)` STRICT (frac > 0 — the only Fs where contamination is value-detectable; F=445-class). The contamination test MUST select via the strict predicate or it passes on broken code; if the hardware has no strict-overshoot F, fall through to sanity-only. (2) At a strict F, build `.nchw` input with per-band spike-first rows (so cross-band contamination lands far outside the victim band's value range); assert every band's last output column stays within its own z-score range and matches a scalar reference interpolation within 1e-4 — fails pre-fix. (3) Bit-identical output across two invocations. (4) Same band-local assertion at a strict-overshooting downsampling F (e.g. 584).
- [x] `Makefile` — add `test-asan`: `swift test --sanitize=address --filter BoomBoomBoomKitTests.BNNSResampleClampTests` with a help comment; not wired into `test` or `pre-commit`.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — append resolution to 7-5-D1 noting the fix, the downsampling reachability correction (75,598 F values in [513, 200000] overshoot, first 584 — the "FR-18 corpora don't hit it" claim was wrong), GH-140, and the provenance irony: the under-clamp landed in `c120bc2` as the Codex 4-5-chunk2 boundary-analysis review fix.
- [x] `_bmad-output/ml-training/feature_substrate_v2.py:104-110` — comment-only edit (operator-authorized 2026-07-21, Ask-First granted): rewrite the stale present-tense "Swift over-reads one float there — deferred 7-5-D1" to past tense citing GH-140. No behavior change; `uv run ruff format --check` must stay clean.
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` — flip/append the corresponding action item if one exists; otherwise skip silently. (No matching item existed; skipped.)
- [x] [Review round 1] `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — add the debug-build `assert(controlVector[W - 1] < Float(F - 1))` after the clamp (the biting guard for the value-invisible 1-ULP class); trim workflow provenance from the comment; document why interior control entries need no clamp.
- [x] [Review round 1] `Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift` + `Makefile` + ledger/docstring patches per the Spec Change Log entry (F-scaled spike, `.enabled(if:)` skip traits with frac floor, determinism-test reframe, F=512 boundary case, reference bounds guard, corrected probe counts, honest `test-asan` comment, original-7-5-D1 annotation, FR-18 re-baselining defer entry, Python docstring past-tense).
- [x] [Review round 2] Hardening patches per the round-2 Change Log entry (always-on OOB-exists boundary smoke test at F=32, assert message, full-range downsampling probe, honest margin comments, F=512 pin else-branch, band-127 loop reconciliation, guard-scoped in-bounds claim, ledger re-open trigger + wording).

**Acceptance Criteria:**
- Given the pre-fix clamp temporarily restored (debug assert kept), when `BNNSResampleClampTests` runs in a debug build, then the contamination assertions fail AND the debug assert traps at an overshooting F (proof both nets bite). [Amended 2026-07-22: the original "make test-asan reports a heap-buffer-overflow" clause was empirically unsatisfiable — ASan cannot see Accelerate-internal reads.]
- Given the fixed clamp, when `make test` runs, then all suites pass including the new file, and `make test-asan` is clean.
- Given any F where `vDSP_vramp` does not overshoot, when `modelInputTensor` runs before and after the fix, then outputs are bit-identical (spot-check at F=64 inside the test).
- Given `make fmt && make lint`, then clean, 0 serious.

## Spec Change Log

- **2026-07-22, review round 2 (patches only — no loopback).** Both hunters re-ran on the round-1 output; Blind Hunter's verdict: the two-step clamp + assert is "correct and mutually coherent", mutation-proven again, including mutations 2/2b establishing the assert is the ONLY net for the frac-0 class. 12 hardening patches applied, no intent_gap/bad_spec: (1) always-on OOB-exists boundary smoke test at F=32 (the guard minimum, a frac-0 min-clamp-ACTIVE case on Apple silicon) — closes the gap where both-probes-nil hardware never exercised the assert at an overshooting F; mutation-verified to trap alone. (2) Assert given a message naming the invariant and the offending values. (3) Downsampling probe extended to the full constructible range [513, 65536] so the real-track regime (F~18k) is scanned. (4) Frac-floor comments corrected to the honest 1.5x worst-case margin; NOT raised to 1e-4 (both hunters proposed it) because the Apple-silicon upsampling frac ceiling ~9.2e-5 would skip the upsampling test — recorded so a future "safe" tolerance loosening does not cite the old 5e-4 overclaim. (5) F=512 pin records an Issue when the bit-identity branch cannot run. (6) Band-127 loop reconciled with the "non-assertable pre-fix" header. (7) In-bounds comment scoped to reachable F >= 32. (8) Ledger: "always-on" wording fixed, re-open trigger added to the FR-18 defer entry, date coherence. (9) Test header documents that the assert SIGABRTs before contamination #expects in mutation runs (strip both to re-verify the value net). KEEP: everything in the round-1 KEEP list, plus the boundary smoke test and the do-not-raise-the-floor rationale.

- **2026-07-22, review round 1 (intent_gap + patches).** Trigger: both hunters + the dev-time bite proof converged on the ASan premise being false — `make test-asan` produced ZERO sanitizer reports on pre-fix code because the over-read executes inside uninstrumented Accelerate (`vDSP_vlint`); the Makefile/test comments overclaimed accordingly. Operator renegotiated the frozen Approach + AC #1: debug-build `assert(controlVector[W - 1] < Float(F - 1))` after the clamp is the biting guard for the value-invisible 1-ULP class; `test-asan` stays as honestly-documented defense-in-depth. Known-bad avoided: shipping a false safety claim in main-bound help text. Additional patches from the same round: (1) Blind Hunter mutation-proved the production-independent band-local bound caught ZERO in the downsampling run — the fixed 100.0 spike sinks below the ramp top at F > ~10k; spike now scales with F. (2) Contamination tests gate on `.enabled(if:)` runtime traits (strict-overshoot F with frac clearing tolerance must exist) so no-overshoot hardware SKIPS visibly instead of silently passing degraded assertions. (3) Determinism test reframed as a property pin — mutation-proven to pass pre-fix, must not claim GH-140 bite coverage. (4) Probe evidence corrected to the API-constructible range (F <= 65,536 under the 8.4M-float cap): downsampling OOB-exists 25,556 / strict 13,344, first strict 696. (5) Workflow provenance (c120bc2/Codex citation, develop-only filename) trimmed from the main-bound comment; history lives in deferred-work.md. KEEP: the strict-vs-non-strict probe predicate split; runtime probing over hardcoded F; the min-form clamp + anti-simplification rationale; the scalar reference validated at mid-column; spike-first contamination design (now F-scaled).

## Design Notes

Why contamination is detectable pre-fix without ASan: at F=445 the vramp overshoot is ~1.22e-4 (~2 ULP at magnitude 444), so after the buggy `.nextDown` the fractional part is ~6e-5 and the last column becomes `z[F-1] + frac * (z_next[0] - z[F-1])`. Craft each band with a spike first element that SCALES with F (20x the ramp top — a fixed spike sinks below the ramp top at downsampling F > ~10k, muting the band-local bound; found by mutation in review round 1) and the contaminated value exceeds the band's own final-segment bound by well over the 1e-4 tolerance. Band 127 has no next band (heap garbage, non-assertable by value) — that class is guarded by the debug assert after the clamp, because ASan cannot observe reads executed inside uninstrumented Accelerate code.

The deferred-work sketch ("clamp floor to F-2") is not directly implementable — `vDSP_vlint` floors internally — and the control-value clamp is its exact equivalent: control < F-1 implies floor <= F-2. Per Apple's contract, `vDSP_vlint` reads `C[q+1]` unconditionally even at frac == 0 (no bounds check, no short-circuit) — which is why 1-ULP overshoots are ASan-visible but value-invisible.

Do NOT "simplify" to an unconditional `Float(F - 1).nextDown`: on the majority undershoot case Python keeps the computed control value, so direct-set would move Swift's last column at every non-overshooting F and OPEN a parity gap. The `min` form is byte-identical wherever the old code was correct.

`min(., Float(F - 1))` exactness: `MLFeatureFrames` caps total floats at 8,388,608, so F <= 65,536 at 128 bands — below 2^24, `Float(F - 1)` is always exact.

`inputFeatureChecksum` hashes the pre-resample log-mel stream — unaffected. No committed test pins exact tensor values. Corpus benchmarks are not re-run: the default pipeline is `.dspOnly` and never enters this code.

## Verification

**Commands:**
- `make test` — expected: all pass, including the new suite.
- `make test-asan` — expected: clean. (Round-1 correction: ASan does NOT report the pre-fix over-read — it executes inside uninstrumented Accelerate; the pre-fix bite proof is the 508 value-assertion failures with the assert removed, plus the assert trap at `BNNSTechnique.swift:643` with the assert kept.)
- `make fmt && make lint` — expected: clean, 0 serious.
- `cd _bmad-output/ml-training && uv run python test_feature_parity.py` — expected: parity harness still passes (tolerance-based; the fix moves Swift toward Python). Skip with a note if the fixture npz is absent.

## Suggested Review Order

**The fix (start here)**

- The two-step clamp: `min` to F-1, then one ULP down — floor <= F-2 unconditionally; comment explains why interior entries need no clamp and why not to "simplify".
  [`BNNSTechnique.swift:638`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L638)

- The debug tripwire for the value-invisible frac-0 class — the ONLY net there (ASan proven blind to Accelerate-internal reads; mutation 2/2b evidence).
  [`BNNSTechnique.swift:643`](../../Sources/BoomBoomBoomKitML/BNNSTechnique.swift#L643)

**The regression net (mutation-proven twice)**

- The two overshoot predicates and why the split matters — strict (value-detectable) vs OOB-exists (assert-only); the whole detection theory in one header.
  [`BNNSResampleClampTests.swift:16`](../../Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift#L16)

- Strict-overshoot selection with the detectability floor; do-not-raise-to-1e-4 rationale pinned at the constant.
  [`BNNSResampleClampTests.swift:87`](../../Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift#L87)

- The contamination tests — probe-gated `.enabled(if:)`, skip visibly on no-overshoot hardware; 508 failures under mutation.
  [`BNNSResampleClampTests.swift:287`](../../Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift#L287)

- Always-on boundary smoke at F=32 (guard minimum, min-clamp-ACTIVE) — guarantees the assert is exercised every debug run; traps alone under mutation.
  [`BNNSResampleClampTests.swift:310`](../../Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift#L310)

- The scalar reference pipeline plus the F-scaled spike input (a fixed spike went inert at downsampling F > ~10k — round-1 mutation finding).
  [`BNNSResampleClampTests.swift:166`](../../Tests/BoomBoomBoomKitTests/BNNSResampleClampTests.swift#L166)

**Honest tooling and record corrections**

- `test-asan` reframed as defense-in-depth with the empirical ASan-blindness evidence in the help text.
  [`Makefile:120`](../../Makefile#L120)

- 7-5-D1 resolution: the fix, the downsampling-reachability correction (the "upsampling only" record was wrong), the c120bc2 provenance irony.
  [`deferred-work.md:799`](deferred-work.md#L799)

- New defer: pre-fix FR-18/parity artifacts carry contaminated last columns — operator/Epic-12 re-baselining decision, with re-open trigger.
  [`deferred-work.md:995`](deferred-work.md#L995)

- Python mirror comments flipped to past tense citing GH-140 (comment-only; operator-authorized).
  [`feature_substrate_v2.py:108`](../ml-training/feature_substrate_v2.py#L108)
