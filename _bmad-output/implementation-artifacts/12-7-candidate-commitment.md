# Story 12.7: candidate-pool commitment record

Status: **superseded**.

Generated 2026-08-08 by `scripts/build-eval-corpus.py commit-pools` (`make eval-corpus-pools`). Counts, seeds, and the named commitment digests only; the row-level candidate inventory is gitignored per the privacy rule (OA300 and the collection inventory are private).

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md section 2`.

Seed algorithm: python-stdlib random.Random (Mersenne Twister), Random(seed).shuffle(sorted_rows). Master seed: 1063288555.

SUPERSEDED 2026-08-10. This commitment was minted without the mandatory pre-commitment audio-fingerprint review that the signed section-2 exclusion rule requires, its opaque row IDs encode draw position (a blinding weakness against an annotator who knows the first-43 rule), and its Tony and OA300 rows are bound only by track identifier and filename rather than by audio content. It is retained as the record of what was minted and is never operated on: every consumer of this harness refuses while status is superseded, in code and not merely in prose. Nothing was lost by re-minting, because the working state held only candidate and draw files at the time, with no batch staged and no annotation recorded. Re-minting is blocked on the recorded fingerprint dispositions and on two operator decisions: the short-band allocation and the cross-band duplicate rule.

| Band | Candidates | manifest-hash | tony-split | artist | audio-unresolved | Seed |
|---|---|---|---|---|---|---|
| sub-100 | 206 | 1988 | 527 | 290 | 109 | 387184073 |
| 100-120 | 3 | 262 | 5 | 7 | 25 | 3788676503 |
| 120-140 | 28 | 52 | 99 | 37 | 44 | 737215078 |
| 140-160 | 60 | 42 | 246 | 36 | 47 | 2135622856 |
| 160-175 | 41 | 102 | 0 | 0 | 0 | 949256517 |
| 175-plus | 9 | 104 | 0 | 0 | 0 | 804341996 |

Tag-less rows excluded before banding (face-value banding requires a value): pool 2198, tony 2, oa300 0. Tag-less rows carry no band, so these counts are per source.

Artist-exclusion limitation: Pool rows carry no artist field, so artist-string FR-59a.2 exclusion was enforceable only for Tony rows in this mint. NOTHING compensated that gap here: the earlier text named an audit fingerprint pass as the compensating control, and no such pass existed in the harness at the time. That is one of the reasons this record is superseded. In the re-mint the compensating control is real and named: the mandatory pre-commitment fingerprint review covers every candidate against the training manifests by audio content, and confirmed matches are excluded before minting. Even then the residual gap is a training track by the same artist that is a DIFFERENT recording, which artist-string exclusion would have removed and fingerprinting deliberately does not.

Row-level pool file SHA-256: `56b48eccfb4a7a27030cc6d0f43e25d5da4f138a5690e831ac7004b617c3864d`

Draw-sequence file SHA-256: `5772f474de20e205f0bee743d8ff7572178169cddedfe0d7d1ac252ef93062c4`

HALT recorded: these bands CANNOT reach 43 members from the committed pools: 100-120 (3 of 43, short 40), 120-140 (28 of 43, short 15), 160-175 (41 of 43, short 2), 175-plus (9 of 43, short 34). No auto-extension was performed.

The signed exhaustion fallback does NOT resolve this on its own. Its source order is Tony as-entered rows, then OA300 rows, and both are already inside the primary pools, so the fallback set is empty by construction: it can recover at most 25 rows for 100-120 and 44 for 120-140, and exactly ZERO for 160-175 and 175-plus. A precommitted primary allocation plus reserves would draw across all three sources while preserving a real fallback; shrinking the corpus by operator decision is the other signed option. This is an operator decision, supplied as machine-readable input; the harness refuses to mint while it is absent rather than inferring a policy from prose.
