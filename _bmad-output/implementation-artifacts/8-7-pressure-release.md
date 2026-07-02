# Story 8.7 — Pressure-release: measured beat-grid accuracy is far below the epic's published targets

**Date:** 2026-06-17
**Trigger:** DD-1 pressure-release valve (measured < target → document actual, recommend Story 8.4 reopen, do NOT silently weaken).

## What was measured

Calibration run: `make benchmark-beatgrid` (release) over the full Rekordbox JAMS oracle
(`rekordbox-beats.jams.json`, Story DD-13). 1264 on-disk-resolved gridded tracks, 910
constant-tempo (single-anchor), 0 missing from the estimated artifact. Our anchor+tempo
**full-span extrapolated** grid (stable, non-downbeat anchor — Codex-reviewed) vs the
Rekordbox extrapolated grid, octave-tolerant, ±70 ms.

| Gated metric | Measured | Epic published target | Committed floor (`measured − margin`) |
|---|---|---|---|
| F-measure (octave-normalized, constant-tempo) | **0.3718** | 0.75 (AC4) | **0.33** |
| Downbeat correctness-when-fired (octave-tolerant, constant) | **0.1444** (n=42 fired) | — (AC7 measure-first) | **0.10** |
| FR-29 P95 last-beat drift | **1652 ms** (median 176 ms, n=450 ≥5 min) | 30 ms (AC6) | **2.0 s** (regression ceiling, NOT the 30 ms aspiration) |

Reported (not gated): raw all-corpus F-measure 0.2622; octave all-corpus 0.3721; downbeat
fire-rate **4.3%** (54/1264), abstain-rate 95.7%.

(The oracle audio-path resolution was made deterministic across machines — sorted
basename-collision candidates, Copilot review — which shifted the reported fire-rate by one
track and the all-corpus octave mean by 0.0004; the GATED constant-tempo numbers above are
unchanged.)

## Why the numbers are this low (analysis, not excuse)

1. **Rekordbox is an imperfect, auto-analyzed reference**, not hand-annotated ground truth.
   The OA300 dawproject (the spec's original source) was operator-hand-warped; the operator
   redirected to the Rekordbox corpus (DD-13) for authoritative downbeat phase (`Battito`),
   accepting that the position reference is auto-generated.
2. **Per-track phase + fine-tempo disagreement.** Per-track median offset is ~0 (no systematic
   codec-priming offset), but the within-track spread is 50–100 ms (MAD). On a constant-tempo
   track both grids are constant extrapolations, so a 50–100 ms spread means our `estimatedTempo`
   differs from Rekordbox's `Bpm` by a few tenths of a BPM, and the offset accumulates across the
   track — pushing ~half the beats outside ±70 ms. That is the dominant F-measure loss.
3. **Real-world material.** Tony's corpus is vinyl rips / old jungle / DJ edits with genuine
   tempo fluctuation; our tracker is documented constant-tempo-only (`BeatGrid` DocC). FR-29
   drift of 1.65 s reflects real audio tempo drift, not a code regression — but it also means the
   30 ms FR-29 contract (validated on the cleaner OA300 corpus) does not transfer to this corpus.
4. **Downbeat detector (8.5a) is deeply conservative.** 4.4% fire rate is the measured value
   behind the previously-unquantified word "conservative" — exactly what AC7 set out to replace.
   When it fires, phase correctness vs Rekordbox `Battito` is 0.14 (octave-tolerant), i.e. it is
   roughly as likely to disagree as agree on the bar phase.

## Recommendation (do NOT weaken the targets to fit)

- **The committed `#expect` floors above are regression nets at the measured level**, not a claim
  that the epic's 0.75 / 30 ms targets were met. They catch *future regressions* in the beat
  tracker; they do not certify the current quality as "good".
- **Reopen Story 8.4 (beat tracker) for refinement** before Epic 8 can claim a beat-grid accuracy
  target was hit. Highest-leverage items: (a) tighten `estimatedTempo` precision so the
  extrapolated grid does not drift a few tenths of a BPM off the reference over a full track;
  (b) revisit the 8.5a downbeat fire/abstain gates now that there is a measured fire rate (4.4%)
  and correctness (0.14) to optimize against.
- **The published 0.75 / 0.65 / 30 ms targets remain the aspiration** in the epic; this story
  records that they are currently unmet on the Rekordbox real-world corpus and provides the
  measurement harness (`make benchmark-beatgrid`) to track progress toward them.
