---
title: 'GH-141 — Octave-folded posterior decode: measured, disproved, REMOVED'
type: 'feature'
created: '2026-07-26'
status: 'removed'
review_loop_iteration: 0
baseline_commit: 'e74ce57'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BNNSTechnique.swift:852` decodes tempo as `bpm = 30.0 + Double(maxIdx)` — bare argmax over 256 bins, with no octave reasoning. The E0 diagnostic (2026-06-09) showed that below 100 BPM this fails in one specific, correctable way: of 60 GiantSteps tracks in that band, **38 predict exactly 2× truth**, and octave-tolerant scoring lifts the band from 1/60 to 39/60. Every BYOW consumer inherits the "calls a 70 BPM track 140" failure. `OctaveEquivalencePolicy` has shipped since Story 6.5a with no consumer.

**Approach:** Add an **opt-in, default-off** octave-folded posterior decode: when the posterior mass sitting at half the argmax tempo is a configurable fraction of the argmax mass, decode the fundamental instead. Ship it with a per-band impact harness so the operator can measure net effect and decide whether the default flips. Fold **downward only**, because that is the only direction the diagnostic evidences.

## Corrections to the issue's own premises

Verified against the plan document and the code before drafting:

1. **#141 says "~53/661 GiantSteps tracks of measured headroom".** It is not measured. `octave-bias-finding-and-plan.md` carries a Codex review caveat from 2026-06-09: 401/661 is an **oracle** ceiling computed with truth-aware octave equivalence, it "is NOT a guaranteed decode recovery", and it "cannot be replayed offline from the current dumps, which carry only decoded BPM + `softmaxMax`, not the full 256-bin posterior". 53 is an upper bound on what a *perfect* octave oracle could recover, not a forecast. No number in this spec's ACs asserts a recovery figure.
2. **The plan requires a gate this issue does not mention.** Same document: recovery "must be MEASURED with full-posterior dumps + DSP arbitration, and gated on per-band NET impact (a 'prefer fundamental' rule can damage the correct 120-175 bands)". Those bands hold 550 of 661 tracks. That is why this ships opt-in with a harness rather than as a default-on fix.
3. **#141's code claim holds.** `BNNSTechnique.swift:852` is verbatim as quoted, and `decodeLogitsWithDiagnostic` is a pure static function over `[Float]`, so the fold is unit-testable with synthetic logits and no model.
4. **#166 does not block this.** Its 2026-07-21 operator update ranks octave-folded decode as lever 1 of 5.

## Boundaries & Constraints

**Always:**
- Default output is **byte-identical** to today. `.disabled` is the default policy and must be provably inert (`Double.bitPattern` equality), per the project's opt-out regression convention.
- Fold **downward only** (argmax → half). The diagnostic recorded 38 doubling errors and **zero** halving errors; a symmetric rule would add risk with no evidence behind it.
- A fold must never produce a BPM outside `60.0...200.0`. If the fundamental falls below 60, do not fold.
- Every fold is visible in `MLDiagnosticSnapshot` — a silent tempo rewrite is unacceptable on a diagnostic path built to explain abstains.
- Swift and Python decode must agree. `eval.py` is the offline scorer and must mirror the rule.
- The harness reports per-band results and must not print a single aggregate number without the band breakdown.

**Ask First:** Flipping the default to enabled (that is the follow-up, gated on measurement). Any change to `MLTechnique` / `MLEvaluation` signatures — frozen per Story 4-5 DD #18. Folding upward.

**Never:** Claiming a recovery number this change has not measured. Touching the DSP path or any corpus floor. Making the fold depend on `BPMDiagnosticTrace` DSP state — DSP arbitration is a separate, larger lever the plan sequences after this one.

**Decisions frozen at planning (operator, 2026-07-26):**
1. Opt-in, default OFF, shipped together with the measurement harness.
2. `BNNSTechnique.Options` struct replaces the growing defaulted-init-parameter list. Pre-1.0 break, no BC.
3. Fold rule is posterior mass ratio with a tunable threshold — not unconditional prefer-lower, not DSP-arbitrated.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Default policy | `.disabled` | Bare argmax; bit-identical `bpm`/`confidence` to `e74ce57` | n/a |
| Clean doubling | argmax bin 110 (140 BPM), strong mass near bin 40 (70 BPM), ratio ≥ threshold | Decodes **70.0**; snapshot records the fold and the ratio | n/a |
| Model is right | argmax 140 BPM, negligible mass at 70 | No fold; decodes 140.0 | n/a |
| Fundamental below range | argmax bin 30 (60 BPM), half = 30 BPM | **No fold** — would leave `60...200` | decode proceeds unfolded |
| Half-bin parity | argmax odd-offset bin, exact half lands between bins | Mass summed over the bins straddling the half-tempo, not a single bin | n/a |
| Threshold 0.0 | fold on any non-zero half mass | Folds aggressively; legal, and what the sweep's low end exercises | n/a |
| Non-finite threshold | `.massRatio(threshold: .nan)` | `init` throws `MLTechniqueError.invalidThreshold` | throw, do not substitute |
| Out-of-range threshold | `threshold: 4.0` | Clamped to `[0, 1]`; a finite value carries intent (item 6 precedent) | clamp |
| Non-finite logits | NaN / ±Inf present | Unchanged: `.nonFiniteLogits` abstain, fold never runs | existing path |
| Harness, no model | `BNNS_MODEL_URL` unset | `make` errors out; a directly-enabled run fails its `#require`. Never silently passes | fail closed |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:811-864` — `decodeLogitsWithDiagnostic`, pure static over `[Float]`; the softmax `probs` array is already materialized, so the fold needs no new compute pass. `:852` is the bare-argmax line. `:160` `bpmBinOffset = 30.0`. `:253-272` the init whose three defaulted params become `Options`.
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:1206-1222` — `BNNSDecodeOutcome` (`.success` / `.outOfRangeArgmax` / `.nonFiniteLogits`); fold evidence rides on `.success`.
- `Sources/BoomBoomBoomKit/MLDiagnosticSnapshot.swift` — `Outcome.win(Decode)` and the `Decode` payload reshaped in GH-167 item 6; the fold record is an additive optional on `Decode`.
- `Sources/BoomBoomBoomKit/MLTechnique.swift` — `MLTechniqueError.invalidThreshold(reason:)`, added in item 6; reused for the fold threshold.
- `Tests/BoomBoomBoomKitTests/BNNSTechniqueTests.swift:441-480` — the existing "decodeLogits hardening" section: synthetic `[Float]` logits, no model, runs in `make test`. The fold fixtures extend it.
- Construction sites to migrate: `BNNSTechniqueTests.swift` (6), `BNNSImpactTests.swift:469,474`, `FR18EvaluationHarnessTests.swift:176`, plus doc comments in `AudioAnalysisService.swift:230-231`, `MLTechnique.swift:111`, `CoreMLTechnique.swift:17`.
- `_bmad-output/ml-training/eval.py:93,111` — `pred_bin = int(np.argmax(probs))`, the Python mirror. `model.py:87` documents the formula string.
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` — ground-truth loading + band reporting to reuse for the harness.
- `_bmad-output/ml-models/giantsteps_v2_seed_42.mlmodelc` — the model the operator measures against.

