# Epic 12 Context: Measurement integrity and the DSP tempo prior

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Establish whether the thirty-point gap between our ML model (348/661 GiantSteps FR-18-strict) and the published TempoCNN family is a modelling problem or a measurement problem, and fix the measurement layer so no future accuracy figure is compared against a different ruler. The epic delivers one user-facing capability (consumer-specifiable tempo range, shipped in 12.1) and eight measurement/decision deliverables: annotation-version tagging, a reproduced reference baseline, a cause-ranked pipeline differential, a declared metrical-level convention, a band-balanced 258-track evaluation corpus with detector-independent labels, a public bin-schema contract, and a pre-registered bundle gate. Every deliverable survives the stopping rule firing, so the epic cannot be terminated mid-flight.

## Stories

- Story 12.1: Consumer-specifiable tempo search range — **done** (merged into rterhaar/epic-12)
- Story 12.2: Style-classifier decision — **done** (outcome: reject; SMC hard-bound replication addendum ran and was negative)
- Story 12.3: Annotation-version tagging and the octave-error metric — **done** 2026-08-08 (PR #195, squash-merged into rterhaar/epic-12 as 255a159)
- Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0) — **done**; Gate 0 did NOT fire (reference reproduced at 545/661; verdict gap-attributable-to-our-model)
- Story 12.5: Pipeline differential and cause ranking — **done** (FR-58 ranking recorded)
- Story 12.6: Metrical-level convention and the ground-truth rule — **next** (backlog)
- Story 12.7: Build the 258-track band-balanced corpus — backlog
- Story 12.8: Declare the bin schema a public contract — backlog
- Story 12.9: Define the bundle gate — backlog

## Requirements & Constraints

- **Byte-identity is the default posture.** Default-options DSP output must stay byte-identical (`Double.bitPattern` on bpm/confidence, element-wise candidates). Measurement/decision stories (12.3–12.6, 12.8, 12.9 definition work) keep `Sources/` byte-identical or doc-comment-only; changes live in benchmark, test-support, and develop-only tooling.
- **Corpus floors always hold:** OA300 Acc1 >= 57/82, Acc2 >= 73/82; GiantSteps Acc1 >= 537/661, Acc2 >= 546/661.
- **Accuracy-affecting changes** require a per-track impact report with per-band and per-genre breakdown.
- **Any feature-substrate parameter change bumps `featureSetVersion`** (binds 12.7 if it touches features).
- Every reported accuracy figure carries its ground-truth annotation-version tag; historical figures with unknown versions are marked `untagged`; `Acc2 − Acc1` is reported first-class alongside Acc1 (landed in 12.3 — new reporting must conform).
- **Literature claims trace to primary text**, never to a summarizer (a summarizer fabricated figures during Discovery).
- **Bundle-gate margins are stated in tracks, never percentages**; per-band lift is always reported; per-band results are deterministic tripwires, never significance claims. Gate threshold: ALPHA 0.05, T_MIN 12 net tracks at 10% discordance.
- **Ground-truth labels must never be selected or corroborated by the detector under test** (fails closed in the 12.7 audit). Cross-corpus partitioning must show no residual overlap.
- **No OA300 track is re-labelled in place** — it stays a tagged historical artifact. OA300 is private; never referenced outward.
- Story 12.6 **cannot close on agent work alone** — the ground-truth rule carries explicit operator signoff. 12.7 also carries operator hand-verification.

## Technical Decisions

