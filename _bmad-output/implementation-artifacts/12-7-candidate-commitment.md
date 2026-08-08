# Story 12.7: candidate-pool commitment record

Generated 2026-08-08 by `scripts/build-eval-corpus.py commit-pools` (`make eval-corpus-pools`). Counts, seeds, and the named commitment digests only; the row-level candidate inventory is gitignored per the privacy rule (OA300 and the collection inventory are private).

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md section 2`.

Seed algorithm: python-stdlib random.Random (Mersenne Twister), Random(seed).shuffle(sorted_rows). Master seed: 1063288555.

| Band | Candidates | manifest-hash | tony-split | artist | audio-unresolved | Seed |
|---|---|---|---|---|---|---|
| sub-100 | 206 | 1988 | 527 | 290 | 109 | 387184073 |
| 100-120 | 3 | 262 | 5 | 7 | 25 | 3788676503 |
| 120-140 | 28 | 52 | 99 | 37 | 44 | 737215078 |
| 140-160 | 60 | 42 | 246 | 36 | 47 | 2135622856 |
| 160-175 | 41 | 102 | 0 | 0 | 0 | 949256517 |
| 175-plus | 9 | 104 | 0 | 0 | 0 | 804341996 |

Tag-less rows excluded before banding (face-value banding requires a value): pool 2198, tony 2, oa300 0. Tag-less rows carry no band, so these counts are per source.

Artist-exclusion limitation: Pool rows carry no artist field, so artist-based FR-59a.2 exclusion is enforceable only for Tony rows; recorded as a limitation, compensated by the audit fingerprint pass.

Row-level pool file SHA-256: `56b48eccfb4a7a27030cc6d0f43e25d5da4f138a5690e831ac7004b617c3864d`

Draw-sequence file SHA-256: `5772f474de20e205f0bee743d8ff7572178169cddedfe0d7d1ac252ef93062c4`

HALT recorded: these bands CANNOT reach 43 members from the committed pools: 100-120 (3 of 43, short 40), 120-140 (28 of 43, short 15), 160-175 (41 of 43, short 2), 175-plus (9 of 43, short 34). The operator's next action is the signed fallback addendum (Tony as-entered rows, then OA300, banded by the same face-value rule, committed as a dated addendum before any DSP statistic about it is consulted). No auto-extension was performed.
