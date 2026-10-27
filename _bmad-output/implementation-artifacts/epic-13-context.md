# Epic 13 Context: DSP Accuracy Experiments

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Improve BPM accuracy through measured experiments on the existing digital signal processing pipeline. The charter reserves this work for DSP changes that can be isolated, compared with the shipped configuration, and reverted if they do not generalize. Epic 13 remains a charter: its provisional experiments have not been scoped into numbered stories, and whether the remaining work warrants a separate epic is unresolved.

## Stories

- No numbered stories have been defined. Provisional experiment areas are aggregated tempo evidence across analysis regions, adaptive sub-band weighting, multi-region anchoring, and normalized autocorrelation.

## Requirements & Constraints

- Introduce each experiment behind an opt-in technique or equivalent controlled configuration, with an ablation and a clear route to revert it. Do not change the default configuration on the strength of a promising example alone.
- Before a new default DSP behavior ships, measure at least a two-track OA300 accuracy improvement and no GiantSteps regression. Preserve the existing unconditional OA300 and GiantSteps accuracy floors. Assess per-track changes and separate octave errors from other error types; aggregate accuracy alone is insufficient to explain a change.
- Freeze any OA300-tuned configuration before the GiantSteps measurement. A flagged, default-off experiment may have an explained GiantSteps cost during investigation, but promotion to the default path requires no GiantSteps regression.
- Keep runtime costs measurable. The existing architecture sets a 15% OA300 wall-clock regression budget for its main analysis path and uses shared decoding to avoid repeated audio reads.
- Do not present a tiny set of drum-and-bass tracks as proof of general accuracy. Broad corpora carry the generalization claim.
- Preserve Swift strict concurrency, the package's dependency and platform constraints, and the current diagnostics and benchmark gates.

## Technical Decisions

- The remaining proposed experiments concern evidence aggregation over audio regions, sub-band onset weighting, anchor choice, and autocorrelation normalization. They are hypotheses, not committed implementations or a required bundle of changes.
- Keep BPM selection compatible with the existing signal-pool and selection-policy architecture. Any new evidence that participates in a BPM result must remain observable in diagnostic traces so accuracy changes can be attributed.
- The onset-feature substrate is shared by DSP analysis, beat-grid analysis, and ML feature generation. A weighting experiment must consider those consumers and avoid silently forking their input representations.
- Normalized autocorrelation comes last in the charter because octave fusion and sub-band thresholds were tuned against the current autocorrelation; it requires a full technique-combination retune before promotion.

## Cross-Story Dependencies

- Epic 12 owns DSP octave-resolution levers and beat-grid support for candidate rescoring. Epic 13 should not reclaim those transferred experiments.
- Epic 15 owns beat-grid observation and phase-correction work; its metrical-level choice remains upstream with BPM analysis. Epic 13's region or tempo-evidence experiments must not be represented as beat-grid phase fixes.
- A multi-region anchor was provisional pending evidence of intro or transition locks. Measurement should establish that failure mode before changing the shipped anchor.
