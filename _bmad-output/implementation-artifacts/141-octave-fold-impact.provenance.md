# Provenance for 141-octave-fold-impact.json

This artifact records a **removed** experiment. It is not a runnable benchmark:
the harness that produced it (`OctaveFoldImpactTests.swift`) and the feature it
measured (`OctaveFoldPolicy` and the decode fold in `BNNSTechnique`) were
deleted when GH-141 closed as measured-disproved-removed. Re-running it requires
re-implementing the fold.

## Why the recorded commit does not resolve

The JSON records `gitSHA: 288c015`. That commit is on no branch: a rebase onto
`develop` after PR #177 squash-merged replaced it. The measurement itself is
unaffected, because the replacement has the **identical tree**.

| | |
|---|---|
| Recorded commit | `288c015` (unreachable) |
| Reachable replacement | `8ec7bac` |
| Tree, both | `fce7bda74f4ad3826697aea75ffca1ff72f42b56` |
| Model digest | `5dc5873bef88e0ab73ce6107411696715a2459b1fc80727cb871b16fa845dd37` |
| Model | `_bmad-output/ml-models/giantsteps_v2_seed_42.mlmodelc` |
| Corpus | GiantSteps, 661 tracks, 0 abstained, 0 missing |

Identical trees mean the code that produced these numbers is recoverable exactly,
not approximately. The JSON is left **byte-for-byte as measured** — a measurement
record is not edited to make its metadata tidy.

## What it shows

Every threshold from 0.0 to 1.0 is net negative on Acc1; the best is −2, reached
by folding almost nothing. Threshold 0.0 recovers exactly the +38 sub-100 BPM
tracks the E0 diagnostic predicted, at a cost of 346 harmful folds, for −308.

The reason no threshold works: folds that help have a median mass ratio of 0.199,
folds that hurt 0.192. 336 of the 346 harmful folds sit above the smallest
helpful one, and no helpful fold sits above the largest harmful one. The scalar
mass ratio carries no information about whether a fold is correct.

This scopes to *that* statistic. A richer posterior feature, or an arbiter using
evidence from outside the posterior, is untested.

Separate from `../perf-baselines/COMMIT-IDS.md`, which covers a different
directory and a different history rewrite.
