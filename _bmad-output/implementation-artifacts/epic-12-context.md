# Epic 12 Context: Measurement integrity and the DSP tempo prior

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Find out whether a bundleable BPM model is reachable and which lever is worth funding, and fix the measurement layer so no accuracy figure is compared against a different ruler. The epic ships one consumer feature (callers can bound the tempo search range, so a 70 BPM drum-and-bass track stops reading as 140 without any model) and builds what the project never had: a published reference baseline scored on our own evaluation path, a band-balanced 258-track evaluation corpus whose labels were never checked against our own detector, a public declaration of the 256-bin schema, and a bundle gate stated in tracks. Every deliverable stays useful even if the model programme is stopped. There is no architecture coverage for this epic: architecture.md predates it, so the epics file and story artifacts are the planning source, and story authors must not invent architecture decisions to fill the gap.

## Stories

- Story 12.1: Consumer-specifiable tempo search range
- Story 12.2: Style-classifier decision (scope it, defer it, or reject it)
- Story 12.3: Annotation-version tagging and the octave-error metric
- Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0)
- Story 12.5: Pipeline differential and cause ranking
- Story 12.6: Metrical-level convention and the ground-truth rule
- Story 12.7: Build the 258-track band-balanced corpus
- Story 12.8: Declare the bin schema a public contract
- Story 12.9: Define the bundle gate

## Requirements & Constraints

- Default-path DSP output stays byte-identical: `Double.bitPattern` equality on bpm and confidence, element-wise on candidates. New behaviour is opt-in with defaults equal to today's.
- Measurement, decision and declaration stories leave `Sources/` byte-identical (12.8 allows doc-comment edits only); their work lives in benchmark, test-support and develop-only tooling.
- Corpus floors always hold: OA300 Acc1 >= 57/82, Acc2 >= 73/82; GiantSteps Acc1 >= 537/661, Acc2 >= 546/661.
- Any accuracy-affecting change ships a per-track impact report with per-band and per-genre breakdown.
- Any feature-substrate change bumps `MLFeatureFrames.currentFeatureSetVersion` (one constant) and keeps Swift/Python parity via the FNV-1a checksum.
- Bulk numeric work goes through vDSP. No new dependencies; new public types are `Sendable`.
- Every reported accuracy figure carries the annotation version of its ground truth; figures with unknown versions are marked `untagged`. `Acc2 - Acc1` is reported alongside Acc1 as a first-class octave-error metric.
- Every literature figure traces to the paper itself, never to a summarizer (a summarizer fabricated numbers during discovery).
- A label may never be chosen or confirmed using the detector under test; the corpus audit fails closed on this, and cross-corpus partitioning must show no residual overlap.
- OA300 is private: never published or referenced outward, and no OA300 track is re-labelled in place.
- Weights are never committed to the repository.

## Technical Decisions

