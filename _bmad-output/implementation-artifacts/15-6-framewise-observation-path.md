# Story 15.6: Add an internal framewise beat and downbeat observation path with a 4/4 structured decoder

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 6 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Internal framewise observation and 4/4 decoder infrastructure for Epic 12 corrected-ranking item 7(b). A decoded audio span becomes timed beat and downbeat observations, a bar-state 4/4 decoder returns a candidate beat sequence, and a constant-tempo refinement locks the grid. All kept separate from `MLTechnique` and from the `SignalSource.beatGrid` placeholder. Epic 15 ships the plumbing and a DSP-derived stub producer; Epic 14 (gated on Epic 12 Gate 1) owns bundling a trained observation weight.

## Key Design Decisions

0. **Stub-plus-decoder is a decision-worthy baseline, not placeholder infrastructure.** The DSP-derived stub observation producer and the 4/4 structured decoder together are a *falsifier* for Epic 14's eventual training question. If the stub-plus-decoder path already beats `BeatGridAnalyzer` on OA300 and GiantSteps against the Phase 9 reference set, Epic 14 has evidence for training a trained observation head; if it does not, Epic 14 saves the retrain. This story is cheap compared to the training round it informs.
1. **New internal interface, not on MLTechnique.** Add an `internal` protocol in `Sources/BoomBoomBoomKit/` that takes a decoded audio span and returns a value type carrying timed beat and downbeat observations. The scalar `MLTechnique.evaluate(trace:) -> MLEvaluation?` surface at `Sources/BoomBoomBoomKit/MLTechnique.swift:143` is preserved; no public API changes this story.
2. **Observations are distinct from any final playable grid.** The observation value type carries per-frame beat and downbeat probabilities, the frame rate, the first-frame origin against the decoded span, the coverage window in seconds, and a model and frontend identifier pair. It does not expose a beat sequence; a separate decoder consumes it. Frame timing follows the fixed-hop convention already used by `MLFeatureFrames` rather than the whole-segment-to-512-frame rescaling at `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:537`.
3. **Published method, independently trained weights, stub producer in this story.** The decoder follows the Böck et al. ISMIR 2016 family through the madmom reference (bar-state HMM over neural beat and downbeat observations with Viterbi decoding). No dependency on rekordbox weights or the TensorFlow bundle under `rekordbox.app/Contents/Resources/models/detect_beat/`. This story ships a DSP-derived stub producer conforming to the protocol so the end-to-end path integrates without a bundled model; trained weights arrive in a follow-up that owns its own evaluation gate.
4. **DSP path is baseline and fallback, not modified.** The new path is evaluated alongside `BeatGridAnalyzer` (`Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:49`). When the observation producer returns an empty result or coverage below the configured minimum, the pipeline returns the existing `BeatGridAnalyzer` output byte-identically. The DSP path's code is unchanged in this story.
5. **No circular confidence into BPM.** The derived grid does not vote back into BPM selection. `SignalSource.beatGrid` at `Sources/BoomBoomBoomKit/SignalPool/SignalSource.swift:12` and `SignalWeights.beatGrid` at `Sources/BoomBoomBoomKit/SignalPool/SignalWeights.swift:37` remain placeholders; this story adds no producer and does not change the weight. The ensemble is not touched.
6. **Compare musical half and double tempo before locking a grid.** The decoder returns a candidate beat sequence annotated with a metrical level. A metrical-level selector evaluates the candidate at that level and at half and double, picks the level with the highest per-beat observation support over the coverage window, then emits the final constant-tempo grid. The chosen level, runner-up level, and both support scores are written to `BPMDiagnosticTrace` so the choice is auditable.
7. **Benchmark before any bundled weight.** A model is not bundled solely because the inference path runs. The observation producer stays stub-only in this story. Any later weight is introduced in a separate story that measures accuracy against the Phase 9 matched evaluation harness; `BoomBoomBoomKitML` continues to build without a bundled downbeat weight file.
8. **Coordinate with Epic 12 corrected-ranking item 7(b) (standing ownership rule).** Epic 12 charter item 7(b) names a multi-task beat and tempo head as a candidate octave arbiter (`_bmad-output/planning-artifacts/epics.md:2393`). Epic 15 Story 15.6 ships the independent observation and decoder path with a stub producer. The fusion decision (whether the derived grid votes into primary BPM selection via `SignalSource.beatGrid`, and under what weight) stays with Epic 12. The trained-weight follow-up for the stub producer stays with Epic 14 (dormant until Epic 12 Gate 1 fires); Epic 15 does not open a Story 15.6.1 for training on its own.