- **Gate 0 ran at 12.4 and did not fire** (545/661 vs pre-registered midpoint 446.5). The gap is our model, not our ruler; 12.5 executed as planned and the pressure-release artifact was not needed.
- **The Story 12.5 FR-58 ranking supersedes the charter's corrected lever ranking** as the driver of everything after F2 (annotated in epics.md; charter retained, not deleted). Ranking: 1 corpus composition (charter never listed it), 2 augmentation breadth (rank 1's cheap probe, not independent), 3 input representation (constant frame rate), 4 window policy (inference-time multi-window, no retrain needed if the posterior is salvageable), 5 loss/target shape. Bin schema and decode: neutral; evaluation protocol: ruled out. Causes outside Epic 12's scope become documented Epic 14 input, not action inside this epic.
- **Style classifier: rejected (12.2).** Epic 12 builds no style-conditioned prior of any kind; FR-53's caller-declared bounds (`Options.tempoScanRange` scan bounds, `Options.perceptualWindow` octave-fold window — two pairs with distinct semantics and blast radii, opt-in, defaulting to current behavior) supersede FR-54's delivery mechanism. The SMC 130–180 hard-bound replication was negative on all three corpora; the soft-reweighting form remains untested (deferred).
- **Metrical-level convention (12.6):** exactly one level, recorded with the corpus, with its own annotation-version tag; the collection's own convention is half-tempo for 71% of tagged tracks; only the as-entered Rekordbox column is detector-independent (the octave-corrected column came from a vote our detector participated in). The 80-85 / 160-175 ambiguity pairs are retained as a tagged sentinel subset. The legacy-corpus audit records which convention each corpus was trained toward. FR-62a (re-label OA300) is struck — must not become a story.
- **258-track corpus (12.7):** 43 tracks x 6 bands drawn across OA300, Tony's Rekordbox collection, and the non-Rekordbox pool; scarce bands (100-120, 175+) sourced from the pool; the 175+ band's degeneracy (130-of-140 within 175-179, non-separable from 160-175 at +/-4% Acc1 tolerance) is recorded with the corpus. The training corpus is a separate, volume-sized, band-aware-sampled artifact — never truncated to 258. A fail-closed signoff gate (KDD-B4 pattern in train.py) must be wired before any training story runs.
- **Bin schema (12.8):** three declaration sites move together — `tools/coreml-convert/reference_arch.py` (ships to main), `_bmad-output/ml-training/dataset.py`, `BNNSTechnique.expectedBinCount = 256`. Declares only: no bin or decode changes (FR-66 moved to Epic 14). The dead range (bins 0-29 and 171-255 vs the 60-200 runtime abstain) is recorded and cross-referenced to #147. Any schema change requires a named story; pre-1.0 promises no compatibility.
- **Bundle gate (12.9):** ensemble lift — DSP+ML beats DSP alone on the 258-track corpus by a stated margin, no regression in any predeclared DSP-handled band; OA300/GiantSteps report alongside as context and do not gate; seed agreement is a robustness guardrail, never a substitute for the paired margin; preconditions are the four DnB triplet sentinels plus a confidence-calibration floor (FR-25's metric, never run in Epic 7, committed and run here); the harness must demonstrably reject the failed Epic 7 `giantsteps_v2` negative control; each statistical-consult design risk is answered in writing before the gate is final.
- **Develop-only Python lives under `_bmad-output/ml-training/`**, never under `tools/coreml-convert/` (the only Python shipping to main).
- Remaining stopping rules: Gate 1 (after F4 — no ensemble lift from training-target repair = failed lever one) and Gate 2 (top FR-58 cause also produces no lift = failed lever two; the epic stops and the premise is re-examined). Epic 14 is chartered but deliberately unscoped until Gate 1 passes.

## Cross-Story Dependencies

- 12.6 -> 12.7: the convention and ground-truth rule must be declared before any labelling starts (the rule cannot change mid-verification). 12.7 -> 12.9: the gate is defined against the corpus 12.7 built. 12.3's tagging makes 12.6's convention transition survivable (the new convention gets its own tag).
- All dependencies point backward; no story requires a later one. Stories 12.7 and 12.9 exceed a single dev session and should be split at story-creation time.
- Epic 14 consumes the FR-58 ranking and FR-66; Epic 13's charter items 1 and 2 were struck when Epic 12 took the DSP octave levers.
- Note: architecture.md predates this epic and has zero Epic 12 coverage; the epics file and story artifacts are the operative planning source.