## Tasks & Acceptance

**Execution:**
- [x] `BNNSTechnique.swift` — add `public struct Options: Sendable, Hashable` (`confidenceThreshold`, `marginThreshold`, `octaveFold`), `public enum OctaveFoldPolicy: Sendable, Hashable { case disabled; case massRatio(threshold: Double) }`, and `init(modelURL:options:)`. Per ADR-11 use `init() {}` with property defaults plus a `.default` static. Validate non-finite → throw, out-of-range → clamp.
- [x] `BNNSTechnique.swift` — implement the fold in `decodeLogitsWithDiagnostic`, taking the policy as a defaulted parameter so the static function stays directly testable. Sum half-tempo mass across the straddling bins; fold only when ratio ≥ threshold and the fundamental stays in range.
- [x] `MLDiagnosticSnapshot.swift` — add `OctaveFold { fromBPM, massRatio }` as an optional on `Decode`. **This spec is the named story authorization** the trace-field rule requires; run the five `bpm-diagnostic-trace` audit recipes.
- [x] Migrate the 9 construction sites and 3 doc-comment references to `options:`.
- [x] `BNNSOctaveFoldTests.swift` (new) + `BNNSTechniqueTests.swift` — fixture tests on synthetic logits: clean doubling folds; confident-correct does not; below-range fundamental does not; parity case sums both straddling bins; threshold boundary; non-finite threshold throws. Plus a `bitPattern` inertness test proving `.disabled` matches `e74ce57`.
- [x] `eval.py` + `model.py` — mirror the rule behind the same default-off flag; keep the formula string accurate.
- [x] New `Tests/BoomBoomBoomKitBenchmarkTests/OctaveFoldImpactTests.swift` + `make octave-fold-impact-report` — env-gated (`OCTAVE_FOLD_IMPACT=1`, `BNNS_MODEL_URL`), runs the corpus ONCE at threshold 0.0 and reconstructs every other threshold offline from the recorded mass ratios, emitting per-band Acc1/Acc2 and net delta to JSON.
- [x] `deferred-work.md` — ledger whatever surfaces, including the DSP-arbitration lever this deliberately does not take.

