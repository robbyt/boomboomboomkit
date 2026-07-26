---
title: 'GH-167 item 4 — Test-gate integrity (#155, #156, #163, #165)'
type: 'bugfix'
created: '2026-07-24'
status: 'done'
review_loop_iteration: 0
baseline_commit: '2e5b458'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Four validated defects share one failure mode — a test gate that exits green having measured nothing. `BNNSTechnique`'s happy path is gated on a `nil` literal so 8 of 20 tests never run and one whole suite is unreachable even from its own make target (#156). The AC8 consistency gate excludes `analyze()` failures from its own denominator and silently skips entirely when the corpus env var is unset (#163, #165). Seven of eleven OA300 benchmarks assert nothing, and two of them shrink their denominator through `try?` so printed percentages change basis between runs (#155). Items 5-7 of the #167 plan treat these instruments as evidence.

**Approach:** Delete what provably cannot run, assert what is actually measured, and convert the one gate-bearing suite to the fail-loud throwing-init idiom. Test and benchmark targets only. This PR makes the instruments honest, not stricter — no accuracy floor moves.

## Boundaries & Constraints

**Always:**
- Zero `Sources/` changes. `bundledReferenceURL` is `public` and is the default argument of `public init(modelURL:)` — it is production API and stays.
- Bare `make test` with no corpus env vars stays green.
- Every new guard bite-proven by temporary mutation/revert, recorded in Verification.
- `make consistency-rate-oa300` measures 81 tracks, not 82 (see Design Notes).

**Ask First:** Any new environment variable. Any `Sources/` edit. Any accuracy-floor value change. Salvaging any part of the abstain-floor suite.

