# Label-Tier Policy v1 (Story 7.1, FR-14 / FR-15)

Develop-only policy document. Single source of truth for how the 1,344-track
hand-labeled corpus (`tony-corpus/tony-truth-labels.json`) is banded into tiers
and which subset is trainable. The banding here is the ONLY definition; the
diagnostics generator, the split builder, and the audit all import it from
`corpus_common.tier_for` — do not re-implement banding anywhere else.

> All confidence figures are LABEL-confidence over the labeler's disagreement
> signals, NOT model metrics (Guardrail 2). This policy produces evidence +
> exclusions; it produces no transferable FR-18 accuracy claim.

## Tier bounds — EXACT half-open intervals on `truth_confidence`

`truth_confidence` is the labeler's head-to-head winner margin
`winner_weight / (winner_weight + runner_up_weight)`, rounded to 3 decimals
(`scripts/tony-tunes-labels.py`). It is winner-margin, NOT calibrated
correctness — two biased signals agreeing yields high confidence. See the E1
label-octave-error audit in `corpus-diagnostics-v1.json` for the wrong-octave
class this margin cannot catch.

| Tier | Interval on `truth_confidence` | Count (current corpus) |
|---|---|---|
| Strong | `[0.80, +inf)` | 333 |
| Solid | `[0.65, 0.80)` | 745 |
| Marginal | `[0.55, 0.65)` | 241 |
| Reject | `[0.00, 0.55)` **plus every `bpm_truth == null` abstention** | 25 |

- **Half-open, boundary goes UP (M2):** a record at exactly `0.65` is Solid (not
  Marginal); a record at exactly `0.80` is Strong (not Solid). Intervals are
  closed on the left, open on the right.
- **Null abstentions are Reject regardless of confidence:** the 25 Reject tracks
  are exactly the `bpm_truth == null` set (the labeler withholds truth below
  `MIN_TRUTH_CONFIDENCE = 0.55`). On the current corpus there are zero non-null
  tracks below 0.55, so Reject == the null set; the `[0.00, 0.55)` interval is
  retained for correctness against future relabels.
- **Counts are a snapshot, not a contract.** FR-14 says "currently". The
  diagnostics emit the *computed* histogram and reconcile it against this PRD
  snapshot (333/745/241/25) as a drift delta — never coerced (AC10). The corpus
  is develop-local/gitignored; `corpus-diagnostics-v1.json` pins the label-file
  + labeler-script SHA-256 so a regenerated label file is detectable (AC9).

## Supervised set

- **Trainable = Strong + Solid = 1,078 tracks** (matches the FR-14 target).
- **Excluded from supervised training = Marginal (241) + Reject (25) = 266.**
  Marginal is retained as a failure-categorization lens / disagreement-geometry
  input / post-bundle watchlist (Story 7.4), not as training labels.
- After the Story 7.1 split guards, the 1,078 trainable set is further reduced
  before train/val assignment by: cross-corpus eval-leak exclusion (AC5, 54
  tracks colliding with OA300/GiantSteps) and the 8 held-out expanded DnB
  sentinels (AC7) — leaving 1,016 in `tony.train` + `tony.val` +
  `tony.leaveArtistOut`. The exclusions are recorded in `corpus_splits.json`.

## Single-source-truth trainability policy (M3)

The labeler sets a `single_source_truth` QA flag when the winning tempo cluster
rests on fewer than two distinct **non-playlist** sources, yet still assigns
`bpm_truth`. Policy decision and count:

- **Count:** 10 tracks carry `single_source_truth` corpus-wide; **0 of them
  reach the Strong/Solid trainable tier** — the flag co-occurs with
  `low_confidence` and every single-source track tiers into Marginal/Reject.
- **Decision: INCLUDE (moot on this corpus).** Because no single-source track is
  trainable today, the trainable set of 1,078 is fully multi-source; no special
  handling is required. **Trigger to revisit:** if a future relabel pushes a
  single-source track into Strong/Solid, this decision must be re-made before
  that track enters training (the drift-block threshold in AC9 will flag the
  tier-count change).

## KDD-B3 — Marginal-tier reopen triggers (VERBATIM)

Source: `_bmad-output/planning-artifacts/architecture.md`, section header
**"Reopen triggers (Codex's 5 named signals):"** (cited by header text, not line
number — offsets drift). Reproduced verbatim:

1. Strong/Solid validation accuracy plateaus below target while train accuracy is materially higher
2. Leave-artist-out or GiantSteps underperforms despite good in-domain validation
3. Error analysis shows many failures are near marginal-style ambiguity (half/double confusions, 87/174, 130/65/260, breakbeat/DnB edge cases)
4. Masked-mel pretraining helps materially, implying unlabeled/ambiguous audio structure is useful
5. Marginal tracks receive stable, high-confidence predictions across seeds/checkpoints/augmentations and do not degrade sentinels

If any trigger fires during Epic 7 training, the Marginal tier (and its banding)
is reopened for reintroduction review per KDD-B3.

## FR-15 — Forbidden model inputs (audio-only constraint)

The trained tempo model consumes AUDIO ONLY. The signals below inform LABELING
(they produced `bpm_truth`) but MUST NEVER become model features. Any future
feature-pipeline contract that admits one of these is an FR-15 violation:

- **Playlist names** (`signals.playlist.names`) — the corpus's only
  genre-adjacent signal; it may seed by-ear sentinel curation (AC7) but is a
  curator artifact, never a feature.
- **File-path components** (`local_path`, directory/release-folder names).
- **Rekordbox-specific signals** — `AverageBpm`, grid tempo arrays, beatgrid
  anchors, cue points, the `track_id`.
- **DSP candidate scores** — the DSP pre-pass BPM/confidence (`signals.dsp`); a
  labeling input, not a model feature (the model must learn tempo from audio,
  not inherit the DSP's answer).
- **Artist / artist embedding** — including the canonical artist key used for
  the leave-artist-out split; it partitions data, it does not describe audio.
- **ID3 / container BPM tags** — any embedded metadata BPM.

Permitted model input is the log-mel feature substrate only (Story 6.2 /
`FeatureSubstrate`), produced from PCM. The leave-artist-out and tier metadata
above are TRAINING-CONTROL data, not features.

## What 7.1 "done" means

7.1 "done" = corpus evidence assembled + label-tier policy written + splits
guarded + review **pending**. It is NOT "corpus-safe-to-train". The KDD-B4
reviewer signoff in `corpus-diagnostics-v1.md` (enforced by
`audit-corpus-splits.py --check-gate`) flips that — and it gates Story 7.5
`train.py`, not 7.1 close.

### Story 7.5 `train.py` precondition contract

Story 7.5's `train.py` MUST, before reading any split, shell out to:

```
python scripts/audit-corpus-splits.py --check-gate
```

and refuse to start (non-zero exit propagated as a hard error) unless it returns
0. `--check-gate` returns 0 only when `corpus-diagnostics-v1.md` carries
`REVIEWER_SIGNOFF: signed`. This is the single executable source of truth for the
KDD-B4 gate; 7.1 does NOT implement the `train.py` precondition itself (that is
7.5's task) — it ships the gate `train.py` will call.