- **Tempo range (12.1, shipped):** two separately documented pairs on `AudioAnalysisService.Options`: `tempoScanRange` (candidate search grid, default 40...250) and `perceptualWindow` (octave-fold window, default 60...200, must span at least one octave). Invalid input is normalized, never thrown. Target set is three octave fixtures; `robbyt_x-ray-120s` is a triplet relation and its existing test label is correct.
- **No style classifier (12.2, reject):** Epic 12 builds no style-conditioned prior of any kind. The caller-declared range supersedes it. A hard 130...180 replication was negative on all three corpora; the soft-reweighting form is untested and filed as deferred work.
- **Gate 0 did not fire (12.4):** the reference reproduced at 545/661 against our model's 348/661 (threshold 446.5). The gap is our model, not our ruler. Reference harness code is develop-only Python under `_bmad-output/ml-training/`, never under `tools/coreml-convert/`.
- **Cause ranking (12.5) drives all later work,** replacing the older charter ranking (kept, annotated): 1 corpus composition, 2 augmentation breadth, 3 input representation, 4 multi-window inference, 5 loss/target shape. Bin schema and decode are neutral; evaluation protocol is ruled out. Causes outside Epic 12 become Epic 14 input, not action here.
- **Convention (12.6, signed off):** one metrical level, full tempo, tagged `declared:metrical-full-tempo-v1-2026-08-08`. Ground truth is human verification of every corpus track. Only the as-entered Rekordbox column is independent of our detector. The 80-85 / 160-175 ambiguous pairs stay as a tagged subset. FR-62a (relabel OA300) is struck and must not become a story.
- **Corpus (12.7):** 43 tracks in each of six bands (<100, 100-120, 120-140, 140-160, 160-175, 175+), 258 total, drawn from OA300, Tony's Rekordbox collection and the non-Rekordbox pool; scarce bands come from the pool. Record that 175+ is almost entirely 175-179 and cannot be told apart from 160-175 at the 4% tolerance. The training corpus is a separate, volume-sized, band-aware sample, never cut to 258. `train.py` carries a fail-closed gate that refuses to run until this corpus is signed off, and that gate must stay wired before any training story runs. **Closed 2026-10-23 at current coverage:** 172 members in four full bands (120-140, 140-160, 160-175, 175+ at 43 each), with 100-120 and sub-100 declared short in `12-7-short-bands.json` (12-6 section 6 amendment of 2026-10-23, awaiting the operator's signature), plus an 11-track slow-tempo supplement outside membership that is report-only (every track is tagged `detector-visible`, so none enters a pass or fail gate). Signoff still refuses and the `train.py` gate stays closed; filling the slow bands, the blind re-pass and the training-overlap sign-off are deferred.
- **Bin schema (12.8):** names the three sites that move together (`tools/coreml-convert/reference_arch.py`, which ships to main; `_bmad-output/ml-training/dataset.py`; `BNNSTechnique.expectedBinCount = 256`), notes `MLTechniqueError.binCountMismatch` is consumer-visible, records the 115 unusable bins (0-29, 171-255) against #147, and changes nothing. Any schema change needs a named story.
- **Bundle gate (12.9):** DSP+ML must beat DSP alone on the 258-track corpus by a margin stated in tracks (ALPHA 0.05, 12 net tracks at 10% discordance), with `gains >= losses` in every band DSP already handles (a band counts as handled when DSP gets 30 of 43 right). OA300 and GiantSteps report alongside and do not gate. Seed agreement is a robustness check, never a replacement for the paired margin. Preconditions: the four DnB triplet test tracks and a confidence-calibration floor (the calibration metric is committed and run here). The harness must reject the failed Epic 7 `giantsteps_v2` model. Each open design risk from the statistical consult is answered in writing first. The 258-track figures (the corpus size, the 12-net-track margin, the 30-of-43 handled-band rule) must be restated for the corpus 12.7 actually closed with: 172 tracks in four bands, two bands short, and no gate-eligible slow track.
- **Stopping rule:** if training-target repair yields no ensemble lift (Gate 1) and the top-ranked cause also yields none (Gate 2), the model programme stops and the premise is re-examined. Epic 14 stays unscoped until Gate 1 passes.

## Cross-Story Dependencies

- 12.3 before 12.6: tagging lets the new convention carry its own version tag. 12.6 before 12.7: the convention and ground-truth rule are fixed before labelling starts. 12.7 before 12.9: the gate is defined against that corpus. All dependencies point backward. 12.9 should be split: the gate definition can start now, and the final run on the full corpus waits for a later story that completes it.
- Human verification of 258 tracks has no cost bound and its rate is unproven (the DAW-oracle precedent verified 23); re-plan if the rate does not hold.
- Epic 14 consumes the 12.5 ranking, the bin-range alignment work, and the delivery requirements. `Options.ensemblePolicy` defaults to `.dspOnly`, so a model that passes the gate changes nothing users see until that default is decided.
- Epic 13's items 1 and 2 moved here; the SignalPool octave arbiter is post-MVP and not covered by any 12.x story.
