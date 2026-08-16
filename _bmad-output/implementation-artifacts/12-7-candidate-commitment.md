# Story 12.7: candidate-pool commitment record

Status: **active**.

Generated 2026-08-15 by `scripts/build-eval-corpus.py` (`make eval-corpus-pools`). Counts, seeds, and the named commitment digests only; the row-level candidate inventory is gitignored per the privacy rule (OA300 and the collection inventory are private).

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md section 2`.

Seed algorithm: python-stdlib random.Random (Mersenne Twister), Random(seed).shuffle(sorted_rows). Master seed: 982188959.

Generation: `ge94c3fc04f636363` (every row-level path is scoped to it).

Supersedes commitment `986156f5600a298b7c7c581936ad54139b5cfd960214d5f2d8ce2d83d166055e`, archived byte-for-byte alongside this record. Commitment validation walks the chain, so an archived predecessor cannot silently vanish.

| Band | Candidates | manifest-hash | tony-split | artist | audio-unresolved | audio-unhashable | fingerprint-uncoverable | fingerprint-confirmed | cross-band-duplicate | continuous-mix | Seed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| sub-100 | 2155 | 0 | 527 | 290 | 109 | 14 | 0 | 7 | 10 | 8 | 2627814653 |
| 100-120 | 263 | 0 | 5 | 7 | 25 | 1 | 0 | 1 | 0 | 0 | 844345532 |
| 120-140 | 76 | 0 | 99 | 37 | 44 | 2 | 0 | 0 | 2 | 0 | 227114723 |
| 140-160 | 73 | 0 | 246 | 36 | 47 | 13 | 0 | 3 | 12 | 1 | 3068079782 |
| 160-175 | 114 | 0 | 0 | 0 | 0 | 29 | 0 | 0 | 0 | 0 | 2250969899 |
| 175-plus | 104 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 9 | 3325602299 |

Tag-less rows excluded before banding (face-value banding requires a value): pool 2198, tony 2, oa300 0. Tag-less rows carry no band, so these counts are per source.

Artist-exclusion limitation: Pool rows carry no artist field, so artist-string FR-59a.2 exclusion is enforceable only for Tony rows. What compensates is NOT the artist check by another name: the mandatory pre-commitment fingerprint review covers every candidate against the training manifests by audio content, and every confirmed match is DISPOSED OF before minting. What disposal means depends on the recorded partition order. Under the pre-amendment order a confirmed match excludes the candidate. Under the signed 2026-08-11 repartition order a confirmed match against a training-MANIFEST row instead retains the candidate and enumerates the training row the rebuild must drop, while a confirmed match against a tony.train or tony.val row still excludes. The residual gap is the same either way: a training track by the same artist that is a DIFFERENT recording, which artist-string exclusion would have removed and fingerprinting deliberately does not.

Pre-commitment fingerprint review (mandatory, signed section 2): method librosa-mfcc-chroma-timbral-v3, 182 review flag(s), 146 confirmed same-recording, 36 cleared by recorded human disposition, 6 transitive same-recording group(s). The algorithm flags; the disposition disposes. Outcomes of the confirmed dispositions, reported as ATTRIBUTIONS rather than as an arithmetic split (one candidate can carry several confirmed flags, and one obligation can be found by several routes): 11 candidate(s) excluded, of which 11 attributable to a training-fingerprint match and 0 to a GiantSteps-title match; 143 must-drop obligation(s) enumerated by a confirmed training-fingerprint match instead of excluding, per the partition order below.

Fingerprint coverage (the route fails closed): candidates 2820 of 2820 covered, by reason {'resolved': 2820, 'unresolved-path': 0, 'missing-file': 0, 'decode-failed': 0, 'too-short': 0, 'non-finite': 0, 'metadata-excluded': 0, 'no-path': 0}; training rows 5193 of 5193 covered, by reason {'resolved': 5193, 'unresolved-path': 0, 'missing-file': 0, 'decode-failed': 0, 'too-short': 0, 'non-finite': 0, 'metadata-excluded': 0, 'no-path': 0}, with 0 accepted by dated operator amendment. An uncovered candidate is hard-excluded; an uncovered training row blocks certification.

Coverage digest: `bc5f3306db520739d54ae635c248efedd09725ade7c8754a89edee144cc55dca`

Dispositions digest: `c1eb9e64288bc54fd38f079c5500bd004baf461def2c3bcba6dce6bd53b48165`

Candidate-universe digest: `55e3ea63629807a4b2d48463c6d3c34f576fe901514bdf137b906c293af7363e`

Training-input digest: `d77f177d9252c3afdc262d16ab9fa671e2904868803a16fdd0c204fa83856102`

Mint-time training-input provenance, pinned per file so a later rebuild is attributable rather than one opaque mismatch: `corpus_splits.json` `86594293d668b654292dc8b4ce1f0694b4d18c183dd25e28d5606dae688cffea`, `non-rekordbox-secondary-supervised-manifest.json` `7f5c9eb54f777bf7beca370a2816f3a27122b58b5a7d05e0dee192d641764e5f`, `non-rekordbox-unsupervised-pretrain-manifest.json` `56ca9c907f33eb2360d1cf4a4389c9e2126ba1789f162d50af4a1b4e62e3caff`

FR-59a.2 partition order: **repartition**, status provisional. Route reversed: non-Rekordbox training manifest audioHash. Must-drop obligations at mint: 2684 distinct (eval row, training row) pair(s), of which 2541 were found by the training-manifest audioHash route and 143 by a confirmed training-fingerprint disposition; a pair found by both is counted once in the total and under both routes. Must-drop digest `bf000ab82402d1f865998cb0555f8af6ea21d7a86f06aa807f5f8110068435a3`; the row-level list is gitignored. Signed amendment 2026-08-11 (FR-59a.2 partition ORDER). Under the repartition policy one exclusion route reverses: a candidate matching a non-Rekordbox TRAINING MANIFEST by audioHash is drawn into the eval corpus, and the training rebuild drops it. The tony.train and tony.val recording-identity route and the artist-string route are unchanged and still exclude at candidate construction. The counts here are the MINT-TIME obligation universe over candidates; the list bound at signoff is derived from the final MEMBER roster, because dropping training rows for candidates that were rejected or ended up surplus would starve training for nothing. Row-level entries are private and live in a gitignored sidecar; only this digest and these counts are committed.

Operator decisions (2026-08-11): short-band allocation repartition, cross-band duplicate rule pre-commitment-recording-dedup; decisions digest `e560a93ed0ba5947ed2ee4df10d335707e32c10acbbf2f8adf3b15330055e7ea`.

Signed exhaustion fallback (enumerated under EVERY short-band policy, applied only under `fallback-addendum`): candidates by band {'sub-100': 198, '100-120': 3, '120-140': 28, '140-160': 59, '160-175': 41, '175-plus': 0}, already in the primary pool {'sub-100': 184, '100-120': 2, '120-140': 26, '140-160': 46, '160-175': 12, '175-plus': 0}, NET NEW {'sub-100': 0, '100-120': 0, '120-140': 0, '140-160': 0, '160-175': 0, '175-plus': 0}. The signed exhaustion fallback source order is Tony as-entered rows, then OA300 rows. Both are already inside the primary pools, so the addendum's NET NEW set is empty by construction: enumerating it recovers nothing for any band. A short band still HALTS. This is reported rather than inferred so the operator can see it.

Row-level pool file SHA-256: `2a9cff7cf36070c8341d847270a7256379da1e0540982f9c9307817cccf385b8`

Draw-sequence file SHA-256: `be9f3ccf01d13ba84d7d8b13cc071010d436c00acafeb07d702cb9c85a784efb`

The annotation ledger provides INTEGRITY, not backup or recovery. It detects editing, deletion, reordering, and stale-file reuse of annotation state; it cannot restore a lost annotation, and these labels cannot be regenerated. Annotation records are immutable and versioned: no command overwrites or unlinks one.