**Acceptance Criteria:**
- Given default `Options`, when a file is analyzed, then `bpm` and `confidence` are `bitPattern`-identical to `e74ce57`.
- Given logits whose argmax is 140 BPM with half-tempo mass above threshold, when decoded under `.massRatio`, then the result is 70.0 and the snapshot carries `fromBPM == 140.0`.
- Given the same logits under `.disabled`, when decoded, then the result is 140.0 and the fold record is nil.
- Given an argmax at 60 BPM, when decoded under any threshold, then no fold occurs, because 30 BPM is outside the accepted range.
- Given a non-finite fold threshold, when `BNNSTechnique.Options` is used to construct, then init throws `.invalidThreshold` rather than substituting a value.
- Given `make test`, when it runs with no corpus and no model, then the fold fixtures all execute — they need neither.
- Given the harness, when run without `BNNS_MODEL_URL`, then it skips with a printed reason and does not report a passing measurement.

## Spec Change Log

**2026-07-26 (removal) — the feature is gone; the measurement is the deliverable.**
A full-branch review found eight defects, all verified. Five existed only
because the fold existed, and they cascaded: fixing the borrowed confidence
forced a gate-2 exemption, which corrupted `Decode.softmaxMax` (its documented
"max" fell below `softmaxSecondMax` on 602 of 604 folds), which made the golden
fixture's posterior arithmetically impossible. Each repair spawned the next.
Weighed against evidence that the fold is net-negative at EVERY threshold on the
only model that exists, and that the mass ratio does not discriminate at all,
the operator chose removal over further repair — matching the project's own rule
that a headline deliverable which does not work gets Branch-C deletion rather
than a deprecation cycle (Story 4-6 bundle pull; Story 8.9 revert).
Removed: `OctaveFoldPolicy`, `Options.octaveFold`,
`MLDiagnosticSnapshot.OctaveFold` and its projections, `octaveFoldCandidate` and
the decode fold branch, the gate-2 exemption, three JSON/UI mirrors, the Python
fold and its CLI flag, the impact harness, and `make octave-fold-impact-report`.
These are **intentional public API removals** relative to `develop`, allowed
pre-1.0. Fold-bearing JSON exports were never released and are intentionally
unsupported.
Kept: `BNNSTechnique.Options` (an API-design decision independent of the fold),
the golden fixture's populated `diagnosticSnapshot` (with a coherent non-fold
posterior — it was nil, so that schema had no coverage at all), and
`141-octave-fold-impact.json` byte-for-byte with a provenance note.
**KEEP on re-derivation:** one guard survives the deletion by design, in
`BNNSTechniqueTests` — every successful decode must report
`softmaxMax >= softmaxSecondMax` with the confidence and BPM both belonging to
the argmax. That is the invariant the fold broke, and without it the corrupted
behaviour could return unnoticed.

**2026-07-26 (measurement) — the fold works exactly as designed and is still net-negative. E1 is closed as measured-and-failed.**
The spec deliberately asserted no recovery number, and that restraint was
right: the rule does not pay out. Measured over all 661 GiantSteps tracks
against `giantsteps_v2_seed_42` (0 abstains), **every threshold from 0.0 to
1.0 is net negative on Acc1**; the best is -2, reached by folding almost
nothing. Threshold 0.0 recovers exactly the +38 sub-100 tracks E0 predicted
— the mechanism is sound — but costs 346 harmful folds elsewhere for a net
of -308.
The diagnosis is that the mass ratio carries no signal about correctness:
helpful folds median 0.199 (0.037-0.745), harmful folds median 0.192
(0.014-1.700), with 336 of 346 harmful folds above the smallest helpful one
and **zero** helpful folds above the largest harmful one. No threshold
separates them, because the model is *confidently* wrong on the tracks that
need folding — its mass sits at the doubled tempo with nothing at the
fundamental. The information needed is absent from the posterior, so no rule
reading only the posterior can recover it. That is the mechanism behind the
plan's Codex caveat that the 401 oracle ceiling "cannot be replayed
offline".
Operator decision: ship default-OFF with the finding recorded, keeping the
knob (free at the default), the fixtures, and the reusable harness.
**KEEP on re-derivation:** the ACs must stay free of a recovery figure, and
the `OctaveFoldPolicy` doc comment must keep stating the negative result —
a knob documented as "prefers the fundamental" without the measurement
beside it is a trap for the next reader.

