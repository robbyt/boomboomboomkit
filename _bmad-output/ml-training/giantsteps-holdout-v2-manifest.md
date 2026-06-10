# GiantSteps holdout v2 — reproducibility manifest (Story 7.7 AC6 / DD #10)

- selection_script: `scripts/sample-giantsteps-holdout.py`
- gs_corpus_version: `giantsteps-tempo-dataset`
- seed: `7700`
- n: `150`
- stratification: `{'mode': 'style+tempo', 'styleKey': 'genre', 'strata': 17}`
- hash_manifest_sha256: `fef92c28f073cd7e5c93f6ac9f748e6d48b4337af1f5f2ae7c3f48b3a0c6403e`

The hash-list itself (`giantsteps-holdout-v2.json`) is `.gitignore`'d. Re-running with the same seed re-samples the identical 150 hashes (reproducibility guard); `holdout_gap.py` only subtracts these from Story-7.6 dumps that predate this file (the temporal/structural seal).
