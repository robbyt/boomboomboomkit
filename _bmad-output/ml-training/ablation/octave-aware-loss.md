# Octave-aware training loss (FR-16) — v1 scaffolding

Story 7.3 / AC2 / DD #2. Develop-only. Implemented in `octave_aware_loss.py`.

## What it does

A soft-target cross-entropy over the 256 integer BPM bins (30..285). Instead of a
one-hot target on the true bin `T`, the target distribution places:

- primary mass `1 - octave_mass` on `T`;
- `octave_mass` split evenly across the **in-range** octave-family partners
  `{2T, T/2}` (the OA300/Tony Acc2 convention — NOT the GiantSteps `{3, 1/3}`
  triplet extension);
- then label smoothing applied **once** as a convex combination with the uniform
  distribution.

The loss is `-(soft_target * log_softmax(logits)).sum(1).mean()`.

## Why it does not "collapse to 0" (AC2)

Most target mass stays on `T`, so a model that confidently predicts an octave
(`2T`/`T/2`) still incurs a large, finite penalty — **smaller** than confidently
predicting a far-off bin (which captures none of the octave mass), but never
free. This teaches octave structure without licensing octave errors. The unit
test `test_octave_penalty_less_than_far_off` asserts
`loss(true) < loss(octave) < loss(far)` and `loss(octave) > 0`.

## The clamp fix (Codex/Winston 2026-06-02)

Octave partners are computed in **BPM space** and **dropped when their BPM falls
outside [30, 285] before binning**. Without this, a 170 BPM DnB track's
`2T = 340` would clamp (via `bpm_to_bin`) to bin 255 (285 BPM) and smear octave
credit onto a spurious in-range bin; a 32 BPM track's `T/2 = 16` would clamp to
bin 0. After dropping out-of-range partners, duplicate partner bins are merged
and the target is renormalized to sum to 1.0.

## Constants (held identical across BOTH arms — DD #12)

| constant | value | note |
|---|---|---|
| `octave_mass` | `0.15` | partial-credit mass split across in-range `{2T, T/2}` |
| `label_smoothing` | `0.05` | applied once; convex combo with uniform |
| octave family | `{2.0, 0.5}` | `{1, 2, 1/2}` Acc2 convention (no triplet) |
| bin schema | 256 bins, 30..285 | local 3-line clamp (`dataset.py` has no `bpm_to_bin`) |

The constant is held identical across `supervisedAugmented` and
`maskedMelPretrain` so the KDD-B2 result is attributable to encoder init, not a
loss difference (DD #12).

## v1 sub-band-emphasis weighting stand-in (AC3 / DD #7)

The `--weighting-profile sub-band-emphasis` path applies a documented Python
mel-band weight vector to the `extract_log_mel` OUTPUT (post-mel, pre-z-score) —
a low-mid (kick/snare body) 1.3x boost over the middle bands. This is an explicit
**v1 scaffolding APPROXIMATION** of the unimplemented Swift
`FeatureSubstrate.WeightingProfile.subBandEmphasis` (Story 6.2 / 7.5 is
authoritative). It is NOT the headline profile — the KDD-B2 winner that Story 7.5
hard-codes is selected under `uniform` only (AC3/AC10). No v1 sub-band metric is
a v2 claim.

## References

- Schreiber & Müller 2018, *A Single-Step Approach to Musical Tempo Estimation
  Using a Convolutional Neural Network* — tempo-octave error taxonomy.
- Hendrycks & Gimpel 2017, *A Baseline for Detecting Misclassified and
  Out-of-Distribution Examples in Neural Networks* — calibration; `ECE_half_double`
  is the KDD-B2 tiebreaker (AC6).
