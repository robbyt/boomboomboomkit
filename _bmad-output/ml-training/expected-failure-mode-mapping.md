# Expected-failure-mode mapping (Story 7.4, DD #7 / KDD-B4)

Develop-only. The deterministic mapping from `failureCategory` to a human
`expectedFailureMode` label AND a closed-enum `verificationPredicate`. The
predicate is the MECHANICAL check Story 7.6 runs against each watchlist row's
`v2Prediction` — a free string like "model may correct DSP" cannot be graded
("may" never fails), so every category names a checkable predicate (Mary's rule
/ KDD-B4). `unresolved -> none` names the absence VISIBLY (a legitimate
"no a-priori expectation"), not disguised as "indeterminate".

One row per category (total over the closed `CATEGORIES` set). Every
`expectedFailureMode` is non-null; every `verificationPredicate` is in the closed
enum `{octave_family_error, model_corrects_metadata, model_corrects_dsp,
harmonic_ratio_error, none}`.

| failureCategory | expectedFailureMode | verificationPredicate |
|---|---|---|
| halfDoubleOctave | off-by-octave | octave_family_error |
| metadataConflict | DSP-wins-over-stale-tag | model_corrects_metadata |
| dspFailure | DSP-outlier-vs-consensus | model_corrects_dsp |
| harmonicAmbiguity | harmonic-ratio-confusion | harmonic_ratio_error |
| unresolved | no-a-priori-expectation | none |

## How Story 7.6 grades each predicate (forward contract)

`verificationPredicate` is the closed tag; the v2 prediction
(`v2Prediction.seeds[]` filled by Story 7.5, octave-normalized) is graded
against it to set `v2Prediction.matchesExpected`:

- `octave_family_error` — the v2 model lands on the full tempo (the 2x of the
  metadata half / the truth-cluster centroid) rather than the half-time tag.
- `model_corrects_metadata` — the v2 model agrees with truth against the
  stale/wrong metadata tag.
- `model_corrects_dsp` — the v2 model agrees with truth against the DSP outlier.
- `harmonic_ratio_error` — the v2 model resolves the 3:2 / 3:1 confusion toward
  the truth-cluster centroid.
- `none` — no a-priori expectation; the row is recorded for completeness and is
  NOT scored pass/fail (it cannot fail a check it does not assert).

The mapping is the single source consumed by both `marginal-watchlist.json`
(use-c, this story) and Story 7.6's `post-bundle-regression-watchlist-v2.json`.
