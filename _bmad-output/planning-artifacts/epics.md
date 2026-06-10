---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/.decision-log.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md'
workflowType: 'create-epics-and-stories'
project_name: 'BoomBoomBoomKit'
user_name: 'robbyt'
date: '2026-05-26'
status: 'complete'
completedAt: '2026-05-27'
lastStep: 4
prdReference: 'prd-BoomBoomBoomKit-2026-05-25 (status: final, 51 FRs across 5 epics)'
architectureReference: 'architecture.md (status: complete, 27 KDDs resolved, 2026-05-26)'
archivedPredecessor: '_bmad-output/planning-artifacts/archive/epics-2026-03-31.md'
epicNumbering: 'monotonic — old epics.md used Epic 1-5; new PRD epic A → Epic 6; B → Epic 7; C → Epic 8. PRD epic D (demo) split into Epic 9 (demo shell, dep Epic 6 only) and Epic 10 (demo integration of beat-grid + LUFS + per-case docs, dep Epic 8 + Epic 11). PRD epic E (per-case docs) → Epic 11. Total 6 epics.'
partyModeAmendmentsApplied:
  - '2026-05-26: Epic 9 split into 9 (demo shell) + 10 (demo integration) — renumbered per operator; old Epic 10 (per-case docs) → Epic 11. 4 agents pushed; John framed as "three outcomes wearing a trenchcoat."'
  - '2026-05-26: Epic 7 framing reshaped per John — FR-18 becomes promotion gate, not existence gate. Training pipeline + reproducible artifact + BYOW reference is unconditional Epic 7 deliverable. Bundle on main = promotion outcome.'
  - '2026-05-26: Epic 6 / Epic 8 seam mitigation per Mary — Epic 6 public-API touchpoints in AudioAnalysisService remain internal or unannotated; Epic 8 stories promote them to public.'
  - '2026-05-26: Epic 7 phasing — PHASED with 3 guardrails per Codex (thread 019e660f-08cd-7373-b616-700e5566eb54). Settles Amelia-vs-Winston/John/Mary split. Guardrails: (1) v1 training is scaffolding/diagnostics, NOT a promotable bundle candidate; (2) featureSetVersion seam blocks runtime miscalibration but v1 FR-18 metrics do NOT transfer to v2 — any mel/FFT/log/default-weighting change invalidates Acc1/ECE/tail-error claims, FR-18 reruns from scratch on the exact runtime feature config Story 6.4 ships; (3) sub-band weighting trains against ONE declared profile encoded in model metadata alongside featureSetVersion; alternate profile is ablation/augmentation only.'
  - '2026-05-26: Post-story-drafting party-mode review (Sally, Paige, Mary, Amelia) — 16 amendments applied. Critical: Story 11.3 count fix (46→49, split into 11.3a/11.3b), Story 6.5 valve + AC #9 (35-file Sources + 70-file Tests tripwires), Story 7.4 expectedFailureMode populated mechanically, Story 7.5 multi-seed training (3 seeds) for KDD-B3 reopen-trigger #5. Important: Story 11.5 DocC symbol-extension shape pinned, Story 11.4 sequencing gate + validator scope + _-prefix skip, Story 7.7 prior-bundle calibration anchor side-by-side, Story 9.1 preset subtitles, Story 7.1 n=12 sentinel curation in JAMS format, Story 7.5 cite both 6.2 AND 6.4 gates, Paige #3 Option A Tradeoff failure-mode sentence rule.'
  - '2026-05-26: Codex-blessed iteration-leak mitigation (thread 019e6662-22ab-7451-957e-ae93b0cb1a6e). Story 7.6 grows N=3 FR-18 re-run governance tripwire with deviation log at _bmad-output/implementation-artifacts/7-6-fr18-rerun-log.md. Story 7.7 grows held-out GiantSteps slice of n=150 tracks (Codex preferred over Mary suggested 50) with stratified-by-tempo-band + stratified-by-style-label selection; sealed locally with committed selection-script + seed + SHA256 manifest digest; iteration-leak tripwire fires at gap ≥ 8 Acc1 points. ACs added to Stories 7.6 + 7.7; no new Story 7.8 needed per Codex verdict.'
  - '2026-05-26: JAMS (JSON Annotated Music Specification, marl/jams, ISC) + mir_eval adopted for ground-truth annotation artifacts. Story 8.7 updated: F-measure via mir_eval.beat.f_measure (Python sidecar, develop-only Python dep), daw-oracle-beats.json emits JAMS natively, Swift JAMS decoder lands at Tests/BoomBoomBoomKitBenchmarkTests/Helpers/JAMSDecoder.swift (~100-150 LOC). Story 8.8 added: one-time migration of daw-oracle.json + oa300-ground-truth.json + 4-dnb-triplet-targets.json to JAMS shape via make oracle-migrate-to-jams. Python jams + mir_eval deps added to _bmad-output/ml-training/pyproject.toml (develop-only, NOT shipped to main).'
  - '2026-05-26: Global valve artifact-path pass — every Pressure-release valve in the file that proposes a deviation now cites _bmad-output/implementation-artifacts/<story>-pressure-release.md as documentation target. 13 valves updated; 11 already cited; 10 say None. Closes audit-trail hole flagged by Amelia #6.'
  - '2026-05-30: Epic 7 runtime-gate reconciliation (Epic 6 retro Action Item A1). The genuine KDD-A6 Stage 3 semantic flip + KDD-A5 activation landed in Story 6.5b, not Story 6.4 — 6.4b was byte-inert prep and FR-1/2/6/7 were reallocated to 6.5 on 2026-05-29 (see the Story 6.4/6.5 sections at the merge-flip text). The Epic 7 FR-18 runtime-stability gates (dependency preamble bullet 3, dependency diagram, Epic 7 stories preamble, Story 7.5 precondition AC, Story 7.6 want-statement) are repointed Story 6.4 to Story 6.5b. Guardrail (2) feature-config reference is corrected Story 6.4 to Story 6.2 (the mel/FFT/log feature shape freezes in 6.2, consumed unchanged by the 6.5b runtime). The 2026-05-26 entries above are kept as the historical record of what was decided at the time. No code change; epics.md + architecture.md doc-only. Also corrected architecture.md residual drift: SignalParticipationTraceEntry Hashable drop, MLExecutionPolicy non-allCases case-coverage invariant, and the BPMSelectionPolicy/OctaveEquivalencePolicy invariant-test file pointers.'
---

# BoomBoomBoomKit — Epic Breakdown

## Overview

This document decomposes the 51 FRs + 10 NFRs from the 2026-05-25 PRD and the 27 KDDs resolved in `architecture.md` into implementable stories grouped under six epics (Epic 6-11). The PRD's Epic D (demo) is split into two epics here per party-mode review — old PRD epic D's 9 FRs separate into a demo-shell epic (depends on Epic 6 only) and a demo-integration epic (depends on Epic 8 + Epic 11). PRD epic E's per-case docs work renumbers from Epic 10 to Epic 11 as a consequence.

Epic numbering continues monotonically from the archived `epics-2026-03-31.md`, which used Epic 1-5 for the Phase 1-3 work (Stories 1-1 through 5-7 — DSP accuracy, ML augmentation, demo polish, and shipping discipline). Story identifiers remain unique across project history (Story 6.1 vs the historical Story 1-1).

