# Marginal-tier failure categorization (Story 7.4, FR-14 / KDD-B4)

Develop-only. Documents the deterministic, dataset-side rule that assigns a
`failureCategory` to each of the 241 Marginal-tier tracks
(`truth_confidence in [0.55, 0.65)`, re-derived via `corpus_common.tier_for`).
The rule and the artifacts it produces are the use-(a) named use of the
Marginal cohort (KDD-B4 / Mary's "name how it's used" rule).

> Guardrail 2: every figure here is a LABEL diagnostic over the labeler's
> pre-computed disagreement signals + cluster geometry. NO model predictions are
> consulted. This produces no transferable FR-18 accuracy claim.

## Inputs (what the categorizer reads)

Per Marginal track, from `tony-corpus/tony-truth-labels.json`:

- `bpm_truth` (= `tonyLabel`), `truth_cluster.centroid`, `runner_up_cluster.centroid`.
- `signals.{dsp, rekordbox_average, grid_bpm, playlist}`, each with a `relation`
  to `bpm_truth` in the closed enum `{same, half, far, near, missing}`. **There
  is NO `double` relation** — the labeler never emits one. Octave/harmonic
  structure therefore comes from the CLUSTER CENTROID RATIO, never a relation tag.

`idTagBPM` and `durationDerivedBPM` are emitted `null` (DD #1): no ID3/`tmpo` BPM
key was ever wired into the labeler (`scripts/tony-tunes-labels.py:64` — "not
yet wired"; ID3 BPM is also an FR-15-forbidden MODEL input), and no
duration-derived BPM signal exists in any planned story. Tracked as
**deferred-work 7-4-D1**: the `idTagBPM` blind spot may under-count tag-driven
`metadataConflict`; re-open if Story 7.6 regression surfaces metadata-driven
failures.

## Empirical signal distribution (241 tracks @ baseline 2a92369)

- All 4 signals present on all 241.
- `dsp` relation-to-truth: `same` 93, `half` 43, `far` 105 (the independent
  audio estimator disagrees often).
- `rekordbox_average` relation: `same` 30, `half` 207, `far` 4 — and `grid_bpm`
  is IDENTICAL (`same` 30, `half` 207, `far` 4): the two metadata sources are
  near-duplicate signals on this cohort.
- `playlist` relation: `missing` 185, `near` 30, `same` 15, `far` 11 (weak,
  rarely decisive).
- Cluster geometry: **199/241** carry a `runner_up_cluster` whose centroid is
  ~2x/0.5x the `truth_cluster` centroid (octave band); **0** have a null/absent
  runner-up; **11** carry a 3:2 or 3:1 centroid ratio (harmonic band, see AC9).

## Categorization rule (deterministic, precedence-ordered)

Cluster-ratio predicates use the single promoted `corpus_common` helper (Task
0): `ratio = canonical_ratio(truth_centroid, runner_up_centroid)` (larger /
smaller, zero-guarded, direction-symmetric — the 0.5x direction needs no
separate branch). With `OCTAVE_RATIO_TOL = 0.05`, `HARMONIC_RATIO_TOL = 0.03`:

- `is_octave  = ratio > 0 and abs(ratio - 2.0) <= OCTAVE_RATIO_TOL * 2.0`
- `is_harmonic = ratio > 0 and (abs(ratio - 1.5) <= HARMONIC_RATIO_TOL * 1.5 or abs(ratio - 3.0) <= HARMONIC_RATIO_TOL * 3.0)`

If `runner_up_cluster` is null/absent, `ratio == 0.0` and both predicates are
`False` — the track falls through to the relation-only rules.

Assignment (top-to-bottom, FIRST match wins):

1. **`dspFailure`** — `dspRelation == far` AND `rekordboxRelation == same` AND
   `gridRelation == same`. The metadata sources agree with truth; the
   independent audio estimator is the lone outlier. Evaluated FIRST so the broad
   octave sweep (rule 3) does not swallow DSP-outlier tracks (rule-1 over-reach
   guard, Mary/Codex).
2. **`metadataConflict`** — `not is_octave` AND (`rekordboxRelation in {far, near}`
   OR `gridRelation in {far, near}`) AND `dspRelation == same`. Non-octave metadata
   disagreement while audio + DSP support truth (a stale/wrong tag). The `not is_octave`
   guard (code-review 7-4, Codex thread `019e8f9f`) is load-bearing: an octave-geometry
   track with a `half` relation is a halfDoubleOctave (rule 3), not a stale-tag conflict —
   without the guard, first-match-wins would mis-route it here. 0 reclassifications on the
   live 241 (no overlap track exists today); the guard prevents a future silent surprise.
3. **`halfDoubleOctave`** — `is_octave` AND at least one of
   `{dspRelation, rekordboxRelation, gridRelation} == half`. Dominant category.
4. **`harmonicAmbiguity`** — `is_harmonic` (3:2 or 3:1 cluster ratio).
   Cluster-geometry-only; measured before ship (AC9).
5. **`unresolved`** — none of the above.

## Measured per-category counts (241 @ baseline 2a92369)

| failureCategory | count | sanity band (AC8 regression) |
|---|---|---|
| dspFailure | 30 | meaningful minority |
| metadataConflict | 2 | small (single digits) |
| halfDoubleOctave | 199 | dominant |
| harmonicAmbiguity | 8 | sparse, non-zero |
| unresolved | 2 | small |
| **total** | **241** | == 241 |

These are the actual `categorize()` outputs over the live 241; the AC8 pytest
regression asserts the per-category counts stay within their sanity bands. The
bands are directional, not contractual (FR-14 "currently"); a count landing
wildly outside its band means the precedence rule (not the corpus) is suspect.

### AC9 — `harmonicAmbiguity` measured, not assumed

The precedence-independent 3:2 / 3:1 cluster-ratio candidate count over the 241
Marginal tracks is **11**. Of those, 3 are claimed by an earlier precedence rule
(`dspFailure` / `metadataConflict`), so **8** land in `harmonicAmbiguity` after
precedence. The category is non-zero on this corpus; had the count been 0, it
would have shipped as an explicit zero-count category (the epic enum is closed —
the category is retained for enum-completeness, never removed).

## Taxonomy anchor (Schreiber & Müller tempo octave-error family)

This is a project-local diagnostic lens over the standard tempo-error family
(Schreiber & Müller, "A Single-Step Approach to Musical Tempo Estimation"), NOT
a claim of a canonical 5-class taxonomy:

- `halfDoubleOctave` = metrical-level / octave-family error (2x / 0.5x).
- `harmonicAmbiguity` = non-2x ratio-family error (3:2 / 3:1).
- `dspFailure` = audio-estimator outlier vs label consensus.
- `metadataConflict` = curator / file-metadata outlier vs audio + truth.
- `unresolved` = insufficient evidence (no a-priori expectation).

Empirical caveat (Mary): rule 3's broad metadata-`half` population is partly a
consequence of `rekordbox` / `grid` being near-duplicate signals, so the rule-1
/ rule-2 pre-tests for the `dsp != same` subpopulation are load-bearing.

## FR-15 boundary (DD #12 / AC10)

`marginal-failure-categorization.json` and `marginal-watchlist.json` are
develop-only DIAGNOSTIC artifacts. FR-15 governs MODEL INPUTS (the trained tempo
model consumes audio only); it does NOT forbid a diagnostic file from CONTAINING
BPM signals. The genuine risk is a feature-transform / training path READING one
of these JSONs. AC10 closes that: the FR-15 audit grep is extended to these two
filenames, and a test proves no feature-transform / training path (`dataset.py`
feature builders, `train.py`, `ablation/` transforms) imports or opens them.
This mirrors the Story 7.2 AC9 / 7.3 DD #4 locator-vs-feature distinction.

## Downstream ownership (DD #13)

Story 7.4 owns the watchlist SCHEMA and the seed-INDEPENDENT fields
(`failureCategory`, `expectedFailureMode`, `verificationPredicate`). The
`v2Prediction` field is reserved at 7.4 close as a typed stub OBJECT (not a bare
`null`) whose seed-dependent values are empty/`null`:
`{status: "pending-7.5", seeds: [], varianceBpm: null,
octaveNormalizedAgreement: null, matchesExpected: null}` — declared shape
`{status, seeds: [{seed, bpm, confidence}], varianceBpm,
octaveNormalizedAgreement, matchesExpected}`. Story 7.5 fills `seeds[]` (per-seed
BPM/confidence across seeds 42/43/44) + `varianceBpm` /
`octaveNormalizedAgreement`; Story 7.6 fills `matchesExpected` by grading the v2
prediction against the row's `verificationPredicate`.
