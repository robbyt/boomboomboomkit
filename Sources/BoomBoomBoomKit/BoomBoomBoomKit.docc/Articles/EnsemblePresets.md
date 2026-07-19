# Ensemble Presets

Combine the DSP-derived BPM with an optional machine-learning voice, and tune how
much each signal counts.

## Overview

When a ``MLTechnique`` is attached via `Options.mlTechnique`, BoomBoomBoomKit can
fuse its evaluation with the DSP result. The fusion is governed by:

- ``EnsemblePolicy``: the winner rule across DSP and ML (5 cases).
- ``SignalWeights``: per-source multipliers that parameterize weighted fusion.
- ``MLExecutionPolicy``: when ML inference should run at all (3 cases).
- ``SignalSource``: the closed set of signal identities (4 cases).

This article surveys the family. Each per-case reference page carries the full
prose; this article compares them and flags where each preset can go wrong.

## EnsemblePolicy

``EnsemblePolicy`` has five cases. It is **not** a `String`/`CaseIterable` enum
(``EnsemblePolicy/weightedVoting(_:)`` carries an associated ``SignalWeights``),
so it exposes `allPolicies` and a hand-written stable key instead.

| Preset | Invokes ML? | Winner rule | When to use |
|---|---|---|---|
| ``EnsemblePolicy/default`` | Yes | Balanced peers: `effectiveVote = confidence × weight`, higher wins, DSP breaks ties (equivalent to `weightedVoting` with default ``SignalWeights``) | Equal trust in DSP and a wired-up model |
| ``EnsemblePolicy/dspOnly`` | No | DSP result only; ML is never invoked | Ship byte-identical DSP behavior even with a model loaded |
| ``EnsemblePolicy/mlOnly`` | Yes | ML wins when it returns a non-nil evaluation; DSP otherwise | Trust the model, fall back to DSP on abstain |
| ``EnsemblePolicy/highestConfidence`` | Yes | Whichever side self-reports higher confidence (DSP tiebreak) | Let each track pick its more-confident estimator |
| ``EnsemblePolicy/weightedVoting(_:)`` | Yes | Per-source weighted `effectiveVote`, DSP ties | You have measured per-source reliability and want to tilt fusion |

`invokesMLInference` is `true` for every case **except** ``EnsemblePolicy/dspOnly``.

> Important: The ``EnsemblePolicy/default`` *case* is **not** the `Options`
> default. `AudioAnalysisService.Options.ensemblePolicy` defaults to
> ``EnsemblePolicy/dspOnly``, so by default no ML is invoked and output is
> byte-identical to the DSP-only pipeline even when a technique is attached. You
> must opt in to an ML-invoking preset explicitly.

## SignalWeights

``SignalWeights`` (a `Sendable, Hashable` struct) carries four multipliers
(`dsp`, `ml`, `fileMetadata`, `beatGrid`), each defaulting to `1.0`. `.default`
is all-ones (equal weighting), and each input is finite-normalized (non-finite →
`1.0`, then clamped non-negative). Weighted fusion computes
`effectiveVote = confidence × weights[source]`.

Not every weight feeds the ensemble vote:

- Only `dsp` and `ml` participate in the ensemble `effectiveVote`.
- `fileMetadata` scales the strength of Phase-2a metadata (tag) corroboration.
  It does **not** enter the ensemble vote.
- `beatGrid` is **inert**: no producer feeds a beat-grid voice into the pool.
  Beat-grid analysis ships as a parallel `BeatGrid` output, not a pool signal, so
  this weight currently changes nothing.

## MLExecutionPolicy

``MLExecutionPolicy`` (`Sendable, Equatable`, non-`Hashable`) has three cases and
defaults to ``MLExecutionPolicy/whenDSPConfidenceBelow(_:)`` at `0.85`:

- ``MLExecutionPolicy/never``: never run ML.
- ``MLExecutionPolicy/always``: always run ML.
- ``MLExecutionPolicy/whenDSPConfidenceBelow(_:)``: run ML only when DSP
  confidence is below the associated `Double` threshold.

> Important: ``MLExecutionPolicy`` is a **forward-declared** surface. It is not
> yet wired into `Options`, so today it does not gate ML invocation at runtime.
> Whether ML runs is governed by ``EnsemblePolicy`` (via `invokesMLInference`),
> not by this policy.

## SignalSource

``SignalSource`` (a `String`, `CaseIterable` enum, closed set) names the four
signal identities: ``SignalSource/dsp``, ``SignalSource/ml``,
``SignalSource/fileMetadata``, and ``SignalSource/beatGrid``. As with the weight
above, ``SignalSource/beatGrid`` has **no producer** yet; it is reserved.

## Related guides

- <doc:SelectionStrategies>: merging per-window DSP candidates before fusion.
