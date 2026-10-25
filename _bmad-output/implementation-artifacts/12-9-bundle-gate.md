# Story 12.9 bundle gate definition (2026-10-25)

Status: **defined and provisionally exercised; bundle approval blocked**.
The operator's 2026-10-25 decisions in `spec-12-9-bundle-gate-definition.md`
replace the old 258-track, fixed-12-net-track rule for this gate. The 12.7
candidate commitment, signed corpus and training manifests are unchanged.

## Frozen denominator and arms

`scripts/build-bundle-gate-cohort.py` freezes a private, generation-bound
cohort from the 172 signed 12.7 member labels plus every sound, unique,
blinded `e1-` through `e5-` DAW row in the committed draw. A row requires one
finite verified tempo, its committed opaque ID, source audio matching its
committed SHA-256, no unresolved duplicate or unstable finding, and source
and verified bands. An added DAW row must also play `audio/<opaque-id>.<ext>`
in the project ZIP, with bytes matching the committed source hash. The signed
member JAMS label wins over a stale DAW clip.
The DAW supplies only extra labels. No `x1-` row can enter the gate; those
detector-visible annotations may be reported separately. OA300 and GiantSteps
are contextual reports and have no vote in pass/fail.

The 2026-10-25 frozen private snapshot for generation `ge94c3fc04f636363`
has digest `6cee900bd8fd8d84e120b5e82047cc35049828e78128aaadf8cebf846f17798c`.
Its count is **245**: 172 locked signed members and 73 eligible blinded extras.
The verified-band denominator is:

| Verified band | Rows | Measurement |
| --- | ---: | --- |
| sub-100 | 4 | sparse; unmeasurable |
| 100-120 | 0 | sparse; unmeasurable |
| 120-140 | 48 | measurable |
| 140-160 | 50 | measurable |
| 160-175 | 91 | measurable |
| 175-plus | 52 | measurable |

These counts are bound to the snapshot, not targets forced by the script.
The source-band field preserves how a rejected 12.7 pool row entered this new
cohort. The original 172 is a locked subset with its own paired table.

Both arms receive the **same audio** through the production
`AudioAnalysisService.analyzeBPM` path at `.thorough` intensity. The baseline
sets `Options.ensemblePolicy = .dspOnly`; the candidate sets
`Options.ensemblePolicy = .default` and wires the frozen checkpoint through
`BNNSTechnique(modelURL:)`. `.default` is the equal-weight balanced-peer
policy and is fixed for this gate. The library's Options default remains
`.dspOnly`, so a later bundle must explicitly select the policy at its use
site. The run manifest records the selected policy's `stableKey`, the exact
prediction-file digest, and a deterministic hash of every file in the
compiled checkpoint bundle, including separate weights. The old `.mlOnly`
FR-18 `runtimeResultBPM` is DSP-contaminated on ML
abstain and is not a substitute for the paired candidate arm.

## Decision rule

Accuracy is strict Acc1: `abs(prediction - truth) / truth <= 0.04`; an absent
or non-finite final BPM is incorrect. For paired rows, `b` is a **gain**
(DSP incorrect, ensemble correct), `c` is a **loss** (DSP correct,
ensemble incorrect), `d=b+c`, and net tracks are `b-c`. The primary gate
requires positive net lift and exact two-sided McNemar `p <= 0.05`, where
`p = min(1, 2 * P[Binomial(d, 0.5) <= min(b,c)])`. There is no fixed
12-track floor. Every report states `b`, `c`, `d`, net tracks, exact `p`, and
the **minimum net tracks needed at that observed `d`**. A percentage-only
lift claim does not satisfy this rule.

Every verified band has a descriptive paired table with gains and losses.
For `n >= 43`, DSP handles a band when it scores at least
`ceil(30*n/43)` correct; if handled, the ensemble must have `gains >= losses`
there. This is a deterministic benchmark tripwire, not a population
noninferiority claim. A band below 43 is **unmeasurable**, never passing,
and blocks final approval. For the current cohort the four measurable
thresholds are respectively 34, 35, 64, and 37 correct.

The model calibration gate reuses FR-18's `ECE_half_double < 0.10` over the
DSP candidate half/double subset. Fewer than 100 usable rows is
**inconclusive** and blocks approval. The four original DnB triplet
sentinels each require an Acc1-correct **ensemble** result; their individual
DSP and ensemble outcomes appear in the report. Legacy OA300 and GiantSteps
figures are context only, with their overlap and convention limits named.