**2026-07-26 (implementation) — two corrections to the spec's own plan.**
(1) The spec specified `Options`/`OctaveFoldPolicy` as `Hashable`. Shipped as
`Sendable, Equatable` instead: the fold threshold is validated in
`BNNSTechnique.init`, not in `Options`, so a `.nan` threshold is
representable in an `Options` value and would break the hash invariant. This
follows the `MLExecutionPolicy` and `EnsembleDecision` precedent rather than
`SignalWeights` (which normalizes at init and therefore keeps `Hashable`).
(2) The harness's first full corpus run returned 0 of 661 rows because it
used `.dspOnly` to "populate the trace without ML fusion" — but
`captureMLFeatures` is gated on
`enableTrace && mlTechnique != nil && ensemblePolicy.invokesMLInference`, and
`.dspOnly` is the single policy for which the last term is false. The
empty-report `#require` caught it instead of emitting an all-zero report that
would have read as "the fold has no impact". Same failure shape as the
GH-111 metric error: reasoning about what a flag ought to do instead of
reading its gate. Ledgered as a usability trap.

**2026-07-26 (review round) — two merge-blockers and three tests that did not constrain what they claimed.**
The measurement artifact was unattributable: `gitSHA: "unknown"`, because the
first corpus run was invoked with bare `env` rather than through the Make
target that sets it, and the report recorded only a mutable absolute model
path. Regenerated through `make octave-fold-impact-report` (`e74ce57-dirty`)
with a SHA-256 digest over the `.mlmodelc` bundle; results reproduced
exactly. The harness now also `#expect`s a real SHA and full track
accounting (`decoded + abstained + missing == ground-truth`), so a partial
corpus can no longer read as a full one.
The API break itself was already authorized (frozen decision 2; no BC
pre-1.0), but four DocC references still pointed at the removed initializer
and one doc line said pre-GH-141 callers "keep exact behavior" in a way that
read as source compatibility. Both fixed.
Three test defects, all the same measure-nothing shape that has now bitten
three times in this issue series: the "bit-identical" test compared BPM to a
literal and only checked the other two outputs were *finite*, so it
constrained neither; the exact-threshold test never inspected the computed
ratio, so a `>` implementation could pass by float luck; and there was no
coverage of the range boundaries 120→60 and 200→100. All three rewritten —
the inertness test now compares `bitPattern` across all three pre-GH-141
entry points including the legacy `decodeLogits` wrapper and both failure
outcomes, and the threshold test reads the decoder's own ratio and probes
one ulp either side. Re-bitten: flipping `>=` to `>` now fails 5 tests where
the old test passed.
Also narrowed two over-claims: "no rule reading only the posterior can find
it" became "no threshold on this mass ratio separates the populations" (one
experiment does not disprove every posterior-derived rule), and the Python
mirror's "lockstep" comment now names what it deliberately does not mirror.
**KEEP:** the reviewer confirmed the fold algebra, the bounds safety, the
offline reconstruction, and every cited number against the artifact. The
value was entirely in the tests and the provenance, not the algorithm.

