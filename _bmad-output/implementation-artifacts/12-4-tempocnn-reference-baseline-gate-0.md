---
title: 'Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0)'
type: 'chore' # diagnostic measurement; no shipping code
created: '2026-08-07'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: true # 16 patches applied, one measurement-affecting (per-window normalization moved the gate row 539 -> 545)
baseline_revision: '4184c72' # branch rterhaar/12-4-tempocnn-reference-baseline, clean tree
final_revision: '0b8ef2c' # results commit (amended); harness+rule at 093decb
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** Our v2 model scores 348/661 (52.6%) GiantSteps Acc1 on the FR-18 evaluation
path while the published TempoCNN family reports ~82% -- but no published baseline has
ever been run on OUR evaluation path at OUR annotation version, so the thirty-point gap
is unattributed between model and ruler. Gate 0 (PRD §6, `prd.md:343`) exists to make
that attribution before any further model work is funded.

**Approach:** Obtain the published Schreiber & Müller TempoCNN weights (baseline settled
2026-08-01, `epics.md:159`), record provenance and checksums, run the model end to end in
a develop-only Python harness under `_bmad-output/ml-training/`, and score it on the same
661 GiantSteps rows, same accuracy definition, and same annotation source that produced
our 348/661 -- with the annotation alignment established from primary text and recorded
BEFORE scoring. Emit the Gate 0 report with a pre-registered decision rule.

## Boundaries & Constraints

**Always:**
- **Annotation alignment precedes scoring.** Establish from the primary papers which
  GiantSteps annotation set the published figures were scored against; record it, record
  the identity of our ground-truth file (basename + SHA-256, the `InputProvenance`
  precedent), and state whether they match. If they differ, the published figure is
  reported as measured-on-a-different-ruler and the only aligned comparison is the one
  this harness produces. Skipping this makes Gate 0 measure the ruler and report it as
  the model.
- **One pinned scoring protocol for the gate comparison**: the FR-18 definition our
  348/661 was measured on -- strict Acc1, 4% relative tolerance, no `tempo2` fallback,
  abstain/decode-failure counts as wrong, denominator exactly 661
  (`evaluate_fr18.py:41,46,75,89`). Strict Acc1 @2% and `tempo2`-floor Acc1 are reported
  as context rows only, each labelled with its protocol, so the DSP path's 81.2%
  (`tempo2`-floor @2%) is never silently compared against a strict number.
- **Pre-registered gate rule, in tracks, written into the report before the run:** let P
  = the published Acc1 converted to tracks on 661 at the aligned annotation (traced to
  primary text). Gate 0 fires iff the reference scores at or below the midpoint of 348
  and P; it passes iff above. Binary by construction -- no post-hoc judgment.
- **Every literature figure traces to primary text** (PRD §11, `prd.md:411` -- a
  summarizer previously fabricated a sigma, a decode method, and accuracy figures). The
  report carries a citation ledger: claim, paper, section/table. `prd.md:95`'s "82.1/97.1"
  is itself unverified until traced; if the primary text says otherwise, the primary text
  wins and the PRD row is annotated.
- Weights live OUTSIDE git (env-var path `TEMPOCNN_WEIGHTS_DIR`); the committed artifact
  is the provenance record (URL, version/tag, per-file SHA-256, license, retrieval date).
  The harness refuses to run if a checksum mismatches.
- The reference implementation is AGPL-licensed: develop-only consumption is fine, but
  nothing from it is copied into this repository, and public-facing surfaces and
  commit/PR text cite the academic papers (Schreiber & Müller), never the implementation
  repo or package name.
- `make test` unaffected; all four corpus floors unaffected (nothing here touches the
  Swift pipeline).

**Block If:**
- The weights cannot be obtained, or their checksums cannot be pinned to a stated source.
- The primary papers do not establish which annotation set the published GiantSteps
  figures used -- do not guess; the alignment record is the story's spine.
- The published evaluation corpus differs from our 661-row set such that the
  tracks-on-661 conversion for P is not defensible (e.g. a different track count with no
  stated subset) -- surface the discrepancy for the operator instead of improvising a
  denominator.
