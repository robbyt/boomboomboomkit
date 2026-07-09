---
title: ML Retraining, Multi-Signal Ensemble, and Selection-Strategy Documentation
status: final
created: 2026-05-25
updated: 2026-05-25
---

# PRD: ML Retraining, Multi-Signal Ensemble, and Selection-Strategy Documentation

_Status: final. 51 outcome FRs across 5 epics, 10 NFRs, ~25 named KDDs deferred to architecture / training plan, 8 Non-Goals, 9 Cross-Cutting Risks. Reviewer Gate complete (1 high finding autofixed + 4 mediums/lows). Polish complete (structural reorganization + prose tightening). Ready for architecture-doc authoring._

## Vision

Developers building Apple-platform DJ and production apps can use BoomBoomBoomKit to extract BPM, loudness (LUFS), and beat-grid timestamps from any supported audio file. Under the hood, DSP, ML, and file metadata are peer signals in a unified weighted voting system. ML augmentation is opt-in; the library has zero external dependencies.

## Non-Goals

Explicit non-goals — things this PRD does NOT do, consolidated for reviewer visibility. Each entry cross-references the FR or KDD where it surfaces in-context.

- **Waveform rendering in the demo** (per FR-39). Beat-grid surfaces as timeline ticks + text readout. Building a waveform engine is its own product surface and is out of scope.
- **Consumer-facing library export tooling for trained models** (per FR-19). The library accepts model URLs via `BNNSTechnique(modelURL:)`; the export step from a trained checkpoint to a CoreML model lives outside this PRD's scope.
- **`BNNSTechnique` documentation via the per-case typed-property protocol** (per FR-51 dropped). `BNNSTechnique` is a struct, not a `CaseIterable` enum — type-level documentation goes through DocC, not the `DocumentedCase` protocol.
- **DocC integration as runtime documentation source** (per Epic E KDD #10). DocC catalogs and the runtime Markdown resource bundle are parallel documentation surfaces; single-sourcing them is not pursued in this PRD.
- **Embedding GPL-licensed third-party code** (per Epic C aubio reference). The library may study aubio's `src/tempo/beattracking.c` for algorithm understanding and re-implement in Swift, but may NOT link against aubio or include any GPL-derived code.
- **iOS / iPadOS / visionOS platform expansion** (per NFR-3). Library targets macOS 15+ minimum. Architecture must not preclude future expansion, but expansion itself is not a deliverable here.
- **Recovering the 378 tracks missing from Tony's Rekordbox-XML to disk path resolution** (per Discovery decision). Path-remap recovery is not pursued; the 1,344-track labeled corpus is the working baseline.
- **Backwards compatibility across the Epic A architecture refactor** (per NFR-4). Pre-1.0 framing authorizes breaking the post-merge corroboration boundary and the frozen `merge` signature.

## Features

This PRD ships in five epics. Each epic has its own functional requirements (FRs); FR IDs are globally numbered (FR-1 through FR-N across all epics) and stable once published.

### Epic A — Unified-signal-pool architecture refactor

The library's current architecture treats DSP, ML, and file metadata as sequential stages: DSP runs first, `CandidateMergeStrategy.merge` picks a winner, `MetadataCorroborator.apply` boosts it post-merge, and `EnsembleCombiner` runs the DSP-vs-ML arbiter at the end. Epic A replaces this with a unified weighted voting system where every signal is a peer.

FRs below are outcome statements — what becomes true for developers. Type-taxonomy decisions (umbrella enum vs split policy types, struct vs dict for weights, enum vs Double for thresholds) are deferred to the architecture document Winston authors during implementation. See "KDDs deferred to architecture doc" at the bottom of this epic.

**FR-1 — Unified signal pool.** DSP candidates, ML predictions, and file-metadata tags contribute to a single unified pool for BPM determination. No signal type is privileged over another at the voting stage.

**FR-2 — Configurable per-source weighting.** Consumers can configure how heavily each signal type contributes to the final result. Signal influence scales with the signal's self-reported confidence and a per-source reliability factor. Consumer-visible contract: between two signals from the same source family, the higher-confidence signal contributes more weight to the cluster vote; between signals from different families, the configured per-source reliability factor mediates the relative influence (a higher-reliability source's lower-confidence signal can outweigh a lower-reliability source's higher-confidence signal).

**FR-3 — Octave-equivalence handling is configurable.** Consumers can choose how the pool handles same-tempo-different-octave signals (e.g., a 174 BPM ML prediction and an 87 BPM ID3 tag): collapse to one cluster, treat as octave-aware with a penalty, or require exact match.

**FR-4 — ML execution policy.** Consumers can configure when ML inference is invoked: always run, run only when DSP confidence falls below a threshold, or never run. ML's status as a peer signal at the voting stage is preserved regardless of execution policy.

**FR-5 — Common ensemble cases stay ergonomic.** Common ensemble configurations (DSP-only, ML-only, highest-confidence selection across signals, weighted voting) are expressible without consumers manually configuring per-source weights or selection policies.

**FR-6 — Per-window contribution caps.** Multi-window DSP signal counts do not swamp single-instance ML or metadata signals. The system normalizes contribution per source family, not per individual signal row.

**FR-7 — Metadata as peer voter; voter is smart.** File-metadata tags (ID3 TBPM, MP4 tmpo, FLAC Vorbis) participate in the unified pool as voting signals, replacing today's post-merge multiplicative boost behavior. The voter normalizes likely half/double relationships (87 ↔ 174 for DnB tracks), tracks tag-source provenance where derivable (e.g., user-tagged vs auto-imported vs Beatport), penalizes implausible-for-genre tags, and lets strong audio evidence override stale or implausible tags.

**FR-8 — Empty pool returns nil.** When the unified pool has no signals (e.g., DSP failed AND ML disabled AND no metadata tags present), the library returns nil with a documented diagnostic trace reason. No synthesized "default BPM" is produced.

**FR-9 — Diagnostic trace surfaces the pool.** When `Options.enableTrace = true`, the diagnostic trace surfaces every input signal that contributed to the pool, the cluster each signal landed in, and the winner. The legacy `ensembleDecision` trace field is removed.

**FR-10 — Accuracy floors hold across the refactor.** OA300 single-window Acc1 ≥ 55/82 (current floor) and GiantSteps Acc1 ≥ 537/661 (current floor) both hold after the refactor lands at default options. Measured via `make benchmark` and `make benchmark-giantsteps`.

**FR-11 — Performance budget.** The unified-pool runtime path does not regress OA300 wall-clock by more than 15% at default intensity. Measured via `make perf-benchmark`.

**FR-11a — Intensity is a compute-budget dial coupled to the active ensemble configuration.** `AnalysisIntensity` levels gate which compute-expensive signal sources contribute to the unified pool, AND the mapping depends on what's wired up. Examples: at `EnsemblePolicy.dspOnly` (or equivalent post-Epic-A configuration), low intensities skip optional DSP rescore stages; with ML enabled, low intensities skip ML inference (the most expensive signal source); with beat-grid extraction enabled, low intensities skip beat-grid refinement. The specific mapping table — which signals are enabled at which intensity levels under which ensemble configurations — is architecture detail; the consumer-visible outcome is that lower intensity gives cheaper analysis, and the cheapness scales coherently with whichever signals are active. **Interaction with FR-4:** intensity is one dimension along which ML execution may be gated; the explicit ML execution policy from FR-4 (always / threshold / never) is the consumer-facing override. When both are in play, the explicit policy wins. Cross-epic concern: see Epic E KDD #4 (AnalysisIntensity reshape), Epic A FR-4 (ML execution policy), Epic C FR-27 (beat-grid extraction).

**KDDs deferred to architecture doc:**

1. Single umbrella type for the voting policy (rename `CandidateMergeStrategy` to `BPMSelectionPolicy`) vs split into multiple policy types (`SignalWeights` + `BPMEquivalencePolicy` + `BPMSelectionPolicy`) vs Animation-style typed-struct-with-static-factories. Party verdicts split 4 ways; architect chooses.
2. `SignalWeights` shape: strongly-typed struct (`SignalWeights { dsp: Double; ml: Double; fileMetadata: Double; beatGrid: Double }`) vs `[SignalSourceKind: Double]` dictionary. Siri cites Animation/URLSessionConfiguration precedent for the struct; party leans struct but final call is architect's.
3. Source-weight formula: 1-layer (`confidence × weight`), 2-layer (`confidence × reliability`), or 3-layer (`confidence × reliability × contextAdjustment`). Room mostly converges on 1-layer or 2-layer; architect picks.
4. ML execution policy surface: `Double` threshold field vs `MLExecutionPolicy` enum (3 cases). Siri argues `Double` for threshold/budget semantics; Amelia and Winston argue enum for type safety. Architect picks.
5. `EnsemblePolicy` fate: remove entirely vs preserve as facade with `.weightedVoting(SignalWeights)` case vs keep as leaf-only convenience enum. Party split; architect picks per the consumer-ergonomics test in Epic D.

6. **`MetadataCorroborator.apply` post-merge boundary collapse.** Preserve today's separation (corroboration runs AFTER `merge`, never inside it) OR fully collapse into the unified pool (metadata tags are direct voters per FR-7). Cost of collapse: breaks the "Post-Pipeline Corroboration Boundary" project-context rule and the frozen 41-call-site `merge` signature. The unified-signal-pool architecture in this Epic implies the collapse path; the architect re-decides if a hybrid (e.g., keep `MetadataCorroborator` as a thin shim that emits unified-pool voters) is preferable on implementation grounds. Also tracked in Open Questions as KDD-A6 for visibility.

### Epic B — ML retraining (Tony corpus)

The previously-bundled `giantsteps_v1.mlmodelc` was pulled in Story 4-6 Branch C — softmax_max_p95=0.294, bimodal at 125/175 BPM regardless of input. Epic B replaces it with a retrained model on Tony's hand-labeled DJ-heavy corpus (1,344 labeled tracks today + ~4,700 unlabeled audio files for semi-supervised expansion). The retraining must not encode "Tony's library heuristics" (playlist names, Rekordbox conventions) as hidden labelers.

**FR-12 — Corpus diagnostics produce reviewable evidence.** Diagnostics expose label-source bias, octave ambiguity (including Tony's historical half-tempo-labeling pattern — Rekordbox shows e.g. 87 BPM while DSP and grid show 174 BPM), confidence calibration, cluster stability, and representative manual-review findings. The artifact supports a freeze-or-relabel decision before training begins. The existing labeler already handles half-tempo expansion via octave variants + a half-time-boost factor; diagnostics validate that handling applies correctly on representative half-tempo tracks. (The specific diagnostic suite — ablation histogram, winner-source audit, octave-conflict table, cluster-width jitter, playlist-prior calibration, manual review of 30 DSP-vs-AverageBpm conflicts — lives in the architecture / training plan.)

**FR-13 — Non-Rekordbox audio expansion with clean provenance.** Tony's ~4,700 audio files outside the Rekordbox `<COLLECTION>` are surveyed and tiered as a semi-supervised pool. Files with audio-derived DSP + generic file-metadata (ID3 TBPM, MP4 tmpo, FLAC Vorbis) agreement within 2-3% after octave normalization become a secondary supervised tier. Path-, playlist-, and Rekordbox-derived signals are forbidden as expansion-tier evidence. A source-distribution report (genre / tempo / source / tier counts before and after expansion) is produced for review.

**FR-14 — Label tier policy.** Initial supervised training uses only Strong (≥0.80, currently 333 tracks) and Solid (0.65-0.80, currently 745 tracks) tiers. Marginal labels (0.55-0.65, 241 tracks) are excluded from initial supervised training and may only be reintroduced in later semi-supervised runs when model confidence and evaluation ablations meet a documented promotion policy. (The specific reintroduction mechanism — FixMatch, self-training, consistency regularization — is an architecture choice.)

**FR-15 — No library-curator artifacts; audio-only model with transparent fusion.** Training input features exclude library-curator artifacts (playlist names, file path components, Rekordbox-specific signals, DSP candidate scores) AND exclude auxiliary metadata layers (no artist embedding, no ID3 BPM as model input, no other side-channel features). Metadata-driven adjustments happen via the unified voting pool (Epic A FR-7), not via the model. Reasoning: SOTA tempo estimators (madmom, Essentia, TempoCNN, aubio) are universally audio-only; on a 1,344-track / ~250-artist corpus, artist embedding memorizes rather than generalizes; ID3 BPM as model input would double-count an existing peer voter. Verified by inspection of the dataset module and documented in the training plan.

**FR-16 — Octave-aware training loss.** Training loss respects octave equivalence — octave-paired BPMs (87 vs 174) are not treated as unrelated classes. The model learns the octave relationship rather than collapsing to fixed priors (the failure mode that killed `giantsteps_v1.mlmodelc`).

**FR-17 — DnB challenge set held out as sentinel.** The 4 named DnB triplet targets in `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) are reserved as a held-out evaluation set — never used in training. These are must-pass sentinels, not proof of generalization (the corpus is small; broader corpora carry the generalization claim).

**FR-18 — Trained-model evaluation gates.** Before any decision to bundle the model in the SPM library on the public `main` branch (i.e., ship the compiled `.mlmodelc` inside the library's resources so consumers get it by default), the trained model must clear: (a) all 4 named DnB triplet targets correct, (b) OA300 Acc1 strictly exceeds the DSP single-window ceiling of 55/82, (c) GiantSteps Acc1 ≥ 537/661 floor, (d) confidence-calibration floor (see FR-25). If any gate fails, the model ships as a BYOW reference only — published in `_bmad-output/ml-models/` for developers to wire up via `BNNSTechnique(modelURL:)`.

**FR-19 — Model exportable to BYOW runtime path.** The trained checkpoint exports to a CoreML model consumable by `BNNSTechnique(modelURL:) throws`. The export tooling lives outside this PRD's scope.

**FR-20 — Training reproducibility.** Training runs are reproducible: fixed seeds, deterministic data shuffling, recorded model metadata (architecture, seed, epoch count, corpus version hash, train/val/test split). Logged to `_bmad-output/ml-training/training_log.json` and `model_metadata.json`.

**FR-21 — Feature-pipeline parity train-vs-runtime.** Training-time feature extraction (Python) and Swift runtime feature extraction (the `MLFeatureFrames` path) produce equivalent feature tensors within documented numeric tolerance, with exact match on frame shape, ordering, normalization, and `featureSetVersion`. The model artifact records the `featureSetVersion` it was trained against; runtime inference rejects or warns on mismatch. Parity fixtures (a small fixed set of audio clips with expected feature hashes/statistics + tolerances) live alongside the training artifact.

**FR-22 — Split contamination guards.** Train / validation / test splits are generated and audited from `_bmad-output/ml-training/corpus_splits.json` so related recordings (alternate encodes, edits, DnB triplet family members, near-duplicates) cannot cross split boundaries. The audit artifact lists duplicate / near-duplicate groups and confirms held-out challenge material (FR-17) is absent from training and validation sets. Evaluation also reports on a **leave-artist-out slice** (artists held out of training appear only in test) to detect artist-memorization leakage even though artist is not an explicit feature per FR-15.

**FR-23 — Octave policy consistency across training and runtime.** Training loss, validation scoring, and runtime weighted voting use the same documented octave-equivalence policy. Acceptance metrics report both raw Acc1 and octave-normalized accuracy. A policy mismatch between training and runtime is treated as a defect that blocks model acceptance.

**FR-24 — Semi-supervised expansion must prove net benefit.** Secondary supervised and pseudo-labeled data (FR-13) may only be promoted into the active training set if an ablation against supervised-only training improves or preserves all acceptance gates — OA300 Acc1, GiantSteps Acc1, DnB challenge set, labeled validation accuracy — within documented tolerance. Regression beyond tolerance blocks promotion.

**FR-25 — Confidence calibration verified.** Trained-model confidence scores are calibrated to predictive correctness — higher confidence corresponds to higher accuracy. Acceptance includes a measurable calibration metric (e.g., expected calibration error, softmax distribution shape) and a documented floor that the previously-bundled `giantsteps_v1.mlmodelc` failed to meet (the forensic anchor: `softmax_max_p95 = 0.294`, bimodal at 125/175 regardless of input). The specific calibration metric and numeric floor are committed in the training/eval plan before Epic B is considered complete. Calibration failure blocks bundling regardless of Acc1.

**KDDs deferred to architecture / training plan:**
1. Training architecture: TempoCNN-style retain or alternative (TCN, conformer-lite). Performance budget on M-series CPU at inference is the constraint.
2. Semi-supervised method: BYOL-A / masked-mel pretraining vs supervised-only-with-augmentation. Codex flagged "4,700 is modest" — pretrain pass may not pay off.
3. Marginal-tier reintroduction mechanism: FixMatch, self-training, consistency regularization, or none.
4. Diagnostic suite composition: the 6 named diagnostics (or successor set) live in the training plan, not the PRD.

### Epic C — Public API expansion (LUFS + beat-grid + model registry)

Three new public surfaces. LUFS is mostly API design (the analyzer exists internally). Beat-grid is novel algorithm work. Model registry is a lightweight type Epic D consumes for the demo selector.

**FR-26 — LUFS public API.** The library exposes integrated loudness (LUFS) as a public capability via a service-level entry point `analyzeLUFS(url:options:)`. Result carries integrated loudness, true-peak, and loudness range (LRA). The existing internal `LUFSAnalyzer` (ITU-R BS.1770-5 K-weighted, 44.1/48/96kHz pre-computed coefficients) is promoted to public-facing through the service boundary. `analyzeLUFS` is a sibling to `analyzeBPM`, not a replacement.

**FR-27 — Beat-grid extraction.** The library extracts per-beat timestamps for any supported audio file via a service-level entry point `analyzeBeatGrid(url:options:)`. Output carries beat timestamps, downbeat information, the estimated tempo at grid-derivation time, and a grid-level confidence.

**FR-28 — Downbeat state distinguishes "not attempted" from "attempted, none found."** The beat-grid result lets consumers tell whether downbeat detection ran but found no high-confidence downbeats vs whether downbeat detection wasn't attempted at all. Wrong downbeats are worse than absent downbeats for DJ cues; a tri-state result avoids the silent-bug class.

**FR-29 — Long-file sync stability.** Beat timestamps remain audibly accurate at the end of long files (5+ minute tracks). The specific drift tolerance (numeric, in ms-per-minute or beats-over-duration) is committed in the acceptance corpus spec before Epic C is considered complete.

**FR-30 — Playback-aligned timestamps.** Beat timestamps line up with the audio playback position a consumer's app actually hears, regardless of input codec (AAC, MP3, FLAC, WAV, AIFF, CAF). Codec priming-delay and sample-rate conversion do not introduce visible offset. Timestamps round-trip correctly through Apple's media frameworks for asset-anchored alignment.

**FR-31 — BPM and beat-grid consistency contract.** If a consumer calls `analyzeBPM` and `analyzeBeatGrid` on the same file with the same options, either (a) the returned BPM and the implied tempo of the beat-grid agree, or (b) the disagreement is surfaced in the beat-grid result so consumers can arbitrate. Naive callers see consistent answers; sophisticated callers see the disagreement.

**FR-32 — Model registry public type.** The library exposes a registry listing available ML models — bundled (if any), user-added, and known-public references. Each entry carries enough information for consumers to (a) identify the model, (b) verify integrity, (c) check capability compatibility with the library's analysis methods, (d) attribute / license-comply. The registry is in-memory only at the library level; persistence across app launches is the consumer app's responsibility.

**FR-33 — User-picked models integrity-checked.** The library validates the integrity of user-picked models before loading. Mismatch surfaces a clear error rather than silent corruption at inference time. Integrity validation happens once per model registration; results are cached for subsequent loads.

**FR-34 — Beat-grid acceptance corpus.** Beat-grid accuracy is validated against the OA300 corpus (where DAW oracle ground truth is available) and a stratified DnB subset. Specific accuracy thresholds (F-measure floor, beat-position tolerance) live in the training/eval plan and are committed there before Epic C is considered complete.

**FR-35 — Shared decode for combined analysis.** Consumers can extract BPM, LUFS, and beat-grid from a single file decode pass without re-reading the file three times. The seam is exposed before the unified `analyze(...) -> AudioAnalysisReport` API lands, so consumers wiring all three today don't pay 3× decode latency.

**KDDs deferred to architecture doc:**

1. **Beat-tracking baseline algorithm.** Three credible candidates: Ellis 2007 dynamic programming over onset envelope (simple, non-causal, pure Swift+vDSP); Davies & Plumbley 2004-2005 causal tempo tracking with Rayleigh / exponential / Gaussian weighting (more sophisticated, real-time-capable, aubio's choice — see License note below); RNN/DBN beat tracking (Böck et al. / Krebs et al., requires bundled model). Architect picks the MVP. aubio's `src/tempo/beattracking.c` is a reference implementation of Davies & Plumbley that we may study but not embed.

2. **Beat-grid result type shape.** Tri-state downbeat enum (`.notAttempted` / `.none` / `.detected([…])`), separate `downbeats: [BeatTimestamp]?` optional, or unified `BeatEvent` list. Party-mode prefers tri-state; architect re-decides.

3. **Disagreement-surfacing pattern (FR-31).** Does the beat-grid result carry a `tempoAgreedWithBPMStage: Bool`, or just return its own tempo and let consumers compare?

4. **Internal shared-decode seam (FR-35).** What internal API allows the unified `analyze(...)` to land later without breaking the sibling-method approach today? Likely a `DecodedAudio` value type that BPM/LUFS/beat-grid analyzers consume.

5. **Integrity-check algorithm.** SHA-256 (CryptoKit, hardware-accelerated on Apple Silicon — measured 1.5 GB/s, ~150 ms for 200 MB) vs BLAKE3 vs CMS signature. Algorithm choice is architect's; PRD pins the outcome.

6. **Beat-grid engine abstraction.** Protocol matching the `MLTechnique` pattern, or simpler enum of implementations. Engine swap (Ellis → DBN → RNN) is a future-epic concern.

**License / provenance note (Epic C KDD #1 dependency):** aubio (`github.com/aubio/aubio`) is **GPL-3.0** — we may study the source to understand Davies & Plumbley's algorithm and re-implement in Swift, and cite the academic papers (Davies & Plumbley ISMIR 2004, AES 118 2005); we may NOT embed aubio code or link against it. Specific aubio reference files (`tempo.h`, `beattracking.h/.c`, `onset.h`, `peakpicker.h/.c`) and the `///`-comment citation pattern are documented in `.decision-log.md`.

### Epic D — Demo app ML + ensemble UX

The demo's job is to prove the library's three outputs (BPM, LUFS, beat-grid) and the ensemble surface work in a real Apple-platform app — without exposing Epic A's still-fluid architecture KDDs to users. Codex's UX guidance (thread 019e6143) anchors the FRs below.

**FR-36 — Demo exposes named ensemble presets in primary view; raw weights surface in advanced sidebar.** The primary view offers named ensemble presets (`Default`, `DSP only`, `ML augmented`, `Trust file tags`) rather than raw signal weights or policy enums. The existing advanced sidebar (the `.inspector(isPresented:)` developer surface from Story 5-6b) exposes raw per-source weights when Epic A's architecture surfaces them, so power users and benchmark scripts retain the diagnostic affordance. Presets remain stable across Epic A KDD outcomes; the sidebar adapts to whatever Epic A ships.

**FR-37 — Model selection from registry + file picker.** Demo lets users select an ML model from the registry (bundled, if any, + known-public references + previously-added user models) OR add a new model via file picker. Selection drives subsequent analysis runs.

**FR-38 — Demo owns persistence for user-added models only.** When a user adds a model via file picker, the demo stores a security-scoped bookmark so the URL resolves correctly across app launches. The library accepts already-resolved URLs; the demo handles the bookmark lifecycle, entitlement scope, and persistence (UserDefaults or equivalent). Bundled models and known-public registry entries are stateless and need no persistence — they resolve from `Bundle.module` or code-defined references at every app launch. Required entitlements: `com.apple.security.files.user-selected.read-write` (the shipped app-level superset — read-only is *sufficient* for the model bookmark and is enforced at creation via `.securityScopeAllowOnlyReadAccess`, but the audio-file open path already requires read-write; Story 10.1 DD1) + `com.apple.security.files.bookmarks.app-scope` (the second is the one developers commonly forget).

**FR-39 — Beat-grid as timeline + text readout (no waveform).** Demo presents beats and downbeats on a horizontal timeline with current-time scrubber, plus a text readout (estimated tempo, beat count, downbeat status, grid confidence). Waveform rendering is explicitly out of scope for v1 — the demo's job is to prove the API surface, not to build a mini DJ waveform engine.

**FR-40 — LUFS as primary measurement, secondary breakdown.** Demo shows integrated LUFS as a single number (with `LUFS` unit label), plus a small panel for true-peak and LRA. LUFS surfaces without dominating the BPM-centric flow.

**FR-41 — Final-state signal-pool diagnostic table in the advanced sidebar.** When `enableTrace: true`, the existing advanced sidebar shows a table with one row per contributing signal: source, BPM, confidence, weight, contribution, cluster. Rows grouped by winning cluster vs rejected candidates; the winner is visually emphasized. The table is **final-state, post-analysis** — live per-window updates would require a library-API addition (incremental `BPMDiagnosticTrace` emission) that's a future-epic concern, not Epic D scope. Replaces the current `EnsembleDecision` summary view inside the sidebar.

**FR-42 — Strategy popover wired to Epic E docs with graceful degradation.** Demo's preset / policy / strategy controls each have a "?" help button that opens a popover rendering the docs sourced from Epic E's Markdown SPM resource bundle. The library exposes a public accessor (e.g., `BoomBoomBoomKitDocs.attributedString(for:)`) that hides `Bundle.module` resolution from the demo's Xcode app target — the demo cannot see `Bundle.module` directly since that's synthesized only for SPM resource-bearing targets. If Epic E hasn't shipped or the markdown bundle is unavailable, the popover degrades gracefully (e.g., shows a one-line description + link to the repo docs), not a broken `Bundle.module` lookup. No duplicated prose between library and demo.

**FR-43 — Primary flow stays primary; developer surface lives in the advanced sidebar.** The "drop file → get answer" path remains the dominant interaction in the main window. All developer/diagnostic affordances — raw signal weights, diagnostic table, hidden parameters, future dev tools — live in the existing advanced sidebar (the `.inspector(isPresented:)` toggle from Story 5-6b, keyboard `⌘⇧D`). Closing the sidebar restores a clean end-user experience without losing any primary functionality. The library's developer audience and the demo's end-user audience are both served by this two-tier discipline.

**FR-44 — Confidence semantics explicitly labeled.** Wherever the demo shows a confidence-like number (BPM confidence, beat-grid confidence, signal weight, source reliability, ML softmax max), the label tells the user what kind of confidence it represents. No bare numeric value without context. Prevents BPM confidence and LUFS readout from being read as comparable diagnostic claims. Specific label strings live in the Epic E doc-authoring style guide (KDD-E8) — outcome here is that the demo never emits a bare numeric, not that the canonical label text is pinned in this PRD.

**KDDs deferred to architecture / UX doc:**

1. Specific preset list — Codex proposed `Default / DSP only / ML augmented / Trust file tags`. UX may refine names or add presets (e.g., a "Strict tags" variant).
2. Timeline rendering primitives — custom SwiftUI path overlay, `Canvas`, or `Chart`. None of these are waveform; choice affects animation smoothness on long files.
3. Bookmark persistence shape — `UserDefaults` keyed table vs SwiftData vs a flat plist. Demo's existing `MergeStrategyPersistence` (Story 5-6) is the precedent pattern.
4. Popover presentation style — SwiftUI `.popover()`, `.sheet()`, or inline disclosure. Matches platform-idiom expectations for help surface.
5. Diagnostic table interaction model — read-only, sortable, expandable per-row? Affects developer ergonomics during ablation runs.

### Epic E — Selection-strategy docs (per-case typed API + Markdown resources)

The library exposes authored documentation for every public mode enum (`CandidateMergeStrategy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`, and `AnalysisIntensity` post-reshape). API shape and Apple-precedent comparison live in KDD #2 below. Codex consult thread 019e60e1.

**FR-45 — Per-case help via typed property access.** Every public mode case the library exposes carries authored documentation accessible on the case value (e.g., `mergeStrategy.docs`) — Xcode autocomplete surfaces it without string lookups. The mechanism (protocol conformance, static map, etc.) is architecture; the outcome is "consumer types the case, Xcode shows the help."

**FR-46 — Help renders offline without network access.** Documentation ships inside the SPM resource bundle. Consumers render help in any context (offline, sandboxed, low-bandwidth) without network calls. No GitHub-raw URL fetches, no privacy-manifest reason codes.

**FR-47 — Help explains what and why.** Each documented case carries concise prose covering what the option does AND why a developer would choose it. (Markdown syntax constraints — what renders via `AttributedString(markdown:)` and what doesn't — live in the doc-authoring style guide, not in this PRD.)

**FR-49 — Informative fallback when docs missing.** If a documentation resource is missing or unreadable at runtime, the accessor returns a clear informative fallback `AttributedString` — never an empty result, never a crash. Non-throwing, non-optional. (Fallback content shape — repository URL, "docs pending" message, version metadata — is architecture, not PRD.)

**FR-50 — New documented cases cannot ship without docs.** Adding, removing, or renaming a documented case fails automated verification until matching documentation coverage is updated. (Specific mechanisms — exhaustive `switch`, lint rule, XCTest, or combination — live in the test plan.)

**FR-52 — Documentation bundles with the library binary.** Documentation content ships inside the library's binary distribution (SPM resource bundle). Runtime fetching of documentation content (from network sources, dynamic loading, CDN, etc.) is prohibited. Doc updates ship with library version updates — consumers receive new docs by updating the library.

**(FR-48 moved to NFRs)** "No prose duplication between library and consumers" is a maintenance / source-of-truth concern, not a developer-outcome FR. Lives in NFRs / authoring rules instead.

**(FR-51 dropped)** "Optional-target docs live in optional targets" was scoped to `BNNSTechnique` documentation in `BoomBoomBoomKitML`. Party-mode caught that `BNNSTechnique` is a struct, not a `CaseIterable` enum, so the per-case protocol mechanism doesn't fit. ML target's struct types use DocC for type-level documentation; the protocol-based per-case docs apply only to `CaseIterable` enums in either target. Documented as architectural hygiene, not as an FR.

**KDDs deferred to architecture / type-design doc:**

1. **Protocol family cap pre-1.0.** Cap the per-case documentation pattern at ONE protocol (`DocumentedCase` or similar). Adding sibling protocols (`DefaultProvidable`, `PerformanceAnnotated`, `DeprecatedIn`, etc.) requires explicit story-spec authorization. Mirrors the closed-set `DSPTechnique` discipline. Prevents capability-surface sprawl on every public enum.
2. **Protocol name + shape.** Per-instance `var docs: AttributedString` (Codex / operator preference, simpler call site) vs static `[Self: AttributedString]` map (Apple's `CaseDisplayRepresentable` precedent, better exhaustiveness audit). Cite Apple as inspiration, not as direct precedent — the shape differs. Architect picks.
3. **`documentationID` derivation.** Exhaustive `switch` (compile-safe, ~3 LOC/case boilerplate, catches new cases at build time) vs `String(reflecting: self)` (zero boilerplate, brittle to type renames) vs raw-value (for `String, CaseIterable` enums). Trade-off between belt-and-suspenders drift detection and per-conformer LOC.
4. **`AnalysisIntensity` reshape from struct to enum.** Currently `AnalysisIntensity` is a public struct carrying integer level 1-10 with named constants (`.fastest`, `.default`, `.thorough`, `.maximum`). Reshape to a `String, CaseIterable, Hashable, Sendable` enum so it conforms to `DocumentedCase`. Specific case list (4 named only, or 10 levels, or hybrid with `case custom(Int)`) is architect's call. Pre-1.0 break authorized per project framing. **Semantic expansion (per Epic A FR-11a):** post-reshape, `AnalysisIntensity` is a compute-budget dial across the unified ensemble, not only a DSP-technique-set selector — its mapping to active signal sources depends on ensemble configuration. The enum's case list should reflect that broader semantic.
5. **Cache `AttributedString` parse results.** Per-instance `.docs` access can be I/O-bound (`AttributedString(contentsOf:)` reads from disk). Default impl caches parse results in a `static let` lookup table keyed by `documentationID` (or equivalent), protected by `OSAllocatedUnfairLock` for thread safety. Architect picks exact cache primitive.
6. **SPM resource rule:** use `.copy("Resources/Documentation")` not `.process(...)` for Markdown — `.copy` is byte-for-byte verbatim and avoids SPM ever deciding to "process" `.md` files in a future Swift toolchain. (Siri's call; documented here so it doesn't get re-litigated.)
7. **Front-matter YAML schema.** Keys: `kind` (the type name, e.g., `CandidateMergeStrategy`), `id` (the case name, e.g., `windowVoting`), optional `title`, `version`. Concrete schema lives in the doc-authoring guide.
8. **Markdown content style guide.** Paragraph length, examples policy, voice, AttributedString-renderable subset (no tables, no fenced code blocks, no images, no heading hierarchy). Lives in `Sources/BoomBoomBoomKit/Resources/Documentation/STYLE.md` if it exists.
9. **Demo's `HelpButton<T: DocumentedCase>` generic.** Cross-epic dependency — Epic D's demo implementation builds a single generic help-button view used across all preset/policy/strategy pickers. Belongs to Epic D implementation.
10. **DocC integration.** DocC catalog at `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/` is a separate documentation surface from the runtime Markdown resources. Format divergence (DocC's `@Metadata` vs YAML front-matter) means single-source is impractical. Treat as parallel surfaces; defer DocC integration to a follow-up epic.

## Epic Dependency Graph

Order constraints between epics (does NOT imply they ship sequentially — parallelizable where independent):

```
Epic A (architecture refactor — unified signal pool)
   ├──→ Epic B (training reads Epic A's signal contract for FR-21 feature parity)
   ├──→ Epic C (LUFS/beat-grid surfaced as new signal types in the pool)
   │       └──→ Epic D (demo selector consumes Epic C model registry FR-32;
   │                    beat-grid/LUFS surfaces from FR-26/FR-27)
   └──→ Epic E (DocumentedCase protocol covers Epic A enums + Epic C types)
          └──→ Epic D (demo popover wired to Epic E docs per FR-42, with
                       graceful degradation when Epic E ships late)
```

- Epic A unlocks Epic B (signal contract), Epic C (new signal types), and Epic E (which enums get documented).
- Epic C unlocks Epic D's beat-grid timeline, LUFS readout, model-registry-driven selector.
- Epic E unlocks Epic D's strategy popover; FR-42 graceful-degradation lets D ship before E if necessary.
- Epic B is largely independent of D/E and can run in parallel with C.

## NFRs

Cross-cutting non-functional requirements that apply across all epics.

**NFR-1 — Swift 6 strict concurrency.** All new public types conform to `Sendable`. All async/await paths are data-race-free under Swift 6's strict checking. `@unchecked Sendable` requires explicit justification in the architecture doc.

**NFR-2 — Zero external dependencies.** Library may import only Apple system frameworks (Foundation, Accelerate/vDSP, AVFoundation, CryptoKit, optional CoreML/BNNSGraph). No third-party packages, ever. Hard constraint per CLAUDE.md "Language-Specific Rules".

**NFR-3 — Platform: macOS 15+.** Library targets macOS 15+ as minimum deployment. iOS/iPadOS/visionOS expansion is not in this PRD's scope, but architecture decisions taken here must not preclude future platform expansion (e.g., avoid AppKit-only types in public library API; AppKit usage is acceptable in the demo, not in the library).

**NFR-4 — Pre-1.0 framing: no backwards compatibility promised.** This PRD introduces a major refactor (Epic A unified signal pool) that breaks load-bearing invariants — `MetadataCorroborator.apply` post-merge boundary, frozen `merge` 41-call-site signature, removal of `EnsembleCombiner`. Breaking changes are explicitly authorized; the ABI / source-stability commitment kicks in at 1.0.

**NFR-5 — No prose duplication library→consumers.** Documentation source-of-truth lives in the library's Markdown SPM resource bundle. The demo and any consumer app access docs through typed library APIs, never via duplicated string literals. (Carried forward from Epic E FR-48; lives here because it's a maintenance contract, not a developer outcome.)

**NFR-6 — Performance budgets.**
- OA300 wall-clock at default intensity does not regress more than 15% (per FR-11).
- Beat-grid extraction overhead bounded and measured separately (per FR-34).
- LUFS analysis cost is dominated by file decode, already paid for BPM analysis under the shared-decode seam (FR-35).
- Combined analysis (BPM + LUFS + beat-grid) decodes the file once, not three times.

**NFR-7 — Accuracy floors hold across the refactor.** OA300 single-window Acc1 ≥ 55/82 + GiantSteps Acc1 ≥ 537/661 are unconditional CI assertions (per FR-10) — they fire on every test run regardless of preset/policy. Trained-model bundling has its own evaluation gates (FR-18) beyond these floors.

**NFR-8 — Test discipline.** New analyzer/algorithm work includes paired byte-equality opt-out tests where feasible (no longer required as default contract per pre-1.0 framing, but valuable as architecture-refactor regression scaffolding). Drift-detection mechanisms (FR-50) gate on every CI run.

**NFR-9 — App Store compliance (demo).** Demo app is sandboxed (`com.apple.security.app-sandbox`), signs with developer identity, ships via `make demo-archive`. Required entitlements include `com.apple.security.files.user-selected.read-write` (app-level superset required by the audio-file open path; the model bookmark is read-only via `.securityScopeAllowOnlyReadAccess`) + `com.apple.security.files.bookmarks.app-scope` (per FR-38).

**NFR-10 — No new internet requests.** Library and demo make no internet requests from any code introduced by this PRD (per FR-46 + FR-52). Privacy manifest reason codes already covered by Story 5-7 do not need expansion.

## Open Questions

Consolidated from epic-level KDDs and architecture-cascade reviews. Each entry resolves in the named epic's architecture doc, training plan, or implementation phase — not before that epic begins.

**Architecture (Epic A):**
- KDD-A1: Single umbrella type for voting policy vs split into multiple policy types vs Animation-style typed-struct-with-static-factories.
- KDD-A2: `SignalWeights` shape (strongly-typed struct vs `[SignalSourceKind: Double]` dict).
- KDD-A3: Source-weight formula layering (1-layer / 2-layer / 3-layer).
- KDD-A4: ML execution policy API surface (`Double` threshold vs `MLExecutionPolicy` enum).
- KDD-A5: `EnsemblePolicy` fate (remove / preserve as facade with `.weightedVoting(SignalWeights)` / keep as leaf-only convenience enum).
- KDD-A6: Whether to preserve today's `MetadataCorroborator.apply` post-merge boundary, OR collapse DSP + ML + metadata into a unified pool voting inside `CandidateMergeStrategy.merge`. (Tracked here because the architecture epic's outcome ripples into FR-7, FR-31, and the Epic A vs Epic C API surfaces.)

**Training (Epic B):**
- KDD-B1: Training architecture (TempoCNN-style retain vs alternative: TCN, conformer-lite).
- KDD-B2: Semi-supervised method (BYOL-A / masked-mel pretraining vs supervised-only-with-augmentation).
- KDD-B3: Marginal-tier reintroduction mechanism (FixMatch / self-training / consistency regularization / none).
- KDD-B4: Diagnostic suite composition.
- KDD-B5: Quality-bar branching — re-bundle on `main` (default-shipped) vs BYOW-only, conditional on FR-18 evaluation gates.

**Public API (Epic C):**
- KDD-C1: Beat-tracking baseline algorithm (Ellis 2007 DP / Davies & Plumbley 2004-2005 causal / RNN-DBN).
- KDD-C2: `BeatGrid` result type shape (tri-state downbeat enum vs optional array vs unified `BeatEvent` list).
- KDD-C3: Disagreement-surfacing pattern for FR-31 (explicit `tempoAgreedWithBPMStage: Bool` flag vs let consumers compare).
- KDD-C4: Internal shared-decode seam shape (FR-35).
- KDD-C5: Integrity-check algorithm (SHA-256 / BLAKE3 / CMS signature).
- KDD-C6: Beat-grid engine abstraction (protocol vs enum of implementations).

**Demo UX (Epic D):**
- KDD-D1: Specific preset list and naming.
- KDD-D2: Timeline rendering primitive (`Canvas` vs `Chart` vs custom `Path`).
- KDD-D3: Bookmark persistence shape (`UserDefaults` vs SwiftData vs plist).
- KDD-D4: Popover presentation style.
- KDD-D5: Diagnostic table interaction model.

**Docs (Epic E):**
- KDD-E1: Protocol family cap pre-1.0.
- KDD-E2: Protocol shape (per-instance `var docs` vs static `[Self: AttributedString]` map).
- KDD-E3: `documentationID` derivation (exhaustive switch vs reflection vs raw-value).
- KDD-E4: `AnalysisIntensity` reshape (struct → enum), specific case list, compute-budget semantic.
- KDD-E5: Cache primitive for `AttributedString` parse results.
- KDD-E6: Front-matter YAML schema.
- KDD-E7: Markdown content style guide.
- KDD-E8: DocC integration (defer or parallel surface).

## Cross-Cutting Risks

**No hidden labelers.** The trained model must NOT learn Tony's library heuristics (playlist names, Rekordbox conventions, DSP biases) — these are labeler-derived signals that would contaminate generalization. Codex Q1 flagged; operator explicitly endorsed. Mitigation: FR-15 restricts training input features to audio-derived only; FR-22 adds leave-artist-out evaluation slice; party-mode reframed FR-15 as "no library-curator artifacts" with explicit reasoning.

**Tony-domain overfit.** ~1,344-track DnB-heavy corpus risks producing a model that excels on Tony's library and degrades on broader DJ/producer audio. Mitigation: FR-22 split contamination guards + leave-artist-out slice; FR-24 semi-supervised expansion must prove net benefit on independent corpora; OA300 and GiantSteps remain primary acceptance corpora.

**Calibration failure.** The previously-bundled `giantsteps_v1.mlmodelc` failed at calibration (softmax_max_p95=0.294, bimodal at 125/175 regardless of input). Mitigation: FR-25 codifies a calibration metric and floor; calibration failure blocks bundling regardless of Acc1.

**Octave-normalization metric gaming.** Training-time octave-aware loss can optimize for behavior that fails operationally in DJ workflows. Mitigation: FR-23 (octave policy consistency train/runtime); FR-22's leave-artist-out and raw vs octave-normalized accuracy reporting.

**Long-file sync drift.** Beat-grid timestamps may diverge audibly from audio over 5+ minute tracks. Mitigation: FR-29 (long-file sync stability); FR-34 acceptance corpus includes long-file representative tracks.

**Codec priming-delay semantics.** AAC/MP3 priming-trim differs between `AVAudioFile` (decoded-content frames) and `AVAssetReader` (`CMSampleBuffer.presentationTimeStamp` with `kCMSampleBufferAttachmentKey_TrimDurationAtStart`). Mitigation: FR-30 (playback-aligned timestamps via Apple's media frameworks for asset-anchored alignment).

**API churn from Epic A KDDs.** Five architecture decisions deferred to the architecture doc (KDD-A1 through KDD-A5). Late settling could ripple into Epic D's preset list (FR-36), Epic E's documented enums (FR-45), and consumer migration cost. Mitigation: Epic D's named-presets-in-primary-view + advanced-sidebar pattern (FR-36) decouples demo UX from Epic A KDD churn.

**Tiny DnB challenge set fragility.** Four named targets in `4-dnb-triplet-targets.json` are statistically insufficient as a generalization claim. Mitigation: FR-17 explicitly frames them as sentinels-not-proof; broader corpora (OA300, GiantSteps) carry the generalization claim.

**Pre-1.0 framing: backwards compatibility is NOT a goal.** This PRD's Epic A breaks load-bearing invariants (post-merge corroboration boundary, frozen merge signature). Operator endorsed pre-1.0 break authorization repeatedly. Risk: consumers who wired against the pre-PRD API surface (if any) need migration. Mitigation: NFR-4 codifies; no consumer commitments exist in pre-release.
