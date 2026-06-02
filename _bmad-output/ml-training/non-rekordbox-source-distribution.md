# Non-Rekordbox source distribution (Story 7.2, FR-13 / KDD-B4)

Analyzable files surveyed: **4766**. Skipped (reported, not analyzed): cloud_only **0**, ambiguous_membership **86**, duplicate_audio_hash **294**, unreadable **0**.

## (d) Tier counts

| tier | count |
|---|---|
| secondarySupervised | 2172 |
| unsupervisedPool | 2407 |
| reject | 187 |

## (c) Source / format distribution

| format | count |
|---|---|
| aif | 2 |
| aiff | 16 |
| flac | 29 |
| m4a | 16 |
| mp3 | 4172 |
| wav | 531 |

## (b) Tempo distribution (metadata-blind DSP BPM, 5-BPM bins)

| bin | count |
|---|---|
| none | 13 |
| 65-69 | 14 |
| 75-79 | 5 |
| 80-84 | 16 |
| 85-89 | 82 |
| 90-94 | 3 |
| 95-99 | 2 |
| 100-104 | 6 |
| 105-109 | 26 |
| 110-114 | 84 |
| 115-119 | 101 |
| 120-124 | 19 |
| 125-129 | 22 |
| 130-134 | 33 |
| 135-139 | 89 |
| 140-144 | 39 |
| 145-149 | 32 |
| 150-154 | 24 |
| 155-159 | 100 |
| 160-164 | 103 |
| 165-169 | 277 |
| 170-174 | 2714 |
| 175-179 | 805 |
| 180-184 | 84 |
| 185-189 | 25 |
| 190-194 | 19 |
| 195-199 | 17 |
| 200-204 | 12 |

## (a) Genre proxy (file-path hint -> coarse bucket; REPORT-ONLY, never a tiering input)

Purpose: let the reviewer judge whether the expansion BROADENS the domain or REINFORCES the DnB-heavy labeled corpus — a composition-balance judgment, not a per-file decision.

| bucket | count |
|---|---|
| Bass Music | 135 |
| Drum and Bass | 4630 |
| Rave | 1 |

## Yield, threshold sensitivity, and ablation risk (DD #8)

- secondarySupervised yield at the 0.03 tolerance: **2172**.

| sensitivity datapoint | value |
|---|---|
| would-agree at 0.03 (= secondarySupervised) | 2172 |
| would-agree at 0.04 (non-reject rows, delta <= 0.04) | 2180 |
| rejects DUE TO the 0.40 DSP-confidence floor (no metadata + weak DSP) | 174 |

Reported as analysis ONLY — the 0.03 tolerance and 0.40 reject floor are NOT loosened to manufacture a larger supervised tier (DD #8).

## Sentinel review (FR-17 / AC7 — REPORT-ONLY, never a tiering input)

- 4-needle title near-copies in the pool: **0** (already audioHash-excluded: 0; **NOT hash-excluded (manual review — possible re-encode): 0**).
- 12-sentinel-set title cross-check matches (8 of 12 titles specific enough to check): **2** (the 8 expanded sentinels are Rekordbox-collection IDs, structurally outside the pool; generic short titles are skipped to avoid noise).

## Octave-correctness caveat (DD #6)

A `secondarySupervised` label proves DSP<->tag *consistency*, NOT octave *correctness*: when DSP picks the wrong fundamental (Tony's half-tempo pattern, FR-12) and the tag agrees, `bpm_truth` enshrines the DSP octave error. Story 7.3's octave-aware loss (FR-16) is the trainer-side backstop. Agreement != correctness.