- The alignment record establishes that the paper scored a DIFFERENT annotation set than
  ours and no published figure at our annotation exists. P is then a different-ruler
  number and the midpoint rule's input is not self-evident; present the alignment record
  and a proposed P to the operator before running the gate comparison, rather than
  choosing silently.
- Gate 0 fires. Completing the report and the pressure-release artifact IS the story's
  deliverable in that branch, but re-planning stories 12.5+ is an operator decision:
  finish both artifacts, then HALT with the gate outcome as the blocking condition.

**Never:**
- No changes to `Sources/` or `Tests/` -- the AC is byte-identical on BOTH
  (`epics.md:2166`), stricter than 12.3. Verify with
  `git diff --stat 4184c72 -- Sources/ Tests/` empty.
- Nothing lands under `tools/coreml-convert/` (the only Python that ships to `main`;
  its scope is the consumer convert CLI -- `epics.md:2143-2145`).
- No weights, no downloaded model files, and no third-party model code committed to git.
- No fixing anything this story finds: no retrain, no decode change, no measurement
  repair. Gate 0's output is a finding; the fixes belong to 12.5+ or the re-plan.
- Do not depend on Story 12.3's Swift `AnnotationVersion` type (spec merged, not
  implemented). The Python side records annotation identity itself via digest.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Happy path | Weights present, checksums match, 661 rows resolve | Per-track predictions JSON + scored report: strict @4% (gate row), strict @2% and `tempo2`-floor @2% (context rows) | No error expected |
| Checksum mismatch | A weights file differs from the provenance record | Harness refuses to run, names the file and both digests | Hard exit, non-zero |
| Missing audio / row | Denominator would not be 661 | Refuse to score (the `EXPECTED_GIANTSTEPS` guard precedent) rather than silently shrinking the denominator | Hard exit naming missing rows |
| Per-track model failure | Decode error or non-finite output on one track | Counted as wrong (FR-18 abstain convention), recorded per-track | No global abort |
| Gate fires | Reference Acc1 <= midpoint(348, P) | Report states measurement-not-modelling; pressure-release artifact written; HALT blocked with gate outcome | By design |
| Gate passes | Reference Acc1 > midpoint | Report states the gap is attributable to our model/training; 12.5 differential proceeds on this scored baseline | No error expected |

</intent-contract>

## Code Map

Line numbers as of `4184c72`, 2026-08-07; named symbols govern.

- `_bmad-output/ml-training/evaluate_fr18.py` -- the scoring definitions to mirror:
  `ACC1_TOL = 0.04:41`, strict `acc1_correct:89` (no octave fallback),
  `octave_match:98` diagnostic, `EXPECTED_GIANTSTEPS = 661:75` denominator guard.
- `_bmad-output/ml-training/build_fr18_input.py:72-104` -- GiantSteps row resolution
  (`$GIANTSTEPS_CORPUS_PATH/giantsteps-tempo-ground-truth.json`, audio under
  `<corpus>/audio/`, `bpm <= 0` rows dropped). The harness reuses this resolution so the
  reference is scored on literally the same rows as our 348/661.
- `_bmad-output/ml-training/pyproject.toml` -- uv project; `[dependency-groups] dev`
  precedent; deps carry inline justification comments and sub-major pins; no
  tensorflow/keras today.
- `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md:13-17` and
  `_bmad-output/ml-training/fr18-predictions/maskedMelPretrain/seed_42/predictions.json`
  -- where our 348/661 lives (prose + raw predictions).
- `prd.md` -- FR-56 `:142`, Gate 0 `:343`, the 52.6 rows `:83`/`:95`, §11 tracing `:411`.
- `epics.md:2131-2168` -- the story ACs; `epics.md:52` -- pressure-release convention
  (realized example: `_bmad-output/ml-training/7-1-pressure-release.md`).
- `Makefile` -- ml-* develop-only target convention (fails loudly on main-only checkout).

## Tasks & Acceptance

**Execution (in order):**

- [x] Trace the published figures to primary text (Schreiber & Müller: the ISMIR 2018
  single-step TempoCNN paper and any follow-up carrying the GiantSteps evaluation).
  Record: exact Acc1/Acc2 figures with table/section, the accuracy tolerance used, the
  GiantSteps annotation set used, and the evaluated track count. This is the P input and
  the alignment record; everything downstream consumes it.
