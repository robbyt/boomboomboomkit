---
title: 'GH-167 item 3 — Ensemble seam correctness (octave fold, NaN-confidence rule, abstain records)'
type: 'bugfix'
created: '2026-07-23'
status: 'in-progress'
baseline_commit: '0da557d'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not renegotiate without the human">

## Intent

**Problem:** Three validated defects at `AudioAnalysisService.combineEnsemble` (GH #126, #149, per their 2026-07-22 validation comments). (A) `clampEnsembleBPM` fabricates boundary tempos: a finite out-of-range ML BPM is clamped to 60/200 (240 → 200, a tempo supported by nothing) where an octave fold gives 120 — and the library already owns the folding tool, `BPMAnalyzer.rangeNormalize`. (B) Under `.mlOnly`, a non-finite ML confidence collapses to 0.0 and ML still wins unconditionally (winner `.ml`, confidence 0.0) — a silently-wrong high-trust result from the shipped BYOW extension point. (C) `evaluate()` returning nil under `.mlOnly`/`.highestConfidence` returns bare DSP with NO `EnsembleDecision`, while the non-finite-bpm abstain right beside it attaches one; the repo's own FR-18 artifact called this contamination "the blocker" (`7-6-fr18-promotion-gate-and-fr23-octave-consistency-report.md:29`).

**Approach:** One PR per the #167 item-3 plan, fixing exactly the three defects at the seam. (A) `foldEnsembleBPM` delegates to `BPMAnalyzer.rangeNormalize` — no second folding implementation. (B) Non-finite confidence becomes an abstain under both `EnsembleDecision`-recording policies (`.mlOnly`, `.highestConfidence`); the weighted policies keep their collapse-to-0 vote, test-locked. (C) A three-state seam input (`notInvoked` / `abstained` / `evaluated`) replaces the optional `MLEvaluation?`, and every ML invocation outcome under `.mlOnly`/`.highestConfidence` attaches a decision, discriminated by a new `EnsembleDecision.AbstainKind`. Closes #126, #149 (manual close — PR base is develop).

**Defect-B re-litigation (explicit, per the task brief):** The Story 4.4 two-sentinel rule (deferred-work.md:415, DD #4: "non-finite [confidence] collapses to 0.0 (NOT abstain — bpm may still be valid)") was recorded 2026-05-08, when the bundled model was the only conformer and its softmax-derived confidence could not be non-finite. That context is gone: Story 4-6 Branch C removed the bundle, BYOW is the ONLY ML path, and a buggy consumer conformer emitting NaN confidence is the realistic input class. "bpm may still be valid" remains true but no longer justifies trusting the evaluation: under `.mlOnly` the collapsed 0.0 wins unconditionally, and under `.highestConfidence` the record claims ML participated normally with confidence 0 (a 0-conf tie at `dspConfidence == 0` records `.tie`, not the truth). DECISION: non-finite confidence is unusable under the two `EnsembleDecision`-recording policies → abstain (`.nonFiniteConfidence`), DSP result unchanged. Under `.default`/`.weightedVoting` the 0-vote collapse is KEPT (task-brief mandate) and test-locked as "zero-vote participation" — never described as equivalent to abstention; the residual record conflation goes to the ledger.

## Boundaries & Constraints

**Always:** `.dspOnly` byte-identity under default options — no additional ML work, byte-identical observable output (locks: `dspOnlyDoesNotInvokeMLTechnique` + the inertness bitPattern suites, all untouched). `evaluateMLIfActive`'s cancellation bracket ordering is preserved exactly (`.notInvoked` returns before the checks; `.abstained` means evaluation ran and passed both; strict mutation-after-cancellation per Story 4-6 AC #4). Every behavior change bite-proven via temporary revert, recorded in the Change Log. Sentinel precedence is bpm-first: `bpm: .nan, confidence: .nan` records `.nonFiniteBPM`.

**Ask First:** Any `EnsembleDecision`/`AbstainKind` shape beyond what this spec enumerates (this spec is the named vehicle for exactly these changes). Any new `Winner` case. Any `EnsembleWeightResolution` field change. Changing weighted-policy NaN-confidence behavior.

**Never:** No DSP behavior change (`BPMAnalyzer` untouched except `rangeNormalize`'s stale doc comment). No throws added to analyzers. No touching #148 (confidence calibration), #127 (effective-intensity report), #144 (abstain thresholds), or the dead abstain-floor suite (#167 item 4). No `rawMLBpm` field this PR (ledger). No rewriting historical story specs in the stale-prose sweep. Corpus benchmarks not re-run (default path byte-identical; `make test` is the net).

## I/O & Edge-Case Matrix

All rows at the `combineEnsemble` seam with a trace present; `dsp` = DSP winner (bpm 120, conf 0.9 unless stated).

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fold high (A) | `.mlOnly`, ml bpm 240, conf 0.8 | bpm 120 (NOT 200), decision `.ml`, `selectedBPM == 120` | N/A |
| Fold low (A) | `.mlOnly`, ml bpm 45 | bpm 90 (NOT 60) | N/A |
| Fold multi-octave (A) | `.mlOnly`, ml bpm 999 | bpm 124.875 (999/8) | N/A |
| Fold boundaries (A) | ml bpm 200 / `200.nextUp` / `60.nextDown` / 30 | 200 / ~100 / `119.9…` (doubled) / 60 | N/A |
| Non-positive bpm (A) | `.mlOnly`, ml bpm 0 or −5 | 60 (`rangeNormalize` floor — byte-identical to old clamp; ACCEPTED unchanged) | N/A |
| Subnormal bpm (A) | `.mlOnly`, ml bpm `Double.leastNonzeroMagnitude` | doubled into range: finite, in `60..<120` | N/A |
| Fold under weighted (A) | `.weightedVoting`, ML wins, ml bpm 240 | bpm 120; resolution `selectedBPM == 120` | N/A |
| NaN conf, `.mlOnly` (B) | ml bpm 128, conf `.nan`/`.infinity`/`-.infinity` | DSP unchanged; decision `.dsp`, `mlConfidence == nil`, `abstainKind == .nonFiniteConfidence` | Abstain, no trap |
| NaN conf, `.highestConfidence` (B) | same | same abstain record; DSP unchanged | Abstain |
| NaN conf, weighted (B, locked) | `.default`/`.weightedVoting`, ml conf `.nan` | ML vote 0 (`mlEffectiveVote == 0`, not nil); DSP wins; zero-DSP-vote case records `.tie` | Zero-vote participation |
| Both sentinels (B) | ml bpm `.nan`, conf `.nan` | `abstainKind == .nonFiniteBPM` (bpm checked first) | Abstain |
| nil-abstain, `.mlOnly` (C) | seam input `.abstained` | DSP unchanged; decision `.dsp`, `mlConfidence nil`, `abstainKind == .modelAbstained` | Abstain |
| nil-abstain, `.highestConfidence` (C) | `.abstained` | same record shape | Abstain |
| Not invoked (C) | seam input `.notInvoked` (any policy) | no `EnsembleDecision` (weighted still emit their `EnsembleWeightResolution`, unchanged) | N/A |
| No trace (C) | `.abstained`, `dspWinner.trace == nil` | no attachment (nothing to attach to) — locked | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — the seam. New internal `enum MLSeamOutcome { case notInvoked, abstained, evaluated(MLEvaluation) }`; `evaluateMLIfActive` returns it (`.notInvoked` from the first guard, before cancellation checks); `finishBPMAnalysis` passes it through; `combineEnsemble(dspWinner:ml:policy:)` consumes it — `.mlOnly`/`.highestConfidence` attach a decision for every invocation outcome; `clampEnsembleBPM` → `foldEnsembleBPM` delegating to `BPMAnalyzer.rangeNormalize`; doc-comment Sanitization + EnsembleDecision-matrix sections rewritten ("when a trace exists, `.mlOnly`/`.highestConfidence` record every ML invocation outcome; `.notInvoked` attaches nothing").
- `Sources/BoomBoomBoomKit/EnsembleDecision.swift` — nested `public enum AbstainKind: String, Sendable, Hashable, Codable { case modelAbstained, nonFiniteBPM, nonFiniteConfidence }`; stored `abstainKind: AbstainKind?`; `mlAbstained` becomes computed (`abstainKind != nil`); init drops `mlAbstained`, adds `abstainKind`, `precondition`-enforced population matrix: `mlConfidence == nil` IFF `abstainKind != nil`; abstain ⇒ `winner == .dsp`; `policy ∈ {.mlOnly, .highestConfidence}`; `.tie` only under `.highestConfidence`. Doc rewrite (attachment rule, folded-not-clamped `selectedBPM`).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2100-2101` — `rangeNormalize` stale doc comment only (subnormals are doubled into range, not floored).
- Doc prose/symbol refs: `EnsemblePolicy.swift` (`:13`, `:45` signature refs; `:39-43`, `:88-89` clamp/abstain prose), `BPMDiagnosticTrace.swift:166`, `MLTechnique.swift` `MLEvaluation.init` doc, `Resources/Documentation/EnsemblePolicy/mlOnly.md`; factual-claims grep over `Sources/`, `Tests/`, `README.md`, the docs corpus, DocC `Articles/`, `Demo/` for stale clamp/iff prose.
- `CLAUDE.md` — `EnsembleDecision` bullet rewrite.
- `Tests/BoomBoomBoomKitTests/EnsembleCombinerTests.swift` — seam migration (~25 sites), matrix-row tests per I/O matrix, computed-`mlAbstained` locks, existing `*_mlNil` tests flip to expect decisions (fixtures must carry a trace — verify `makeFixture`).
- `Tests/BoomBoomBoomKitTests/EnsemblePolicyTests.swift` — 9-cell matrix Cell B flips under `.mlOnly`/`.highestConfidence`; decision-table generator grows `ml_not_invoked`/`ml_abstained` outcomes with the seam outcome as a dedicated row field (`.dspOnly × .abstained/.evaluated` rows documented as defensive, not production-reachable); determinism test migrated.
- `Tests/BoomBoomBoomKitTests/MergeSemanticEqualityTests.swift` — 4 mechanical seam-call updates.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceExport.swift` — `EnsembleDecisionJSON` gains optional `abstainKind: String?`; `Demo/.../BoomBoomBoomBPMTests/Fixtures/5-4-trace-export-golden.json` updated; 5 demo-test `EnsembleDecision` constructors migrate (the three `.dspOnly` fixtures move to a decision-producing policy — now precondition-unconstructible).
- `_bmad-output/implementation-artifacts/deferred-work.md` — `:415` DD annotation gains a supersession pointer to this spec; "does not record pre-clamp ML BPM" (~`:471`) + m18 (`:506`) strengthened (fold fired the old trigger; new decision + trigger); new item-3 section: (1) `enableTrace == false` record drop, (2) `EnsembleWeightResolution` provenance conflation incl. weighted NaN 0-vote residual.
- `_bmad-output/implementation-artifacts/4-4-ensemble-policy-decision-table.json` — regenerated (WILL change: new rows + row field); committed same commit.

## Tasks & Acceptance

**Execution:**
- [ ] `AudioAnalysisService.swift` — `MLSeamOutcome` + `evaluateMLIfActive` return + `combineEnsemble` reshape + `foldEnsembleBPM` + doc rewrite.
- [ ] `EnsembleDecision.swift` — `AbstainKind` + stored/computed reshape + precondition matrix + doc rewrite.
- [ ] `BPMAnalyzer.swift` — `rangeNormalize` comment fix.
- [ ] Doc prose/symbol refs + `mlOnly.md` + CLAUDE.md + stale-prose grep sweep.
- [ ] Library tests: EnsembleCombinerTests / EnsemblePolicyTests / MergeSemanticEqualityTests migrations + all I/O-matrix rows + locks.
- [ ] Demo: TraceExport + golden fixture + constructor migrations.
- [ ] deferred-work.md: annotation, strengthened entries, new item-3 section.

**Acceptance Criteria:**
- Given each fix temporarily reverted (fold→clamp; NaN-confidence abstain removed; nil-abstain record removed), when its regression tests run, then they fail exactly as the pre-fix defect predicts; recorded per fix.
- Given `make test` post-fix, then all suites pass; `dspOnlyDoesNotInvokeMLTechnique` and the inertness bitPattern suites are byte-untouched.
- Given every I/O-matrix row driven at the seam, then the stated output and record shape hold, including `selectedBPM == result.bpm` for every attached decision.
- Given `make fmt && make lint`, then clean, 0 serious. Given `make demo-fmt && make demo-lint && make demo-build && make demo-test`, then all green (demo files touched).
- Given the PR, then it targets `develop`, notes that `Fixes #126`/`Fixes #149` will not auto-close, and calls out the regenerated decision-table artifact.

## Spec Change Log

- **2026-07-23, PR #170 review round (robbyt, full 17-file review; `@codex` bot found no major issues).** No blockers — the review independently confirmed the fold/abstain/record semantics against the I/O matrix, all five init preconditions against every constructor site, the four earlier Codex blockers as actually fixed, and the test-count arithmetic. Four non-blocking items raised, all verified against source and all addressed here. (1) **Sentinel-coverage asymmetry:** `.highestConfidence`'s non-finite-*bpm* guard had no test though the symmetric `.mlOnly` arm had three, and the weighted branch's no-voice guard — reachable both via `.abstained` and via `.evaluated` carrying a non-finite bpm — was locked only on the first route. Both closed with parameterized tests whose fixtures give ML a WINNING confidence (0.99 vs 0.3/0.9), so they prove the guard fires rather than that DSP happened to be ahead. (2) **The non-positive-bpm acceptance was implicit** — `fold_nonPositive_floors` locks that `bpm: 0`/`-5` produces a *winning* 60.0 while `MLEvaluation` documents `0` as undefined; baseline-identical and correctly out of scope, but it lacked the entry + re-open trigger the other three accepted residuals have. Now ledgered. (3) **The public-init precondition matrix is a BYOW trap surface** — recorded in Design Notes and the PR body, since the repo has no CHANGELOG. (4) **Naming drift:** `MergeSemanticEqualityTests.defaultWithoutMLEqualsDSP` said "ML is absent" while passing `.abstained` (the model ran and declined); parameterized over both no-voice outcomes so the name is true and neither route depends on the two staying branch-shared. Items 1 and 4 are the same principle the PR applies elsewhere: do not rely on a shared branch staying shared.

- **2026-07-23, post-implementation Codex diff review (thread `019f9113-1fe1-7181-a7b2-fa11f066a679`).** Reviewed the staged 17-file diff against the spec. Confirmed upheld: `.dspOnly` byte-identity (guard returns `.notInvoked` before the cancellation checks; combiner returns `dspWinner` untouched), no analyzer throws added, cancellation bracket ordering preserved exactly, fold correct at both boundaries / multi-octave / non-positive / subnormal with no remaining clamp call site, demo field mapping correct. Four blockers raised, all verified against source and all fixed: (1) **`EnsembleDecision` under-enforced the `.mlOnly` matrix** — `policy: .mlOnly, winner: .dsp, abstainKind: nil` was constructible though production cannot emit it (no reachable precondition failure among the 10 production constructors — under-enforcement, not a shipping crash); added the `.mlOnly` contested ⇒ `winner == .ml` precondition. (2) **`.weightedVoting` zero-vote behavior was not test-locked** — every zero-vote test used `.default`; the two policies share a branch today but the associated-value case could regress independently, and the frozen requirement names both; the three zero-vote tests are now parameterized over both. (3) **The demo golden fixture encoded an impossible pairing** — its run block said `ensemblePolicy: "dspOnly"` while its ML block carried an `.mlOnly` decision (the pre-diff version was self-consistent but represented an equally impossible `.dspOnly`-with-decision state); run policy moved to `mlOnly` in both the Swift expectation and the checked-in JSON. (4) **Bite proofs and verification results were not recorded** — now in the Verification section. Test gaps closed: the `0-vs-0` `.highestConfidence` case (pre-fix recorded `.tie`, post-fix records the abstain — the exact record-honesty argument that justified extending the abstain to that policy, previously untested), the fold on `.highestConfidence`'s ML-win branch (third call site), and export projection of all three `AbstainKind`s (the golden pins only `modelAbstained`). Left as-is with rationale: no new cancellation test for nil-return-plus-late-cancellation (existing tests protect the bracket; Codex confirmed by inspection the ordering is intact).

- **2026-07-23, pre-approval Codex plan review (thread `019f8d77-315d-7651-9a0d-c3d1de85cfa9`, 2 rounds).** Round 1: three-state `MLSeamOutcome` replaces `mlInvoked: Bool + MLEvaluation?` (meaningless fourth state unconstructible); NaN-confidence abstain extended to `.highestConfidence` (record honesty); `mlAbstained` computed, not stored (contradictory states unrepresentable); `.evaluationNil` renamed `.modelAbstained` (domain name); demo compile breakage surfaced (export mirror, golden fixture, 5 direct constructors); boundary/precedence/trace-nil tests; grep scoped away from historical story specs. Round 2 ("with those adjustments the plan is ready"): two-way `mlConfidence`↔`abstainKind` invariant + policy/winner precondition matrix; `.dspOnly` demo fixtures migrate (now unconstructible); `abstainKind` exported in demo JSON + golden update; ±∞ parameterized confidence tests; weighted locks assert `mlEffectiveVote == 0` + zero-DSP-vote `.tie` case; decision-table gains a dedicated seam-outcome field; subnormal fold test; honest rawMLBpm ledger language (old trigger fired; `decodedBPM` is NOT a general substitute — plain conformers need not implement diagnostics); computed-`mlAbstained` locks; cancellation-ordering preservation named an Always constraint.

## Design Notes

Fold termination: for finite positive input, doubling strictly increases to ≥ 60 and halving strictly decreases to ≤ 200 — both loops are bounded (≈1,100 doublings from `Double.leastNonzeroMagnitude`; ≈1,020 halvings from `.greatestFiniteMagnitude`), so `rangeNormalize` always terminates in range. Finite ≤ 0 returns the 60 floor — same value the old clamp produced, so the blast radius of accepting it is zero relative to baseline; a garbage non-positive BYOW estimate becoming an authoritative 60 predates this PR and is out of its validated-defect scope. That acceptance is now an explicit, re-openable ledger entry rather than an implicit one (`deferred-work.md`, GH-167 item 3 section, third entry — candidate fix is a fourth `AbstainKind` case, which is an Ask-First boundary here).

**The `EnsembleDecision.init` precondition matrix is a pre-1.0 break across the public BYOW boundary.** The type is public and its initializer is the surface a consumer touches when constructing decisions in their own tests; the five preconditions mean previously-compiling constructions now trap at runtime instead of failing to compile. The in-repo precedent is this PR itself — three demo fixtures constructed decisions under `.dspOnly`, a combination production can never emit, and had to migrate. This is deliberate and consistent with the `MLDiagnosticSnapshot` population-matrix precedent (make impossible states unrepresentable rather than silently accepted), and pre-1.0 framing permits it. The repo carries no CHANGELOG, so this note and the PR #170 body are the release record.

Seam three-state: `notInvoked` = the `evaluateMLIfActive` first guard (policy inert, no technique, or no trace) — returns before the cancellation brackets; `abstained` = `evaluate(trace:)` ran and returned nil; `evaluated` = non-nil. The seam can now express what actually happened, so the decision-table artifact encodes it as a dedicated field.

## Verification

**Commands (RUN 2026-07-23, results recorded):**
- `make fmt && make lint` — PASS: clean, 0 serious. Six warnings remain, all pre-existing in files this diff does not touch (5 × `optional_data_string_conversion` in demo test files, 1 × grandfathered `todo` in `ContentView.swift:701`).
- `make test` — PASS: **921 tests / 159 suites** (item-2 baseline was 907/156; +14 tests, +3 suites). Re-run post-review-patches: see Change Log entry.
- `make demo-fmt && make demo-lint && make demo-build && make demo-test` — PASS (`confidence-label-audit: PASS`, `** BUILD SUCCEEDED **`, `** TEST SUCCEEDED **`).
- Corpus benchmarks NOT re-run — default `.dspOnly` path byte-identical (locked by `dspOnlyDoesNotInvokeMLTechnique` + the inertness bitPattern suites, all untouched and green); documented in the PR.

**Bite proofs (temporary revert, one per fix — all three confirmed to bite):**

| Fix | Mutation applied | Observed failure |
|---|---|---|
| A (fold) | `foldEnsembleBPM` body reverted to `min(max(bpm, 60.0), 200.0)` | 7 assertions across 5 tests: `999 → 200` not `124.875`; `240 → 200` not `120` (result AND `resolution.selectedBPM`); `45 → 60` not `90` (result AND `decision.selectedBPM`); `200.nextUp` and `60.nextDown` unfolded; subnormal → `60` not `64` |
| B (NaN-confidence abstain) | `.mlOnly`'s `guard evaluation.confidence.isFinite` block deleted | `mlOnly_nonFiniteConfidence_abstains` fails for all three arguments (`nan`/`inf`/`-inf`): `r.bpm → 128.0` (ML won) not `120.0`, `r.confidence → 0` not `0.9`, `d?.winner → .ml` not `.dsp` — i.e. the mutation reproduces defect #126b exactly |
| C (nil-abstain record) | `.mlOnly`'s `.abstained` arm reverted to bare `return dspWinner` | Bites at BOTH grains: unit — `mlOnly_modelAbstained` 4 issues (`d?.winner → nil`, `abstainKind → nil`, `mlAbstained → nil`, `selectedBPM → nil`); service end-to-end — `EnsemblePolicyTests` 9-cell matrix fails with `trace.ensembleDecision → nil` |

Each mutation was reverted immediately after its proof and the suites re-confirmed green (`grep -c "MUTATION PROOF"` → 0).