**2026-07-26 (edge-case review) — five gaps, and my clamp test could not fail.**
An exhaustive path trace over the staged diff found seven boundaries; five
were fixed, two deferred as documented-and-out-of-scope.
Fixed: (1) `MLDiagnosticSnapshot.OctaveFold` was `Hashable` with an
unchecked public initializer, so any foreign `MLDiagnosticTechnique` could
construct a `.nan` field and break the hash invariant for `Decode`,
`Outcome` and the whole snapshot — the exact hazard that keeps
`EnsembleDecision` off `Hashable`. My doc comment asserted "finite by
construction" when only the internal producer was constrained. Now a
failable init that refuses, with the record built inside
`octaveFoldCandidate` so a folded tempo and its provenance come from one
expression. (2) The harness used `#expect` for its `gitSHA` and
track-accounting checks; `#expect` does not halt, so a run failing its own
provenance gate still wrote a committable artifact — the very thing the gate
existed to prevent. Now `try #require`. (3) Rows with non-positive or NaN
truth BPM fell into no band and vanished from every per-band tally while
still counting as evaluated; now `require`d to sum. (4) `bundleDigest` of a
regular file or empty directory returned SHA-256 of nothing, a valid-looking
digest identifying no weights; now "unavailable". (5) Python `decode_bpm`
raised `ValueError` from `np.argmax` on an empty posterior where Swift
returns a clean abstain; now an explicit guard on both paths.
Deferred: the Python NaN-posterior divergence (already documented as
deliberately not mirrored) and nothing else.
**The bite proofs caught my own bad test.** The first clamp test asserted
threshold `-1.0` behaves like `0.0` — but `ratio >= -1.0` and `ratio >= 0.0`
accept every reachable ratio, since `halfMass` and `maxMass` are both
guarded positive, so it could not fail. Rewritten against the HIGH side,
where a ratio above 1.0 is reachable (two straddling bins; the corpus
recorded up to 1.70) and an unclamped 4.0 measurably differs from a clamped
1.0. Now bites: 5 failures.
**One guard is explicitly NOT bite-proven.** The `guard let record` else
branch is unreachable today — `fromBPM` is `30.0 + Double(maxIdx)` and
`ratio` was just guarded finite — so a mutation there changes dead code.
Kept as structure, labelled as such in both the code and the test, rather
than counted as a proof.
**KEEP:** run bite proofs on every new guard, including the ones that look
obviously correct. This is the fourth measure-nothing test in this issue
series, and each time only the mutation caught it.

## Design Notes

**Why mass-ratio rather than prefer-lower.** Unconditional preference for the fundamental is the plan's literal wording, and it is the rule most likely to do net harm: bands 120-175 hold 550 of 661 tracks and the model is already right on most of them, so halving a correct 140 to 70 costs more than the sub-100 band can repay. A ratio test only fires where the posterior is genuinely bimodal, which is the signature the E0 data describes — the pulse is found, the octave is picked wrong. The threshold is the knob the operator's measurement calibrates.

**Why downward only.** E0's per-band table records `pred = 2× truth` for 38 of 60 tracks below 100 BPM, and **zero** occurrences in every other band. There is no measured halving failure to correct, so a symmetric rule would add an unevidenced failure mode.

**Half-tempo does not land on a bin.** Bins are `bpm = 30 + index`, so the half of bin *i* sits at index `(i − 30) / 2`, an integer only when `i` is even. Rather than rounding to one bin, sum the mass of the bins straddling the exact half-tempo. This also matches how a trained classifier spreads probability across adjacent tempo bins.

## Verification

**Commands (final figures; see the Change Log for the intermediate rounds):**
- `make test` — **966 tests / 162 suites / 4 known issues, 0 failures.** Baseline before this branch was 941/161/4. No corpus, no model required for the fold fixtures.
- `make lint` — **6 violations, 0 serious in 186 files.** Unchanged.
- `uv run ruff check eval.py model.py` + `ruff format --check` — clean.
- The five `bpm-diagnostic-trace` audit recipes — **0 matches each** against `Sources/` and `Tests/`.
- `make octave-fold-impact-report` against `giantsteps_v2_seed_42.mlmodelc` — **661 tracks, 0 abstained, 130 s** in release. Artifact committed at `141-octave-fold-impact.json`.

**Bite proofs** (mutate, observe, restore from a scratchpad copy; source SHA re-verified `OK` afterwards):

| Mutation | Result |
|---|---|
| Invert the ratio comparison | 8 tests fail |
| Remove the 60 BPM floor | 5 tests fail |
| Round the half tempo to one bin | 5 tests fail |
| Fold even when `.disabled` | 7 tests fail |

Every guard is load-bearing. The harness's empty-report `#require` also bit for real, catching the 0-of-661 trace-gating bug described in the change log.

**Measured outcome:** net Acc1 delta by threshold — 0.0: −308, 0.1: −260, 0.2: −150, 0.3: −85, 0.4: −48, 0.5: −26, 0.6: −17, 0.7: −10, 0.8: −7, 0.9: −5, 1.0: −2. The `<100` band gains +38 at threshold 0.0 and +2 at 0.6-0.7. No threshold is net positive.