- [x] Obtain the published weights into `TEMPOCNN_WEIGHTS_DIR` (outside git). Write
  `_bmad-output/ml-training/tempocnn-baseline-provenance.json` -- source URL,
  version/tag, per-file SHA-256, license identifier, retrieval date, and the chosen model
  variant with the paper's name for it.
- [x] `_bmad-output/ml-training/pyproject.toml` -- add a `tempocnn-baseline` dependency
  group (TensorFlow/Keras runtime, sub-major pinned, inline comment naming this story).
  Core deps unchanged.
- [x] `_bmad-output/ml-training/tempocnn_baseline.py` -- NEW harness: verify checksums
  against the provenance record; resolve the same 661 rows via the `build_fr18_input`
  resolution; run the reference model end to end (its own featurization and decode, per
  the paper -- not ours); emit per-track predictions JSON (schema mirroring
  `fr18-predictions`) plus a scored summary with the three protocol rows and the
  pre-registered gate rule evaluated. Record the ground-truth file's SHA-256 in the
  output.
- [x] `_bmad-output/ml-training/tests/test_tempocnn_baseline.py` (or the existing pytest
  location under ml-training) -- unit tests on synthetic rows for: the strict @4% scorer
  reproducing `evaluate_fr18`'s verdicts, the denominator guard, the checksum refusal,
  and the midpoint gate rule at boundary values. No network, no weights needed.
- [x] `Makefile` -- `tempocnn-baseline` target (develop-only, ml-* convention;
  `TEMPOCNN_WEIGHTS_DIR` env-var with a loud failure when unset).
- [x] Run the full 661-track scoring. Write
  `_bmad-output/implementation-artifacts/12-4-tempocnn-baseline-report.md`: the
  alignment record, citation ledger, provenance pointer, the three protocol rows
  alongside our 348/661 and the DSP 537/661 (each labelled with its protocol), the gate
  rule and its verdict, and per-axis observations handed to Story 12.5.
- [ ] If and only if Gate 0 fires:
  `_bmad-output/implementation-artifacts/12-4-pressure-release.md` per the `epics.md:52`
  convention, then HALT per Block If.

**Acceptance Criteria:**

- Given the published weights, when reproduction begins, then their provenance and
  per-file checksums are recorded in a committed artifact and verified at every run.
- Given the harness, when it is built, then it lives under `_bmad-output/ml-training/`
  as develop-only Python and nothing under `tools/coreml-convert/` changes.
- Given the published and local figures may rest on different annotation sets, when
  scoring runs, then the alignment record exists FIRST (paper's annotation, ours by
  digest, match/mismatch stated) and the report states that skipping it would make Gate 0
  measure the ruler.
- Given the scored baseline, when results are reported, then the reference, our model's
  348/661, and the DSP path's 537/661 appear together with each number labelled by its
  scoring protocol, and the gate comparison uses only the FR-18-strict protocol.
- Given the pre-registered rule, when the reference scores at or below
  midpoint(348, P) tracks, then Gate 0 fires: the report says measurement-not-modelling,
  the pressure-release artifact is written, and the run HALTs blocked for the operator's
  re-plan of 12.5+.
- Given every literature claim, when it appears in any artifact of this story, then it
  cites the primary paper by section/table, never a summary.
- Given this is diagnostic work, when the story lands, then
  `git diff --stat 4184c72 -- Sources/ Tests/` is empty and `make test` still reports
  993 tests / 168 suites / 4 known issues.

## Spec Change Log

## Review Triage Log