**Never:** Production code. New public API. Accuracy floors (item 5, #154/#160/#161). BYOW init work (#144, item 6). Silencing a visible skip on a genuinely optional suite.

**Decisions frozen at planning (operator, 2026-07-24):**
1. #163 uses an **exact failing-filename allowlist**, not a `<=N` ceiling — a ceiling permits substitution (one track recovers, another regresses, gate stays green).
2. #155 **deletes** `benchmarkDefaultIntensity` (an exact-duplicate corpus pass) and asserts denominators on the other six. **No new env variables**; no test moves behind a gate.
3. The m4a corpus gap is **documented and ledgered**, not fixed — `ProbeFormat` is the grouping key for four wall-clock gates this PR does not touch.
4. All four issues ship in **one PR**.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Consistency gate, corpus set | `OA300_CORPUS_PATH` valid | Suite runs; 81 files resolved; `noResult` set equals the empty allowlist | n/a |
| Consistency gate, corpus unset | env var absent or empty | Suite `init()` **throws** `corpusPathNotSet`; make target exits non-zero | Loud failure, not a skip |
| Consistency gate, a track stops analyzing | one file throws / returns nil grid | Allowlist mismatch names the file; test fails | Failure names cause: absent / threw / nil result / no grid |
| Consistency gate, corpus shrinks | fewer files on disk | `files.count == 81` assertion trips | Loud |
| BNNS inference, production thresholds | fixture + synthetic features | `evaluate` returns nil; snapshot `gateFired == .gate1Softmax` | n/a — abstain is the shipped behavior |
| BNNS inference, thresholds zeroed | same, via `thresholdOverride` | Non-nil `MLEvaluation`, finite bpm in `[60,200]`, confidence in `[0,1]`, id `"CustomBundled"` | n/a |
| BNNS fixture unreachable | `Bundle.module.resourceURL` nil | Suite skips via `.disabled(if: fixtureMissing())` | Documented optional skip |
| OA300 benchmark, corpus present | 82 ground-truth rows on disk | Every default-run test asserts its denominator | n/a |
| OA300 sweeps, unreadable track | `PCMBufferReader` fails | Dropped tracks counted and asserted zero — denominator cannot shrink silently | Loud |
| OA300 benchmark, empty corpus | zero tracks resolved | Test fails; no green early-return | Loud |

</frozen-after-approval>

## Code Map

- `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` — 8 `.disabled(if: bundledModelMissing())` traits at `:82,92,108,131,154,353,393` + `:655`; the predicate at `:42-47`. **Issue #156 says 9 disabled; the true count is 8.**
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift` — delete. Double-gated (`BNNS_IMPACT=1` AND nil URL); also hardcodes 20 private-corpus filenames.
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueDiagnosticTests.swift` — `fixtureURL()` / `fixtureMissing()` at `:37-52` is the port target pattern. Do not duplicate; reuse.
- `Tests/BoomBoomBoomKitBenchmarkTests/ConsistencyContractCorpusTests.swift` — `.enabled(if:)` suite trait `:24-29`; `noResult` drop `:46-51`; denominator `:60-64`.
- `Tests/BoomBoomBoomKitBenchmarkTests/SharedDecodeImpactTests.swift:30-42` — `ProbeFormat`, the m4a gap. Read-only reference.
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` — 7 assertion-free tests; `try?` denominator shrink at `:271-276`, `:350-355`; green-exits at `:251-254`, `:330-333`.
- `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:174` — `AblATION_RESULTS_DIR` typo.
- `Tests/BoomBoomBoomKitBenchmarkTests/MLPolicySweepTests.swift:36` — trait alignment (cosmetic).
- `_bmad-output/implementation-artifacts/deferred-work.md:631-638` — entry **C4**, whose resolution produced the now-dead abstain-floor suite. Append the resolution here.

## Tasks & Acceptance

**Execution:**
- [x] `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift` — delete `bundledModelMissing()` and all 8 `.disabled` traits; delete `initSucceedsForBundledModel` (its subject, a bundled default model, does not exist and construction is already covered by `initAcceptsCustomModelURL_constructionOnly`); repoint the other 7 to the `CustomBundled.mlmodelc` fixture via a shared `fixtureURL()` helper.
- [x] Same file — strengthen `evaluateProducesPlausibleBPM` and `concurrentEvaluateIsContextLocal`: both currently guard on `if let`/`if !isEmpty` and pass vacuously when every evaluation abstains. Require non-nil.
- [x] Same file — add the two missing real-inference assertions (non-nil under zeroed thresholds; production-threshold abstain at gate 1). `.serialized` suite: they mutate `BNNSTechnique.thresholdOverride`.
- [x] `Tests/BoomBoomBoomKitTests/BNNSTechniqueAbstainFloorTests.swift` — delete the file.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/ConsistencyContractCorpusTests.swift` — replace the `.enabled(if:)` trait with a throwing `init()`; collect failing filenames with their cause; assert the allowlist equality, `files.count == 81`, and `analyzed + noResult == files.count`. Keep the printed report, `analyzed > 0`, and `notCompared == 0`.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` — delete `benchmarkDefaultIntensity`; add denominator assertions to the other six; replace both `try?` drops with counted-and-asserted reads; remove both empty-corpus green-exits.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` + `MLPolicySweepTests.swift` — typo fix, trait alignment.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — append the C4 resolution; add new entries for the abstain-floor intent, the m4a gap, `bundledReferenceURL`'s dead default argument, and the 8x recompute in `benchmarkMergeStrategies`.

**Acceptance Criteria:**
- Given no corpus env vars, when `make test` runs, then it is green and no suite in `BoomBoomBoomKitTests` fails to compile or errors on a missing corpus.
- Given `OA300_CORPUS_PATH` is unset, when `make consistency-rate-oa300` runs, then it exits **non-zero** with a `corpusPathNotSet` error rather than reporting success.
- Given the committed fixture, when the ported suite runs under `make test`, then real BNNSGraph inference is asserted non-nil at zeroed thresholds and asserted to abstain at gate 1 under production thresholds.
- Given any single OA300 track becomes unreadable, when `make benchmark` runs, then a denominator assertion fails rather than a percentage changing basis.
- Given every new guard, when the guard is temporarily reverted, then at least one named test fails — recorded in Verification.

## Spec Change Log

- **2026-07-24 — Codex diff review (thread `019f9293`).** Two merge-blockers, both fixed as patches (no frozen-intent change):
  1. *`.serialized` overstated as cross-suite-safe.* `.serialized` only orders tests within a suite; the comment claimed general cross-suite safety. Rewrote it to state the real basis: `BNNSImpactTests` (the other `thresholdOverride` mutator) is in the benchmark target, `make test` filters the unit target and never co-invokes it, and the deleted abstain-floor suite was the only other unit-target mutator — so `BNNSTechniqueInferenceTests` is the sole mutator in the `make test` lane, where no sibling asserts a threshold-dependent `evaluate` outcome. A bare unfiltered `swift test` across both targets could race; the make targets do not.
  2. *`taggedSubsetBreakdown` still measured nothing.* Its `try?` mapped both failed and successful-but-empty analysis to an empty evidence array, so an all-fail corpus printed "0/82" and passed. Added an `analyzed: Bool` to the task result and an `#expect` that all 82 analyses completed before empty evidence is read as "no tag". Verified: 5/82 have metadata, all 82 analyzed.
  Nits also applied: the consistency no-result set now records the CAUSE per file (absent / decode / no-grid) to make the frozen I/O-matrix "names cause" row true; the production-abstain test references `BNNSTechnique.confidenceThreshold` instead of a literal `0.50`; "resolved on disk" wording corrected to "resolved from the roster". Deferred: the allowlist's `lastPathComponent` key depends on cross-subdir filename uniqueness (holds in the current 82-row fixture; ledgered).

## Design Notes

**Two instructions in the task brief cannot be followed as written; both were verified against source.**

1. *"Delete the `bundledReferenceURL` machinery."* It is `public static let` in `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:105` and the default argument of `public init(modelURL: URL? = Self.bundledReferenceURL) throws` at `:264`. Deleting it is a production change and a public-API removal, both forbidden by this PR's own boundaries. Only the **test-side** predicate `bundledModelMissing()` is deleted. The dead default argument is ledgered.

2. *"Real inference yields a non-nil `MLEvaluation`."* Empirically impossible at production thresholds. `CustomBundled.mlmodelc` is the rejected v1 graph; probed on synthetic input it returns `softmaxMax: 0.069` against the shipped gate-1 threshold of `0.50`, so `evaluate` correctly returns nil. The assertion is therefore split: non-nil under `thresholdOverride = (0.0, 0.0)` (proves featurize → infer → decode produces an in-range tempo, `bpm: 169.0`), plus an assertion that the production path abstains at `gate1Softmax` (proves the confidence policy is wired). Asserting the exact decoded BPM was considered and rejected as needlessly toolchain-brittle; the range and the `MLDiagnosticSnapshot.inputFeatureChecksum` already serve as the parity tripwire.

**The consistency gate measures 81 tracks, not 82.** `ProbeFormat` has cases for mp3/flac/wav+aiff and none for m4a, so `filesByFormat` silently `continue`s the corpus's single `.m4a` file out of the input. Confirmed by the 2026-07-24 baseline run: `tracks resolved = 81`. This is a third silent shrink in the suite #163 is about, but `ProbeFormat` is the grouping key for four wall-clock gates in `SharedDecodeImpactTests`, so changing it would move their reporting basis. Pinned at 81 with a comment; ledgered with a re-open trigger.

**The gate has 0.1 points of headroom.** Baseline is 73 usable / 81 analyzed = 90.1% against a `>= 0.90` floor. One additional `.disagree` fails it. This is an independent argument against changing the corpus basis in this PR, and worth stating in the PR body so the next person does not read the margin as comfortable.

**Only one suite converts to throwing init.** Classification by the brief's own test — is a make target or AC treating this suite's green as evidence? `ConsistencyContractCorpusTests` backs the AC8 gate: convert. `DAWOracleBenchmarkTests` and `MLPolicySweepTests` already have throwing inits (their `.enabled(if:)` is a target selector layered on top). `AccuracyForensicsTests`, `BNNSImpactTests`, `FR18EvaluationHarnessTests` are reports and producers. `MLTechniquePerfTests` and `MetadataCorroborationOA300Tests` live in the unit target, where a throwing init would break bare `make test`.

## Verification

**Recorded results (2026-07-24, Apple M-series, macOS 15):**
- `make test` (no corpus env) — **923 tests / 159 suites green.** Delta vs the 925/159 baseline: −4 deleted (`initSucceedsForBundledModel`, the vacuous `evaluateProducesPlausibleBPM`, and the 2-test dead abstain-floor suite) +2 new real-inference assertions. Suites net 0 (−1 abstain-floor, +1 inference). The material win is invisible in the count: 8 formerly-permanently-skipped BNNS tests now execute for real.
- `make benchmark` — **11 tests / 1 suite green, 108s.** The new denominator, decode-count, genre-reconciliation, and non-nil assertions all hold on the real corpus.
- `make consistency-rate-oa300` — green, `tracks resolved = 81`, `noResult = 0` (allowlist calibrates empty), 90.1% ≥ 90%.
- `make fmt` / `make lint` — clean, 6 violations / 0 serious, all pre-existing in build artifacts / untouched files.

**Bite proofs** (temporary mutation → run → revert). Rows a–g all CONFIRMED. The mutations were run against the committed baseline so `git checkout` restores the real work (a mid-run `git checkout` on uncommitted edits reverted three files earlier and had to be reconstructed — commit before mutating):

| # | Guard | Mutation | Result — CONFIRMED |
|---|---|---|---|
| a | consistency fail-loud init | `make consistency-rate-oa300 OA300_CORPUS_PATH=""` | `Caught error: .corpusPathNotSet`; `make: *** Error 1` (was green before) |
| b | `noResult` allowlist | seed allowlist with `BITE-B-bogus.wav` | `observed([]) == known([BITE-B-bogus.wav])` fails, names the recovered file |
| c | 81-file cardinality | expect `== 82` | `files.count(81) == 82` trips |
| d | non-nil inference | remove the threshold override | `evaluate` returns nil → `#require` fires "must produce a non-nil MLEvaluation" |
| e | production-abstain lock | add a threshold override to the abstain test | `evaluation` becomes `MLEvaluation(bpm: 169.0)` → `== nil` + gate-1 asserts fire |
| f | OA300 denominator | `analyzableTrackCount` 82→83 | `availableTracks.count(82) == 83` trips across MIREX/tagged/merge/genre, before the DSP loop |
| g | `try?` removal | pre-read loop over `availableTracks.dropLast()` | `audioData.count(81) == availableTracks.count(82)` trips — no silent shrink |
