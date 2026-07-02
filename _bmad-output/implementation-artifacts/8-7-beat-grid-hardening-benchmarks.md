# Story 8-7 beat-oracle hardening (PR #48) — full benchmark gauntlet

Run at SHA `3a86a07` (`rterhaar/8-7-beat-oracle-hardening`), 2026-06-20, Apple M5 Max / macOS 26.
The change is develop-only Python (`scripts/rekordbox-beats.py`) with zero `Sources/`/Swift/DSP
edits, so every Swift-path number is expected to be byte-identical to the pre-change reference.
All four suites confirm that, and the oracle regeneration confirms the two hardening guards are
inert on the real corpus.

## Oracle regeneration — the actual test of the change

`make oracle-generate-beats` with the patched generator:

- Oracle SHA-256 **`46d60de7…ee4cd6`** — **byte-identical** to the pre-change oracle.
- 1264 tracks, 652,189 beats, all 4/4; 2 no-grid / 371 unresolved / 84 duplicate-path collapsed.
- **0 new `invalid_duration` refusals** — Patch 1's one-bar `duration_slop` clamp
  (`max(1.0, min(one_bar, 4.0))`) fires on nothing in the corpus (max beat-over-duration 0.867 s <
  the 1 s floor).
- 3 collision overrides fire correctly (Patch 2's readable-path branch): `Todd Bucher - Proem.wav`,
  `Todd Bucher - Onyx.wav`, `Ron Mercy - Junkin Da Trunk.mp3`.

## Beat-grid acceptance (`make benchmark-beatgrid`, release, 1264 tracks)

Reproduces the committed `8-7-beat-grid-accuracy.json` exactly (the tracked JSON regenerated with
no diff):

| Metric | This run | Committed baseline | Gate |
|---|---|---|---|
| F-measure octave-norm constant (GATED) | **0.3718** | 0.3718 | ≥ 0.33 ✅ |
| F-measure octave-norm all | 0.3721 | 0.3721 | reported |
| F-measure raw all | 0.2622 | 0.2622 | reported |
| Downbeat correctness-when-fired (constant, gated) | 0.1444 (42 tracks) | 0.1444 | ≥ 0.10 ✅ |
| Downbeat fire-rate / abstain / pass-failures | 4.3% (54/1264) / 95.7% / 0 | same | reported |
| FR-29 last-beat drift P95 (450 tracks ≥ 5 min) | 1652.4 ms (median 175.8) | 1652 ms | ≤ 2000 ms ✅ |

Coverage-parity asserted over all 1264 estimated tracks (910 constant-tempo, 0 missing).

## Accuracy + perf (DSP path — unchanged by construction)

| Suite | This run | Reference |
|---|---|---|
| OA300 @ 2% | Acc1 58/82 (70.7%), Acc2 74/82 (90.2%) | 58/74 ✅ |
| GiantSteps @ 2% | Acc1 537/661 (81.2%), Acc2 546/661 (82.6%) | 537/546 ✅ |
| perf wall-clock (OA300 serial, intensity 7) | mean 0.181 s, p95 0.253 s | within noise (+5% vs last baseline) |

Perf baseline persisted: `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260620T215654Z--3a86a07--580428a0.json`
(schema v2, clean SHA). ML mock-on-abstain gate 1.561× < 1.60× ✅.

## Conclusion

The hardening is byte-inert end-to-end: oracle byte-identical → estimated beats identical →
F-measure / downbeat / drift all identical; OA300/GiantSteps/perf all match reference. The two
new guards change behaviour only on pathological input the corpus does not contain.