### 2026-08-07 -- Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 16: (high 0, medium 9, low 7)
- defer: 0
- reject: 8
- addressed_findings:
  - `[medium]` `[patch]` Whole-batch normalization replaced with the paper's per-window [0,1] rescale; full re-run moved the gate row 539 -> 545, landing exactly on the published tracks-on-661 (P = 545)
  - `[medium]` `[patch]` Failure-rate guard: >5% per-track failures hard-exits (a systematic environment fault could otherwise have scored 0/661 and emitted the gate-fires verdict); degenerate audio counted as failure
  - `[medium]` `[patch]` tempo2 join integrity: hard-exit on unmatched rows, duplicate ids, non-numeric values; matchedTempo2Rows = 661 recorded
  - `[medium]` `[patch]` ml-training-tests Makefile target created and added to pre-commit (the pytest suite was wired into nothing)
  - `[medium]` `[patch]` Provenance re-downloaded from the pinned-commit URL; git blob SHA-1 now verified alongside SHA-256 every run; wording corrected
  - `[medium]` `[patch]` Report's per-axis figures made regenerable: octave-tolerant and Acc2 rows plus strictMissesOctaveRecoverable emitted by the harness
  - `[medium]` `[patch]` PRD prd.md:95 "82.1/97.1" annotated (unconfirmed in primary text; 73.0 ISMIR 2018 Table 1b old ruler / 82.5 SMC 2019 Table 4a revised ruler) -- a spec Always bullet the first pass missed
  - `[medium]` `[patch]` numpy/protobuf lock downgrade side effect validated: ablation-tests 138 passed under the new lock, recorded in the report
  - `[medium]` `[patch]` Scorer parity tests for the @2% and tempo2-floor re-implementations (mirexHit-style synthetic rows); tempo2-floor row labelled a Python re-implementation
  - `[low]` `[patch]` Tail-window drop recorded as a deliberate method decision matching the reference sliding-window behavior
  - `[low]` `[patch]` gate_inputs hard-guards denominator 661
  - `[low]` `[patch]` model_file key replaces verified[0] insertion-order dependence; empty-provenance hard exit
  - `[low]` `[patch]` Dead isfinite check replaced with a finite check on the averaged softmax
  - `[low]` `[patch]` predictions.json audioPath reduced to basename
  - `[low]` `[patch]` weights-dir env validated before Path(); output path echoed; explicit develop-only Makefile guard
  - `[low]` `[patch]` Report method section records normalization, tail, and failure-guard semantics
  - Pre-registration attestability handled at commit time: harness + gate rule committed before the run outputs and report.

## Design Notes

**Why the gate protocol is FR-18-strict and not the benchmark floor.** The "near 52" in
Gate 0's PRD text is 348/661 measured on the FR-18 path: strict Acc1, 4% tolerance, no
`tempo2`, abstains wrong. The DSP path's 81.2% (537/661) is a different instrument: 2%
tolerance with the `tempo2` fallback, which Story 12.3's evidence showed pre-absorbs 71
tracks of octave error on this corpus. Comparing the reference against 348 on any other
protocol would re-create the exact ruler confusion the gate exists to catch, so the gate
row is pinned to the protocol that produced 348 and every other number is a labelled
context row.

**Why the reference runs its own featurization.** FR-56 says end to end. Running the
published model on our log-mel substrate would measure our substrate, not the reference;
the aligned variables are the corpus rows, the annotation source, and the scoring
protocol -- the model's input pipeline is part of the model.

**Why midpoint and not a fixed threshold.** Any fixed "near 52" band is an invented
constant. Midpoint(348, P) is derivable from the two quantities the gate compares, is
computed in tracks, and is written into the report before the run so the decision cannot
drift after the number lands.

**Session-size note.** The epic flags 12.4 as larger than one session. The split that
matters is at the weights/network boundary: tasks 1-6 (trace, acquire, harness, tests,
Makefile) are agent-completable; task 7's full 661-track run is minutes-to-hours of
compute and may be operator-run via the Makefile target if the session cannot carry it.
The spec stays one file; the report task names its runner either way.

## Verification

**Commands:**
- `cd _bmad-output/ml-training && uv run pytest tests/test_tempocnn_baseline.py` --
  expected: all pass, no network.
- `make tempocnn-baseline` (with `TEMPOCNN_WEIGHTS_DIR` set) -- expected: checksum
  verification line, 661/661 scored, summary with three protocol rows and the gate
  verdict.
- `make py-lint` -- expected: green (new file ruff-covered; add to the ty enumeration
  only if it type-checks cleanly against the TF stubs, else record the exclusion beside
  the torch precedent).
- `git diff --stat 4184c72 -- Sources/ Tests/` -- expected: empty.
- `make test` -- expected: 993 / 168 / 4, unchanged.

**Manual checks:**
- The provenance JSON's SHA-256 values match a fresh `shasum -a 256` of the weights.
- The report's citation ledger has no figure without a paper table/section reference.