**Tier-1 strict sequence (per architecture's Implementation Handoff):**

1. Story 6.1 — KDD-S1 `SignalParticipation` + KDD-T0 typed-evidence (same PR) + KDD-A6 Stage 1 `UnifiedSignalPool` adapter
2. Story 6.2 — KDD-S2 `FeatureSubstrate` + `OnsetFeaturesBuilder` (+ `MLFeatureFrames` relocation)
3. Story 6.3 — KDD-A6 Stage 2 (migrate `MetadataCorroborator` to consume pool)
4. Story 6.4 — KDD-A6 Stage 3 (flip `merge` signature; semantic-equality atomic replacement)
5. Story 6.5 — KDD-A1 type taxonomy split (`SignalWeights` + `OctaveEquivalencePolicy` + `BPMSelectionPolicy` rename) + KDD-A2/A3/A4/A4a/A5 derivations
6. Epic 7 / 8 / 9 / 11 can begin in parallel once Story 6.4 lands (Epic 7's Python prefix can begin in parallel with Epic 6 per Codex PHASED verdict + guardrails). Epic 10 waits for Epic 8 + Epic 11.

## Requirements Inventory

### Functional Requirements

**Epic 6 — Unified-signal-pool architecture refactor (formerly Epic A)**

- **FR-1** Unified signal pool. DSP candidates, ML predictions, and file-metadata tags contribute to a single unified pool for BPM determination. No signal type privileged at the voting stage.
- **FR-2** Configurable per-source weighting. Signal influence scales with self-reported confidence × per-source reliability factor. Higher-reliability source's lower-confidence signal can outweigh a lower-reliability source's higher-confidence signal.
- **FR-3** Octave-equivalence handling configurable. Consumers choose collapse-to-fundamental / octave-aware-with-penalty / exact-match-only.
- **FR-4** ML execution policy. `MLExecutionPolicy` configurable: `.always`, `.whenDSPConfidenceBelow(Double)`, `.never`. ML's peer-signal status at voting preserved regardless of execution policy.
- **FR-5** Common ensemble cases stay ergonomic. Named presets (DSP-only, ML-only, highest-confidence, weighted-voting) expressible without manual per-source weight configuration.
- **FR-6** Per-window contribution caps. Multi-window DSP signal counts do not swamp single-instance ML or metadata signals. Normalize per source family, not per signal row.
- **FR-7** Metadata as peer voter. File-metadata tags participate in the pool as voting signals, replacing today's post-merge multiplicative boost. Voter normalizes half/double relationships, tracks tag-source provenance, penalizes implausible-for-genre tags.
- **FR-8** Empty pool returns nil. When the pool has no signals, library returns nil with documented diagnostic trace reason. No synthesized "default BPM."
- **FR-9** Diagnostic trace surfaces the pool. When `enableTrace = true`, trace surfaces every contributing signal, its cluster, and the winner. Legacy `ensembleDecision` field removed.
- **FR-10** Accuracy floors hold. OA300 Acc1 ≥ 55/82 and GiantSteps Acc1 ≥ 537/661 hold at default options after the refactor.
- **FR-11** Performance budget. Unified-pool runtime path does not regress OA300 wall-clock by more than 15% at default intensity.
- **FR-11a** Intensity as compute-budget dial coupled to active ensemble. `AnalysisIntensity` levels gate which compute-expensive signal sources contribute. Explicit `MLExecutionPolicy` wins when both apply.

**Epic 7 — ML retraining on Tony corpus (formerly Epic B)**

- **FR-12** Corpus diagnostics produce reviewable evidence. Diagnostics expose label-source bias, octave ambiguity (Tony's half-tempo-labeling pattern), confidence calibration, cluster stability, representative manual-review findings. Supports freeze-or-relabel decision before training.
- **FR-13** Non-Rekordbox audio expansion with clean provenance. ~4,700 audio files tiered as semi-supervised pool. Audio-derived DSP + generic file-metadata agreement within 2-3% after octave normalization → secondary supervised tier. Path/playlist/Rekordbox-derived signals forbidden as expansion evidence.
- **FR-14** Label tier policy. Initial supervised training uses Strong (≥0.80) + Solid (0.65-0.80) only. Marginal (0.55-0.65, 241 tracks) excluded initially; reintroduction gated by documented promotion policy.
- **FR-15** No library-curator artifacts. Audio-only model. No playlist names / file paths / Rekordbox signals / DSP candidate scores. No artist embedding / ID3 BPM input. Metadata-driven adjustments via Epic 6 voting pool (FR-7), not the model.
- **FR-16** Octave-aware training loss. Training loss respects octave equivalence (87 vs 174 not unrelated classes).
- **FR-17** DnB challenge set held out as sentinel. 4 named DnB triplet targets (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) reserved as held-out evaluation — never used in training.
- **FR-18** Trained-model evaluation gates. Before bundling on `main`: (a) 4 DnB sentinels correct → expand to n=12 by mid-point → Wilson 95% lower-bound ≥ 0.75 at close-out; (b) OA300 Acc1 > 55/82 strictly; (c) GiantSteps Acc1 ≥ 537/661; (d) `ECE_half_double < 0.10`; (e) Tail-error P95 absolute BPM error (GiantSteps < 8 / OA300 < 5 / Sentinels < 3 BPM). Failure → BYOW reference in `_bmad-output/ml-models/`. Genre scope v1.0: breaks + DnB only.
- **FR-19** Model exportable to BYOW runtime path. Trained checkpoint exports to CoreML model consumable by `BNNSTechnique(modelURL:) throws`.
- **FR-20** Training reproducibility. Fixed seeds, deterministic shuffling, recorded model metadata. Logged to `_bmad-output/ml-training/training_log.json` + `model_metadata.json`.
- **FR-21** Feature-pipeline parity train-vs-runtime. Python and Swift produce equivalent feature tensors within documented numeric tolerance, exact match on frame shape, ordering, normalization, and `featureSetVersion`. Model records `featureSetVersion` it trained against; runtime rejects/warns on mismatch.
- **FR-22** Split contamination guards. Train/val/test splits audited via `corpus_splits.json` to prevent related recordings crossing boundaries. Audit lists duplicate groups + confirms FR-17 challenge material absent from train/val. Leave-artist-out evaluation slice reported.
- **FR-23** Octave policy consistency across training and runtime. Same documented octave-equivalence policy in training loss, validation scoring, runtime voting. Acceptance metrics report raw Acc1 + octave-normalized accuracy. Mismatch blocks model acceptance.
- **FR-24** Semi-supervised expansion must prove net benefit. Promotion gated by ablation against supervised-only training improving or preserving all acceptance gates within tolerance.
- **FR-25** Confidence calibration verified. Calibration metric (ECE / softmax distribution shape) with documented floor that the previously-bundled `giantsteps_v1.mlmodelc` failed. Anchor: prior bundle `softmax_max_p95 = 0.294`, bimodal at 125/175. Calibration failure blocks bundling regardless of Acc1.

**Epic 8 — Public API expansion: LUFS + beat-grid + model registry (formerly Epic C)**

- **FR-26** LUFS public API. `analyzeLUFS(url:options:)` exposes integrated loudness, true-peak, LRA. Internal `LUFSAnalyzer` promoted public via service boundary.
- **FR-27** Beat-grid extraction. `analyzeBeatGrid(url:options:)` returns per-beat timestamps, downbeat information, estimated tempo at grid-derivation time, grid-level confidence.
- **FR-28** Downbeat tri-state. `DownbeatResult.notAttempted` / `.noneDetected` / `.detected([…])` — consumers distinguish "ran but found none" from "didn't run."
- **FR-29** Long-file sync stability. Beat timestamps remain audibly accurate at end of 5+ minute tracks. Numeric drift tolerance committed in acceptance corpus spec.
- **FR-30** Playback-aligned timestamps. Beat timestamps line up with audio playback position regardless of input codec (AAC, MP3, FLAC, WAV, AIFF, CAF). Codec priming-delay and SRC do not introduce visible offset.
- **FR-31** BPM and beat-grid consistency contract. Caller sees consistent answers (BPM ≈ beat-grid tempo) OR disagreement surfaced via `tempoAgreedWithBPMStage: Bool?` for arbitration.
- **FR-32** Model registry public type. `ModelRegistry` lists bundled (if any) + user-added + known-public-reference models. Each entry carries identity, integrity, capability compatibility, attribution/license info. In-memory only at library level.
- **FR-33** User-picked models integrity-checked. CryptoKit `SHA256.hash(data:)` validates model integrity at registration. Mismatch → clear error, not silent corruption. Result cached.
- **FR-34** Beat-grid acceptance corpus. Validated against OA300 (DAW oracle ground truth) + stratified DnB subset. Specific F-measure floor + beat-position tolerance committed in training/eval plan.
- **FR-35** Shared decode for combined analysis. Consumers extract BPM + LUFS + beat-grid from a single file decode pass. `DecodedAudio` seam exposed before unified `analyze(...)` API lands.

**Epic 9 — Demo app ML + ensemble UX (formerly Epic D)**

- **FR-36** Demo exposes named ensemble presets in primary view. 4 PRD presets (`Default`, `DSP only`, `ML augmented`, `Trust file tags`) in primary view; raw signal weights in advanced sidebar (existing `.inspector(isPresented:)` from Story 5-6b).
- **FR-37** Model selection from registry + file picker. Demo lets users select an ML model from registry OR add new via file picker. Selection drives subsequent analysis.
- **FR-38** Demo owns persistence for user-added models only. Security-scoped bookmark stored by demo for user-added models. Library accepts already-resolved URLs. Bundled + known-public entries are stateless. Required entitlements: `user-selected.read-only` + `bookmarks.app-scope`.
- **FR-39** Beat-grid as timeline + text readout. SwiftUI Canvas timeline with current-time scrubber + text readout (tempo, beat count, downbeat status, confidence). No waveform.
- **FR-40** LUFS as primary measurement, secondary breakdown. Integrated LUFS as single number with unit label + small panel for true-peak + LRA. Does not dominate BPM-centric flow.
- **FR-41** Final-state signal-pool diagnostic table in advanced sidebar. When `enableTrace: true`, sortable Table with one row per contributing signal (source, BPM, confidence, weight, contribution, cluster). Final-state, post-analysis. Replaces current `EnsembleDecision` summary view.
- **FR-42** Strategy popover wired to Epic 11 docs with graceful degradation. "?" buttons open SwiftUI `.popover()` rendering docs from Epic 11's runtime Markdown bundle via `BoomBoomBoomKitDocs.attributedString(for:id:)` accessor. If Epic 11 ships late or bundle unavailable, popover shows fallback (one-line description + repo URL). _(PRD originally referenced "Epic E" — per-case docs renumbered to Epic 11 after Epic 9 split during party-mode review 2026-05-26.)_
- **FR-43** Primary flow stays primary; developer surface in sidebar. "Drop file → get answer" remains dominant interaction. All developer/diagnostic affordances live in `.inspector(isPresented:)` sidebar (keyboard `⌘⇧D`).
- **FR-44** Confidence semantics explicitly labeled. Every confidence-like number (BPM confidence, beat-grid confidence, signal weight, source reliability, ML softmax max) carries explicit label. No bare numeric value without context.

**Epic 11 — Selection-strategy docs (per-case typed API + Markdown resources) (formerly Epic E; renumbered after Epic 9 split)**

- **FR-45** Per-case help via typed property access. Every public mode case exposes `.docs: AttributedString` (`mergeStrategy.docs`). Xcode autocomplete surfaces without string lookups.
- **FR-46** Help renders offline without network access. Documentation ships inside SPM resource bundle. No network calls.
- **FR-47** Help explains what AND why. Each documented case carries prose covering what the option does AND why a developer would choose it.
- **FR-49** Informative fallback when docs missing. Accessor returns clear fallback `AttributedString` — never empty result, never crash. Non-throwing, non-optional.
- **FR-50** New documented cases cannot ship without docs. Adding/removing/renaming a documented case fails automated verification until matching documentation coverage is updated. Drift detection via exhaustive switch over `CaseIterable` at test time.
- **FR-52** Documentation bundles with the library binary. Doc content ships inside SPM resource bundle. Runtime fetching from network/dynamic loading/CDN prohibited.

_(FR-48 moved to NFR-5; FR-51 dropped per PRD — `BNNSTechnique` is a struct, not a `CaseIterable` enum.)_

### NonFunctional Requirements

- **NFR-1** Swift 6 strict concurrency. All new public types `Sendable`. All async paths data-race-free. `@unchecked Sendable` requires explicit justification.
- **NFR-2** Zero external dependencies. Apple system frameworks only (Foundation, Accelerate/vDSP, AVFoundation, CryptoKit, Synchronization, optional CoreML/BNNSGraph). Hard constraint.
- **NFR-3** Platform: macOS 15+. Minimum deployment. iOS/iPadOS/visionOS expansion out of scope, but architecture must not preclude (no AppKit in public library API; AppKit acceptable in demo).
- **NFR-4** Pre-1.0 framing: no backwards compatibility promised. Authorizes breaking changes for Epic 6 (post-merge corroboration boundary, frozen `merge` signature, `EnsembleCombiner` removal). ABI/source-stability commitment kicks in at 1.0.
- **NFR-5** No prose duplication library→consumers. Documentation source-of-truth lives in library's Markdown SPM resource bundle. Demo and consumers access via typed library APIs, never duplicated string literals.
- **NFR-6** Performance budgets. OA300 wall-clock at default intensity ≤ 15% regression (per FR-11). Beat-grid extraction overhead bounded and measured separately. LUFS analysis cost dominated by file decode (paid for BPM under FR-35 shared-decode). Combined analysis decodes once, not three times.
- **NFR-7** Accuracy floors hold across the refactor. OA300 Acc1 ≥ 55/82 + GiantSteps Acc1 ≥ 537/661 unconditional CI assertions (per FR-10). Trained-model bundling has its own gates (FR-18) beyond these floors.
- **NFR-8** Test discipline. New analyzer/algorithm work includes paired byte-equality opt-out tests where feasible (no longer default contract per NFR-4, but valuable as architecture-refactor regression scaffolding). Drift-detection (FR-50) gates every CI run.
- **NFR-9** App Store compliance (demo). Demo sandboxed (`com.apple.security.app-sandbox`), signs with developer identity, ships via `make demo-archive`. Entitlements: `user-selected.read-only` + `bookmarks.app-scope`.
- **NFR-10** No new internet requests. Library and demo make no internet requests from any code in this PRD (per FR-46 + FR-52). Privacy manifest reason codes already covered by Story 5-7.

### Additional Requirements

Implementation-level requirements derived from `architecture.md` that shape epic/story scoping. (Architecture's 27 KDDs are tracked separately in the epic-level KDD references below — these are the cross-cutting structural requirements that span multiple stories.)

**Starter template / scaffolding:**

- No starter template (brownfield SPM library bootstrapped with `swift package init --type library` and accumulated 30+ stories of conventions). No new initialization story.
- Subfolder creation (`Sources/BoomBoomBoomKit/SignalPool/`, `Sources/BoomBoomBoomKit/FeatureSubstrate/`) happens inside Epic 6 stories, not as separate scaffolding work.
- `Package.swift` updates (platforms expansion to `[.macOS(.v15), .iOS(.v18), .visionOS(.v2)]`, `resources: [.process("Resources/Documentation")]`) land inside their respective Epic stories.

**Target & structure boundaries (architecture-pinned, do not redrew):**

- No new SPM products. Beat-grid (Epic 8), unified-pool types (Epic 6), LUFS public API (Epic 8), `ModelRegistry` (Epic 8), `DocumentedCase` protocol family (Epic 11) all land in existing `BoomBoomBoomKit` core target.
- `MLFeatureFrames` relocates from `BoomBoomBoomKitML/` → `BoomBoomBoomKit/FeatureSubstrate/` (Winston: one source of truth for feature contract).
- Two new subfolders only: `SignalPool/` (10 new files, Epic 6) and `FeatureSubstrate/` (10 new files, Epic 8 + Epic 7 parity).
- LUFS / BeatGrid / ModelRegistry / DocumentedCase files (1-3 each) stay at root. Codified threshold: subdir when ≥ 5 cohesive files.
- Public-API facade stays `AudioAnalysisService`. `analyzeLUFS` + `analyzeBeatGrid` siblings to `analyzeBPM`. No `LUFSService`/`BeatGridService` sibling structs.

**Migration / data shape:**

- Epic 6 KDD-A6 migration MUST stage across 3 stories: Stage 1 introduces `UnifiedSignalPool` adapter (frozen `merge` 41-call-site signature unchanged); Stage 2 migrates `MetadataCorroborator` and `runPreCorroborationPipeline` to consume pool (signature still unchanged); Stage 3 flips `merge` parameter type in a single mechanical PR — byte-equality tests REPLACED in the same commit by `MergeSemanticEqualityTests.swift`. No week-long red intervals.
- Story spec for each stage MUST state: "stage N regression floor = stage N-1 measurement." Encoded via Swift Testing `@Tag(.stageNFloor)`, NOT story-spec checklists.
- NaN-safe `Double.bitEqual(to:)` helper lives in `BoomBoomBoomKitTestSupport` (folded into `NumericTestHelpers.swift` namespace per Amelia). All byte-equality tests use `Double.bitPattern` comparison, not `==`.

**Cross-cutting discipline rules (codified in `_bmad-output/project-context.md` per architecture):**

- KDD-T0 typed-evidence trigger language. Typed evidence structs on `BPMDiagnosticTrace` only when BOTH (a) public type affects winner selection / weight resolution / gate firing, AND (b) emitted boundary would otherwise be ambiguous or collision-prone. Codified BEFORE Tier-1 PR work begins.
- `SignalParticipationTraceEntry` ships in the SAME PR as `SignalParticipation` (KDD-S1). Non-negotiable.
- 4-state `SignalParticipation` is the universal contract. No bare optional return from any signal source into the pool. Per-source assertion: DSP must produce ≥ 1 of `{.present, .abstained, .demoted}`; never `.absent`.
- 5-recipe `BPMDiagnosticTrace` audit (project-local skill `bpm-diagnostic-trace`) returns zero matches against `Sources/` and `Tests/` after each trace-field addition.

**Security & integrity:**

- ModelRegistry uses CryptoKit `SHA256.hash(data:)`. SHA-256 over `.mlmodelc` directory contents (sorted-by-relative-path, concatenated bytes). Computed once per registration; cached.
- Demo entitlements: `com.apple.security.app-sandbox` + `com.apple.security.files.user-selected.read-only` + `com.apple.security.files.bookmarks.app-scope`. The third is the one developers commonly forget for security-scoped bookmark resolution.

**License & provenance:**

- aubio is GPL-3.0. STUDY ONLY the Davies & Plumbley algorithm in `src/tempo/beattracking.c` and the weighted-spectral-filtering technique in `src/onset/onset.c`. NO transcription. NO linkage. Cite via `///` doc comments + Davies & Plumbley 2004-2005 academic papers.
- Frozen surfaces preserved: `MLTechnique.evaluate(trace:) -> MLEvaluation?` (Story 4-5 DD #18). `MLEvaluation` field set (`bpm`, `confidence` only). Field expansion requires named story spec.

**CI / enforcement gates:**

- Unit-test-locked invariants: `BPMSelectionPolicy.allCases.count == 8` (renamed from `CandidateMergeStrategy`), `OctaveEquivalencePolicy.allCases.count == 3` (new), `MLExecutionPolicy.allCases` (associated-value pattern check), `DownbeatResult.allCases` (associated-value pattern check), `AnalysisIntensity.allCases.count == 10` (new — struct → enum reshape).
- CI grep gate (iOS-neutrality): `grep -rE "^import AppKit" Sources/ | grep -v "#if os(macOS)"` returns zero matches. Complements the platforms-array compile-fail tripwire.
- CI iOS compile lane: `swift build -Xswiftc -sdk -Xswiftc iphoneos` clean compile required. Architecture remains macOS-15+ for testing/benchmarks.
- SwiftLint custom rule: ban `case .default:` against `AnalysisIntensity` (static-let alias not pattern-matchable as switch case).
- `DocumentationValidatorTests.swift` per-rule + per-file-parameterized smoke test: no fenced code blocks / no tables / no images / no DocC symbol links / no heading hierarchy / files ≤ 10 KB / required bold leads present / `AttributedString(markdown:)` parse-error → test failure.

**Tooling additions (Makefile, develop-only):**

- `make docc-transclude` — generates `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/<case>.md` from canonical runtime Markdown.
- `make docc-validate` — runs `DocumentationValidatorTests` independently.
- `make new-case TYPE=X CASE=y` — scaffolds new `.md` with front-matter + three bold-lead template.
- DocC `Cases/` directory `.gitignore`'d as a build artifact.

**Imports inventory (`Package.swift` / Sources):**

- `import CryptoKit` — NEW in `ModelRegistry.swift` (Epic 8).
- `import Synchronization` — NEW in `BoomBoomBoomKitDocs.swift` (Epic 11) for `Mutex<T>`.
- All other imports unchanged.

### UX Design Requirements

No standalone UX design document exists. UX is captured inline in PRD Epic D / Epic 9 (FR-36 through FR-44) and resolved via architecture KDD-D1 through KDD-D5. The demo's UX requirements appear as Epic 9 FRs above, not as separate UX-DRs.

Treat Epic 9 FRs as both functional requirements AND the UX specification — primary-view ensemble presets, advanced-sidebar diagnostics, beat-grid timeline (no waveform), strategy popover with graceful degradation, confidence-label discipline.

### FR Coverage Map

Every FR maps to exactly one epic. NFRs are cross-cutting (apply across all epics). FR-48 was moved to NFR-5 (no-prose-duplication is a maintenance contract, not a developer outcome); FR-51 was dropped (`BNNSTechnique` is a struct, not a `CaseIterable` enum).

| FR | Epic | Brief |
|---|---|---|
| FR-1 | Epic 6 | Unified signal pool — DSP/ML/metadata as peers |
| FR-2 | Epic 6 | Configurable per-source weighting |
| FR-3 | Epic 6 | Octave-equivalence handling configurable |
| FR-4 | Epic 6 | `MLExecutionPolicy` enum (3 cases) |
| FR-5 | Epic 6 | Common ensemble cases ergonomic (`EnsemblePolicy` facade) |
| FR-6 | Epic 6 | Per-window contribution caps |
| FR-7 | Epic 6 | Metadata as peer voter (replaces post-merge boost) |
| FR-8 | Epic 6 | Empty pool returns nil |
| FR-9 | Epic 6 | Diagnostic trace surfaces the pool |
| FR-10 | Epic 6 | Accuracy floors hold (OA300 / GiantSteps) |
| FR-11 | Epic 6 | Performance budget ≤ 15% OA300 regression |
| FR-11a | Epic 6 | Intensity as compute-budget dial (`ComputeBudget`) |
| FR-12 | Epic 7 | Corpus diagnostics |
| FR-13 | Epic 7 | Non-Rekordbox audio expansion with clean provenance |
| FR-14 | Epic 7 | Label tier policy (Strong + Solid initial) |
| FR-15 | Epic 7 | No library-curator artifacts |
| FR-16 | Epic 7 | Octave-aware training loss |
| FR-17 | Epic 7 | DnB challenge set held out |
| FR-18 | Epic 7 | Trained-model evaluation gates (bundle vs BYOW) |
| FR-19 | Epic 7 | Model exportable to BYOW runtime |
| FR-20 | Epic 7 | Training reproducibility |
| FR-21 | Epic 7 | Feature-pipeline parity train↔runtime |
| FR-22 | Epic 7 | Split contamination guards + leave-artist-out |
| FR-23 | Epic 7 | Octave policy consistency train↔runtime |
| FR-24 | Epic 7 | Semi-supervised expansion must prove net benefit |
| FR-25 | Epic 7 | Confidence calibration verified |
| FR-26 | Epic 8 | LUFS public API |
| FR-27 | Epic 8 | Beat-grid extraction |
| FR-28 | Epic 8 | Downbeat tri-state |
| FR-29 | Epic 8 | Long-file sync stability |
| FR-30 | Epic 8 | Playback-aligned timestamps |
| FR-31 | Epic 8 | BPM and beat-grid consistency contract |
| FR-32 | Epic 8 | Model registry public type |
| FR-33 | Epic 8 | User-picked models integrity-checked (SHA-256) |
| FR-34 | Epic 8 | Beat-grid acceptance corpus |
| FR-35 | Epic 8 | Shared decode for combined analysis |
| FR-36 | Epic 9 | Demo named ensemble presets in primary view (Epic 6 dep) |
| FR-37 | Epic 10 | Model selection from registry + file picker (Epic 8 dep) |
| FR-38 | Epic 10 | Demo owns persistence for user-added models only (follows FR-37) |
| FR-39 | Epic 10 | Beat-grid as timeline + text readout (Epic 8 dep) |
| FR-40 | Epic 10 | LUFS as primary measurement (Epic 8 dep) |
| FR-41 | Epic 9 | Final-state signal-pool diagnostic table (Epic 6 dep) |
| FR-42 | Epic 10 | Strategy popover wired to Epic 11 docs (Epic 11 dep + graceful degradation) |
| FR-43 | Epic 9 | Primary flow stays primary (cross-cutting discipline) |
| FR-44 | Epic 9 | Confidence semantics explicitly labeled (cross-cutting discipline; Epic 10 inherits) |
| FR-45 | Epic 11 | Per-case help via typed property |
| FR-46 | Epic 11 | Help renders offline |
| FR-47 | Epic 11 | Help explains what AND why |
| FR-49 | Epic 11 | Informative fallback when docs missing |
| FR-50 | Epic 11 | New documented cases cannot ship without docs |
| FR-52 | Epic 11 | Documentation bundles with library binary |
| ~~FR-48~~ | (NFR-5) | Moved to NFR — no prose duplication |
| ~~FR-51~~ | (dropped) | `BNNSTechnique` is a struct, not `CaseIterable` |

**Coverage totals:** Epic 6 = 12 FRs · Epic 7 = 14 FRs · Epic 8 = 10 FRs · Epic 9 = 4 FRs (demo shell) · Epic 10 = 5 FRs (demo integration) · Epic 11 = 6 FRs (per-case docs) · Total = 51 FRs · Cross-cutting NFRs = 10 · Architecture KDDs = 27 (resolved in `architecture.md`).

## Epic List

Six user-value-themed epics deliver the PRD outcomes. Numbering continues monotonically from the archived `epics-2026-03-31.md` (Epic 1-5). The PRD's Epic D (demo) split into Epic 9 (demo shell, depends on Epic 6 only) and Epic 10 (demo integration, depends on Epic 8 + Epic 11) per party-mode review; PRD Epic E (per-case docs) renumbered to Epic 11 as a consequence. Tier-1 strict sequence: Epic 6 must land Story 6.5 before Epic 9 begins; Epic 8 begins after Story 6.2; Epic 7's Python prefix runs in parallel with Epic 6 per Codex PHASED verdict (3 named guardrails). Full dependency graph and calendar implications below.

### Epic 6: Unified-signal-pool ensemble (formerly PRD Epic A)

Consumers analyzing BPM get a peer-voting ensemble where DSP, ML, and file-metadata each contribute as configurable peers — replacing today's sequential DSP-first → `merge` → `MetadataCorroborator.apply` → `EnsembleCombiner` pipeline. Ensemble configuration stays ergonomic via named presets (`.default`, `.dspOnly`, `.mlOnly`, `.highestConfidence`, `.weightedVoting(SignalWeights)`) without sacrificing power-user weight control. Accuracy floors (OA300 Acc1 ≥ 55/82, GiantSteps Acc1 ≥ 537/661) and performance budgets (≤ 15% OA300 regression) hold across the refactor. Pre-1.0 break authorized; KDD-A6 staged across 3 stories with `@Tag`-gated byte-equality regression floors that flip atomically to semantic equality at Stage 3.

**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-11a

**Architecture KDDs landed in this epic:** KDD-S1 (failure-mode taxonomy — `SignalParticipation` 4-state), KDD-S2 (shared feature substrate — `FeatureSubstrate.OnsetFeatures` + `OnsetFeaturesBuilder` + `MLFeatureFrames` relocation), KDD-A6 (post-merge corroboration boundary collapse, 3-stage), KDD-A1 (type taxonomy split — `SignalWeights` + `OctaveEquivalencePolicy` + `BPMSelectionPolicy` rename), KDD-A2 (typed struct shape), KDD-A3 (2-layer weight formula), KDD-A4 (`MLExecutionPolicy` 3-case enum), KDD-A4a (`ComputeBudget` carrier), KDD-A5 (`EnsemblePolicy` 5-case facade), KDD-T0 (typed-evidence trigger + `SignalParticipationTraceEntry` / `MLExecutionDecision` / `EnsembleWeightResolution` — `SignalParticipationTraceEntry` ships in same PR as KDD-S1).

**Epic 6 ↔ Epic 8 seam mitigation (Mary's contribution):** New public-API touchpoints in `AudioAnalysisService.swift` and `BPMDiagnosticTrace.swift` introduced during Epic 6 stories MUST remain `internal` or unannotated (no DocC doc comments, no README mentions). Epic 8 stories are responsible for promoting them to `public` with doc comments + README integration. Rationale: converts file-overlap into temporal-overlap that squash-merge to `main` collapses; prevents Epic 8 PRs from rewriting Epic 6 signatures and chewing review cycles. Codified in Epic 6 story-spec authoring rules.

### Epic 7: ML retraining on Tony's hand-labeled corpus (formerly PRD Epic B)

Epic 7's unconditional deliverable is a reproducible training pipeline + trained TempoCNN-style model artifact + BYOW reference at `_bmad-output/ml-models/`, regardless of whether the model clears FR-18 for bundling. Consumers wire any consumer-trained model via `BNNSTechnique(modelURL:) throws`; FR-18 reshapes from an *existence gate* to a *promotion gate* that determines whether `main` bundles the artifact by default. This framing was John's call during party-mode review — an epic whose outcome depends on a gate it might not pass is a bet, not an epic. Reshaping FR-18 to "promotion vs BYOW-only" makes Epic 7 always deliver value.

**FR-18 as promotion gate** — when the trained model clears ALL of: (a) 4 DnB sentinels correct initially, expanded to n=12 by Epic mid-point, Wilson 95% lower-bound ≥ 0.75 at close-out; (b) OA300 Acc1 > 55/82 strictly; (c) GiantSteps Acc1 ≥ 537/661; (d) `ECE_half_double < 0.10` (anchor: prior bundle ≈ 0.5); (e) Tail-error P95 (GiantSteps < 8 BPM / OA300 < 5 BPM / Sentinels < 3 BPM) → bundle on `main` inside `Sources/BoomBoomBoomKitML/Resources/`. Any failure → BYOW-only deliverable. Genre scope v1.0: breaks + DnB only; future BYOM/TYOM workflows handle other genres.

The corpus is 1,344 hand-labeled DJ tracks (Strong tier ≥0.80 = 333 + Solid tier 0.65-0.80 = 745 = 1,078 trainable) plus ~4,700 unlabeled audio for potential semi-supervised expansion. Audio-only features per FR-15 — no library-curator artifacts (playlist names, file paths, Rekordbox signals, artist embeddings). Octave-aware training loss respects the 87↔174 BPM relationship. Replaces the pulled `giantsteps_v1.mlmodelc` (which failed at calibration: softmax_max_p95 = 0.294, bimodal at 125/175).

**Phased dependency on Epic 6 (Codex PHASED verdict, thread 019e660f, with 3 named guardrails):**

- **Pre-substrate-safe (parallel with Epic 6):** corpus curation, KDD-B4 diagnostic suite, label-tier policy implementation, augmentation-vs-pretraining ablation harness, ECE_half_double instrumentation, marginal-tier categorization wiring. All Python, no Swift dependency. Begins immediately.
- **Substrate-dependent (gates on Story 6.2):** final training run that produces the bundled `.mlmodel` artifact must train against whatever feature shape Story 6.2 freezes.
- **Substrate-coupled at evaluation (gates on Story 6.5b):** FR-18 promotion-gate evaluation must run via the production runtime path (`BNNSTechnique` against the post-Epic-6 unified pool). [The genuine KDD-A6 Stage 3 flip + KDD-A5 activation landed in Story 6.5b, not 6.4 — reconciled 2026-05-30, see partyModeAmendmentsApplied.]

**Three guardrails from Codex (non-negotiable):**

1. **v1 training is scaffolding/diagnostics, NOT a promotable bundle candidate.** Any Python training that completes against the existing v1 feature contract before Story 6.2 lands is treated as research artifact — model weights and final calibration metrics are disposable; corpus prep, diagnostics, ablation harnesses, and parity plumbing are reusable.
2. **`featureSetVersion` seam blocks runtime miscalibration but v1 FR-18 metrics do NOT transfer to v2.** Any mel/FFT/log/default-weighting change in Story 6.2 invalidates Acc1, ECE, and tail-error claims. FR-18 reruns from scratch on the exact runtime feature config Story 6.2 freezes (the feature shape is set in 6.2 and consumed unchanged by the post-Epic-6 runtime).
3. **Sub-band weighting trains against ONE declared profile.** The chosen `WeightingProfile` (e.g., `.uniform` or `.subBandEmphasis(SubBandWeights)`) is encoded in model metadata alongside `featureSetVersion`. Alternate profile is ablation/augmentation only, not a co-equal training target.

**FRs covered:** FR-12, FR-13, FR-14, FR-15, FR-16, FR-17, FR-18, FR-19, FR-20, FR-21, FR-22, FR-23, FR-24, FR-25

**Architecture KDDs landed in this epic:** KDD-B1 (TempoCNN-style retain), KDD-B2 (supervised-only vs masked-mel pretraining ablation — winner picked by `ECE_half_double` per Hendrycks & Gimpel 2017 when Acc1 lands within ±2 tracks), KDD-B3 (marginal-tier reintroduction — None initial; FixMatch deferred behind 5 reopen triggers; the 241 marginal tracks consumed as failure-categorization lens + disagreement-geometry input + post-bundle regression watchlist per Mary's "name how it's used" rule, codified as stories not bullets), KDD-B4 (diagnostic suite structural requirements — artifact at `_bmad-output/ml-training/corpus-diagnostics-v1.{json,md}`), KDD-B5 (bundle vs BYOW — now resolved by FR-18 promotion-gate outcome; either path delivers something consumable).

**Industry precedent (Codex):** TFX guidance on avoiding training/serving skew via shared transforms + schema/version checks; Sculley et al. 2015 "Hidden Technical Debt in ML Systems" on configuration/data dependency risk. Parallelizing non-final ML work around unstable upstream transforms is standard practice when the upstream contract has a version seam.

### Epic 8: LUFS, beat-grid, and ModelRegistry public APIs (formerly PRD Epic C)

Three new public capabilities ship as siblings of `analyzeBPM`. `analyzeLUFS(url:options:)` exposes integrated loudness + true-peak + LRA via promotion of the existing internal `LUFSAnalyzer` to public-facing. `analyzeBeatGrid(url:options:)` extracts per-beat timestamps with strength + confidence + downbeat tri-state, sync-stable on 5+ minute tracks, playback-aligned under codec priming (Davies & Plumbley 2004-2005 Rayleigh-weighted causal DP — pure Swift+vDSP; aubio cited but not linked or transcribed). `ModelRegistry` lists bundled (if any) + user-added + known-public models with CryptoKit `SHA256.hash(data:)` integrity validation. `FeatureSubstrate.DecodedAudio` seam lets consumers extract BPM + LUFS + beat-grid from a single file decode pass.

**FRs covered:** FR-26, FR-27, FR-28, FR-29, FR-30, FR-31, FR-32, FR-33, FR-34, FR-35

**Architecture KDDs landed in this epic:** KDD-C1 (Davies & Plumbley beat-tracking baseline), KDD-C2 (tri-state `DownbeatResult` + `BeatTimestamp` with `confidence` + `strength`), KDD-C3 (`tempoAgreedWithBPMStage: Bool?` disagreement-surfacing), KDD-C4 (`DecodedAudio` shared-decode seam — depends on KDD-S2 from Epic 6), KDD-C5 (CryptoKit SHA-256 integrity), KDD-C6 (no public engine abstraction in v1.0 — protocol introduced when second concrete impl lands).

**Epic 6 ↔ Epic 8 seam responsibility (Mary's mitigation, Epic 8 side):** Epic 8 stories are responsible for promoting the internal/unannotated `AudioAnalysisService` and `BPMDiagnosticTrace` surfaces that Epic 6 introduced to `public` with DocC doc comments and README mentions. The story spec must explicitly cite which Epic 6 internal surface each Epic 8 story promotes; missing promotion = story incomplete.

### Epic 9: Demo shell + ensemble picker (split from PRD Epic D — part 1 of 2)

The demo's primary consumer-evaluation surface — a developer drops an audio file and sees the unified-signal-pool ensemble pick a BPM under one of four named presets. Builds on Epic 6 only; ships as soon as Story 6.5 closes, unblocking external feedback on the ensemble months before beat-grid (Epic 8) and per-case docs (Epic 11) land.

Primary view = audio file picker + ensemble preset picker (4 PRD presets `Default` / `DSP only` / `ML augmented` / `Trust file tags`, mapped to `EnsemblePolicy` facade per KDD-A5) + BPM result display + confidence label. Advanced sidebar (the existing `.inspector(isPresented:)` toggle from Story 5-6b, keyboard `⌘⇧D`) shows the final-state signal-pool diagnostic table — one row per contributing signal (source / BPM / confidence / weight / contribution / cluster) via SwiftUI `Table` with `sortOrder:`. Closing the sidebar restores a clean end-user surface without losing primary functionality. Every confidence-like number (BPM confidence, signal weight, source reliability) carries an explicit label per FR-44 — no bare numerics. Confidence-label discipline is established here as a cross-cutting rule that Epic 10 inherits.

**Why split this out** (John's argument during party-mode review): a consumer evaluating BoomBoomBoomKit on Epic 6's ensemble should not have to wait for Epic 8 + Epic 11 to see the ensemble demonstrated. Epic 9 is the demo's primary job — proving the ensemble. Bundling beat-grid + LUFS + per-case docs into the same epic was "three outcomes wearing a trenchcoat."

**FRs covered:** FR-36, FR-41, FR-43, FR-44

**Architecture KDDs landed in this epic:** KDD-D1 (4 PRD presets verbatim, mapped to `EnsemblePolicy` per KDD-A5), KDD-D5 (SwiftUI `Table` with `sortOrder:` for diagnostic table).

### Epic 10: Demo integration — beat-grid, LUFS, model selection, per-case docs popovers (split from PRD Epic D — part 2 of 2)

The demo's deeper-integration surface — beat-grid timeline rendering, LUFS readout panel, ML model selection from registry plus user-added models via file picker with security-scoped bookmark persistence, and strategy popovers wired to per-case authored prose from Epic 11. Builds on Epic 8 (beat-grid + LUFS + ModelRegistry public APIs) and Epic 11 (per-case docs), with FR-42 graceful degradation allowing Epic 10 to ship before Epic 11 closes (popover degrades to one-line description + repo URL fallback).

Beat-grid renders as a SwiftUI Canvas timeline with current-time scrubber plus text readout (estimated tempo, beat count, downbeat status, grid confidence) — no waveform per FR-39. LUFS displays as a primary integrated-loudness number plus a secondary panel for true-peak and LRA. Model selection draws from `ModelRegistry` (bundled + known-public + user-added); user-added models persist via security-scoped bookmark stored in `UserDefaults` (matching the Story 5-6 `MergeStrategyPersistence` precedent), with required entitlements `com.apple.security.files.user-selected.read-only` + `com.apple.security.files.bookmarks.app-scope`. Strategy popovers ("?" buttons next to ensemble preset / DSP technique / merge strategy controls) anchor SwiftUI `.popover()` to `BoomBoomBoomKitDocs.attributedString(for:id:)` resolution.

**FRs covered:** FR-37, FR-38, FR-39, FR-40, FR-42

**Architecture KDDs landed in this epic:** KDD-D2 (SwiftUI `Canvas` for timeline), KDD-D3 (`UserDefaults` for bookmark persistence — matches Story 5-6 `MergeStrategyPersistence`), KDD-D4 (SwiftUI `.popover()` for strategy help).

### Epic 11: Per-case selection-strategy docs (formerly PRD Epic E; renumbered after Epic 9 split)

Every public mode case (`BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`, `AnalysisIntensity`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `DownbeatResult`, `*Reason` enums) carries authored prose via `case.docs: AttributedString` — Xcode autocomplete surfaces documentation without string lookups. Canonical Markdown lives at `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` (~46 files), shipped via `.process` SPM resource bundle. Documentation renders offline, no network calls. Authoring style: three bold-lead paragraphs (`**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`), 200-400 words per case, 10 KB ceiling, no tables / code blocks / images / DocC symbol links / heading hierarchy. CI validator (`DocumentationValidatorTests.swift`) enforces per-rule + per-file via Swift Testing `@Test` + parameterized smoke test. FR-50 drift detection via exhaustive `switch` over `CaseIterable` fails CI when a new case lands without doc. DocC catalog at `BoomBoomBoomKit.docc/` generates `Cases/` build artifact via `make docc-transclude` from canonical Markdown; `Articles/` carries narrative comparisons (tables, code blocks allowed per DocC). `Mutex<T>` from Swift 6 `Synchronization` module backs the cache with double-checked locking (file I/O outside the lock).

**FRs covered:** FR-45, FR-46, FR-47, FR-49, FR-50, FR-52

**Architecture KDDs landed in this epic:** KDD-E1 (one protocol — `DocumentedCase` — pre-1.0 cap), KDD-E2 (per-instance `var docs` shape), KDD-E3 (raw-value default + exhaustive switch fallback for associated-value enums), KDD-E4 (`AnalysisIntensity` 10-level enum reshape with static-let aliases; bundles two breaking changes per Amelia — paired with KDD-A4a `ComputeBudget`), KDD-E5 (`Mutex<T>` cache + double-checked locking per Axiom Concurrency audit), KDD-E6 (`.process` SPM resource), KDD-E7 (minimal 2-field YAML schema + filename-matches-Swift-identifier rule), KDD-E8 (DocC + runtime Markdown as parallel surfaces with one-way transclude).

### Epic dependency graph

```
Epic 6 (unified-signal-pool — foundation; 5-story Tier-1 sequence)
   │
   ├──→ Epic 7 (ML retraining)
   │      ├─ Python prefix runs in PARALLEL with Epic 6 (corpus prep, diagnostics,
   │      │  ablation harness, ECE instrumentation, marginal-tier wiring)
   │      ├─ Substrate-dependent training gates on Story 6.2 (FeatureSubstrate)
   │      └─ FR-18 promotion-gate evaluation runs on Story 6.5b's stable runtime path
   │         [Codex PHASED verdict, 3 guardrails — see Epic 7 body]
   │
   ├──→ Epic 8 (LUFS + beat-grid + ModelRegistry)
   │      └─ Depends on Story 6.2's FeatureSubstrate (DecodedAudio shared-decode seam)
   │         Epic 8 promotes Epic-6-internal AudioAnalysisService surfaces to public.
   │
   ├──→ Epic 9 (demo shell + ensemble picker)
   │      └─ Depends on Epic 6 only (specifically Story 6.5's EnsemblePolicy facade
   │         + KDD-T0 signal-pool typed-evidence). Ships as soon as 6.5 closes.
   │
   └──→ Epic 11 (per-case selection-strategy docs)
          └─ Depends on Epic 6 enums (BPMSelectionPolicy / OctaveEquivalencePolicy /
             MLExecutionPolicy / EnsemblePolicy) + Epic 8 enum (DownbeatResult)
             + KDD-E4 AnalysisIntensity reshape (paired with KDD-A4a from Epic 6).

Epic 10 (demo integration — beat-grid + LUFS + model selection + strategy popovers)
   └─ Depends on Epic 8 (ModelRegistry, BeatGrid, LUFSReport) AND
      Epic 11 (per-case docs accessor); FR-42 graceful degradation lets Epic 10
      ship before Epic 11 closes (popover degrades to one-line fallback).
```

**Calendar implications:**
- Wave 1 (now → Story 6.4 close): Epic 6 (sequential 6.1 → 6.4) + Epic 7 Python prefix (parallel).
- Wave 2 (Story 6.4 closes → Epic 6 closes): Story 6.5 (Epic 6 type taxonomy) + Epic 8 begins (Story 6.2's substrate already landed) + Epic 11 prep (Markdown authoring style guide, scaffolder Makefile target).
- Wave 3 (Epic 6 closes): Epic 9 ships first (depends on 6.5 only — fast demo feedback loop). Epic 7 substrate-dependent training kicks off. Epic 8 + Epic 11 continue in parallel.
- Wave 4 (Epic 8 + Epic 11 close): Epic 10 ships. Epic 7 FR-18 promotion-gate evaluation runs on the now-stable runtime path; bundle-vs-BYOW decision resolves.

## Epic 6: Unified-signal-pool ensemble (stories)

5 stories in strict Tier-1 sequence per architecture's Implementation Handoff. Each story is sized for single dev-agent context; Stories 6.1 and 6.2 carry documented pressure-release valves if execution cracks.

### Story 6.1: SignalParticipation contract + typed-evidence trace + UnifiedSignalPool Stage 1 adapter

**As a** library maintainer,
**I want** the unified signal pool to expose a typed 4-state participation contract (`SignalParticipation`) and matching trace entry (`SignalParticipationTraceEntry`) that ship in the same PR as the Stage 1 `UnifiedSignalPool` internal adapter,
**So that** DSP, ML, file-metadata, and beat-grid signals share a single abstain / demotion / presence contract with zero silent evidence loss, while the frozen `CandidateMergeStrategy.merge` 41-call-site signature remains untouched and the byte-equality regression scaffold (`@Tag(.stage1Floor)`) stays green.

**Acceptance Criteria:**

**Given** new files land at `Sources/BoomBoomBoomKit/SignalPool/` (`SignalParticipation.swift`, `AbstainReason.swift`, `DemotionReason.swift`, `WeightedSignal.swift`, `SignalSource.swift`, `SignalParticipationTraceEntry.swift`, `UnifiedSignalPool.swift`),
**When** the test suite runs,
**Then** every new public type conforms to `Sendable, Hashable`; `SignalParticipation` carries exactly four cases (`.absent` / `.abstained(AbstainReason)` / `.demoted(WeightedSignal, reason: DemotionReason)` / `.present(WeightedSignal)`); and a new `SignalPoolTests.swift` suite is present.

**Given** `BPMDiagnosticTrace.swift` adds the `signalParticipationTrace: [SignalParticipationTraceEntry]` field,
**When** the 5-recipe BPM-diagnostic-trace audit (`.claude/skills/bpm-diagnostic-trace/SKILL.md`) runs against `Sources/` and `Tests/`,
**Then** all five recipes return zero matches (KDD-T0 typed-evidence trigger satisfied).

**Given** `SignalParticipationTraceEntry` ships in the same PR as `SignalParticipation` (KDD-T0 SAME-PR rule, non-negotiable),
**When** the PR commit list is reviewed,
**Then** both type files plus a populating consumer call in `AudioAnalysisService` are present in the same commit (verified via `git log -p`).

**Given** `UnifiedSignalPool.swift` is introduced as an internal-only adapter (not yet consumed by `CandidateMergeStrategy.merge`),
**When** the existing 41 `merge(_:options:)` call sites compile,
**Then** the frozen `merge` signature is unchanged at this stage and all 8 `CandidateMergeStrategy.allCases` byte-equality tests in `Tests/BoomBoomBoomKitTests/MergeByteEqualityTests.swift` pass on the OA300 sample subset.

**Given** a new `@Tag(.stage1Floor)` declaration in the Swift Testing `Tag` extension and applied to the byte-equality regression tests,
**When** `swift test --filter-tag stage1Floor` runs in CI,
**Then** the byte-equality regression scaffold passes at 100% (Stage 1 floor referenced by Story 6.3).

**Given** the per-source contract assertion in `SignalPoolTests`,
**When** DSP analysis runs at any `AnalysisIntensity` level,
**Then** `SignalSource.dsp` produces ≥ 1 of `{.present, .abstained, .demoted}` per analysis — never `.absent`.

**Given** `Codable` round-trip tests for all four `SignalParticipation` cases,
**When** each case (including `.present(WeightedSignal)` and `.demoted(WeightedSignal, reason: DemotionReason)` payloads) round-trips through `JSONEncoder`/`JSONDecoder`,
**Then** the decoded value byte-equals the encoded value (NaN-safe via `BoomBoomBoomKitTestSupport.Double.bitEqual(to:)`).

**FRs covered:** FR-1, FR-8, FR-9.
**KDDs implemented:** S1, T0, A6 Stage 1.
**Pressure-release valve (Winston):** If implementation cracks under S1 + T0 + A6 Stage 1 combined scope, split into Story 6.1a (`SignalParticipation` + `SignalParticipationTraceEntry`) and Story 6.1b (`UnifiedSignalPool` Stage 1 adapter). Document the split in `_bmad-output/implementation-artifacts/6-1-pressure-release.md` only if executed.

### Story 6.2: FeatureSubstrate namespace + OnsetFeaturesBuilder + MLFeatureFrames relocation

**As a** library maintainer,
**I want** decode + onset-extraction consolidated into a single `FeatureSubstrate` namespace consumed by DSP, beat-grid, and ML feature pipelines via `OnsetFeaturesBuilder.build(decoded:weighting:)`,
**So that** the substrate cannot fork between subsystems, FR-21 train/runtime parity is enforced via the `featureSetVersion` drift-detection seam, and Epic 7's ML training + Epic 8's beat-grid step 11 both consume identical features.

**Acceptance Criteria:**

**Given** new files land at `Sources/BoomBoomBoomKit/FeatureSubstrate/` (`DecodedAudio.swift`, `OnsetFeatures.swift`, `OnsetFeaturesBuilder.swift`, `WeightingProfile.swift`, `SubBandWeights.swift`, `SubBandCutoff.swift`, `AudioCodec.swift`, `PrimingInfo.swift`, `TensorLayout.swift`, `MLFeatureFrames.swift`),
**When** the test suite runs,
**Then** `FeatureSubstrate.OnsetFeatures` carries the 11 fields from architecture KDD-S2 (`frames`, `melBands`, `logMelData`, `tensorLayout`, `weighting`, `parameters`, `featureSetVersion`, …) and the throwing-init invariants enforce `count == melBands * frames`, both dimensions positive, total ≤ `8_388_608` floats.

**Given** `MLFeatureFrames.swift` is relocated from `Sources/BoomBoomBoomKitML/` to `Sources/BoomBoomBoomKit/FeatureSubstrate/`,
**When** all `import BoomBoomBoomKitML` sites that previously referenced `MLFeatureFrames` are updated to import from `BoomBoomBoomKit` core,
**Then** `BoomBoomBoomKitML` no longer publicly exports `MLFeatureFrames` (verified via `swift package describe`), and `BNNSTechnique.featurize` in the ML target imports the relocated type from core.

**Given** `OnsetFeaturesBuilder.build(decoded:weighting:)` is the single shared code path called by `BPMAnalyzer.estimateBPM`, `BeatGridAnalyzer.estimateBeatGrid` (Epic 8 placeholder consumer OK), and `BNNSTechnique.featurize`,
**When** any of the three consumers requests features,
**Then** all three receive byte-identical `OnsetFeatures` for the same `(decoded, weighting)` input — verified by `FeatureSubstrateTests.crossConsumerByteIdentity`.

**Given** `WeightingProfile` carries `.uniform` and `.subBandEmphasis(SubBandWeights)`,
**When** `OnsetFeaturesBuilder.build(decoded:weighting: .uniform)` runs against the OA300 sample subset,
**Then** the output is byte-identical to the current `BPMAnalyzer` mel-spectrogram step 3 output (regression scaffolding — pre-1.0 break authorized at the type level, not at the byte-level for default behavior).

**Given** `featureSetVersion: String` is initialized to `"v1"` matching the current `MLFeatureFrames.featureSetVersion`,
**When** any field of `OnsetFeatures.Parameters` (fftSize, hopSize, melFmin, melFmax, logCompressionScale) or `WeightingProfile` defaults change in any future story,
**Then** `featureSetVersion` MUST bump and `FeatureSubstrateTests.featureSetVersionLocked` asserts the bump.

**Given** aubio-inspired sub-band weighting is implemented as a `Float` weight vector applied during the existing `MelFilterbank.applyMatrix` (`vDSP_mmul`),
**When** code review inspects the implementation,
**Then** no aubio source is transcribed (GPL fence intact); only `///` doc comments cite `aubio/src/onset/onset.c` and Davies & Plumbley 2007 papers; no biquad cascade is introduced.

**Given** Mary's seam-mitigation rule for Epic 6 → Epic 8,
**When** any new public-API surface lands in `AudioAnalysisService.swift` or `BPMDiagnosticTrace.swift` during this story,
**Then** the surface remains `internal` or unannotated — Epic 8 stories promote them.

**FRs covered:** FR-1, FR-21.
**KDDs implemented:** S2.
**Pressure-release valve (Amelia):** Before the story-spec lock, the implementing dev-agent SHOULD run `rg "MLFeatureFrames" Sources/ Tests/` and report the hit count. If > 20, split into Story 6.2a (relocation + import updates) and Story 6.2b (`OnsetFeatures` introduction). Not pre-emptively applied. Document the deviation in `_bmad-output/implementation-artifacts/6-2-pressure-release.md`.

### Story 6.3: KDD-A6 Stage 2 — migrate MetadataCorroborator + runPreCorroborationPipeline to consume the unified pool

**As a** library maintainer,
**I want** `MetadataCorroborator.apply` and `runPreCorroborationPipeline` migrated to consume the `UnifiedSignalPool` from Story 6.1,
**So that** metadata becomes a peer voter within the pool (per FR-7), while the frozen `merge` 41-call-site signature remains unchanged for one more story, preserving the byte-equality regression scaffold across the breaking change.

**Acceptance Criteria:**

**Given** `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` (relocated or updated in place) is rewritten as a caseless-enum namespace,
**When** the test suite runs,
**Then** `MetadataCorroborator` emits `SignalParticipation` values for each parsed metadata tag and writes them into the `UnifiedSignalPool` via an internal helper (no more `apply(to:input:)` method on the legacy candidate array).

**Given** the frozen `CandidateMergeStrategy.merge(_:options:)` signature is unchanged at this stage,
**When** the 41 existing call sites compile,
**Then** zero signature changes are observed (grep for the `func merge(` declaration returns the same parameter list as post-Story-6.2 land).

**Given** `@Tag(.stage2Floor)` is added to the Swift Testing `Tag` extension and applied to the byte-equality regression tests that also carry `@Tag(.stage1Floor)`,
**When** both `swift test --filter-tag stage1Floor` AND `swift test --filter-tag stage2Floor` run in CI,
**Then** both pass 100%. Stage 2 floor = Stage 1 measurement.

**Given** `runPreCorroborationPipeline`'s internal data shape changes,
**When** code review inspects the change,
**Then** the pipeline emits `UnifiedSignalPool` instead of the legacy `[BPMResult.Candidate]` array, and `MetadataCorroborator` consumes the pool rather than wrapping it.

**Given** the existing Story 3-6 byte-equality opt-out test for `Options.metadataPolicy = .disabled`,
**When** the test runs at Stage 2,
**Then** the output is byte-identical to the pre-Story-3-6 baseline (NaN-safe per `Double.bitEqual(to:)`).

**Given** Mary's seam-mitigation rule,
**When** any new public-API surface lands in `AudioAnalysisService.swift`,
**Then** the surface remains `internal` or unannotated — Epic 8 stories promote them.

**FRs covered:** FR-7 (data-shape migration; substantive consumer fires in Story 6.5 — corrected 2026-05-29: the metadata-as-peer-voter consumer was reallocated from 6.4 to 6.5 alongside the pool-authority restructuring).
**KDDs implemented:** A6 Stage 2.
**Pressure-release valve:** None. Story is intentionally narrow.

### Story 6.4: KDD-A6 Stage 3 — atomic byte→semantic equality flip

**As a** library maintainer,
**I want** `CandidateMergeStrategy.merge`'s parameter type flipped from the legacy `[BPMResult.Candidate]` array to `UnifiedSignalPool` in a single mechanical PR, with byte-equality tests atomically replaced by semantic-equality tests in the same commit,
**So that** the unified-signal-pool architecture lands as one auditable atomic change in `git log -p`, with no week-long red intervals between byte-equality going away and semantic-equality arriving.

**Acceptance Criteria:**

**Given** Story 6.3 is merged to develop with `@Tag(.stage2Floor)` passing,
**When** the Stage 3 PR opens,
**Then** the PR contains exactly one commit (or one mechanical squash) that BOTH (a) flips `merge`'s parameter type at all 41 call sites, AND (b) deletes `Tests/BoomBoomBoomKitTests/MergeByteEqualityTests.swift`, AND (c) introduces `Tests/BoomBoomBoomKitTests/MergeSemanticEqualityTests.swift` — all in the same commit.

**Given** `MergeSemanticEqualityTests.swift` defines semantic-equality assertions over the new `UnifiedSignalPool` input shape,
**When** the test suite runs,
**Then** all 8 `CandidateMergeStrategy.allCases` produce results equivalent to the pre-refactor semantic output on the OA300 sample subset (Acc1 stays at 58/82 ± tolerance; Acc2 stays at 74/82).

**Given** `make benchmark` and `make benchmark-giantsteps` run after Stage 3 lands,
**When** OA300 + GiantSteps benchmarks complete,
**Then** OA300 Acc1 ≥ 55/82 (FR-10 floor) AND GiantSteps Acc1 ≥ 537/661 (FR-10 floor).

**Given** `make perf-benchmark` runs after Stage 3,
**When** OA300 wall-clock is measured at default intensity,
**Then** regression is ≤ 15% vs the pre-Stage-3 baseline recorded in `_bmad-output/perf-baselines/`.

**Given** the deleted `@Tag(.stage1Floor)` and `@Tag(.stage2Floor)` tagged tests,
**When** `swift test --filter-tag stage1Floor` or `--filter-tag stage2Floor` runs,
**Then** zero tests match.

**Given** the `EnsembleCombiner` type from the prior architecture,
**When** code review inspects the new `merge` call graph,
**Then** `EnsembleCombiner` is removed (per pre-1.0 break authorization), its branches inlined behind a testable seam in `AudioAnalysisService`. _(Reconciled 2026-05-30 to the delivered byte-inert 6.4b scope: making `merge` operate directly on the pool — the pool-authoritative `select(from: pool)` end-state — is Story 6.5, consistent with the FRs/KDDs lines below. 6.4b removes the arbiter without changing `merge`'s pre-pool signature.)_

**FRs covered:** FR-10, FR-11. (Reallocated 2026-05-29 by operator sign-off: FR-1/FR-2/FR-6/FR-7 moved to Story 6.5 — 6.4b is the corroboration-boundary collapse + atomic byte→semantic test swap and does NOT make the pool authoritative; the `merge`-parameter flip + `select(from: pool)` + metadata-as-peer-voter land in 6.5. See the 6-4 spec DD #2/#11.)
**KDDs implemented:** A6 Stage 3 (corroboration-boundary collapse + atomic test-floor flip; pool-authoritative selection deferred to 6.5 / KDD-A1).
**Pressure-release valve:** None for the corroboration-collapse + test-swap pairing (atomic, one commit). NOTE (2026-05-29 operator sign-off): the original "flip merge's parameter type at 41 call sites" headline was superseded — `merge` runs pre-pool, so that restructuring belongs to 6.5; this is a scope deferral, not a phantom correction.

### Story 6.5: Type taxonomy split — SignalWeights + OctaveEquivalencePolicy + BPMSelectionPolicy rename + KDD-A2/A3/A4/A4a/A5 derivations

**As a** consumer of BoomBoomBoomKit,
**I want** named ensemble presets via the `EnsemblePolicy` facade, raw per-source weight control via the `SignalWeights` struct, configurable octave-equivalence policy, explicit ML execution policy, and a `ComputeBudget` carrier for the intensity dial,
**So that** the 4 PRD ensemble presets stay ergonomic while power users retain full per-source control — all backed by typed Swift enums and structs that Epic 11 documents via `DocumentedCase`.

**Acceptance Criteria:**

**Given** `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` is renamed to `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift`,
**When** the rename is applied across all 41 call sites + all references in `Sources/` and `Tests/`,
**Then** zero stale `CandidateMergeStrategy` references remain (verified by `grep -r CandidateMergeStrategy Sources/ Tests/`), and the unit-test invariant flips from `CandidateMergeStrategy.allCases.count == 8` to `BPMSelectionPolicy.allCases.count == 8`.

**Given** new file `Sources/BoomBoomBoomKit/SignalPool/SignalWeights.swift`,
**When** the test suite runs,
**Then** `SignalWeights` is a `Sendable, Hashable` struct with fields `dsp: Double` / `ml: Double` / `fileMetadata: Double` / `beatGrid: Double` (defaults all 1.0) and a `.default` static-let convenience.

**Given** new file `Sources/BoomBoomBoomKit/OctaveEquivalencePolicy.swift`,
**When** the test suite runs,
**Then** `OctaveEquivalencePolicy` is a `String, CaseIterable, Sendable, Hashable` enum with exactly 3 cases (`.collapseToFundamental`, `.octaveAwareWithPenalty`, `.exactMatchOnly`) and `OctaveEquivalencePolicy.allCases.count == 3`.

**Given** new files `Sources/BoomBoomBoomKit/MLExecutionPolicy.swift` and `Sources/BoomBoomBoomKit/ComputeBudget.swift`,
**When** the test suite runs,
**Then** `MLExecutionPolicy` is a `Sendable, Hashable` enum with 3 cases (`.never`, `.always`, `.whenDSPConfidenceBelow(Double)`) plus a static-let alias `.default = .whenDSPConfidenceBelow(0.85)`; `ComputeBudget` is a `Sendable, Hashable` struct with `dspFraction: Double` / `mlFraction: Double` / `beatGridFraction: Double` fields, all defaulting to 1.0, each fraction silently clamped to `[0.0, 1.0]` at construction.

**Given** `Sources/BoomBoomBoomKit/EnsemblePolicy.swift` is updated,
**When** the test suite runs,
**Then** `EnsemblePolicy` is a `Sendable, Hashable` enum with exactly 5 cases (`.default`, `.dspOnly`, `.mlOnly`, `.highestConfidence`, `.weightedVoting(SignalWeights)`).

**Given** the `effectiveVote` computation inside `BPMSelectionPolicy.merge`,
**When** any signal's vote weight is computed,
**Then** the 2-layer formula `signalConfidence × signalWeights[source]` is applied (KDD-A3 — no automatic cross-source calibration in v1.0).

**Given** the FR-11a intensity-policy interaction,
**When** `Options.mlExecutionPolicy = .always` AND `Options.intensity = .fastest`,
**Then** the explicit ML policy wins (intensity is the budget hint; explicit policy is the override). `SignalPoolTests.intensityPolicyOverride` enforces this.

**Given** Story 6.4 atomically replaced the byte-equality scaffold with `MergeSemanticEqualityTests`,
**When** Story 6.5 lands,
**Then** semantic-equality tests still pass — Story 6.5 is rename + new-type introduction only; no semantic change to `merge`'s behavior.

**Given** the architecture's root-ceiling 35-file tripwire codified in step-06,
**When** Story 6.5 closes,
**Then** `find Sources/BoomBoomBoomKit -maxdepth 2 -type f | wc -l` returns ≤ 35; if exceeded, the closing PR MUST surface a subdir-promotion decision (move a cohesive ≥ 5-file group into a new subfolder per the architecture's "subdir when ≥ 5 cohesive files" rule) before merge. The same closing PR additionally asserts `find Tests/BoomBoomBoomKitTests -maxdepth 1 -type f -name "*.swift" | wc -l` returns ≤ 70; if exceeded, a follow-up story to organize tests into thematic subfolders is filed (not blocking Story 6.5 merge, but tracked).

**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-11a. (FR-1 unified-pool selection + FR-7 metadata-as-peer-voter reallocated from Story 6.4 on 2026-05-29 — they fire here with `BPMSelectionPolicy.select(from: pool)` + `SignalWeights`; this is also where 6.4b's deferred `WeightedSignal.score` read-seam + `SignalParticipation.score` accessor land.)
**KDDs implemented:** A1, A2, A3, A4, A4a, A5.
**Pressure-release valve (Amelia, post-party-mode review):** If the rename across 41 call sites + 4 new types + 1 type update (`EnsemblePolicy`) exceeds a single dev-agent context window, split into Story 6.5a (rename `CandidateMergeStrategy → BPMSelectionPolicy` + introduce `SignalWeights`) and Story 6.5b (`OctaveEquivalencePolicy` + `MLExecutionPolicy` + `ComputeBudget` + `EnsemblePolicy` 5-case facade update). Document the deviation in `_bmad-output/implementation-artifacts/6-5-pressure-release.md`.

## Epic 7: ML retraining on Tony's hand-labeled corpus (stories)

7 stories phased per Codex PHASED verdict: Stories 7.1-7.4 are pre-substrate-safe and may run in parallel with Epic 6; Story 7.5 gates on Story 6.2's `FeatureSubstrate.OnsetFeatures`; Story 7.6 (FR-18 promotion-gate evaluation) gates on Story 6.5b's stable runtime path. The three non-negotiable guardrails — (1) v1 features are scaffolding/diagnostics only, (2) `featureSetVersion` bumps invalidate FR-18 metrics, (3) one declared `WeightingProfile` per trained model — surface as ACs in Stories 7.3 and 7.5.

### Story 7.1: Corpus diagnostics + label-tier policy + split-contamination audit

**As a** library maintainer,
**I want** the 1,344-track hand-labeled corpus diagnosed (label-source bias, octave ambiguity, confidence calibration of the 5 disagreement signals, cluster stability, representative manual-review findings) and tiered (Strong 333 / Solid 745 / Marginal 241 / Reject), with `corpus_splits.json` audited for related-recording leakage across train/val/test boundaries,
**So that** training begins only on evidence-reviewed data with a documented label-tier policy and split-contamination guards, satisfying KDD-B4's "produced + reviewed BEFORE training begins" gate.

**Acceptance Criteria:**

**Given** `_bmad-output/ml-training/corpus-diagnostics-v1.json` and `_bmad-output/ml-training/corpus-diagnostics-v1.md` are produced,
**When** the diagnostics generator runs against the 1,344 hand-labeled tracks under `_bmad-output/ml-training/tony-corpus/`,
**Then** the JSON carries fields `labelSourceBias` (per-signal agreement matrix across the 5 disagreement vectors), `octaveAmbiguityRate` (fraction of tracks where Rekordbox vs DSP disagree by exactly 2:1 — Tony's half-tempo-labeling pattern), `confidenceCalibrationByTier` (per-tier mean confidence + ECE), `clusterStability` (k-means stability score across 5 seeds), and `representativeManualReviewFindings` (≥ 10 named tracks with curator notes); the Markdown sibling is reviewer-readable.

**Given** the label-tier policy is documented in `_bmad-output/ml-training/label-tier-policy-v1.md`,
**When** the policy is reviewed,
**Then** it codifies Strong (≥0.80 confidence, 333 tracks) + Solid (0.65-0.80, 745 tracks) as the initial supervised training set (1,078 trainable per FR-14), declares Marginal (0.55-0.65, 241 tracks) excluded from initial supervised training, and references KDD-B3's 5 reopen triggers verbatim as the reintroduction gate.

**Given** the audio-only model constraint (FR-15),
**When** the tier policy is reviewed,
**Then** the document explicitly enumerates forbidden inputs (playlist names, file path components, Rekordbox-specific signals, DSP candidate scores, artist embedding, ID3 BPM) and confirms they are excluded from any future feature-pipeline contract.

**Given** the split-contamination audit (FR-22),
**When** `_bmad-output/ml-training/corpus_splits.json` is generated and `scripts/audit-corpus-splits.py` runs against it,
**Then** zero alternate-encode pairs, edit pairs, or near-duplicate fingerprints (audio-hash within 0.95 cosine) cross train/val/test boundaries; the 4 named DnB triplet family members from `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` are confirmed absent from all training and validation splits (held-out per FR-17).

**Given** the corpus diagnostics gate (KDD-B4),
**When** Story 7.5 (substrate-bound training) attempts to start,
**Then** Story 7.1's artifacts MUST exist on disk and a reviewer-signoff line MUST be present in `_bmad-output/ml-training/corpus-diagnostics-v1.md` — absent either, training is blocked.

**Given** the leave-artist-out evaluation slice is part of the split contract,
**When** `corpus_splits.json` is audited,
**Then** a `leaveArtistOut: {trainArtists: [...], heldOutArtists: [...]}` block is present and disjoint, sized to ≥ 10% of the trainable set, for use by Story 7.6's FR-23 octave-policy-consistency report.

**Given** Mary #3's n=12 DnB-sentinel-expansion requirement (FR-18 gate (a) at Epic close-out),
**When** Story 7.1 closes,
**Then** an additional 8 DnB tracks are curated as expanded sentinels following a stratified rule documented at `_bmad-output/ml-training/expanded-sentinels-curation.md`: 2 tracks per DnB subgenre (e.g., neurofunk, jungle, jump-up, liquid) stratified by source-confidence quintile from the Strong + Solid tiers; the 12-track hash-list (4 original + 8 expanded) is committed to `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/12-dnb-sentinels-expanded.json` in **JAMS format** (JSON Annotated Music Specification — `tempo` namespace, `file_metadata` carries artist/title/duration, `annotation_metadata.curator` documents who selected the track and why); held-out-from-training verified by `scripts/audit-corpus-splits.py --check-sentinels-against 12-dnb-sentinels-expanded.json` returning zero contamination. The curation rule explicitly favors **representative** tracks (covering each DnB subgenre + the half/double tempo-band Tony's labeling pattern reveals) over adversarial-hard tracks (which would poison the Wilson lower-bound by selection).

**FRs covered:** FR-12, FR-14, FR-15, FR-17 (expanded sentinel set), FR-22.
**KDDs implemented:** B4 (artifact + review gate), B3 (reopen-trigger reference, not yet invoked).
**Pressure-release valve:** If the split-contamination audit surfaces > 5% leakage requiring re-tiering, split into Story 7.1a (diagnostics + policy) and Story 7.1b (split rebuild + audit); document the split in `_bmad-output/implementation-artifacts/7-1-pressure-release.md`. If the n=12 sentinel expansion cannot reach 2-per-subgenre coverage due to corpus thinness in some subgenres, drop to balanced ≥ 1-per-subgenre + document the asymmetry in `expanded-sentinels-curation.md` — but NEVER substitute easy non-DnB tracks for the missing slots (defeats the sentinel purpose).

### Story 7.2: Non-Rekordbox audio expansion + provenance-clean tiering

**As a** library maintainer,
**I want** the ~4,700 unlabeled audio files outside Rekordbox `<COLLECTION>` surveyed, fingerprinted, and tiered as a semi-supervised pool with strict provenance filters (DSP + generic file-metadata agreement within 2-3% after octave normalization → secondary supervised tier; path/playlist/Rekordbox-derived signals forbidden as expansion-tier evidence),
**So that** Epic 7's KDD-B2 ablation can fairly compare supervised-only-with-augmentation vs masked-mel pretraining over a clean expansion pool, with a source-distribution report (genre/tempo/source/tier counts before-and-after) produced for review per FR-13.

**Acceptance Criteria:**

**Given** `scripts/non-rekordbox-survey.py` runs against the ~4,700 audio files under `_bmad-output/ml-training/tony-corpus/non-rekordbox/`,
**When** the script completes,
**Then** `_bmad-output/ml-training/non-rekordbox-survey.json` is produced with per-file fields `path` (relative), `audioHash`, `dspBPM`, `dspConfidence`, `fileMetadataBPM` (ID3v2.3/v2.4 TBPM, MP4 tmpo, FLAC Vorbis BPM= only), `agreementAfterOctaveNormalization: Bool`, `tier` (`secondarySupervised` / `unsupervisedPool` / `reject`).

**Given** the provenance-filter contract (FR-13),
**When** the survey runs,
**Then** path components, parent directory names, and any Rekordbox-derived attribute (XML-cross-referenced track IDs, playlist membership) are NEVER consulted as tiering evidence — verified by the audit at `_bmad-output/ml-training/non-rekordbox-provenance-audit.md`, which enumerates forbidden columns and confirms zero appearances in tiering logic.

**Given** the 2-3% agreement tolerance for secondary-supervised promotion,
**When** a file's DSP BPM and file-metadata BPM are compared,
**Then** agreement is evaluated as `|dspBPM - fileMetadataBPM| / max(dspBPM, fileMetadataBPM) ≤ 0.03` after octave normalization (`x` and `2x` and `x/2` all treated as agreement); files passing → `secondarySupervised` tier with the lower-confidence label written to `bpm_truth`, files failing → `unsupervisedPool` (label-free), files with no parseable file metadata AND no DSP candidate above 0.40 confidence → `reject`.

**Given** the source-distribution report (FR-13),
**When** `_bmad-output/ml-training/non-rekordbox-source-distribution.md` is produced,
**Then** it presents before-and-after tables of (a) genre proxy (file path hint converted to coarse buckets — *retained only in the report, NOT as tiering input*), (b) tempo distribution histogram (60-200 BPM in 5 BPM bins), (c) source/format distribution (MP3/FLAC/M4A/WAV counts), (d) tier counts; the report is reviewer-readable and reference-linked from `corpus-diagnostics-v1.md`.

**Given** the four DnB sentinel tracks (FR-17),
**When** any non-Rekordbox survey row references a Charly / Faraday_Bunker / Yin Yang / HEFT_Anagram 6 audio hash,
**Then** the row is force-set to `tier = reject` regardless of metadata agreement and a warning is logged — held-out sentinels MUST NOT enter expansion pools.

**Given** the secondary-supervised pool is consumed by Story 7.3's ablation harness,
**When** the harness loads the expansion data,
**Then** it reads only the `tier == secondarySupervised` subset; the `unsupervisedPool` subset is reserved for KDD-B2's masked-mel pretraining variant in Story 7.3.

**FRs covered:** FR-13, FR-15 (forbidden-input enforcement), FR-17 (sentinel exclusion).
**KDDs implemented:** B4 (source-distribution report folded into corpus diagnostics).
**Pressure-release valve:** None.

### Story 7.3: KDD-B2 ablation harness + octave-aware loss + WeightingProfile declaration (v1 scaffolding)

**As a** library maintainer,
**I want** the KDD-B2 head-to-head ablation harness wired with both training paths — (a) supervised-only-with-augmentation [tempo-class-preserving time-stretch + octave-aware pitch-shift + noise injection] and (b) masked-mel pretraining → fine-tune — running against the v1 feature pipeline as scaffolding, with an octave-aware training loss (FR-16) and a single declared `WeightingProfile` per training run (Guardrail 3),
**So that** the ablation comparison axes (accuracy + inference latency + memory footprint + ECE / reliability diagram / softmax entropy + leave-artist-out delta vs random-split delta) are measurable end-to-end on v1 before Story 7.5 swaps in the substrate-locked v2 features.

**Acceptance Criteria:**

**Given** `_bmad-output/ml-training/ablation/` contains entrypoints `train_supervised_augmented.py` and `train_masked_mel_pretrain.py`,
**When** either script runs with `--seed 42 --epochs 60 --batch-size 32`,
**Then** the model checkpoints land at `_bmad-output/ml-training/ablation/{variant}/model.pt` with sibling `model_metadata.json` recording `architecture: "TempoCNN"` (per KDD-B1 — architecture retained), `seed`, `epochCount`, `corpusVersionHash`, `featureSetVersion: "v1"`, `weightingProfile`, and `trainingVariant: "supervisedAugmented" | "maskedMelPretrain"`.

**Given** the octave-aware loss (FR-16),
**When** the loss function is reviewed in either training script,
**Then** it penalizes octave-equivalent predictions (target `T`, prediction `T`, `2T`, `T/2`) with a documented per-class weighting that does not collapse to 0 — the loss formula is recorded in `_bmad-output/ml-training/ablation/octave-aware-loss.md` with citations and the weighting constants used.

**Given** Guardrail 3 (one declared `WeightingProfile` per trained model),
**When** any ablation run starts,
**Then** the run rejects (raises `ValueError`) unless `--weighting-profile {uniform|sub-band-emphasis}` is explicitly passed, and the chosen profile is encoded in `model_metadata.json` alongside `featureSetVersion`; alternate-profile training is permitted only as augmentation under `--augmentation-profile`, never as the declared profile.

**Given** Guardrail 1 (v1 training is scaffolding, NOT a promotable bundle candidate),
**When** Story 7.3 checkpoints are produced,
**Then** `model_metadata.json` carries `promotable: false` and `scaffoldingNote: "v1 features — FR-18 metrics do not transfer to v2"` — surfaced verbatim in the file and asserted by `tests/test_metadata_schema.py`.

**Given** the comparison axes of KDD-B2,
**When** both variants complete their 60-epoch runs against the Story-7.1 splits,
**Then** `_bmad-output/ml-training/ablation/kdd-b2-comparison-v1.md` is produced reporting per-variant: (a) Acc1 on validation, (b) inference wall-clock per file in ms, (c) peak memory footprint in MB, (d) ECE + reliability diagram + softmax entropy histogram, (e) leave-artist-out Acc1 minus random-split Acc1 (the calibration tiebreaker delta).

**Given** the Hendrycks & Gimpel 2017 calibration tiebreaker (Mary's rule, KDD-B2),
**When** the two variants land within ±2 tracks on Acc1,
**Then** the variant with lower `ECE_half_double` wins the ablation; the winner-selection clause is recorded in `kdd-b2-comparison-v1.md` with the numeric values surfaced.

**Given** the audio-only constraint (FR-15),
**When** the training scripts' feature pipelines are reviewed,
**Then** zero references to playlist names, file paths, Rekordbox attributes, DSP candidate scores, artist embeddings, or ID3 BPM exist in the feature loaders — verified by `rg -i "playlist|path|rekordbox|artist|id3" _bmad-output/ml-training/ablation/*.py` returning zero hits in feature-loading code paths (comments and docstrings excluded).

**FRs covered:** FR-15, FR-16, FR-20 (reproducibility scaffolding), FR-23 (octave policy declared, consistency proved in Story 7.6).
**KDDs implemented:** B1, B2.
**Pressure-release valve:** If wall-clock on the supervisedAugmented 60-epoch run exceeds 8 hours on the dev workstation, split into Story 7.3a (harness + supervisedAugmented only) and Story 7.3b (maskedMelPretrain variant); document the split in `_bmad-output/implementation-artifacts/7-3-pressure-release.md` and confirm KDD-B2 comparison still occurs before Story 7.5 locks the ablation winner.

### Story 7.4: Marginal-tier "name how it's used" wiring per KDD-B4 / Mary's rule

**As a** library maintainer,
**I want** the 241 Marginal-tier tracks (0.55-0.65 confidence) wired into exactly three named uses with acceptance-criteria-grade artifacts — (a) failure-categorization lens distinguishing half/double vs DSP failure vs metadata conflict via the original 5-signal disagreement vectors, (b) disagreement-geometry input folded into `corpus-diagnostics-v1.json`, (c) post-bundle regression watchlist preserved in `_bmad-output/ml-training/marginal-watchlist.json`,
**So that** KDD-B4's "name how it's used" rule (Mary) is satisfied with concrete artifacts rather than bullets, and the KDD-B3 reopen triggers have empirical inputs ready when invoked.

**Acceptance Criteria:**

**Given** the failure-categorization lens (use a),
**When** `scripts/marginal-failure-categorize.py` runs against the 241 Marginal tracks,
**Then** `_bmad-output/ml-training/marginal-failure-categorization.json` is produced with per-track fields `tonyLabel`, `dspBPM`, `rekordboxBPM`, `idTagBPM`, `gridBPM`, `duration-derived-BPM`, plus a categorical `failureCategory` ∈ {`halfDoubleOctave`, `dspFailure`, `metadataConflict`, `harmonicAmbiguity`, `unresolved`}; the assignment rule is documented in the sibling `.md` and uses the 5-signal disagreement vector (no model predictions consulted — categorization is dataset-side). Story 7.4 ALSO produces a deterministic `failureCategory → expectedFailureMode` mapping table at `_bmad-output/ml-training/expected-failure-mode-mapping.md` documenting which failure modes the bundled model is expected to surface per category (e.g., `halfDoubleOctave → off-by-octave`, `metadataConflict → DSP-wins-over-stale-tag`).

**Given** the disagreement-geometry input (use b),
**When** the failure-categorization JSON is folded into `corpus-diagnostics-v1.json`,
**Then** the diagnostics carry a `marginalTierDisagreementGeometry` block reporting (a) category counts, (b) per-category mean DSP confidence, (c) per-category half/double-rate, (d) per-category proximity to nearest Strong-tier neighbor in audio-hash space — for KDD-B3 reopen-trigger #3 ("error analysis shows many failures near marginal-style ambiguity") to query later.

**Given** the post-bundle regression watchlist (use c),
**When** `_bmad-output/ml-training/marginal-watchlist.json` is produced,
**Then** it carries the 241 Marginal track identifiers + their `failureCategory` + `expectedFailureMode` populated NOT as an empty stub but mechanically derived from the Story 7.4 `failureCategory → expectedFailureMode` mapping table (one row per Marginal track, every `expectedFailureMode` non-null at Story 7.4 close per Mary's "name how it's used" rule — the empty-stub-deferred-to-Story-7.6 pattern is explicitly REJECTED because it turns Story 7.6's verification into null-grading-null).

**Given** KDD-B3's "None initial" policy (FR-14),
**When** any training script under `_bmad-output/ml-training/ablation/` or Story 7.5's substrate-bound run is reviewed,
**Then** Marginal-tier tracks are excluded from the train and validation splits — verified by `scripts/audit-corpus-splits.py --reject-marginal` returning zero contamination, and by `corpus_splits.json` carrying a `marginalTierExclusion: true` assertion.

**Given** the 5 KDD-B3 reopen triggers,
**When** the policy doc at `_bmad-output/ml-training/label-tier-policy-v1.md` is reviewed,
**Then** each trigger is mapped to a concrete artifact: (1) Strong/Solid plateau → `kdd-b2-comparison-v1.md` validation curves; (2) leave-artist-out underperforms → Story 7.6 FR-23 report; (3) error analysis near marginal ambiguity → `marginalTierDisagreementGeometry` block above; (4) masked-mel helps materially → KDD-B2 ablation outcome; (5) stable high-confidence Marginal predictions → `marginal-watchlist.json` regression table from Story 7.6.

**Given** Mary's "MUST be stories with acceptance criteria, not bullets" rule (KDD-B4),
**When** code review inspects the three named uses,
**Then** each use (a/b/c) ships with a concrete file path and a populated artifact (not a placeholder); use-(c)'s artifact may carry the empty `expectedFailureMode` stub for tracks pending Story 7.6 evaluation, but the file structure and tracking IDs MUST be present at Story 7.4 close.

**FRs covered:** FR-14 (Marginal exclusion + reintroduction policy operationalized).
**KDDs implemented:** B3 (reopen-trigger evidence wiring), B4 (Mary's "name how it's used" rule satisfied).
**Pressure-release valve:** None.

### Story 7.5: Substrate-bound TempoCNN training run on FeatureSubstrate.OnsetFeatures (v2)

**As a** library maintainer,
**I want** the final TempoCNN training run executed against the substrate-locked `FeatureSubstrate.OnsetFeatures` from Story 6.2 (v2 features), with the KDD-B2 ablation winner selected, the declared `WeightingProfile` encoded in `model_metadata.json` alongside `featureSetVersion: "v2"`, and Swift/Python feature-pipeline parity verified to the documented numeric tolerance,
**So that** the model under FR-18 evaluation in Story 7.6 trained on byte-identical features to what `BNNSTechnique.featurize` produces at runtime, satisfying FR-21 train/runtime parity and respecting Guardrail 2 (v1 metrics do not transfer; this is the run that produces transferable metrics).

**Acceptance Criteria:**

**Given** Story 6.2 has merged to develop and `FeatureSubstrate.OnsetFeatures` exists in `Sources/BoomBoomBoomKit/FeatureSubstrate/`,
**When** Story 7.5 training starts,
**Then** the Python feature loader at `_bmad-output/ml-training/feature_substrate_v2.py` consumes features dumped by the Swift CLI fixture extractor (`_bmad-output/ml-training/swift_feature_extractor/`) producing the SAME `OnsetFeatures` byte layout — verified by the 4-stage parity harness (`make ml-parity`) reporting zero deltas beyond the documented `±1e-6` per-element tolerance.

**Given** the KDD-B2 ablation winner from Story 7.3,
**When** the final training script `_bmad-output/ml-training/train.py` runs,
**Then** it uses the winning variant (`supervisedAugmented` or `maskedMelPretrain`) — the choice is hard-coded with a comment citing the `kdd-b2-comparison-v1.md` numeric outcome; the runner-up variant is preserved at `_bmad-output/ml-training/train_runnerup.py` for follow-up retrain stories.

**Given** Guardrail 3 (one declared `WeightingProfile` per trained model),
**When** `model_metadata.json` is produced at training close,
**Then** it carries `weightingProfile: "uniform"` OR `weightingProfile: "subBandEmphasis"` (the choice declared explicitly at training start), `featureSetVersion: "v2"`, `architecture: "TempoCNN"`, `seed`, `epochCount`, `corpusVersionHash`, `splitVersionHash`, `trainingVariant`, `promotable: true` (flipped from Story 7.3's `false`), and `bundleEligibilityPendingFR18: true`.

**Given** `featureSetVersion` is encoded in model metadata,
**When** the runtime path at `BNNSTechnique.featurize` reads the model,
**Then** runtime rejects or warns on mismatch (FR-21 + Story 6.2 invariant) — verified by `BoomBoomBoomKitMLTests.featureSetVersionMismatchWarns` exercising a synthetic `v1` model against the `v2` runtime feature pipeline.

**Given** FR-20 reproducibility,
**When** the training run completes,
**Then** `_bmad-output/ml-training/training_log.json` records per-epoch loss + val Acc1 + val Acc2 + ECE; deterministic data shuffling is verified by a second run with the same `--seed 42` producing byte-identical final-epoch loss to within `±1e-9`.

**Given** the audio-only constraint (FR-15) is re-asserted at the substrate boundary,
**When** `feature_substrate_v2.py` is reviewed,
**Then** the feature tensor reaching the model is solely the `logMelData` payload — no playlist, path, Rekordbox, artist, or ID3 BPM signal enters the model input.

**Given** the substrate-dependent gate (Codex PHASED guardrail) AND Story 6.5b's stable-runtime gate (Amelia #2 — body framing earlier in this story refers to runtime-path stability for FR-18 evaluation),
**When** Story 7.5 attempts to start,
**Then** BOTH Story 6.2's `FeatureSubstrate.OnsetFeatures` MUST exist on develop AND Story 6.5b's KDD-A6 Stage 3 semantic flip MUST have merged on develop (6.4b was byte-inert prep; the genuine pool-authoritative flip + KDD-A5 activation that the FR-18 evaluator in Story 7.6 runs against landed in 6.5b); both gates verified by a precondition check in `train.py` that aborts with a named error if either condition fails.

**Given** KDD-B3 reopen-trigger #5 requires evidence of "stable high-confidence Marginal predictions across seeds/checkpoints/augmentations" (Mary #5 — highest-priority defect),
**When** the final training run executes,
**Then** the run produces ≥ **3 checkpoints from 3 distinct seeds** (`--seed 42`, `--seed 43`, `--seed 44`) saved at `_bmad-output/ml-models/giantsteps_v2_seed_{42,43,44}.mlmodel`; `model_metadata.json` is produced PER SEED carrying the seed value; Story 7.6's FR-18 evaluator aggregates across all 3 seeds (reporting per-gate min/max/median rather than single-point) and Story 7.4's marginal-watchlist regression table reports prediction stability across seeds (variance reported in `marginal-watchlist-stability.json`); the seed-aggregation gate is "at least 2 of 3 seeds pass each FR-18 gate" — single-seed pass is insufficient per Mary's adversarial-review verdict.

**FRs covered:** FR-15 (re-asserted at substrate boundary), FR-20, FR-21.
**KDDs implemented:** B1 (TempoCNN architecture retained), B2 (winner consumed), B3 reopen-trigger #5 (multi-seed stability evidence wiring).
**Pressure-release valve:** If the parity harness reports deltas exceeding `±1e-6` per-element after reasonable investigation, split into Story 7.5a (parity reconciliation) and Story 7.5b (training run) — training MUST NOT proceed on a non-parity pipeline. If the 3-seed runs collectively exceed available GPU budget, drop to 2 seeds with a documented exception in `_bmad-output/implementation-artifacts/7-5-pressure-release.md` — but NEVER drop to 1 seed (defeats KDD-B3 trigger #5 evidence shape).

### Story 7.6: FR-18 promotion-gate evaluation + FR-23 octave-policy consistency report

**As a** library maintainer,
**I want** the Story 7.5 trained model evaluated against all 5 FR-18 promotion gates on the production runtime path from Story 6.5b, with the FR-23 raw-vs-octave-normalized accuracy table and the leave-artist-out evaluation slice from Story 7.1 surfaced as named acceptance reports, producing a single bundle-vs-BYOW decision per KDD-B5,
**So that** the model promotes to a bundled `giantsteps_v2.mlmodelc` on `main` only if every gate passes, otherwise ships as BYOW at `_bmad-output/ml-models/` with the failure surfaced in `_bmad-output/ml-training/fr-18-evaluation.md`.

**Acceptance Criteria:**

**Given** the FR-18 promotion-gate evaluator at `_bmad-output/ml-training/evaluate_fr18.py`,
**When** it runs against the Story 7.5 checkpoint via the production runtime path (`BNNSTechnique(modelURL:)` invoked through `AudioAnalysisService.analyzeBPM`),
**Then** `_bmad-output/ml-training/fr-18-evaluation.json` is produced with the 5 gate outcomes: (a) `dnbSentinelsCorrect: Int` (out of 4 named in `4-dnb-triplet-targets.json`) + `dnbSentinelsExpanded: Int` (out of n=12 once expanded by Epic mid-point) + `dnbWilson95LowerBound: Double` (must be ≥ 0.75 at close-out); (b) `oa300Acc1: Int` (strictly > 55/82); (c) `giantStepsAcc1: Int` (≥ 537/661); (d) `eceHalfDouble: Double` (< 0.10, anchor: prior bundle ≈ 0.5); (e) `tailErrorP95: {giantSteps: Double, oa300: Double, sentinels: Double}` (< 8.0 / < 5.0 / < 3.0 BPM respectively).

**Given** the runtime-path requirement (Codex PHASED guardrail),
**When** the evaluator is invoked,
**Then** the evaluation harness loads the model via `BNNSTechnique(modelURL: storyCheckpointURL)` and routes audio through `AudioAnalysisService.analyzeBPM` with `Options.ensemblePolicy = .mlOnly` — NOT a Python-side inference call; verified by `BoomBoomBoomKitBenchmarkTests.FR18EvaluationHarnessTests` exercising the runtime path end-to-end.

**Given** FR-23 (octave policy consistency across training and runtime),
**When** the runtime + evaluation are reviewed,
**Then** `_bmad-output/ml-training/fr-23-octave-consistency.md` reports (a) the runtime `OctaveEquivalencePolicy` used (from Story 6.5 enum), (b) the training-loss octave policy from Story 7.3 — and asserts they are documented as equivalent; raw Acc1 AND octave-normalized Acc1 are reported side-by-side; mismatch blocks model acceptance with a named error.

**Given** the leave-artist-out evaluation slice from Story 7.1,
**When** the FR-18 evaluator runs,
**Then** `fr-18-evaluation.json` carries a `leaveArtistOut: {acc1: Int, acc1Normalized: Int, delta: Int}` block reporting Acc1 on the held-out artist set + its delta vs the random-split Acc1 — feeding KDD-B3 reopen-trigger #2.

**Given** the Story 7.4 marginal watchlist,
**When** the evaluator runs,
**Then** `fr-18-evaluation.json` includes a `marginalWatchlistResults` block reporting the bundled model's predictions against each of the 241 watchlist tracks' `expectedFailureMode` — feeding KDD-B3 reopen-trigger #5.

**Given** the KDD-B5 bundle-vs-BYOW decision,
**When** all 5 FR-18 gates are evaluated,
**Then** `_bmad-output/ml-training/fr-18-evaluation.md` carries an explicit `decision: "bundle" | "byow"` line at the head; `bundle` requires ALL 5 gates pass; ANY single-gate failure → `byow`; the decision rationale enumerates per-gate pass/fail.

**Given** the prior-bundle calibration anchor (FR-25, softmax_max_p95 = 0.294, bimodal at 125/175),
**When** the evaluator reports calibration,
**Then** `fr-18-evaluation.md` includes a side-by-side comparison of the new model's softmax_max_p95 + bimodality test (Hartigan's dip or equivalent) against the prior-bundle anchor — calibration failure blocks bundling regardless of Acc1 per FR-25.

**Given** Mary #6 + Codex iteration-leak risk on repeatedly-evaluated public corpora (thread 019e6662 — Cawley & Talbot 2010 selection-bias risk; Dwork et al. 2015 reusable-holdout work),
**When** any team member runs `evaluate_fr18.py` against the Story 7.5 checkpoint,
**Then** the invocation MUST append a row to `_bmad-output/implementation-artifacts/7-6-fr18-rerun-log.md` documenting: (a) run timestamp, (b) git SHA at evaluation, (c) which checkpoint(s) evaluated, (d) what changed since the previous evaluation (augmentation tweak, loss reweighting, masked-mel recipe change, etc.), (e) per-gate pass/fail outcome. The rerun-log is git-committed (NOT `.gitignore`'d) so the audit trail is durable.

**Given** Codex's N=3 governance tripwire (reasonable not statistically magic for selection-bias detection on a 743-track combined evaluator),
**When** the rerun-log accumulates **≥ 3 entries** for the same Story 7.5 checkpoint family (any branch of the augmentation/loss tuning tree),
**Then** the next FR-18 re-evaluation requires explicit reviewer signoff (Codex/Winston/Mary or equivalent named reviewer) recorded in `7-6-fr18-rerun-log.md` BEFORE the evaluator runs; the precondition check in `evaluate_fr18.py` reads the rerun-log and aborts with a named error if the signoff line is absent for run 4+.

**FRs covered:** FR-17 (sentinels as gate input), FR-18 (5-gate evaluation), FR-23, FR-25 (calibration anchor comparison).
**KDDs implemented:** B5 (bundle vs BYOW resolved).
**Pressure-release valve:** If gate (a) DnB-sentinel-expansion to n=12 cannot complete by Epic mid-point, the close-out gate is evaluated on the original 4 sentinels with `dnbWilson95LowerBound` reported as informational rather than blocking; document the deferral in `_bmad-output/implementation-artifacts/7-6-pressure-release.md`. If the N=3 governance tripwire fires during routine debugging (genuinely fixing a bug rather than tuning for the gate), the reviewer-signoff line cites "bugfix-not-tuning" with the underlying issue link; abuse of this exception is itself flagged in the rerun-log.

### Story 7.7: Confidence-calibration verification + reproducibility artifact + BYOW export + KDD-B2 semi-supervised net-benefit gate

**As a** library maintainer,
**I want** the final Story 7.5 model exported to CoreML via `tools/coreml-convert/` for BYOW consumption, the FR-25 calibration verification recorded with the documented ECE floor, the FR-20 reproducibility artifact frozen, and the FR-24 semi-supervised net-benefit ablation gate evaluated,
**So that** Epic 7 closes with a consumable `giantsteps_v2.mlmodel` at `_bmad-output/ml-models/` (and on `main` only if Story 7.6 said `decision: "bundle"`), a smoke-tested consumer convert path, and a frozen reproducibility record sufficient to retrain bit-identically.

**Acceptance Criteria:**

**Given** the BYOW export (FR-19),
**When** `make ml-export` runs against the Story 7.5 checkpoint,
**Then** `_bmad-output/ml-models/giantsteps_v2.mlmodel` is produced; `make compile-model ML_MODEL_INPUT=_bmad-output/ml-models/giantsteps_v2.mlmodel` produces `_bmad-output/ml-models/giantsteps_v2.mlmodelc`; both artifacts load via `BNNSTechnique(modelURL:) throws` without throwing.

**Given** the consumer-facing convert tool smoke test,
**When** `make ml-convert` runs (which invokes `tools/coreml-convert/convert.py --checkpoint _bmad-output/ml-training/model.pt --arch reference --output <tmp>.mlmodelc --validate`),
**Then** the smoke test passes and `make ml-convert-tests` (pytest suite under `tools/coreml-convert/tests/`) reports zero failures — verifying the only Python tooling that ships to `main` per the DD #13 exception still works against the v2 model.

**Given** FR-25 calibration verification (anchor: prior bundle softmax_max_p95 = 0.294, bimodal at 125/175),
**When** `_bmad-output/ml-training/calibration-verification.md` is produced,
**Then** it reports the v2 model's `softmaxMaxP95`, ECE, ECE_half_double, reliability diagram (saved as `calibration-reliability-v2.png`), and bimodality dip test — each reported **side-by-side against the prior-bundle anchor** (Mary #4): `softmax_max_p95 v2 = X.XXX vs prior = 0.294`, `ECE_half_double v2 = X.XX vs prior ≈ 0.5`, plus a bimodality-dip-test row showing whether the 125/175 bimodal pattern reappears in v2. The documented ECE floor for v2 is recorded as `eceHalfDoubleFloor: 0.10` (from FR-18 gate d); calibration failure here blocks Story 7.7 close even if Story 7.6 said `decision: "bundle"`. Side-by-side comparison shape is non-optional — v2 metrics in isolation (without the prior-bundle anchor) DO NOT satisfy this AC per the analyst review.

**Given** FR-24 (semi-supervised expansion must prove net benefit),
**When** the KDD-B2 ablation winner from Story 7.5 was the `maskedMelPretrain` variant (which consumed the Story-7.2 expansion pool),
**Then** `_bmad-output/ml-training/fr-24-semi-supervised-net-benefit.md` reports Acc1 + ECE + tail-error P95 of `maskedMelPretrain` vs `supervisedAugmented` on OA300 + GiantSteps + sentinels; promotion of the semi-supervised variant requires improving OR preserving all FR-18 gates within documented tolerance (Acc1 within ±2 tracks, ECE within +0.02, tail-error P95 within +0.5 BPM); failure → fall back to `supervisedAugmented` runner-up.

**Given** FR-20 reproducibility,
**When** `_bmad-output/ml-training/training_log.json` and `_bmad-output/ml-training/model_metadata.json` are frozen at Story 7.7 close,
**Then** both files are committed to develop with `gitTag: "epic-7-close"`; `model_metadata.json` carries the final fields from Story 7.5 plus `epic7CloseDecision: "bundled" | "byowOnly"` mirroring Story 7.6's outcome.

**Given** the `main`-branch ship discipline (CLAUDE.md "Stays on develop ONLY"),
**When** Story 7.6 said `decision: "bundle"`,
**Then** the squash-merge to `main` includes only `Sources/BoomBoomBoomKitML/Resources/giantsteps_v2.mlmodelc/` (re-bundled from `_bmad-output/ml-models/`), updates `MODEL_CARD.md` with the new accuracy disclosure, and updates `BoomBoomBoomKitML`'s `Package.swift` target to reinstate `resources: [.copy("Resources")]`; if `decision: "byow"`, the squash-merge updates `MODEL_CARD.md` only to document continued BYOW-only status.

**Given** the four DnB sentinels (FR-17) and the post-bundle regression watchlist (Story 7.4 use c),
**When** the final model is selected (bundled or BYOW),
**Then** `_bmad-output/ml-training/post-bundle-regression-watchlist-v2.json` is produced — the Story-7.4 marginal-watchlist tracks each annotated with the v2 model's actual prediction + whether it matched `expectedFailureMode`.

**Given** Mary #6 + Codex's sealed-local-holdout discipline (iteration-leak tripwire — held-out GiantSteps slice as the truly-untouched final corpus),
**When** Story 7.7 reaches close-out,
**Then** a **stratified GiantSteps holdout** of **n=150 tracks** (Codex preferred over Mary's 50-track suggestion — at n=50 noise is ±10-14 Acc1 points; at n=150 noise narrows to ±6-8 points, making genuine iteration-leak detection feasible) is sampled from the GiantSteps corpus via `scripts/sample-giantsteps-holdout.py` with **fixed seed + stratified-by-tempo-band + stratified-by-style-label** (5 tempo bins × 3 GS style labels = 15 strata, 10 tracks each); the holdout track-hash-list is emitted as `_bmad-output/ml-training/giantsteps-holdout-v2.json` in **JAMS format** (`tempo` namespace, per-track BPM truth from GS ground truth). The hash-list itself is `.gitignore`'d locally per Codex (option (a) — smallest leak surface); the **selection script + source corpus version + seed value + SHA256 digest of the holdout manifest** are committed to develop as `giantsteps-holdout-v2-manifest.md` (reproducibility proof without leaking identity). The holdout is NEVER read by Stories 7.3 / 7.5 / 7.6 — verified by `grep -r "giantsteps-holdout-v2" _bmad-output/ml-training/` returning zero hits outside Story 7.7's evaluator script.

**Given** the iteration-leak tripwire is the gap between iterated-Acc1 (Story 7.6) and held-out-Acc1 (Story 7.7),
**When** Story 7.7's close-out evaluator runs the held-out GiantSteps slice,
**Then** `_bmad-output/ml-training/giantsteps-holdout-gap.md` reports `Acc1_iterated` (Story 7.6's GiantSteps-minus-holdout = 511 tracks), `Acc1_holdout` (the 150-track holdout), and the gap; **a gap ≥ 8 Acc1 points (Codex's "materially below" threshold for n=150)** flags iteration-leak as a real concern and blocks Story 7.7 close until reviewed — the team must decide whether the gap reflects a real model deficiency or selection-bias from FR-18 iteration. Gap < 8 closes Story 7.7 normally.

**FRs covered:** FR-19, FR-20, FR-24, FR-25.
**KDDs implemented:** B5 (close-out execution).
**Pressure-release valve:** If FR-25 calibration verification fails at Story 7.7 even after Story 7.6 said `decision: "bundle"`, the Story 7.7 close-out flips the decision to `byow` and updates `_bmad-output/ml-training/fr-18-evaluation.md` with an addendum citing the FR-25 override; bundling does NOT proceed. If the held-out-gap tripwire fires ≥ 8 Acc1 points, do NOT downgrade the threshold to make it pass — investigate whether the iteration-leak is genuine (which means Story 7.6's gate set has been tuned-against) and either accept the BYOW outcome or restart the FR-18 evaluator cycle on a fresh checkpoint not tuned against the iterated corpus. Document in `_bmad-output/implementation-artifacts/7-7-pressure-release.md`.

## Epic 8: LUFS + beat-grid + ModelRegistry public APIs (stories)

8 stories cover Epic 8's 10 FRs and 6 KDDs. Each story explicitly cites which Epic 6 internal surface it promotes per Mary's seam-mitigation rule. Stories 8.1 and 8.6 can run in parallel once Story 6.2 lands; 8.3 → 8.4 → 8.5 form the beat-grid critical path; 8.7 closes with the acceptance corpus (now using JAMS format + mir_eval interop); 8.8 migrates the existing oracle/sentinel artifacts (`daw-oracle.json`, `oa300-ground-truth.json`, `4-dnb-triplet-targets.json`) to JAMS format (added 2026-05-26 per JAMS adoption decision).

### Story 8.1: LUFS public API — `analyzeLUFS(url:options:)` + `LUFSReport` promotion

**As a** library consumer,
**I want** a public `AudioAnalysisService.analyzeLUFS(url:options:) -> LUFSReport` sibling to `analyzeBPM`,
**So that** I can extract ITU-R BS.1770-5 integrated loudness, true-peak, and loudness range (LRA) from any supported audio file without touching the internal `LUFSAnalyzer` type.

**Acceptance Criteria:**

**Given** a new file `Sources/BoomBoomBoomKit/LUFSReport.swift`,
**When** the test suite runs,
**Then** `LUFSReport` is a `public struct, Sendable, Hashable` carrying three fields (`integratedLUFS: Double`, `truePeakDBTP: Double`, `loudnessRangeLU: Double`) plus an `init` that clamps NaN/Inf to documented sentinels and conforms to `CustomStringConvertible`.

**Given** `AudioAnalysisService.analyzeLUFS(url:options:)` is added as a public sibling to `analyzeBPM`,
**When** consumers call it against the WAV/AIFF/MP3/FLAC/M4A/CAF fixtures in `Tests/BoomBoomBoomKitTests/Fixtures/`,
**Then** every fixture returns a non-nil `LUFSReport` and the previously-internal `LUFSAnalyzer` is no longer referenced from any consumer-facing path (verified by keeping `LUFSAnalyzer` `internal`).

**Given** Mary's Epic 6 → Epic 8 seam-mitigation rule,
**When** Story 6.2 left `AudioAnalysisService.swift` carrying internal `analyzeShared(url:options:)`-family helpers and `BPMDiagnosticTrace.swift` carrying unannotated `decodedAudio`/`featureSetVersion` fields,
**Then** this story promotes the LUFS-relevant subset (`decodedAudio` access on `BPMDiagnosticTrace`, sample-rate validation helpers on the service) to `public` with DocC `///` doc comments and a README "LUFS" section linking the API — explicitly named in the PR description.

**Given** `make benchmark` runs after the LUFS public API lands,
**When** OA300 wall-clock is measured at default intensity with LUFS NOT requested,
**Then** regression vs the pre-Story-8.1 baseline in `_bmad-output/perf-baselines/` is ≤ 1%.

**Given** the existing K-weighted Double-precision biquad coefficients for 44.1/48/96 kHz,
**When** `analyzeLUFS` is called with a sample rate outside that set,
**Then** the service throws `PCMBufferReaderError.unsupportedSampleRate` rather than synthesizing coefficients — KDD-S2 boundary preserved.

**Given** a new test suite `Tests/BoomBoomBoomKitTests/LUFSReportTests.swift`,
**When** the suite runs against the BS.1770-5 reference signals committed to the test fixtures,
**Then** integrated LUFS matches the reference within ±0.1 LU, true-peak matches within ±0.1 dBTP, and LRA matches within ±0.5 LU.

**FRs covered:** FR-26.
**KDDs implemented:** (Promotion-only; KDD-S2 `DecodedAudio` consumer wiring lands in Story 8.2.)
**Pressure-release valve:** If LUFSAnalyzer's internal API resists promotion without leaking pipeline-internal types, split into Story 8.1a (`LUFSReport` + service method against fresh decode) and Story 8.1b (shared-decode integration deferred to Story 8.2). Document the deviation in `_bmad-output/implementation-artifacts/8-1-pressure-release.md`.

### Story 8.2: Shared-decode wiring — three analyzers consume one `DecodedAudio`

**As a** library consumer,
**I want** `analyzeBPM`, `analyzeLUFS`, and the forthcoming `analyzeBeatGrid` to share a single decode pass when orchestrated by `AudioAnalysisService`,
**So that** combined analysis no longer pays 3× file-decode cost, and the `DecodedAudio` seam is in place before any unified `analyze(...)` follow-up.

**Acceptance Criteria:**

**Given** `AudioAnalysisService` is refactored to expose an internal `decodeOnce(url:options:) -> FeatureSubstrate.DecodedAudio` helper,
**When** `analyzeBPM` and `analyzeLUFS` are called within the same outer call frame on the same URL,
**Then** `PCMBufferReader.read(url:)` is invoked exactly once (verified by a test-only injectable decode counter on the service).

**Given** Mary's seam-mitigation rule,
**When** Story 6.2 left the `FeatureSubstrate.DecodedAudio` type `public` (already) but `AudioAnalysisService`'s decode-orchestration helpers `internal`,
**Then** this story promotes whichever orchestration touchpoint the public sibling methods need (typically a `DecodedAudio` accessor on `BPMDiagnosticTrace` plus a `decodeOnce` parameter on the service Options struct) to `public` — the promotion list is explicitly enumerated in the PR description.

**Given** the existing `BPMAnalyzer.estimateBPM` entrypoint,
**When** the analyzer is refactored to accept `DecodedAudio` instead of `[Float]` + sampleRate scalars,
**Then** `BPMAnalyzer` signature changes are confined to internal callers (no consumer-facing API change), and `BPMAnalyzerTests` still pass with semantic equality vs the pre-Story-8.2 OA300 measurement (Acc1 ≥ 58/82, Acc2 ≥ 74/82).

**Given** `LUFSAnalyzer` is similarly retargeted to consume `DecodedAudio`,
**When** the test suite runs,
**Then** integrated LUFS for every test fixture is byte-identical to the Story-8.1 measurement (decode reuse cannot perturb the K-weighting filter output — Double precision preserved end-to-end).

**Given** `make perf-benchmark` runs after Story 8.2 lands,
**When** OA300 wall-clock is measured for combined BPM + LUFS analysis,
**Then** the combined call is ≥ 35% faster than two sequential calls against the same URL.

**Given** `FeatureSubstrateTests.swift` from Story 6.2,
**When** the cross-consumer byte-identity assertion runs against the new combined orchestration path,
**Then** `BPMAnalyzer`, `LUFSAnalyzer`, and a placeholder `BeatGridAnalyzer` stub all receive identical `OnsetFeatures` for the same `(decoded, weighting)` input.

**FRs covered:** FR-35.
**KDDs implemented:** C4.
**Pressure-release valve:** None. Shared-decode is the precondition for Story 8.4's step 11 insertion.

### Story 8.3: `BeatGrid` + `BeatTimestamp` + tri-state `DownbeatResult` public types

**As a** library consumer,
**I want** typed beat-grid result containers (`BeatGrid`, `BeatTimestamp` with `confidence` + `strength`, `DownbeatResult` tri-state) landed as public types before the beat-tracking algorithm itself,
**So that** Story 8.4's `BeatGridAnalyzer` has a stable result shape to populate, and Epic 10's demo `BeatGridTimelineView` (FR-39) can begin design work against the public type.

**Acceptance Criteria:**

**Given** new files at `Sources/BoomBoomBoomKit/BeatGrid.swift`, `BeatTimestamp.swift`, `DownbeatResult.swift`,
**When** the test suite runs,
**Then** all three types are `public`, `Sendable`, `Hashable`; `BeatGrid` carries exactly five fields (`beats: [BeatTimestamp]`, `downbeats: DownbeatResult`, `estimatedTempo: Double`, `confidence: Float`, `tempoAgreedWithBPMStage: Bool?`); `BeatTimestamp` carries exactly three fields (`presentationTime: Double`, `confidence: Float`, `strength: Float`); `DownbeatResult` carries exactly three cases (`.notAttempted`, `.noneDetected`, `.detected([BeatTimestamp])`).

**Given** `BeatTimestamp.init`,
**When** any of `confidence` or `strength` is passed `Double.nan`, `Double.infinity`, or a value outside `[0.0, 1.0]`,
**Then** the init silently clamps to `[0.0, 1.0]` (NaN → 0.0) — never throws, never propagates NaN downstream per KDD-C2 Amelia provenance rule.

**Given** the `DownbeatResult` enum has an associated-value case,
**When** the unit-test invariant for associated-value-pattern coverage runs,
**Then** `DownbeatResult.allCases` is not synthesized (no `CaseIterable` conformance — matches `MLExecutionPolicy` precedent); pattern coverage is enforced via exhaustive `switch` in a dedicated test.

**Given** `Codable` round-trip tests for `BeatGrid` and `DownbeatResult`,
**When** every case (including `.detected([…])` with 0, 1, and 200 beats) round-trips through `JSONEncoder`/`JSONDecoder`,
**Then** the decoded value equals the encoded value under `Double.bitEqual(to:)` from `BoomBoomBoomKitTestSupport`.

**Given** Mary's seam-mitigation rule,
**When** Story 6.2 left a `BPMDiagnosticTrace.beatGridPlaceholder` field (or similarly named seam) `internal`,
**Then** this story promotes the relevant trace field — typically a typed-evidence-pattern `BeatGridTraceEntry` per KDD-T0 — to `public`, and the 5-recipe `bpm-diagnostic-trace` skill audit returns zero matches against `Sources/` and `Tests/`.

**Given** the public type ergonomics test,
**When** a consumer constructs `BeatGrid(beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0, tempoAgreedWithBPMStage: nil)`,
**Then** the empty/notAttempted shape is the documented "no beat-grid run" sentinel, distinguishable from `.noneDetected`.

**FRs covered:** FR-27, FR-28.
**KDDs implemented:** C2, C6 (no engine protocol — concrete result types only).
**Pressure-release valve:** None.

### Story 8.4: Davies & Plumbley beat-tracking DP — `BeatGridAnalyzer` + step 11 insertion

**As a** library maintainer,
**I want** the Davies & Plumbley 2004-2005 Rayleigh-weighted causal dynamic-programming beat-tracker landed as an internal `BeatGridAnalyzer` inserted as **step 11** in the pipeline, reusing existing `BPMAnalyzer` autocorrelation output and `ACFBuffers`,
**So that** `analyzeBeatGrid(url:options:) -> BeatGrid?` ships as a public sibling to `analyzeBPM` with zero new dependencies, no aubio linkage, and no transcription of GPL-3.0 source.

**Acceptance Criteria:**

**Given** a new file `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift`,
**When** the test suite runs,
**Then** `BeatGridAnalyzer` is `internal` (not public — KDD-C6 defers engine protocol until second concrete impl lands), implements `estimateBeatGrid(features: FeatureSubstrate.OnsetFeatures, acf: ACFBuffers) -> BeatGrid?`, and is purely Swift + Accelerate/vDSP.

**Given** the aubio GPL-3.0 fence,
**When** code review inspects `BeatGridAnalyzer.swift`,
**Then** no aubio source is transcribed; `///` doc comments cite `aubio/src/tempo/beattracking.c` for inspiration plus Davies & Plumbley ISMIR 2004 + AES 118 2005 academic references; the file imports only Foundation and Accelerate; and `Package.swift` carries no new dependency.

**Given** the pipeline-step-numbers-are-stable-identifiers rule,
**When** `BPMAnalyzer.estimateBPM` is updated to fan out to `BeatGridAnalyzer` after step 10c,
**Then** beat-grid lands as **step 11** in the documented pipeline; steps 1-10c are unchanged; `BPMDiagnosticTrace` records a typed-evidence `BeatGridTraceEntry` per KDD-T0.

**Given** the ADR-3 buffer-lifetime pattern,
**When** `BeatGridAnalyzer.estimateBeatGrid` runs,
**Then** it reuses `ACFBuffers` and `PipelineBuffers.onsetEnvelope` from the caller (no new buffer allocation in the hot path); `BeatTimestamp.strength` is computed as `onsetEnvelope[frame] / onsetEnvelopeMax` via `vDSP_maxv` per KDD-C2 Amelia provenance; and `frame = round(presentationTime * sampleRate / hopSize)`.

**Given** `AudioAnalysisService.analyzeBeatGrid(url:options:)` is added as a public sibling to `analyzeBPM`,
**When** consumers call it against the OA300 fixtures,
**Then** every fixture returns a non-nil `BeatGrid` with `beats.count > 0` and `estimatedTempo` within ±5 BPM of the corresponding `analyzeBPM` result on the same file.

**Given** Mary's seam-mitigation rule,
**When** Story 6.2 left `AudioAnalysisService.estimateBeatGrid(decoded:)`-style internal helpers unannotated,
**Then** this story promotes the consumer-facing `analyzeBeatGrid(url:options:)` method to `public` with DocC doc comments + a README "Beat-grid extraction" section.

**Given** `make benchmark` runs after Story 8.4 lands,
**When** OA300 wall-clock is measured at default intensity with `analyzeBeatGrid` NOT requested,
**Then** regression vs the Story-8.2 baseline is ≤ 2%; when invoked alongside BPM under shared decode, additional wall-clock overhead vs BPM-only is ≤ 25%.

**FRs covered:** FR-27, FR-30 (partial — full playback alignment lands in Story 8.5).
**KDDs implemented:** C1, C6.
**Pressure-release valve:** If the Davies & Plumbley DP fails to land within a single dev-agent context window, split into Story 8.4a (Rayleigh-weighted period-period transition matrix + score accumulation) and Story 8.4b (DP backtrace + `BeatGrid` population). Document the deviation in `_bmad-output/implementation-artifacts/8-4-pressure-release.md`.

### Story 8.5: Long-file sync stability + playback-aligned timestamps + BPM/beat-grid consistency contract

**As a** library consumer,
**I want** `BeatTimestamp.presentationTime` values that stay audibly accurate at the end of 5+ minute tracks AND line up with audio playback position under any supported codec (AAC, MP3, FLAC, WAV, AIFF, CAF) AND surface BPM/beat-grid tempo disagreement via `tempoAgreedWithBPMStage: Bool?`,
**So that** consumer apps doing DJ sync, beat-aligned video, or DAW import can trust the timestamps without per-codec offset compensation and arbitrate disagreement when both stages compute tempo in the same call.

**Acceptance Criteria:**

**Given** `FeatureSubstrate.PrimingInfo` from Story 6.2 carries `leadingTrimFrames` + `trailingTrimFrames` + `codec`,
**When** `BeatGridAnalyzer` constructs `BeatTimestamp.presentationTime`,
**Then** every timestamp subtracts `leadingTrimFrames / sampleRate` so that AAC/MP3 priming-delay does not introduce a visible offset; FLAC/WAV/AIFF/CAF inputs (zero priming) are unchanged; `BeatGridTests.playbackAlignmentAAC` and `.playbackAlignmentMP3` assert ≤ 5 ms offset vs a hand-clicked oracle stored in `Tests/BoomBoomBoomKitTests/Fixtures/playback-alignment-oracle.json`.

**Given** a 5+ minute fixture committed at `Tests/BoomBoomBoomKitTests/Fixtures/long-track-5min.flac`,
**When** `analyzeBeatGrid` runs end-to-end on the file,
**Then** the last beat's `presentationTime` drifts by ≤ 30 ms vs the expected period × beatIndex (FR-29 numeric drift tolerance; locked by `BeatGridTests.longFileSyncStability`).

**Given** `BeatGrid.tempoAgreedWithBPMStage: Bool?` field from Story 8.3,
**When** `AudioAnalysisService` runs both `analyzeBPM` and `analyzeBeatGrid` in the same orchestrated call,
**Then** the field is set to `true` iff `abs(beatGrid.estimatedTempo - bpmResult.bpm) ≤ 2.0`, `false` otherwise; nil only when one of the two stages did not run.

**Given** the consistency contract test `BeatGridTests.consistencyContract`,
**When** the test runs across the OA300 fixture subset,
**Then** in ≥ 90% of cases `tempoAgreedWithBPMStage == true`, AND in every case the field is non-nil whenever both stages ran.

**Given** Mary's seam-mitigation rule,
**When** Story 6.2 left `PrimingInfo` carried internally on `BPMDiagnosticTrace`,
**Then** this story promotes `BPMDiagnosticTrace.codecPriming: PrimingInfo` (or equivalent accessor) to `public` with DocC doc comments.

**Given** `Tests/BoomBoomBoomKitTests/Fixtures/playback-alignment-oracle.json`,
**When** the oracle is regenerated,
**Then** it carries hand-clicked beat positions for at least one AAC fixture + one MP3 fixture + one FLAC fixture, with the source-of-truth procedure documented in the test's `///` doc comment.

**FRs covered:** FR-29, FR-30, FR-31.
**KDDs implemented:** C3.
**Pressure-release valve:** If the playback-alignment-oracle fixture cannot be hand-clicked within the story's window, defer the AAC/MP3 priming-trim AC to Story 8.7 (acceptance corpus) and ship FLAC/WAV/AIFF/CAF coverage here. Document the deviation in `_bmad-output/implementation-artifacts/8-5-pressure-release.md`.

### Story 8.6: `ModelRegistry` + `ModelRegistryEntry` + `ModelRegistryError` + CryptoKit SHA-256

**As a** library consumer,
**I want** a public `ModelRegistry` that lists bundled (if any) + user-added + known-public-reference models with CryptoKit SHA-256 integrity validation at registration time,
**So that** ML model misuse (corruption, wrong-version weights, silent disk swap) surfaces as a typed `ModelRegistryError.integrityCheckFailed(expected:actual:)` rather than as silently-wrong BPM output.

**Acceptance Criteria:**

**Given** new files `Sources/BoomBoomBoomKit/ModelRegistry.swift`, `ModelRegistryEntry.swift`, `ModelRegistryError.swift`,
**When** the test suite runs,
**Then** all three are `public, Sendable`; `ModelRegistry` exposes `register(url:expectedDigest:metadata:) throws -> ModelRegistryEntry`, `entries: [ModelRegistryEntry]`, and `lookup(identifier:) -> ModelRegistryEntry?`; `ModelRegistryEntry` carries identity (`identifier: String`), integrity (`digest: SHA256.Digest`), capability (`capabilities: Set<ModelCapability>`), and attribution (`license: String?`, `sourceURL: URL?`); `ModelRegistryError` is an enum with at minimum `.integrityCheckFailed(expected: SHA256.Digest, actual: SHA256.Digest)`, `.modelResourceMissing(URL)`, and `.unsupportedFormat(reason: String)`.

**Given** `import CryptoKit` is added to `ModelRegistry.swift` (and only to that file in the core target),
**When** code review inspects the integrity-check implementation,
**Then** SHA-256 is computed via `SHA256.hash(data:)` over `.mlmodelc` directory contents sorted by relative path with concatenated bytes (KDD-C5 algorithm verbatim); zero new external dependencies enter `Package.swift`; computation is hardware-accelerated on Apple Silicon.

**Given** the cache-on-first-load contract per KDD-C5,
**When** `register(url:expectedDigest:metadata:)` is called twice with the same URL,
**Then** the second call short-circuits the SHA-256 computation and returns the cached entry (verified by a test-only digest-computation counter); cache is in-memory only, per NFR — persistence across launches is consumer's responsibility.

**Given** an integrity-mismatch test,
**When** a fixture model at `Tests/BoomBoomBoomKitTests/Fixtures/Models/tampered.mlmodelc/` is registered with a wrong `expectedDigest`,
**Then** `register` throws `ModelRegistryError.integrityCheckFailed(expected:actual:)` with both digests populated; the registry's `entries` array remains unchanged; no silent acceptance.

**Given** Mary's seam-mitigation rule,
**When** Story 6.2 left an internal `BPMDiagnosticTrace.modelIdentifier: String?` field (or equivalent) unannotated,
**Then** this story promotes it to `public` with DocC doc comments, links it to `ModelRegistryEntry.identifier`, and adds a README "Model registry" section.

**Given** the FR-32 in-memory-only constraint,
**When** the `ModelRegistry` API surface is reviewed,
**Then** there is no `save(to:)` / `load(from:)` method on the registry; demos and consumers handle persistence via their own bookmark + `UserDefaults` plumbing (Epic 10's responsibility).

**Given** a new test suite `Tests/BoomBoomBoomKitTests/ModelRegistryTests.swift`,
**When** the suite runs,
**Then** it covers happy-path registration (digest match), failure-path (digest mismatch → typed error), cache reuse (second register short-circuits), and `Sendable` conformance (concurrent register from multiple `Task`s does not corrupt the entry array).

**FRs covered:** FR-32, FR-33.
**KDDs implemented:** C5.
**Pressure-release valve:** None.

### Story 8.7: Beat-grid acceptance corpus + benchmarks — F-measure floor + beat-position tolerance

**As a** library maintainer,
**I want** beat-grid accuracy validated against the OA300 corpus (DAW-oracle ground truth) + a stratified DnB subset, with F-measure floor and beat-position tolerance committed as numeric AC in this story,
**So that** Epic 8 cannot close without committed accuracy gates equivalent to the FR-10 BPM accuracy floors, and future regressions surface immediately.

**Acceptance Criteria:**

**Given** a new env-gated test target `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridBenchmarkTests.swift` AND `mir_eval` adopted as the canonical F-measure implementation (avoids off-by-one bugs that hand-rolled implementations carry — `mir_eval.beat.f_measure(reference_beats, estimated_beats)` is the MIR-research standard),
**When** `make benchmark-beatgrid` runs against the OA300 corpus with `OA300_CORPUS_PATH` set,
**Then** the Swift benchmark test emits per-track estimated beat positions to a temp `.json` file in JAMS format, then invokes a Python sidecar (`_bmad-output/ml-training/eval-beatgrid.py`, develop-only) that calls `mir_eval.beat.f_measure` against the JAMS-format reference at `${OA300_CORPUS_PATH}/daw-oracle-beats.json` (produced by Story 8.7's `make oracle-generate-beats` target) using ±70 ms tolerance window; aggregated mean F-measure ≥ 0.75 across the corpus; per-track F-measure is logged to `_bmad-output/implementation-artifacts/8-7-beat-grid-accuracy.json`. The Python `mir_eval` dependency is added to `_bmad-output/ml-training/pyproject.toml` (develop-only, NOT shipped to `main` — consistent with the existing `tools/coreml-convert/` DD #13 exception that scopes Python tooling to `_bmad-output/` and `tools/coreml-convert/`).

**Given** a stratified DnB subset committed at `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/beat-grid-dnb-subset.json`,
**When** the benchmark runs against the subset,
**Then** mean F-measure on the DnB subset is ≥ 0.65 (lower floor for the harder genre per architecture KDD-C1 expectations); failures are surfaced track-by-track in the JSON output.

**Given** the FR-29 numeric drift tolerance from Story 8.5,
**When** the benchmark measures beat-position drift on the OA300 tracks ≥ 5 minutes long,
**Then** the P95 absolute drift at the last beat is ≤ 30 ms; the gate is locked as a Swift Testing `#expect` assertion.

**Given** a `make perf-benchmark` extension covering beat-grid wall-clock,
**When** OA300 is processed with beat-grid enabled under shared decode (Story 8.2 path),
**Then** total combined-analysis wall-clock (BPM + LUFS + beat-grid) is ≤ 1.25× BPM-only wall-clock baseline.

**Given** the DAW-oracle precedent for BPM (Story 1-1) AND JAMS adoption (JSON Annotated Music Specification — `marl/jams` on GitHub, ISC license, canonical MIR annotation format with built-in interop to `mir_eval`),
**When** beat-grid ground-truth generation is wired in,
**Then** `scripts/dawproject-beats.py` (develop-only) extracts per-beat positions from the existing OA300 `.dawproject` source and emits `daw-oracle-beats.json` in **JAMS format**: `file_metadata` carries per-track artist/title/duration; `annotations` carries one annotation with `namespace: "beat"` and a `SparseObservationList` (per-beat `time` + `confidence` + zero `duration`); `annotation_metadata.curator` documents the DAW-extraction tooling + version + curator name; `annotation_metadata.data_source = "DAW manual placement"`. `make oracle-generate-beats` regenerates the JAMS file via `uv run scripts/dawproject-beats.py`. The Python `jams` dependency is added to `_bmad-output/ml-training/pyproject.toml` (develop-only).

**Given** the Epic-8-closes preconditions per the dependency graph,
**When** all 7 stories merge to develop,
**Then** the README carries new sections for `analyzeLUFS`, `analyzeBeatGrid`, and `ModelRegistry`; `MODEL_CARD.md` references the beat-grid acceptance floor.

**Given** the Swift-side benchmark needs to parse JAMS-format reference files,
**When** Story 8.7 introduces JAMS-format oracle reading,
**Then** a Swift JAMS decoder lands at `Tests/BoomBoomBoomKitBenchmarkTests/Helpers/JAMSDecoder.swift` (~100-150 LOC of Codable structs matching the JAMS schema) — NOT in `BoomBoomBoomKitTestSupport` (which is `public` and would expose a JAMS decoder to downstream consumer test packages); the decoder supports `tempo`, `beat`, and `tag_open` namespaces (enough for our annotation surface) and rejects unknown namespaces with a typed error rather than silent default; consumed by `BeatGridBenchmarkTests` + `DAWOracleBenchmarkTests` + any future JAMS-consumer benchmarks.

**FRs covered:** FR-34.
**KDDs implemented:** (Validation closure for C1, C2, C3, C4, C5, C6 — no new KDD.)
**Pressure-release valve:** If the DnB subset F-measure ≥ 0.65 floor cannot be met within the story's window, document the actual measurement in `_bmad-output/implementation-artifacts/8-7-pressure-release.md` and reopen Story 8.4 for algorithm refinement rather than weakening the floor. If `mir_eval` introduces a major-version breaking change in its `beat.f_measure` API between Story 8.7 start and close, pin the version in `pyproject.toml` and document the version-pin rationale.

### Story 8.8: Migrate existing oracle and sentinel artifacts to JAMS format

**As a** library maintainer adopting JAMS as the canonical annotation format,
**I want** the existing `daw-oracle.json`, `oa300-ground-truth.json`, and `4-dnb-triplet-targets.json` artifacts converted to JAMS shape via a one-time migration script,
**So that** Story 8.7's beat-grid benchmark + Story 1-1's BPM benchmark + all future ground-truth-consuming benchmarks share a single canonical annotation format with mir_eval interop and curator metadata discipline.

**Acceptance Criteria:**

**Given** `_bmad-output/ml-training/migrate-to-jams.py` (develop-only) is added as a one-time conversion script,
**When** the script runs against the three existing artifacts,
**Then** it produces JAMS-format siblings at `${OA300_CORPUS_PATH}/daw-oracle.json` (overwrites in place — JAMS shape per the same `tempo` namespace as Story 8.7's beat output), `${OA300_CORPUS_PATH}/oa300-ground-truth.json` (overwrites in place), and `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (overwrites in place). All three carry `file_metadata` per track + `annotation_metadata.curator` + `annotation_metadata.data_source` documenting provenance.

**Given** the existing Swift-side consumers (`Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift`, `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift`, the 4-sentinel-checking tests),
**When** the JAMS migration lands,
**Then** the Swift consumers are updated to use the JAMS decoder from Story 8.7 (`Tests/BoomBoomBoomKitBenchmarkTests/Helpers/JAMSDecoder.swift`); existing per-track lookup patterns continue to work via decoded `file_metadata.identifiers` mapping; all existing benchmark tests pass against the migrated format.

**Given** the JAMS migration script needs to be reproducible,
**When** `make oracle-migrate-to-jams` runs,
**Then** the Makefile target reads from the current flat-JSON shape (if found) and writes JAMS-shape output, idempotent (re-running on already-JAMS files is a no-op); the script writes a `_bmad-output/implementation-artifacts/8-8-migration-report.md` recording per-file conversion stats (input shape detected, output JAMS namespace, curator field populated).

**Given** the curator metadata discipline JAMS imposes,
**When** each migrated artifact is reviewed,
**Then** `annotation_metadata.curator.name` is populated (the operator name from CLAUDE.md's git user config — "RT" if no better attribution is available), `annotation_metadata.curator.email` is populated from the same source, and `annotation_metadata.data_source` is populated specifically: `"DAW manual placement"` for `daw-oracle.json`, `"OA300 hand-labeled ground truth"` for `oa300-ground-truth.json`, `"DnB triplet challenge set, manually verified"` for `4-dnb-triplet-targets.json`.

**Given** Codex + Mary's iteration-leak concern about repeatedly-evaluated corpora,
**When** Story 8.8 closes,
**Then** the JAMS-format artifacts carry no additional sensitivity that didn't already exist (the existing per-track BPM truth was already in `daw-oracle.json`); the migration does NOT introduce the giantsteps-holdout-v2.json (which Story 7.7 owns and keeps locally-only).

**FRs covered:** None directly (infrastructure migration; supports FR-17, FR-34 indirectly).
**KDDs implemented:** None directly (consumer-of-Story-8.7's JAMS decoder).
**Pressure-release valve:** If the migration script discovers schema-incompatibility issues with any source artifact (e.g., `4-dnb-triplet-targets.json` carrying additional fields that don't fit JAMS), the migration writes the additional fields to `annotation.sandbox` (JAMS's documented extension point for non-schema data) rather than dropping them. Document the deviation in `_bmad-output/implementation-artifacts/8-8-pressure-release.md`.

## Epic 9: Demo shell + ensemble picker (stories)

3 stories ship the demo's primary consumer-evaluation surface as soon as Story 6.5 closes. Story 9.1 introduces the named-preset picker in the primary view; Story 9.2 ships the final-state signal-pool diagnostic table in the existing advanced sidebar; Story 9.3 codifies the primary-flow + confidence-label discipline as a cross-cutting rule Epic 10 inherits.

### Story 9.1: EnsemblePresetPicker in primary view with persistence

**As a** developer evaluating BoomBoomBoomKit,
**I want** the demo's primary view to offer four named ensemble presets (`Default`, `DSP only`, `ML augmented`, `Trust file tags`) mapped to the `EnsemblePolicy` facade from Story 6.5,
**So that** I can drop an audio file, pick a named preset, and see the unified-signal-pool ensemble pick a BPM without ever touching raw per-source weights or policy enums.

**Acceptance Criteria:**

**Given** a new file `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift`,
**When** the demo target builds via `make demo-build`,
**Then** `EnsemblePresetPicker` is a SwiftUI `View` rendering exactly four selectable rows labeled verbatim `Default` / `DSP only` / `ML augmented` / `Trust file tags`, with no fifth raw-weights option in the primary view.

**Given** the preset-to-policy mapping defined by KDD-D1,
**When** each preset is selected,
**Then** the resolved `EnsemblePolicy` value matches `Default → .default`, `DSP only → .dspOnly`, `ML augmented → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0))`, and `Trust file tags → .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0))` — verified by `EnsemblePresetPickerTests.presetMappingMatchesKDDD1`.

**Given** the selected preset drives the next analysis run,
**When** the user picks a preset and drops a file,
**Then** the resulting `AudioAnalysisService.Options.ensemblePolicy` value byte-equals the picker's resolved `EnsemblePolicy`.

**Given** preset persistence following the Story 5-6 `MergeStrategyPersistence` precedent (KDD-D3 `UserDefaults` pattern),
**When** the user selects `ML augmented`, quits the app, and relaunches,
**Then** `ML augmented` is restored as the active preset; persistence is encoded by case identifier (not raw `SignalWeights` floats) so post-1.0 preset-table changes don't poison stored state.

**Given** the picker is anchored in the primary window per FR-43,
**When** the advanced sidebar (`.inspector(isPresented:)`) is closed,
**Then** the preset picker remains visible and functional in the primary view — the picker is not gated behind `⌘⇧D`.

**Given** Sally #2's "Epic 9 alone holds barely" finding — without subtitles, Priya sees four named presets she doesn't understand and bounces,
**When** the `EnsemblePresetPicker` rows render in the four-week window between Epic 9 ship and Epic 10/11 ship,
**Then** each preset row shows a single inline-authored subtitle line beneath the name (no docs bundle, no Bundle.module, no docs accessor): `Default — balanced ensemble`, `DSP only — disables ML, fastest`, `ML augmented — adds the trained classifier`, `Trust file tags — prefer ID3/MP4/Vorbis tempo tags`. The subtitle text is hard-coded in `EnsemblePresetPicker.swift` and explicitly marked `// REPLACED BY Story 10.5: subtitle becomes a "?" popover wired to Epic 11 docs via BoomBoomBoomKitDocs.attributedString(for:id:)` — when Story 10.5 lands, the subtitle line is replaced by the popover; the subtitle text is the seam, not throwaway code.

**Given** the `EnsemblePolicy` facade is the Story 6.5 deliverable,
**When** this story opens its first PR,
**Then** Story 6.5 is closed on develop; absent that close-out, this story is blocked.

**FRs covered:** FR-36.
**KDDs implemented:** D1.
**Pressure-release valve:** None.

### Story 9.2: Signal-pool diagnostic table in advanced sidebar

**As a** developer auditing why the ensemble picked a particular BPM,
**I want** the advanced sidebar to render a sortable `SwiftUI.Table` of every contributing signal — source, BPM, confidence, weight, contribution, cluster — with the winning cluster visually emphasized and rejected candidates grouped separately,
**So that** I can audit the ensemble's decision post-analysis without re-running with `enableTrace: true` and cross-referencing trace dumps by hand.

**Acceptance Criteria:**

**Given** a new file `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/SignalPoolDiagnosticTable.swift`,
**When** the demo target builds via `make demo-build`,
**Then** `SignalPoolDiagnosticTable` is a SwiftUI `View` containing a `Table(of: SignalPoolDiagnosticRow.self, sortOrder: $sortOrder)` with exactly six `TableColumn`s labeled `Source`, `BPM`, `Confidence`, `Weight`, `Contribution`, `Cluster` (per KDD-D5).

**Given** the table reads from `BPMDiagnosticTrace.signalParticipationTrace` (the field introduced by Story 6.1),
**When** an analysis completes with `Options.enableTrace = true`,
**Then** the table renders one row per `SignalParticipationTraceEntry`, with 5-15 rows typical per KDD-D5 sizing; with `enableTrace = false` the table shows an empty-state message ("Enable diagnostic trace in advanced settings") rather than crashing.

**Given** sort interaction via the `Table`'s built-in column-header tap,
**When** the user clicks any column header,
**Then** rows re-sort by that column ascending; a second click reverses; the table's `sortOrder` binding drives the sort (read-only, sortable, no row editing).

**Given** the visual emphasis requirement from FR-41,
**When** the table renders,
**Then** rows belonging to the winning cluster carry a distinguishing background tint (HIG-compliant accent), rejected candidates appear in a visually de-emphasized group below the winner, and the winning row carries an SF Symbol leading badge (e.g., `checkmark.circle.fill`).

**Given** FR-41's "replaces current `EnsembleDecision` summary view" requirement,
**When** the demo's sidebar source compiles,
**Then** the prior `EnsembleDecision`-rendering view is removed (verified by `grep -r EnsembleDecision Demo/` returning zero matches outside string-literal usage references).

**Given** the table lives inside the existing `.inspector(isPresented:)` sidebar from Story 5-6b,
**When** the sidebar is closed (`⌘⇧D` toggle),
**Then** the primary BPM-result flow is unaffected.

**Given** Story 6.1 ships `BPMDiagnosticTrace.signalParticipationTrace` as the source-of-truth,
**When** this story opens its first PR,
**Then** Story 6.1 is closed on develop AND Story 6.5 is closed on develop.

**FRs covered:** FR-41.
**KDDs implemented:** D5.
**Pressure-release valve:** None.

### Story 9.3: Primary-flow discipline + confidence-label rule

**As a** consumer evaluating the demo,
**I want** the demo to keep "drop file → get answer" as the dominant interaction and never display a bare numeric value for any confidence-like quantity,
**So that** the primary flow stays uncluttered for end-user evaluation while developer affordances stay one keystroke away in the sidebar, and so that no number ever appears without a label telling me what kind of confidence it represents.

**Acceptance Criteria:**

**Given** the demo's primary window layout per FR-43,
**When** the demo launches and no file has been dropped,
**Then** the primary view shows only the audio-file drop zone, the `EnsemblePresetPicker` (Story 9.1), and a placeholder result region — no diagnostic-table preview, no raw-weights controls, no model-picker affordance leak from the (Epic 10) sidebar surface.

**Given** the `.inspector(isPresented:)` sidebar toggle keybinding (Story 5-6b),
**When** the user invokes `⌘⇧D`,
**Then** the sidebar opens/closes carrying every developer-facing affordance — diagnostic table (Story 9.2), raw per-source weights, and any future dev-tool extension points reserved for Epic 10.

**Given** closing the sidebar restores the end-user surface per FR-43,
**When** the sidebar transitions from open to closed,
**Then** the primary view retains its current file, current preset, current BPM result, and current confidence label — closing the sidebar is presentation-only.

**Given** the confidence-label discipline per FR-44,
**When** any view in the demo displays a confidence-like quantity (BPM confidence, signal weight, source reliability, ML softmax max, future beat-grid confidence inherited by Epic 10),
**Then** the displayed value carries an explicit label string identifying which kind of confidence it represents (e.g., `BPM confidence: 0.78`, `DSP signal weight: 1.0`) — no `Text("\(value)")` numeric-only call sites permitted.

**Given** a CI grep gate enforcing the FR-44 rule,
**When** `grep -rE 'Text\(verbatim:\s*"\\\(.*confidence' Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/` and the broader bare-numeric audit run as part of `make demo-lint`,
**Then** zero matches are produced (the audit's exact regex set ships alongside this story in `Demo/BoomBoomBoomBPM/scripts/confidence-label-audit.sh`).

**Given** Epic 11's doc-authoring style guide owns the specific label *strings* per FR-44's cross-reference to KDD-E8,
**When** this story closes,
**Then** the demo enforces the *no-bare-numerics rule* but defers exact label-string vocabulary to Epic 11; placeholder labels chosen in this story are explicitly marked `// TODO(Epic 11): align with KDD-E8 style guide`.

**Given** the cross-cutting discipline framing,
**When** Epic 10 stories author beat-grid and LUFS views,
**Then** they inherit the FR-44 audit and the `⌘⇧D` sidebar convention from this story — Epic 10 story specs cite Story 9.3 rather than re-deriving the rule.

**FRs covered:** FR-43, FR-44.
**KDDs implemented:** None directly (cross-cutting rule).
**Pressure-release valve:** If the bare-numeric audit regex set proves too brittle during implementation, downgrade the CI gate to a SwiftLint custom rule for the demo target only. Document the deviation in `_bmad-output/implementation-artifacts/9-3-pressure-release.md`.

## Epic 10: Demo integration — beat-grid + LUFS + model selection + popovers (stories)

5 stories wire the Epic 8 surface (`BeatGrid`, `BeatTimestamp`, `DownbeatResult`, `LUFSReport`, `ModelRegistry`) and Epic 11 docs accessor (`BoomBoomBoomKitDocs.attributedString(for:id:)`) into the `Demo/BoomBoomBoomBPM/` Xcode app. FR-44 confidence-label discipline (from Story 9.3) applies throughout; FR-42 graceful degradation ensures Epic 10 can ship before Epic 11 closes.

### Story 10.1: ModelPickerView — registry-backed model selection

**As a** demo user evaluating BoomBoomBoomKit's ML augmentation,
**I want** to pick an ML model from a list of registry entries (bundled + known-public references + previously-added) or add a new one via file picker,
**So that** I can compare model behavior across runs without rebuilding the app.

**Acceptance Criteria:**

**Given** the demo launches with no user-added models,
**When** the user opens the model picker sheet from the main window,
**Then** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` renders a SwiftUI `List` populated by `ModelRegistry.allEntries()` (Epic 8 dependency — story spec cites the upstream `ModelRegistry` API), with each row showing the entry's display name, source category (`Bundled` / `Known-public` / `User-added`), and a labeled integrity status string (e.g., `Integrity: verified` — bare booleans/numerics are FR-44 violations).

**Given** the picker sheet is open,
**When** the user taps "Add model from disk…",
**Then** the view presents an `NSOpenPanel` constrained to `.mlmodelc` bundles and `.mlmodel` files, and on selection invokes `BookmarkPersistence.store(url:)` from Story 10.2 before appending the resolved entry to the registry's user-added slot.

**Given** a registry entry is highlighted,
**When** the user taps "Use this model",
**Then** the demo's analysis service options carry the resolved URL on the next `analyzeBPM(url:options:)` invocation, and the picker dismisses; the previously selected entry is visually marked with a labeled `Selected: yes` indicator.

**Given** `ModelRegistry` returns an empty list (no bundled, no known-public, no user adds),
**When** the picker sheet opens,
**Then** the view renders a non-empty-state explanatory panel ("No models available — add one to begin"), and the "Use this model" button is disabled with a labeled rationale (`Reason: no-models-available`).

**FRs covered:** FR-37.
**KDDs implemented:** None directly (composes Epic 8's `ModelRegistry`).
**Pressure-release valve:** If `ModelRegistry` from Epic 8 lands late, ship a stub registry that surfaces only the file-picker path; document the dependency in the story implementation artifact and reopen the AC once Epic 8 closes. Document the deviation in `_bmad-output/implementation-artifacts/10-1-pressure-release.md`.

### Story 10.2: BookmarkPersistence — security-scoped bookmarks across launches

**As a** demo developer ensuring user-added models survive app restarts,
**I want** a `BookmarkPersistence` helper that stores security-scoped bookmark `Data` in `UserDefaults` and resolves them on launch,
**So that** user-added model URLs from the file picker continue to resolve after the demo relaunches without re-prompting the user.

**Acceptance Criteria:**

**Given** the demo's `Info.plist` and entitlements file are being audited,
**When** the operator inspects `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements`,
**Then** all three keys are present and `true`: `com.apple.security.app-sandbox` (per NFR-9), `com.apple.security.files.user-selected.read-only`, AND `com.apple.security.files.bookmarks.app-scope` — the third is the one developers commonly forget; the story spec explicitly enumerates it so the implementation cannot silently omit it.

**Given** the user picks a model file via the Story 10.1 file picker,
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BookmarkPersistence.swift` calls `URL.bookmarkData(options: .withSecurityScope, …)`,
**Then** the resulting `Data` is stored under `UserDefaults.standard` keyed by a stable user-added-model UUID, mirroring the `MergeStrategyPersistence` precedent from Story 5-6 (KDD-D3); no Keychain, no file-system sidecar, no JSON wrappers.

**Given** the demo relaunches and `BookmarkPersistence.resolveAll()` runs during app startup,
**When** any stored bookmark resolves with `isStale == true`,
**Then** the entry is refreshed by re-creating the bookmark from the resolved URL and re-persisting it; if resolution throws, the entry is dropped from the registry with a labeled diagnostic (`Reason: bookmark-resolution-failed`) and the user is NOT prompted mid-launch.

**Given** the entitlement `com.apple.security.files.bookmarks.app-scope` is intentionally removed for a regression test,
**When** the demo is built with `make demo-build-sandboxed` (NOT `demo-build`, which bypasses signing — Story 5-1 DD #6),
**Then** bookmark resolution fails on the second app launch, confirming the entitlement is load-bearing; this negative-path verification step is documented in the story implementation artifact.

**FRs covered:** FR-38.
**KDDs implemented:** D3.
**Pressure-release valve:** If `URL.bookmarkData(options: .withSecurityScope, …)` proves unstable for `.mlmodelc` directory bundles specifically, fall back to storing the parent directory bookmark and reconstructing the bundle path on resolve; do not abandon security scope. Document the deviation in `_bmad-output/implementation-artifacts/10-2-pressure-release.md`.

### Story 10.3: BeatGridTimelineView — Canvas-based timeline + text readout

**As a** demo user evaluating BoomBoomBoomKit's beat-grid output,
**I want** a horizontal timeline showing beats and downbeats with a current-time scrubber, alongside a text readout,
**So that** I can visually verify the grid aligns with the audio and read out the tempo / beat-count / confidence numbers without inspecting JSON.

**Acceptance Criteria:**

**Given** an `AudioAnalysisResult` carrying a non-nil `BeatGrid` (Epic 8 dependency — `BeatGrid`, `BeatTimestamp`, and `DownbeatResult` produced by Epic 8 stories),
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridTimelineView.swift` renders,
**Then** the view uses SwiftUI `Canvas` (KDD-D2 — not `Path`-in-`ZStack`, not Metal, not `UIView`/`NSView` bridging) to draw vertical tick marks for each `BeatTimestamp` and visually-distinguished taller marks for `DownbeatResult` positions across a horizontal time axis.

**Given** the audio is mid-playback,
**When** the playback time advances,
**Then** a vertical scrubber line tracks the current time across the Canvas at 60Hz via `TimelineView(.animation)`, NOT via `Timer`-driven `@State` mutation; the scrubber stays within the Canvas bounds at all zoom levels.

**Given** the timeline view is visible,
**When** the user reads the text readout panel beneath the Canvas,
**Then** the panel shows four labeled fields (FR-44 discipline — no bare numerics): `Estimated tempo: <X> BPM`, `Beat count: <N>`, `Downbeat status: <detected | not-detected | partial>`, and `Grid confidence: <0.00-1.00>` formatted to two decimal places with the literal `Grid confidence:` label preceding the value.

**Given** the analysis produced a `BeatGrid` but no `DownbeatResult` (downbeats absent or low confidence),
**When** the view renders,
**Then** the Canvas draws only beat ticks (no taller downbeat marks), and the text readout shows `Downbeat status: not-detected` with the grid-confidence field still populated; no silent rendering of zero-confidence downbeats.

**Given** the operator inspects the file diff for waveform-rendering primitives,
**When** the search is run for `AVAudioFile` waveform sampling, `FFT`-on-display, or any pixel-per-sample loop,
**Then** zero matches are found in `BeatGridTimelineView.swift` — waveform rendering is explicitly OUT of scope per FR-39.

**FRs covered:** FR-39.
**KDDs implemented:** D2.
**Pressure-release valve:** If SwiftUI `Canvas` performance degrades at high beat density (e.g., 200+ beats visible), reduce visible-tick density via downsampling at the view layer, not by switching to Metal. Document the deviation in `_bmad-output/implementation-artifacts/10-3-pressure-release.md`.

### Story 10.4: LUFSReadoutView — primary integrated LUFS + secondary breakdown

**As a** demo user comparing tracks for loudness alongside BPM,
**I want** a clean LUFS panel showing integrated loudness as the primary number with true-peak and LRA as secondary context,
**So that** loudness information surfaces without competing with the BPM-centric flow.

**Acceptance Criteria:**

**Given** an `AudioAnalysisResult` carrying a non-nil `LUFSReport` (Epic 8 dependency),
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/LUFSReadoutView.swift` renders,
**Then** the primary readout shows `<X.X> LUFS` (FR-44 — the literal `LUFS` unit label is always present; never a bare number) using a typography scale at least 2× larger than the secondary panel.

**Given** the secondary panel is visible,
**When** the operator inspects the rendered text,
**Then** two labeled fields appear: `True peak: <Y.Y> dBTP` and `Loudness range: <Z.Z> LU`, both formatted to one decimal place with explicit unit suffixes.

**Given** the demo's main analysis result pane is laid out,
**When** the operator inspects the visual hierarchy,
**Then** the LUFS panel occupies a clearly subordinate region (right sidebar, below-the-fold accordion, or equivalent) such that BPM remains the dominant visual element; LUFS does NOT take center stage per FR-40 framing.

**Given** the `LUFSReport` carries any field as `nil` (e.g., true-peak unavailable for a particular sample rate),
**When** the view renders,
**Then** the absent field shows `True peak: unavailable` (labeled fallback) rather than silently hiding the row or rendering `0.0 dBTP`.

**FRs covered:** FR-40.
**KDDs implemented:** None directly (consumes Epic 8's `LUFSReport`).
**Pressure-release valve:** None.

### Story 10.5: HelpButton + strategy popovers wired to Epic 11 docs

**As a** demo user exploring preset / policy / strategy options,
**I want** a "?" button beside each control that opens a popover showing per-case authored prose from Epic 11's docs bundle,
**So that** I can understand what `.optimal` vs `.dnbOptimized` vs `.windowVoting` actually do without leaving the app — and even if Epic 11 hasn't shipped yet.

**Acceptance Criteria:**

**Given** the `HelpButton` type is being designed,
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift` is implemented,
**Then** it is declared as `struct HelpButton<T: DocumentedCase>: View` (generic over Epic 11's `DocumentedCase` protocol — story spec cites Epic 11 dependency), taking a `case: T` parameter and rendering an SF Symbol `questionmark.circle` button.

**Given** the user taps the "?" button beside a `TechniqueSet` preset control,
**When** the button's `.popover()` modifier fires (KDD-D4 — SwiftUI `.popover()`, NOT a custom overlay, NOT a sheet, NOT a tooltip-emulation),
**Then** the popover renders the result of `BoomBoomBoomKitDocs.attributedString(for: T.self, id: case.docID)` (Epic 11 dependency — public library accessor that hides `Bundle.module` resolution).

**Given** Epic 11 has NOT yet shipped or `BoomBoomBoomKitDocs.attributedString(for:id:)` returns `nil` (FR-42 graceful degradation),
**When** the popover would render,
**Then** the view falls back to a two-element view: a one-line description sourced from `case.shortDescription` (declared on `DocumentedCase`) and a `Link` to the repo's GitHub docs URL for that case — NOT a broken `Bundle.module` lookup, NOT an empty popover, NOT a crash, NOT a hidden button.

**Given** the demo is built without Epic 11's Markdown resource bundle present (simulated by stubbing the docs accessor to return `nil` for all IDs),
**When** the operator clicks every "?" button in the demo across every wired control,
**Then** every popover opens with the fallback prose + repo URL, and zero `Bundle.module` resolution errors appear in the console — FR-42 graceful degradation is observable end-to-end.

**Given** the popover is dismissed,
**When** the user taps outside the popover or presses `Escape`,
**Then** the popover dismisses via SwiftUI's native `.popover()` behavior (KDD-D4 — no custom dismissal logic).

**FRs covered:** FR-42.
**KDDs implemented:** D4.
**Pressure-release valve:** FR-42 IS the pressure-release valve at the epic level. If Epic 11's `DocumentedCase` protocol shape diverges from what Story 10.5 expects, update the call site; do not abandon the popover-with-fallback contract. Document the deviation in `_bmad-output/implementation-artifacts/10-5-pressure-release.md`.

## Epic 11: Per-case selection-strategy docs (stories)

6 stories implement the `DocumentedCase` protocol and its **49** canonical Markdown files (count corrected from "~46" per Paige's audit 2026-05-26 — original miscount dropped `AbstainReason/` (4) and `DemotionReason/` (2) as separate directories). Story 11.1 lands the protocol + accessor + cache; 11.2 reshapes `AnalysisIntensity` to a 10-level enum (depends on Story 6.5 `ComputeBudget`); 11.3 split into 11.3a (24 files: `BPMSelectionPolicy` + `VotingPolicy` + `EnsemblePolicy` + `DSPTechnique`) and 11.3b (25 files: `AnalysisIntensity` + `OctaveEquivalencePolicy` + `MLExecutionPolicy` + `DownbeatResult` + `AbstainReason` + `DemotionReason`) per Amelia's sizing review; 11.4 locks drift detection; 11.5 wires the DocC parallel surface.

### Story 11.1: DocumentedCase protocol, Bundle.module accessor, Mutex<T> cache

**As a** library consumer using Xcode autocomplete,
**I want** every public mode case to expose a `docs: AttributedString` property,
**So that** I can read authored guidance inline without string lookups, network calls, or runtime crashes.

**Acceptance Criteria:**

**Given** the library source tree has no `DocumentedCase` protocol yet,
**When** Story 11.1 lands,
**Then** `Sources/BoomBoomBoomKit/DocumentedCase.swift` declares `public protocol DocumentedCase: Sendable, Hashable` with `static var documentedKind: String { get }`, `var documentationID: String { get }`, and `var docs: AttributedString { get }` per KDD-E2.

**Given** a conformer is `RawRepresentable` where `RawValue == String`,
**When** it adopts `DocumentedCase` without overriding `documentationID`,
**Then** the protocol extension at KDD-E3 returns `rawValue` automatically, so 7 of the 9 target types get the ID derivation for free.

**Given** the accessor must serve concurrent readers under Swift 6 strict concurrency,
**When** `BoomBoomBoomKitDocs.attributedString(for:id:)` is invoked,
**Then** `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift` uses `Mutex<[CacheKey: AttributedString]>` from `import Synchronization`, performs file I/O OUTSIDE the lock, and re-checks the cache under lock before insertion per KDD-E5's double-checked-locking sketch.

**Given** a doc resource is missing, unreadable, or fails `AttributedString(markdown:)` parsing,
**When** any call site reads `.docs`,
**Then** the accessor returns a clear informative fallback `AttributedString` (e.g., `"Documentation unavailable for <kind>.<id>."`) — never empty, never optional, never throws (FR-49).

**Given** the SPM manifest currently has no resource declaration on the `BoomBoomBoomKit` target,
**When** Story 11.1 ships,
**Then** `Package.swift` adds `resources: [.process("Resources/Documentation")]` per KDD-E6, and `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep` reserves the directory until Story 11.3 populates it.

**Given** the protocol family cap rule applies pre-1.0,
**When** the PR is reviewed,
**Then** no sibling protocols (`DefaultProvidable`, `PerformanceAnnotated`, `DeprecatedIn`) ship — KDD-E1 holds at one protocol only.

**FRs covered:** FR-45, FR-46, FR-49, FR-52.
**KDDs implemented:** E-1, E-2, E-3, E-5, E-6.
**Pressure-release valve:** If `Mutex<T>` import surfaces unexpected macOS 15 toolchain friction, fall back to `OSAllocatedUnfairLock` and re-open KDD-E5 as a follow-up — the cache contract (double-checked, I/O outside lock) is the load-bearing invariant. Document the deviation in `_bmad-output/implementation-artifacts/11-1-pressure-release.md`.

### Story 11.2: AnalysisIntensity struct-to-enum reshape with ComputeBudget bundling

**As a** library consumer choosing analysis intensity,
**I want** `AnalysisIntensity` to be a finite enum with documented per-level cases,
**So that** I can exhaustively switch on intensity levels and Xcode autocomplete surfaces guidance for each.

**Acceptance Criteria:**

**Given** `AnalysisIntensity` currently ships as a struct holding a `1...10` `Int` and a `techniqueSet: TechniqueSet`,
**When** Story 11.2 lands,
**Then** `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` redeclares it as `public enum AnalysisIntensity: String, CaseIterable, Sendable, Hashable` with cases `level1` through `level10` per KDD-E4, conforming to `DocumentedCase` with `documentedKind = "AnalysisIntensity"`.

**Given** the named constants `fastest` / `default` / `thorough` / `maximum` must remain source-compatible at the call site,
**When** consumers reference `.fastest`, `AnalysisIntensity.default`, etc.,
**Then** the extension declares `public static let fastest: AnalysisIntensity = .level1`, `public static let default: AnalysisIntensity = .level7`, `public static let thorough: AnalysisIntensity = .level8`, `public static let maximum: AnalysisIntensity = .level10` per KDD-E4.

**Given** `static let default` is NOT pattern-matchable as `case .default:` (Swift parses the identifier as the default-case keyword),
**When** a new contributor writes `switch intensity { case .default: ... }`,
**Then** a custom SwiftLint rule named `analysis_intensity_default_case` in `.swiftlint.yml` rejects the pattern with an error-level violation; the rule ships with at least one positive and one negative test fixture under `Tests/BoomBoomBoomKitTests/LintFixtures/`.

**Given** Story 6.5 introduces `ComputeBudget` carrying the ensemble-budget semantic per KDD-A4a,
**When** Story 11.2 reshapes `AnalysisIntensity`,
**Then** the two breaking changes ship in the same PR per Amelia #3 — struct → enum AND the budget semantic migration — so consumers absorb one upgrade, not two; `AnalysisIntensity.level7` (the new `.default`) wires through `ComputeBudget` exactly as Story 6.5 wired the prior struct's level 7.

**Given** every level needs its own canonical doc file,
**When** Story 11.3 authors prose,
**Then** `Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/level1.md` through `level10.md` exist; Story 11.2 itself only reserves the directory.

**Given** the ablation matrix infrastructure (Story 4-7, 256-combination) consumes `AnalysisIntensity` as a parameter,
**When** the reshape lands,
**Then** `AblationMatrixTests` and any other internal call sites compile cleanly against the enum form; tests use `AnalysisIntensity.allCases` instead of an `Int` range loop.

**FRs covered:** FR-45 (the per-level case docs).
**KDDs implemented:** E-4.
**Pressure-release valve:** If `ComputeBudget` from Story 6.5 slips, Story 11.2 ships the struct→enum reshape alone and adds a marker test verifying `AnalysisIntensity.default == .level7` so the budget bundling can land in a follow-up. Document the deviation in `_bmad-output/implementation-artifacts/11-2-pressure-release.md`.

### Story 11.3a: Author canonical Markdown for BPMSelectionPolicy + VotingPolicy + EnsemblePolicy + DSPTechnique (24 files)

**As a** library author shipping per-case prose for the ensemble-and-selection types,
**I want** every case of `BPMSelectionPolicy` (8), `VotingPolicy` (3), `EnsemblePolicy` (5), and `DSPTechnique` (8) to have a 200-400 word Markdown file with consistent structure,
**So that** the ensemble-decision API surface (the most consumer-visible documented family) ships first with authored prose, and Xcode autocomplete + the demo's strategy popovers surface uniform high-signal guidance for these 24 cases.

**Acceptance Criteria:**

**Given** the 4 types listed (`BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`),
**When** Story 11.3a lands,
**Then** `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` exists for every case across exactly **24 files**: `BPMSelectionPolicy/` (8), `VotingPolicy/` (3), `EnsemblePolicy/` (5), `DSPTechnique/` (8).

**Given** the three-bold-lead authoring style per KDD-E8,
**When** any case file is read,
**Then** the body contains exactly three paragraphs led by `**What it does.**`, `**When to pick it.**`, and `**Tradeoff.**` in that order; total prose length between 200 and 400 words; file size at most 10 KB. **The "Tradeoff" paragraph MUST include at least one concrete failure-mode sentence** (Paige #3, Option A) — e.g., `Tradeoff. Picks the loudest candidate — fails on DnB tracks where octave-doubled candidates self-report higher confidence than the fundamental.`

**Given** YAML front-matter is required per KDD-E7,
**When** each `.md` file is parsed,
**Then** the front-matter block contains `id:` matching the Swift case identifier (e.g., `maxConfidence`, not `max-confidence`), `title:` as a human-readable phrase, and an optional `payload:` field naming the associated-value type for cases that carry one (e.g., `payload: SignalWeights` for `EnsemblePolicy.weightedVoting`).

**Given** filenames must match Swift case identifiers 1:1 per KDD-E7,
**When** `EnsemblePolicy.weightedVoting(SignalWeights)` is documented,
**Then** the file is named `weightedVoting.md` — NOT `weightedVoting_SignalWeights.md`.

**Given** the format MUST stay renderable through `AttributedString(markdown:)` without code blocks, tables, images, or DocC symbol links per KDD-E8,
**When** authors compose prose,
**Then** all 24 files use plain paragraphs with `**bold**` and `_italic_` inline only; the file `Sources/BoomBoomBoomKit/Resources/README.md` documents this restriction and points to `BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` as the place to put tables/code samples.

**Given** Paige's scaffolder Makefile target,
**When** a contributor runs `make new-case TYPE=BPMSelectionPolicy CASE=newCase`,
**Then** the Makefile creates `Sources/BoomBoomBoomKit/Resources/Documentation/BPMSelectionPolicy/newCase.md` by reading `Sources/BoomBoomBoomKit/Resources/Documentation/_template.md` and substituting `{{TYPE}}` and `{{CASE}}` placeholders; the scaffolder refuses to overwrite an existing file; the scaffolder does NOT validate `TYPE` or `CASE` against Swift source (per Paige #5 — fail-late through Story 11.4's validator, not fail-early in the Makefile); `_template.md` ships in the same PR as the scaffolder.

**FRs covered:** FR-46, FR-47, FR-52.
**KDDs implemented:** E-7 (front-matter schema), E-8 (authoring portion for the 4 types).
**Pressure-release valve:** If a specific case genuinely needs a table or code sample to be clear, the author writes plain-prose `.md` for the per-case file AND adds a richer treatment in `BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` (Story 11.5) — the canonical per-case file stays validator-clean. Document the deviation in `_bmad-output/implementation-artifacts/11-3a-pressure-release.md`.

### Story 11.3b: Author canonical Markdown for AnalysisIntensity + OctaveEquivalencePolicy + MLExecutionPolicy + DownbeatResult + AbstainReason + DemotionReason (25 files)

**As a** library author shipping per-case prose for the budget/policy and failure-mode types,
**I want** every case of `AnalysisIntensity` (10), `OctaveEquivalencePolicy` (3), `MLExecutionPolicy` (3), `DownbeatResult` (3), `AbstainReason` (4), `DemotionReason` (2) to have a 200-400 word Markdown file with consistent structure,
**So that** the budget-control + failure-mode documented family ships with authored prose, completing the ~49-file canonical Markdown corpus and unblocking Story 11.4's drift-detection test across every `DocumentedCase` conformer in the project.

**Acceptance Criteria:**

**Given** the 6 types listed,
**When** Story 11.3b lands,
**Then** `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` exists for every case across exactly **25 files**: `AnalysisIntensity/` (10 — `level1.md` through `level10.md`), `OctaveEquivalencePolicy/` (3), `MLExecutionPolicy/` (3), `DownbeatResult/` (3 — `notAttempted.md`, `noneDetected.md`, `detected.md`), `AbstainReason/` (4 — `policyDisabled.md`, `inputBelowMinimum.md`, `confidenceBelowFloor.md`, `sourceSpecific.md`), `DemotionReason/` (2 — `implausibleForContext.md`, `sourceSpecific.md`).

**Given** Paige #1's hard-count rule,
**When** the combined Stories 11.3a + 11.3b close,
**Then** the canonical Markdown corpus totals exactly **49 files** (24 from 11.3a + 25 from 11.3b) — verified by `find Sources/BoomBoomBoomKit/Resources/Documentation -type f -name "*.md" | grep -v '^.*/_' | wc -l` returning 49; the leading-underscore exclusion accommodates `_template.md` from Story 11.3a.

**Given** the three-bold-lead authoring style per KDD-E8 + Paige #3 Option A,
**When** any case file is read,
**Then** the body contains exactly three paragraphs led by `**What it does.**`, `**When to pick it.**`, and `**Tradeoff.**`; the "Tradeoff" paragraph includes at least one concrete failure-mode sentence; prose length 200-400 words; file size ≤ 10 KB.

**Given** the `*Reason.sourceSpecific(String)` escape-hatch cases (Paige #2),
**When** authors write `AbstainReason/sourceSpecific.md` and `DemotionReason/sourceSpecific.md`,
**Then** the doc describes **the pattern** — "this is the escape hatch when a source surfaces a reason that doesn't fit the typed cases" — NOT a specific runtime string value. The "When to pick it" paragraph explains the conditions under which a `MLTechnique` / metadata source / DSP path SHOULD reach for the escape, and the "Tradeoff" paragraph notes the loss of typed-pattern coverage at the pool layer. Example phantom strings (`"modelGateRejected"`) MUST NOT appear as concrete examples — they invite future drift.

**Given** the `AnalysisIntensity` 10-level case naming,
**When** authors write `level1.md` through `level10.md`,
**Then** each file documents the level's tradeoff against the 3 ComputeBudget fractions (`dspFraction` / `mlFraction` / `beatGridFraction`) for that level, cites which `EnsemblePolicy` configurations behave coherently at that intensity, and explicitly notes the `case .default:` SwiftLint footgun for `level7.md` (since `level7` is aliased as `.default`).

**Given** YAML front-matter (KDD-E7),
**When** files are validated by Story 11.4,
**Then** every file carries `id:` matching the case identifier, `title:` as a human-readable phrase, and `payload:` for the two `sourceSpecific(String)` cases plus `whenDSPConfidenceBelow(Double)` and `detected([BeatTimestamp])`.

**FRs covered:** FR-46, FR-47, FR-52, FR-50 (drift-detection-ready surface complete).
**KDDs implemented:** E-7, E-8 (authoring portion for the 6 types).
**Pressure-release valve:** If the 25-file authoring overflows a single dev-agent context window, split further by type group (e.g., 11.3b.i covers AnalysisIntensity + OctaveEquivalencePolicy + MLExecutionPolicy = 16 files; 11.3b.ii covers DownbeatResult + AbstainReason + DemotionReason = 9 files). Document the deviation in `_bmad-output/implementation-artifacts/11-3b-pressure-release.md`.

### Story 11.4: DocumentationValidatorTests with FR-50 drift detection

**As a** maintainer guarding against documentation drift,
**I want** automated tests that fail if a `DocumentedCase` ships without a doc file or if any `.md` violates the authoring rules,
**So that** new cases cannot land without prose and no malformed Markdown reaches consumers via `AttributedString`.

**Acceptance Criteria:**

**Given** Stories 11.3a + 11.3b are both closed on develop (Amelia #2 — Story 11.4 has an implicit dependency on the canonical Markdown actually existing),
**When** Story 11.4 attempts to open its first PR,
**Then** both 11.3a and 11.3b are merged to develop; absent either, this story is blocked (cited dependency, not optimistic concurrency).

**Given** `Tests/BoomBoomBoomKitTests/DocumentedCaseTests.swift` does not yet exist,
**When** Story 11.4 lands,
**Then** the file contains one `@Suite` per documented type with a parameterized `@Test` iterating `Type.allCases`, asserting for each case that `BoomBoomBoomKitDocs.attributedString(for: Type.documentedKind, id: case.documentationID)` returns a non-fallback value (FR-50 drift detection via exhaustive switch over `CaseIterable`).

**Given** the rules enumerated in KDD-E8 (no fenced code, no tables, no images, no DocC symbol links, no heading hierarchy beyond what `AttributedString` accepts, max 10 KB, required bold leads),
**When** `Tests/BoomBoomBoomKitTests/DocumentationValidatorTests.swift` runs,
**Then** the suite contains one `@Test` per rule AND one parameterized `@Test` per `.md` file under `Resources/Documentation/`, so a failure isolates BOTH the offending file and the violated rule.

**Given** the front-matter schema from KDD-E7,
**When** the validator reads each file,
**Then** it confirms the YAML block contains required `id` and `title` keys, the `id` matches the filename stem, the `id` matches a real case on the type named by the parent directory, and optional `payload` (if present) parses as a Swift type identifier.

**Given** the validator must round-trip through the actual rendering path,
**When** a file is validated,
**Then** it is parsed via `AttributedString(markdown: ..., options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))` and the result is asserted non-empty; this catches malformed Markdown that the static rule checks miss.

**Given** adding, removing, or renaming a case MUST fail CI until docs catch up (FR-50),
**When** a contributor adds a new case to e.g. `BPMSelectionPolicy` without authoring `Resources/Documentation/BPMSelectionPolicy/<newCase>.md`,
**Then** the `DocumentedCaseTests` suite fails the exhaustive-switch test for that type, with an assertion message naming the missing case and the expected file path.

**Given** Paige #6's validator-scope rule,
**When** `DocumentationValidatorTests` enumerates files to validate,
**Then** the validator scans `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/*.md` only — files at `Sources/BoomBoomBoomKit/Resources/*.md` (i.e., `Resources/README.md`) are explicitly OUT of scope, and files whose stem begins with `_` (e.g., `_template.md`) are skipped; verified by a dedicated `validatorScopeRespectsReadmeAndTemplates` test that places a deliberately-invalid `_test.md` and a `Resources/README.md` with headings and confirms neither triggers a validator failure.

**Given** the 200-400 word range is a soft authoring target,
**When** word-count validation runs,
**Then** values outside `100...600` words fail; values inside `100...199` or `401...600` emit a Swift Testing `Issue.record` warning rather than a failure.

**FRs covered:** FR-50.
**KDDs implemented:** E-8 (validator portion).
**Pressure-release valve:** If `AttributedString(markdown:)` parsing flakiness surfaces on specific punctuation patterns, the per-file render test is downgraded to a non-fatal `Issue.record` while the structural checks stay fatal. Document the deviation in `_bmad-output/implementation-artifacts/11-4-pressure-release.md`.

### Story 11.5: DocC catalog with transclude generator and articles

**As a** consumer browsing BoomBoomBoomKit's DocC bundle,
**I want** the per-case prose mirrored into a navigable DocC catalog alongside hand-authored selection-strategy and ensemble-preset articles,
**So that** the same content surfaces both inline (via `.docs`) and in DocC's reference site without duplicated authoring.

**Acceptance Criteria:**

**Given** `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/` does not yet exist,
**When** Story 11.5 lands,
**Then** the directory contains `Articles/SelectionStrategies.md` and `Articles/EnsemblePresets.md` as hand-authored narrative articles (tables, code blocks, and DocC symbol links ARE allowed here per KDD-E8) plus a `BoomBoomBoomKit.md` landing page that links them.

**Given** the canonical per-case `.md` files must NOT be duplicated by hand into the DocC catalog (KDD-E8 one-way transclude rule),
**When** `make docc-transclude` runs,
**Then** the Makefile target reads every file under `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/*.md` (skipping `_`-prefixed stems and `Resources/README.md`) and writes corresponding `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/<case>.md` files with **DocC symbol-extension headers prepended** per Paige #4: each generated file (a) strips the YAML front-matter (DocC doesn't parse it), (b) prepends a DocC symbol-link h1 of the form `` # ``<Type>/<case>`` `` derived from the parent directory and filename stem (e.g., `` # ``BPMSelectionPolicy/maxConfidence`` ``), (c) inserts a `@Metadata { @PageKind(symbolExtension) }` block, and (d) preserves the three-bold-lead body verbatim. The generator MUST NOT inject DocC symbol links into the body — only the header.

**Given** the generated `Cases/` directory is a build artifact,
**When** Story 11.5 lands,
**Then** `.gitignore` excludes `Sources/BoomBoomBoomKit/BoomBoomBoomKit.docc/Cases/`, and a `README` note in the `.docc` directory explains that hand-edits to `Cases/*.md` are overwritten — author in `Resources/Documentation/` instead.

**Given** KDD-E8 mandates inline-shell-until-ten-lines for the generator,
**When** the `make docc-transclude` recipe exceeds ~10 lines of shell,
**Then** it is extracted to `scripts/docc-transclude.py` (develop-only, NOT shipped to main) and the Makefile recipe becomes a single `uv run` invocation.

**Given** the generated catalog must stay in sync,
**When** `make docc-validate` runs,
**Then** it (a) invokes `make docc-transclude` against a temp directory, (b) diffs against the committed (or `.gitignore`'d but freshly regenerated) `Cases/` content, and (c) fails CI if the generator output drifts from what would be regenerated.

**Given** DocC must consume the transcluded files cleanly,
**When** `swift package generate-documentation --target BoomBoomBoomKit` runs (or the equivalent xcodebuild docbuild invocation),
**Then** the build completes without warnings about malformed symbol links or missing references, and the resulting `.doccarchive` contains both the hand-authored articles and the per-case pages.

**FRs covered:** FR-46, FR-52.
**KDDs implemented:** E-8 (DocC parallel surface + transclude generator).
**Pressure-release valve:** If DocC fails to ingest the transcluded `Cases/` content cleanly, the catalog ships with `Articles/` only and the per-case pages move to a follow-up — the inline `.docs` accessor (Story 11.1) is the load-bearing surface. Document the deviation in `_bmad-output/implementation-artifacts/11-5-pressure-release.md`.

---

## Epic 12 — Model-quality redesign: octave-aware BPM model (CHARTER / UNPLANNED)

> **Status: CHARTER ONLY (added 2026-06-09 from the Epic-7 BYOW close).** Named so the gap is visible, NOT yet scoped into stories. Needs its own PRD + KDD decision gates before any Story 12.x exists. Do NOT let Epic 8 absorb this — Epic 8 is LUFS/beat-grid/ModelRegistry (plumbing + adjacent surface); it does NOT retrain or improve the BPM model.

**Why this epic exists.** Epic 7 closed BYOW: the v2 TempoCNN fails both bundle gates (OA300 43/82 vs >55; GiantSteps 348/661 vs ≥537). Three retrains proved the failure is **structural, not data-volume**, and a zero-compute diagnostic (E0) localized it: `<100` BPM is clean octave-doubling (38/60 predict exactly 2× truth; Acc2 65% vs Acc1 2%), `100-120` is genuinely mis-pulsed. FR-16's octave-aware *loss* was delivered and the model still doubles — so loss-only is insufficient; representation and decode must be tested before spending capacity. The library's core value prop is "drop-in BPM detection"; BYOW undercuts it. This epic is the path to a bundle-quality model. Evidence: `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md`, `epic-7-retro-2026-06-05.md` close-out addendum. (Codex review 2026-06-09 corrected two over-stated claims below — see the CAVEATS.)

**Provisional scope (sequenced — each gates the next; bigger model is LAST):**
1. **Octave-aware decode** (cheap, no retrain — an EXPERIMENT, not a guaranteed fix) — replace `30 + argmax` with an octave-folded posterior; wire the idle `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as octave arbiter via the SignalPool. E0's Acc2 exposes up to **+53 GiantSteps tracks of octave-confusion *headroom*** (348→401 oracle ceiling) — actual no-retrain recovery must be MEASURED, not assumed, and gated on **per-band net impact** (an aggressive "prefer fundamental" rule can damage the currently-correct 120–175 bands), not just `<100` recovery.
2. **(E1b) Diagnostic-dump expansion** — BEFORE any redesign, and cheaper than it: dump full per-track logits / top-k posterior, decoded BPM + truth, DSP candidate BPMs, segment/window metadata, per-band confusion. Required because the current dumps carry only decoded BPM + `softmaxMax` — you cannot validate an octave-folded posterior decode (step 1) or confirm whether half-tempo softmax mass even exists without this.
3. **Input-representation redesign** — the fixed 30/60/90s-window→512-frame representation is the **prime suspect for poor tempo-scale invariance + corpus-prior leakage** (the model learning the DnB-dominant metrical level as a prior). NOTE: a naive frame-rate argument does NOT explain the slow-tempo failure — at ~5.7 fps a 60-BPM track gets *more* frames/beat than a 174-BPM track, so if anything fast tempo is nearer temporal Nyquist; the mechanism is scale-invariance/prior, not a resample "smear." Candidate fix: tempo-invariant hop or a log-lag/tempogram input. Bumps `featureSetVersion`; re-runs the Swift↔Python parity harness (FR-21). May warrant splitting into its own substrate-v3 sub-epic.
4. **Octave-aware training target + tempo-class rebalance** — soft/Gaussian target, explicit octave penalty, sub-120 oversample.
5. **Bigger model on the Apple Neural Engine** — CoreML/MLProgram `MLTechnique` conformer (the protocol froze at 4-5 DD #18 to allow exactly this), *preferring* `.cpuAndNeuralEngine`, off the current CPU-only BNNS path. The model is ~1.2 MB, so size/bundling is NOT the constraint. Capacity is the *amplifier*, applied only after 1-4 make the signal correct. Deployment traps to scope: ANE scheduling is a *preference not a guarantee* (CPU fallback required), platform/availability gating, simulator behavior, MLProgram packaging as an SPM resource, compile/load latency, model signing posture.

**Dependencies / sequencing.** Comes AFTER Epic 8: Epic 8's ModelRegistry is the distribution channel for whatever this epic produces (bundled or BYOW, a config flip not a `main`-history event), and Epic 8's beat-grid (`SignalSource.beatGrid`, W53) is an independent tempo signal that can cross-check octave errors in the ensemble. The bigger-model training run does not start until step 2 lands with parity green and the ANE inference path (step 4 skeleton) is proven end-to-end — training on a substrate the runtime can't reproduce, or for a backend that can't run it, is wasted compute (the exact Epic-7 mistake).

**Open scoping questions for the PRD:** does the representation redesign stand alone as a substrate epic between 8 and 12? new corpus signoff on par with KDD-B4 against the new representation? does GiantSteps' own sub-120 annotation set need an octave-cleanliness audit (the ruler vs the lens)? Genre/tempo mixture-of-experts is explicitly the LAST resort, not a first move (router-error surface + N model loads + re-bundling).