The weights and policy to ship must be frozen before the confirmatory run.
The selected checkpoint gets one evaluation against the frozen cohort. Other
seed results can describe development robustness, but correlated seeds do
not multiply p-values or provide independent confirmation. The evaluator
records each seed separately and flags net-lift dispersion above 10 tracks.
It does not promote a partial seed set to a bundle decision.

Final approval requires complete production-path manifest accounting, the
above substantive gates, all six bands measurable, a current 12.7 signoff
attestation validated through the 12.7 training-gate validator, **and a
separate training-partition closure bound to the expanded 245-row cohort**.
The 12.7 attestation certifies its 172 members only; it cannot certify the
73 added rows. No such gate-specific closure validator exists in this
defined-and-tested slice, so the evaluator hard-blocks bundle approval even
if 12.7 later signs off. The future closure work must prove the extra rows
are absent from the rebuilt training inputs, bind the proof to the frozen
cohort digest and training-input digests, and then replace this explicit
block with validation. The evaluator still emits a provisional report.

## FR-69c risk answers

1. **GiantSteps independence.** It is contextual only, never confirmatory.
   A distribution match to a reference model cannot establish untouched
   evaluation, and track or label exposure would weaken it further.
2. **DnB/high-BPM dominance.** The single cohort reports every verified band.
   Slow bands with 4 and 0 rows are unmeasurable and block approval; a good
   aggregate over high-BPM material cannot cover them.
3. **Repeated screening.** The private cohort digest, one frozen candidate
   checkpoint, `.default` policy, thresholds, and analysis command are fixed
   before the final run. A failed checkpoint cannot be tuned on these rows
   and tested again as if untouched. The failed Epic 7 seed-42 run is an
   explicitly labeled negative control, not candidate selection evidence.
4. **One-track/no-regression claim.** Bands under 43 are unmeasurable. For
   measurable DSP-handled bands, the zero-loss-margin `gains >= losses`
   tripwire is deterministic and reported as such. It makes no confidence
   claim about a population regression rate.
5. **Dependent tracks and annotation error.** The 12.7 precommitment
   duplicate and artist review, SHA-256 uniqueness in this cohort, and the
   pending blind re-pass/partition signoff reduce known overlaps. Exact
   McNemar is reported on the fixed benchmark, not as an independent-artist
   generalization estimate. Remaining remix/artist clustering and annotation
   error are named limits; the re-pass and signoff must close before approval.

## Execution and current limits

Freeze with `make bundle-gate-freeze DAWPROJECT=<private .dawproject>`.
Run one seed with `make bundle-gate-produce SEED=42
BNNS_MODEL_URL=<private .mlmodelc>` and report with
`make bundle-gate-evaluate`. `make bundle-gate-negative-control` requires a
**substantive** failed model/ensemble gate for the failed Epic 7 seed-42
checkpoint; a missing signoff alone cannot satisfy that control. Add
`BUNDLE_GATE_LEGACY=1` on the producer to include OA300 and GiantSteps for
context. All row-level inputs, predictions, and reports live in the ignored
`_bmad-output/ml-training/eval-corpus/bundle-gate/` directory.

Current training-overlap limit: the FR-59d rebuild and partition closure are
pending for the 172 signed members, and the 73 new rows have no cohort-bound
training closure at all. The failed seed-42 checkpoint may have trained on
gate audio; its negative-control score demonstrates evaluator rejection only,
not an independent estimate of generalization. The slow-band and signoff
blocks remain even if it fails for a substantive reason.

**Negative control, 2026-10-25.** The real production-path seed-42 run
accounted for all 249 inputs (245 cohort rows plus four sentinels). On the
cohort DSP got 191/245 and balanced-peer DSP+ML got 192/245: `b=1` gain,
`c=0` losses, `d=1`, net +1, exact two-sided `p=1.0`. The 172 locked
members were 147 to 148, likewise `b=1`, `c=0`. Calibration failed with
`ECE_half_double=0.516` on 154 usable rows, and the ensemble got 0/4
original sentinels correct. These are substantive failed gates, independently
of the absent signoffs. The rerun after the manifest hardening recorded policy
key `default`, whole compiled-bundle digest
`89eb32933789aa222bb2ffc9da273c8df2e2ce5f99608a3861903ae4bbd9e3ba`, and
prediction-file digest
`b8ed8d46d94d656f6f0b37aa1cc5e783a4a377234560d40c51aa3a13b4c4b61b`.
The provisional report remains private under the
ignored bundle-gate directory; no row predictions or weights are committed.