## Story

As a library engineer working toward rekordbox-informed grid accuracy,
I want an internal path from decoded audio to timed beat and downbeat observations plus a 4/4 structured decoder with constant-tempo refinement, with the existing DSP grid kept as baseline and fallback,
so that later phases can refine a constant-tempo grid against framewise evidence without forcing timed data through `MLTechnique` and without giving the derived grid a vote in BPM selection.

## Acceptance Criteria

1. **Given** a decoded audio span at 44.1 kHz passed to the new internal observation producer in its stub implementation
   **When** the producer runs on a 12 second input
   **Then** it returns a value type carrying a per-frame beat probability sequence and a per-frame downbeat probability sequence, declares a frame rate, declares the first-frame origin relative to the decoded span, reports a coverage window in seconds, and exposes a model identifier and a frontend identifier (both reported as `dsp-stub` for the stub).

2. **Given** a stub observation sequence consistent with 120 BPM clicks for 12 seconds at a 100 fps observation rate
   **When** the 4/4 structured decoder runs on it
   **Then** it returns a candidate beat sequence whose per-beat times reproduce the planted clicks within one frame, declares a metrical level of quarter note, and carries a per-level observation support score. The decoder output exposes the candidate beat sequence, its metrical level, and the support score only; it does not re-expose the per-frame probabilities.

3. **Given** a stub observation sequence that is ambiguous between 60 BPM and 120 BPM interpretations
   **When** the metrical-level selector runs over the decoder output
   **Then** both candidates are reported, the level with the higher per-beat observation support over the coverage window is selected, and the chosen level, runner-up level, and both support scores appear in `BPMDiagnosticTrace`. The selection is recorded before the final constant-tempo grid is emitted.

4. **Given** the stub observation producer returns an empty result or coverage below the configured minimum
   **When** `AudioAnalysisService` invokes the new path
   **Then** the service returns the same `BeatGridAnalyzer` output it would produce with the new path disabled, no field is added to any public type, and `BeatGrid` byte-identity against the pre-story baseline holds for all fixtures under `Tests/BoomBoomBoomKitTests/`.

5. **Given** `make fmt`, `make lint`, and `make test`
   **When** all three run on the branch
   **Then** they pass with no new warnings. `SignalSource` enum cases, `SignalWeights.beatGrid` default, and all `MLTechnique` and `MLEvaluation` fields are unchanged, and `BoomBoomBoomKitML` builds without a bundled downbeat weight file.

6. **Given** `make benchmark` on OA300 and `make benchmark-giantsteps` with the new path active against the stub producer
   **When** both runs complete
   **Then** OA300 Acc1 is at least 69.5 percent (57/82) and Acc2 is at least 89.0 percent (73/82), and GiantSteps Acc1 is at least 81.2 percent (537/661) and Acc2 is at least 82.6 percent (546/661). The new path is evaluated alongside DSP but does not vote into BPM, so these baselines must hold exactly.

7. **Given** a reader inspecting the module's public API
   **When** they diff the public surface against the pre-story baseline
   **Then** the new protocol, the observation value type, the decoder entry point, and the metrical-level selector are all `internal`; the only visible public change is additional diagnostic fields on `BPMDiagnosticTrace`, and `BeatGridAnalyzer` output remains unchanged in shape and in the DSP-only path.

8. **Given** the Epic 15 ground rule that nothing new ships to `main` unless already allowlisted
   **When** the final diff is prepared for review
   **Then** no file touched by this story appears in `scripts/promote-to-main.py`'s `SHIPS_TO_MAIN` or in the CLAUDE.md allowlist, except where it is already there (`Sources/`, `Tests/`); no file is added to `EXCLUDED_FROM_MAIN`; and `docs/rekordbox-analysis/` is not referenced from any shipped file.

## Affected files

- `Sources/BoomBoomBoomKit/MLTechnique.swift:143`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:49`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:330`
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1083`
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:262`
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`
- `Sources/BoomBoomBoomKit/BeatGrid.swift`
- `Sources/BoomBoomBoomKit/BeatGridCoverage.swift`
- `Sources/BoomBoomBoomKit/SignalPool/SignalSource.swift:12`
- `Sources/BoomBoomBoomKit/SignalPool/SignalWeights.swift:37`
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:537`
- `Tests/BoomBoomBoomKitTests/`

## Overlap with Epic 12

Overlaps Epic 12 corrected-ranking item 7(b) at `_bmad-output/planning-artifacts/epics.md:2393`, which names a multi-task beat and tempo head as a candidate octave arbiter. This story builds the compact independent observation and decoder path with a stub producer and no trained head, keeps the derived grid out of BPM voting, and leaves `SignalSource.beatGrid` and `SignalWeights.beatGrid` as placeholders. Any decision to fuse the derived tempo into primary BPM selection, either by producing a `SignalSource.beatGrid` vote or by shipping a multi-task tempo head, stays with Epic 12. The project-level coordination rule from `docs/rekordbox-analysis/AGENT_GUIDANCE.md` applies: Epic 15 does the measurement, representation, and decoder work; Epic 12 owns the model-quality lever ranking and any retrain or fusion gate.

## Open questions for the PRD

- Which observation frame rate the protocol standardizes on. The published method and the rekordbox native decoder both use 100 fps, while the current `MLFeatureFrames` substrate is fixed-hop at a hop configured per model. The protocol must declare a frame rate rather than assume one, and the stub needs a canonical choice.
- How the coverage window is defined relative to leading and trailing silence. The decoder expects observations spanning the usable segment; the stub's coverage must line up with how `BeatGridCoverage` already reports usable span, or the mismatch surfaces as a fallback trigger on real tracks.
- How the metrical-level selector reports its decision when the two candidates are within observation noise, including whether a minimum support margin or an abstain signal is required before a non-default level is emitted.
- Where trained observation weights will come from in the follow-up story. The Böck ISMIR 2016 reference and the madmom public implementation describe the training recipe; the project has no retrained weights in this story and the follow-up's own evaluation gate must be defined before any weight is bundled.
- Whether `BeatGrid.coverage` or an adjacent type needs a new field for the chosen metrical level and runner-up, or whether the full report lives only on `BPMDiagnosticTrace`. The AC 7 constraint is that `BeatGridAnalyzer`'s output shape does not change in this story; the trace is the current carrier.

## Explicit scope exclusions

- Do not force timed observations through `MLTechnique` or `MLEvaluation`; the scalar API at `MLTechnique.swift:143` is preserved exactly.
- Do not add a producer for `SignalSource.beatGrid` or change `SignalWeights.beatGrid`; the derived grid does not vote in BPM selection in this story.
- Do not bundle a trained observation weight file; the observation producer stays stub-only until a follow-up story measures accuracy on the Phase 9 matched evaluation harness.
- Do not alter runtime preprocessing of any existing bundled weights and claim better accuracy. Any new weight must be trained or loaded for the new contract.
- Do not change public API. The new protocol, observation value type, decoder entry point, and metrical-level selector are `internal`; the only visible public change is additional fields on `BPMDiagnosticTrace`.
- Do not modify `BeatGridAnalyzer`'s DSP code or its default output. The new path is additive and falls back to today's `BeatGridAnalyzer` output when evidence is weak.
- Do not touch Story 12-7 corpus membership or the signed corpus protocol as a side effect of anything in this story.
- Do not add any file in this story to `scripts/promote-to-main.py`'s `SHIPS_TO_MAIN`, to `EXCLUDED_FROM_MAIN`, or to the CLAUDE.md allowlist; nothing in this story ships to `main`.
- Do not reference the rekordbox TensorFlow bundle, model7, or model8 from any shipped source file or test; the architecture reference is the public Böck ISMIR 2016 paper and the madmom implementation.
- Do not add emojis or em-dashes to source, tests, documentation, or trace strings.

