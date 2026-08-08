---
stepsCompleted: [1, 2, 3, 4]
epic12Run:
  stepsCompleted: [1, 2, 3, 4]
  completedAt: '2026-08-02'
  validation: 'PASS with three recorded exceptions. (1) 26 of 35 FRs covered by stories; Epic 14''s 9 are knowingly uncovered per operator decision, re-open trigger Gate 1. STILL 26 AFTER STORY 12.2 (2026-08-05): FR-54 and FR-54a stay covered by Epic 12, because the written reject decision IS their coverage. Coverage is not implementation; do not "correct" this count downward on the ground that no classifier was built. The phrasing "covered by stories" is literally true either way, since Story 12.2 is the covering story. (2) Stories 12.4, 12.7 and 12.9 exceed a single dev session and should be split at bmad-create-story time; 12.7 additionally carries operator hand-verification that no agent can complete. (3) Epic 12 delivers one user-facing capability (12.1) and eight measurement/decision deliverables — a deliberate consequence of the learning success condition, not an oversight. Starter template N/A confirmed against architecture.md. Epic 12 / Epic 14 file overlap in _bmad-output/ml-training/ is justified by the Gate-2 risk boundary and the FR-58 feedback loop. Zero forward dependencies.'
  outstandingAfterWorkflow: 'Two coherence gaps this workflow could not close in epics.md alone. (a) Epic 13''s charter still lists items 1 (resolveOctaveAmbiguity sweep) and 2 (beat-grid rescoring), which the operator struck on 2026-08-01 when Epic 12 took the DSP octave levers — Epic 12''s new entry now contradicts Epic 13''s charter. (b) Charter item 7(a) was re-admitted as an explicit post-MVP feature but exists only in this file: the PRD does not mention it, it is not an FR, no story covers it, and GH-138''s three dead public knobs remain ownerless. Also outside this workflow: sprint-status.yaml holds zero epic-12 story keys (bmad-sprint-planning seeds them), and PRD section 6 still has an evidence bound with no cost bound.'
  storiesCreated: 'Epic 12: nine stories (12.1 through 12.9), every dependency backward-pointing. Epic 14: none — deliberately unscoped (operator decision 2026-08-02) because Story 12.5''s FR-58 ranking, not the charter''s, drives everything after F2. Re-open trigger: Gate 1 passes. Section order in this file is now 6, 7, 8, 9, 10, 11, 12-stories, 12-charter (superseded 2026-08-02, retained per the supersession-header convention), 13-charter, 14-chartered.'
  startedAt: '2026-08-01'
  status: 'in-progress'
  epicsDesigned: 'Epic 12 (Measurement integrity and the DSP tempo prior, 26 FRs, STILL 26 after Story 12.2, 2026-08-05: the reject decision on the style classifier IS FR-54/FR-54a''s coverage, and coverage is not implementation) + Epic 14 (Model retrain and delivery, 9 FRs, CHARTERED NOT SCOPED). Split at the Gate-2 boundary: every Epic 12 deliverable survives the stopping rule firing, so the epic cannot be terminated mid-flight the way a single 35-FR Epic 12 could. Epic 13 keeps its number; numbering stays monotonic.'
  partyModeAmendments: '2026-08-02 party-mode review (Winston, Grumbal, Dana, Sally, Mary, John, Paige, Gloria) amended the proposed structure with two requirement-level splits, neither of which was in the first proposal. (1) F1 SPLITS: FR-54a says the style classifier is an unscoped second model this PRD does not build, so Story 12.1 = FR-53 (consumer-specifiable tempo range) alone -- no classifier, no model, no corpus, testable today against the four AccuracyFloorTests fixtures -- and FR-54/54a becomes ~~a later story or explicit deferral plus a written decision on whether the project builds a style classifier~~ RESOLVED 2026-08-05 BY STORY 12.2: the written decision has landed and the answer is REJECT. This project does not build a style classifier. Artifact: `_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`. Neither a later story nor a deferral; the third exit. The replacement octave mechanism is FR-53''s caller-declared bounds, already shipped by Story 12.1. This item is no longer outstanding. Winston caveat carried into the spec: FR-54 mandates reweight-never-hard-filter and a range IS a hard filter, so FR-53 ships opt-in defaulting to current bounds. (2) F5 SPLITS: FR-67 (declare the bin schema a public contract) stays in Epic 12 because reference_arch.py ships to main and a gate-conditional epic would leave GH-147 open indefinitely if Gate 2 fires; FR-66 (align the range) moves to Epic 14 with the retrain. Gloria on the record: the PRD survived four rounds of self-review and its own feature groupings still did not survive contact with sequencing.'
  writeStrategy: 'append-in-place (operator decision 2026-08-01) — step 07 of the workflow specifies overwriting this file from the blank template, which would destroy Epics 6-11 plus both charters. Overwrite REFUSED. Epic 12 requirements are appended to the existing inventory (FR namespace is continuous: the 2026-05-25 PRD ended at FR-52, this one starts at FR-53); the Epic 12 charter section is replaced in place by the generated epic. Epics 6-11 and the Epic 13 charter are not touched. Pre-replacement charter text is recoverable at commit 7d96cf0.'
  lineNumberNotice: 'The step-01 inventory insert shifts every line below it. Citations of the form epics.md:18xx in reconcile-epic12-charter.md, in GitHub issue #166, and in the Epic 13 charter references are stale from 2026-08-01 onward.'
inputDocuments:
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/.decision-log.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md'
epic12InputDocuments:
  - '_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/ml-training/q9-ratio-cluster-2026-08-01.md'
  - '_bmad-output/ml-training/three-source-band-census-2026-08-01.md'
  - '_bmad-output/planning-artifacts/epics.md (Epic 12 + Epic 13 charters, read as input)'
epic12InputsExcluded:
  - 'addendum.md — operator excluded as a formal input; prd.md:23 and :350 cite section A directly, so its conclusions arrive through the PRD regardless'
  - 'reconcile-epic12-charter.md — operator excluded as a formal input; its unresolved divergences remain open scope'
workflowType: 'create-epics-and-stories'
project_name: 'BoomBoomBoomKit'
user_name: 'robbyt'
date: '2026-05-26'
status: 'complete'
completedAt: '2026-05-27'
lastStep: 4
prdReference: 'prd-BoomBoomBoomKit-2026-05-25 (status: final, 51 FRs across 5 epics)'
epic12PrdReference: 'prd-BoomBoomBoomKit-2026-07-26 (status: draft, 35 FRs FR-53 through FR-74 across features F1-F7; one gate outstanding — FR-59f, operator hand-verification of 258 corpus tracks)'
architectureReference: 'architecture.md (status: complete, 27 KDDs resolved, 2026-05-26)'
epic12ArchitectureReference: 'ABSENT — architecture.md is dated 2026-05-25 against the prior PRD and covers epics A-E (Epics 6-11) only. Zero Epic 12 coverage. FR-53 (tempo bounds onto Options, ADR-11 territory) and FR-67/68/69 (bin schema as public contract, bundle gate) have public-API surface with no architecture decision behind them.'
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
  - '2026-07-07: Epic 10 prep party-mode review (John, Winston, Sally, Amelia, Gloria) — operator robbyt directing. Three decisions. (1) Story order = build order: the only Epic 10 inversion was 10.1 (ModelPickerView) consuming 10.2 (BookmarkPersistence), so the two were swapped — BookmarkPersistence is now 10.1, ModelPickerView 10.2 — and the epic runs chronologically 10.1→10.5 with every dep satisfied per step. Cross-refs + pressure-release filenames flipped with the numbers. (2) Story 10.2 folds Epic 9 retro action AI-3: relocate the grandfathered primary-view "Load Model…" button into the picker sheet, restoring FR-43. (3) DocumentedCase seam: robbyt chose scope-into-10.5 over pull-Epic-11-forward. Because DocumentedCase is a LIBRARY protocol (Story 11.1, KDD-E1 one-protocol cap), 10.5 declares a demo-local descriptor protocol bridged to Epic 11 by string docID (not shared type) — Epic 10 now has zero compile-time Epic 11 dependency; docs content still degrades via FR-42. Epic 9 (in-progress, held only by operator GUI smokes) is NOT a blocker: full-speed on Epic 10 per operator. No sprint-status story-keys seeded yet.'
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
- **FR-29** Long-file sync stability. Beat timestamps remain audibly accurate at end of 5+ minute tracks. Numeric drift tolerance committed in acceptance corpus spec. *(UNVALIDATED — see the PRD FR-29 amendment of 2026-07-25, issue #111: the committed 30 ms tolerance measured 1,652 ms, and the gate does not test the audio-accuracy claim.)*
- **FR-30** Playback-aligned timestamps. Beat timestamps line up with audio playback position regardless of input codec (AAC, MP3, FLAC, WAV, AIFF, CAF). Codec priming-delay and SRC do not introduce visible offset.
- **FR-31** BPM and beat-grid consistency contract. Caller sees consistent answers (BPM ≈ beat-grid tempo) OR disagreement surfaced via `tempoAgreedWithBPMStage: Bool?` for arbitration.
- **FR-32** Model registry public type. `ModelRegistry` lists bundled (if any) + user-added + known-public-reference models. Each entry carries identity, integrity, capability compatibility, attribution/license info. In-memory only at library level.
- **FR-33** User-picked models integrity-checked. CryptoKit `SHA256.hash(data:)` validates model integrity at registration. Mismatch → clear error, not silent corruption. Result cached.
- **FR-34** Beat-grid acceptance corpus. Validated against OA300 (DAW oracle ground truth) + stratified DnB subset. Specific F-measure floor + beat-position tolerance committed in training/eval plan. *(MISSED — see the PRD FR-34 amendment of 2026-07-25, issue #111: thresholds were committed in Story 8.7 and measured at F 0.37 vs 0.75; the corpus was also redirected to Rekordbox per DD-13.)*
- **FR-35** Shared decode for combined analysis. Consumers extract BPM + LUFS + beat-grid from a single file decode pass. `DecodedAudio` seam exposed before unified `analyze(...)` API lands.

**Epic 9 — Demo app ML + ensemble UX (formerly Epic D)**

- **FR-36** Demo exposes named ensemble presets in primary view. 4 PRD presets (`Default`, `DSP only`, `ML augmented`, `Trust file tags`) in primary view; raw signal weights in advanced sidebar (existing `.inspector(isPresented:)` from Story 5-6b).
- **FR-37** Model selection from registry + file picker. Demo lets users select an ML model from registry OR add new via file picker. Selection drives subsequent analysis.
- **FR-38** Demo owns persistence for user-added models only. Security-scoped bookmark stored by demo for user-added models. Library accepts already-resolved URLs. Bundled + known-public entries are stateless. Required entitlements: `user-selected.read-write` (the shipped app-level superset — read-only is *sufficient* for the model bookmark and is enforced at bookmark creation via `.securityScopeAllowOnlyReadAccess`, but the audio-file open path already requires read-write; Story 10.1 DD1) + `bookmarks.app-scope`.
- **FR-39** Beat-grid as timeline + text readout. SwiftUI Canvas timeline with current-time scrubber, click-to-scrub (beat-snap), and text readout (tempo, beat count, downbeat status, confidence), on the Epic-8 `BeatGridView` waveform overlay. No new waveform engine. *(Amended 2026-07-11, Story 10-3.)*
- **FR-40** Loudness surfaced as a time-series graph with a labeled scalar summary, subordinate to BPM. LUFS-over-time graph (X time, Y loudness on a fixed dB-FS axis: momentary + short-term series, integrated + max-true-peak reference lines, LRA band) PLUS a compact FR-44-labeled scalar summary (integrated LUFS / true-peak dBTP / loudness range LU). Occupies a subordinate, height-capped region (shares the analysis lane with the beat grid behind a segmented switch); does not dominate the BPM-centric flow. *(Amended 2026-07-11: the original "single number + small panel" wording was superseded by Story 8.1 DD#5 (2026-06-10) — a single integrated number misdescribes dynamic material; 8.1 shipped the momentary/short-term series specifically to enable this time-series rendering. Shipped as `LoudnessGraphView`, d3af680/#96; see sprint-change-proposal-2026-07-11-story-10-4.md.)*
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

#### Epic 12 requirements (PRD `prd-BoomBoomBoomKit-2026-07-26`, extracted 2026-08-01)

Numbering continues the inventory above — the 2026-05-25 PRD ended at FR-52, so there is no collision. Feature groupings are the PRD's own (§5, F1-F7).

**F1 — Style-conditioned tempo prior**

- **FR-53** Tempo search range consumer-specifiable. All four bounds are `private static let` on `BPMAnalyzer` and unreachable from `Options` today (public API change; ADR-11 governs).
- **FR-54** ~~Style-conditioned prior that **reweights, never hard-filters** candidates by plausibility for a classified style. Defaults to no prior so the default path stays byte-identical. Must abstain rather than guess.~~ **REJECTED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** the project does not build a style classifier. **CORRECTED 2026-08-05, same day, after external review:** two claims first written here are withdrawn. ~~There is no classified style left to condition on~~ is false: PRD §14 Q5 names three style sources and only one is a classifier, and this repository already reads file-tag metadata. The accurate statement is that Epic 12 builds **no style-conditioned prior of any kind**, on the product-policy premise recorded in §1.1 of the decision artifact (automatic style inference is outside this library's mission; callers own their own domain constraints). ~~The abstain requirement is satisfied vacuously~~ is also withdrawn: a **rejected** requirement is **inapplicable, not satisfied**. FR-53's caller-declared bounds (`Options.tempoScanRange`, `Options.perceptualWindow`, shipped by Story 12.1) are the alternative octave mechanism the reject exit requires be named; they are **not** Q5's caller-declared-*style* option, which is a different axis and is not built. FR-54 stays **covered by** Epic 12: this decision is its coverage, and coverage is not implementation.
- **FR-54a** **The classifier F1 depends on is an unscoped second model, and this PRD does not build it.** No training corpus, style taxonomy, accuracy gate, or size is specified anywhere. ~~Blocks or rescopes any F1 story.~~ **DISCHARGED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** the written decision this requirement demanded has landed and it is **reject**, taking FR-54a's own second exit (revisit §14 Q5 in favour of the caller-declared option, which needs no model). The four artifacts stay absent, and that absence is the reject basis rather than a gap to fill. FR-54a stays **covered by** Epic 12: this decision is its coverage.
- **FR-55** Measure per-band and per-genre against the four `AccuracyFloorTests` fixtures. **Not all four are octave errors** — `robbyt_x-ray-120s` is a 1.5047 triplet relation, mislabelled at `AccuracyFloorTests.swift:126`. Target set is 3 octave fixtures, not 4.

**F2 — Reference-gap diagnosis**

- **FR-56** Reproduce a published TempoCNN-family baseline end to end and score it on our evaluation path **at our annotation version**. Establishes whether the gap is ours or the ruler's. Baseline settled 2026-08-01: Schreiber & Müller TempoCNN.
- **FR-57** Written differential across every axis separating our pipeline from the reference — input representation, window policy, bin schema, loss, augmentation, corpus composition, decode, evaluation protocol — each labelled *suspect* / *neutral* / *ruled out*, with evidence.
- **FR-58** Rank suspected causes by expected contribution and cost to test. **That ranking, not the charter's, drives everything after F2.**

**F3 — Purpose-built corpus and measurement integrity**

- **FR-59** Band-balanced evaluation corpus across OA300, Tony's Rekordbox collection, and the Story 7.2 non-Rekordbox pool. Balanced to the scarcest band: 43 per band, 258 tracks, six bands (top edge settled 2026-08-01 — `175+` stays separate).
- **FR-59a** Source the scarce bands (100-120, 175+) from the non-Rekordbox pool, subject to two non-optional conditions — **FR-59a.1** forbids corroborating a label with the detector under test; **FR-59a.2** governs cross-corpus partitioning.
- **FR-59b** Declare **one metrical-level convention** and label every track to it. **The load-bearing decision of F3** — the band distribution follows from the convention, not from the music.
- **FR-59c** Per-band inference is possible but narrow. Superseded in part by Q11: per-band is a deterministic tripwire, never a significance claim.
- **FR-59d** Training corpus built for **volume with band-aware sampling**, explicitly **not** balanced to the scarcest band.
- **FR-59e** Training and evaluation corpora share FR-59b's convention and FR-59a.2's partition.
- **FR-59f** Define how a tag becomes ground truth **without using our DSP**. **The one remaining PRD gate**; operator-owned, 258 tracks, blocks F3 and therefore F6.
- **FR-60** Tag every reported accuracy figure with its ground-truth annotation version. Untagged historical figures are marked untagged, never assumed. Precondition of FR-59b.
- **FR-61** Report `Acc2 − Acc1` as a first-class metric alongside Acc1 — the standard octave-error proxy.
- **FR-62** Record the metrical-level convention the project trains toward and audit the training corpus against it. Subsumed into FR-59b for the new corpus; retained for auditing legacy corpora.
- **FR-62a** ~~Re-label affected OA300 tracks.~~ **STRUCK — superseded 2026-07-28 by FR-59b. Must not become a story.**

**F4 — Training-target repair**

- **FR-63** Replace one-hot bin targets with ordinal targets. Justified by general ordinal literature, **not** by TempoCNN (which uses one-hot). Ships with a smearing-vs-one-hot ablation and a sigma sweep — no tempo paper has published either.
- **FR-64** Reconsider octave-partner target mass entirely. The symmetric 0.15 has no published precedent, and `octave_partner_bins` drops out-of-range partners, so above ~142 BPM the full mass lands on the half.
- **FR-65** Log the complete loss configuration into run metadata. `model_metadata.json` records none, so which `octave_mass` prior the retrains used is unrecoverable.

**F5 — Bin-range alignment**

- **FR-66** Align the training bin range with the decode range, or fold out-of-range mass at decode. Bins 0-29 and 171-255 (**115 of 256**) can never produce a usable result against the runtime's `60.0...200.0` abstain.
- **FR-67** Treat the bin schema as a **public contract**. Declared in `tools/coreml-convert/reference_arch.py:37-39` (**ships to main**) and `dataset.py:59-62`, enforced by `BNNSTechnique`'s hard-coded 256 via `MLTechniqueError.binCountMismatch`. All three move together; breaking for BYOW consumers.

**F6 — The bundle gate**

- **FR-68** Gate is **ensemble lift**: DSP+ML beats DSP alone by a stated margin on the 258-track balanced corpus, with **no regression** in any band DSP already handles. OA300 and GiantSteps report as context and **do not gate**.
- **FR-69** State the margin in **tracks, not percentages** (settled after a statistical consult; the original wording was wrong in both its statistic and its conclusion).
- **FR-69a** Multiplicity correction for the 2-of-3 corpus rule. Retired by Q10 along with the multi-corpus gate; `ALPHA` reverts to 0.05.
- **FR-69b** Seed agreement is a robustness guardrail, **not** a substitute for the paired margin.
- **FR-69c** **Unresolved design risks in the gate itself**, raised by the consult and not yet answered. Must be settled before the gate runs.
- **FR-70** Retain the DnB triplet sentinels and a confidence-calibration floor. FR-25's calibration metric was never committed and never ran; here it is a precondition.
- **FR-71** Report per-band lift, never only an aggregate. A deterministic benchmark tripwire (Q11): `gains ≥ losses` required in every predeclared DSP-handled band.

**F7 — Delivery**

- **FR-72** Ship weights inside the demo app archive (`make demo-archive`), **never in the repository**.
- **FR-72a** Bundle the model card into the demo archive and link it from the about screen. Three gaps this does not close.
- **FR-72b** Decide and state what `Options.ensemblePolicy` defaults to once a model ships. It defaults to `.dspOnly`, the operation-inert case — **a model can clear every gate in F6 and change nothing any user sees.**
- **FR-73** Library keeps its BYOW seam unchanged. Absent weights degrade to DSP-only via the existing abstain path — no network, no new dependency, no behavioural change for existing consumers.
- **FR-74** Register the bundled model through `ModelRegistry` for SHA-256 identity verification at load. The digest machinery exists and already handles `.mlmodelc` directory bundles.

### NonFunctional Requirements

- **NFR-1** Swift 6 strict concurrency. All new public types `Sendable`. All async paths data-race-free. `@unchecked Sendable` requires explicit justification.
- **NFR-2** Zero external dependencies. Apple system frameworks only (Foundation, Accelerate/vDSP, AVFoundation, CryptoKit, Synchronization, optional CoreML/BNNSGraph). Hard constraint.
- **NFR-3** Platform: macOS 15+. Minimum deployment. iOS/iPadOS/visionOS expansion out of scope, but architecture must not preclude (no AppKit in public library API; AppKit acceptable in demo).
- **NFR-4** Pre-1.0 framing: no backwards compatibility promised. Authorizes breaking changes for Epic 6 (post-merge corroboration boundary, frozen `merge` signature, `EnsembleCombiner` removal). ABI/source-stability commitment kicks in at 1.0.
- **NFR-5** No prose duplication library→consumers. Documentation source-of-truth lives in library's Markdown SPM resource bundle. Demo and consumers access via typed library APIs, never duplicated string literals.
- **NFR-6** Performance budgets. OA300 wall-clock at default intensity ≤ 15% regression (per FR-11). Beat-grid extraction overhead bounded and measured separately. LUFS analysis cost dominated by file decode (paid for BPM under FR-35 shared-decode). Combined analysis decodes once, not three times.
- **NFR-7** Accuracy floors hold across the refactor. OA300 Acc1 ≥ 55/82 + GiantSteps Acc1 ≥ 537/661 unconditional CI assertions (per FR-10). Trained-model bundling has its own gates (FR-18) beyond these floors.
- **NFR-8** Test discipline. New analyzer/algorithm work includes paired byte-equality opt-out tests where feasible (no longer default contract per NFR-4, but valuable as architecture-refactor regression scaffolding). Drift-detection (FR-50) gates every CI run.
- **NFR-9** App Store compliance (demo). Demo sandboxed (`com.apple.security.app-sandbox`), signs with developer identity, ships via `make demo-archive`. Entitlements: `user-selected.read-write` (app-level superset required by the audio-file open path; the model bookmark itself is read-only via `.securityScopeAllowOnlyReadAccess`) + `bookmarks.app-scope`.
- **NFR-10** No new internet requests. Library and demo make no internet requests from any code in this PRD (per FR-46 + FR-52). Privacy manifest reason codes already covered by Story 5-7.

#### Epic 12 NFRs (PRD `prd-BoomBoomBoomKit-2026-07-26` §10, extracted 2026-08-01)

Two of the PRD's six §10 bullets restate NFR-1 (Swift 6 strict concurrency, `Sendable` on new public types) and NFR-2 (zero third-party dependencies) and are not renumbered. The four that add new obligations:

- **NFR-11** DSP-only output remains **byte-identical**, test-locked by the existing opt-out suite. Stronger than NFR-8, which made byte-equality tests conditional ("where feasible"); for Epic 12 the byte-identity of the DSP-only path is a hard contract, because every lever is additive and the default path must not move.
- **NFR-12** All bulk numeric work goes through vDSP. Previously a `project-context.md` rule only; elevated to an epic NFR because F1's candidate reweighting operates on score arrays.
- **NFR-13** Swift↔Python feature parity holds via the FNV-1a checksum tripwire, and **any substrate change bumps `MLFeatureFrames.currentFeatureSetVersion`** (one constant, never hardcoded at a call site).
- **NFR-14** Every accuracy-affecting change ships a **per-track impact report**. Existing precedent: `make click-impact-report`, `make super-flux-impact-report`, `make bnns-impact-report`.

**Constraints and guardrails (PRD §11), carried as binding context rather than numbered NFRs:**

- Weights are **never committed to the repository**. Git LFS is unusable (SPM support landed on `main` only March 2026, needs a toolchain no macOS 15 consumer has).
- A library owns none of network policy, entitlements, cache location, or user consent. **This is the structural reason delivery goes through the demo app.**
- OA300 is private and never published or referenced outward. It stays an evaluation corpus.
- Cloud training is permitted; reproducibility requirements (FR-65, the parity tripwire) apply identically wherever training runs.
- **Every literature claim traces to primary text.** During Discovery a PDF summarizer fabricated a sigma value, a decode method, and accuracy figures.

**Public surface and dependency policy (PRD §12):**

- `MLTechnique.evaluate(trace:)` is frozen (Story 4-5 DD #18); changes need a named story.
- The 256-bin contract (FR-67) is public via `MLTechniqueError.binCountMismatch`.
- Pre-1.0: breaking changes are permitted and **preferred over compatibility shims**.

### Additional Requirements

Implementation-level requirements derived from `architecture.md` that shape epic/story scoping. (Architecture's 27 KDDs are tracked separately in the epic-level KDD references below — these are the cross-cutting structural requirements that span multiple stories.)

**Starter template / scaffolding:**

- No starter template (brownfield SPM library bootstrapped with `swift package init --type library` and accumulated 30+ stories of conventions). No new initialization story.
- Subfolder creation (`Sources/BoomBoomBoomKit/SignalPool/`, `Sources/BoomBoomBoomKit/FeatureSubstrate/`) happens inside Epic 6 stories, not as separate scaffolding work.
- `Package.swift` updates (platforms expansion to `[.macOS(.v15), .iOS(.v18), .visionOS(.v2)]`, `resources: [.copy("Resources/Documentation")]` — amended from `.process` by Story 11.1, see KDD-E6) land inside their respective Epic stories.

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
- Demo entitlements: `com.apple.security.app-sandbox` + `com.apple.security.files.user-selected.read-write` (app-level superset for the audio-file open path; the model bookmark is read-only via `.securityScopeAllowOnlyReadAccess`) + `com.apple.security.files.bookmarks.app-scope`. The third is the one developers commonly forget for security-scoped bookmark resolution.

**License & provenance:**

- aubio is GPL-3.0. STUDY ONLY the Davies & Plumbley algorithm in `src/tempo/beattracking.c` and the weighted-spectral-filtering technique in `src/onset/onset.c`. NO transcription. NO linkage. Cite via `///` doc comments + Davies & Plumbley 2004-2005 academic papers.
- Frozen surfaces preserved: `MLTechnique.evaluate(trace:) -> MLEvaluation?` (Story 4-5 DD #18). `MLEvaluation` field set (`bpm`, `confidence` only). Field expansion requires named story spec.

**CI / enforcement gates:**

- Unit-test-locked invariants: `BPMSelectionPolicy.allCases.count == 8` (renamed from `CandidateMergeStrategy`), `OctaveEquivalencePolicy.allCases.count == 3` (new), `MLExecutionPolicy.allCases` (associated-value pattern check), `DownbeatResult.allCases` (associated-value pattern check), `AnalysisIntensity.allCases.count == 10` (new — struct → enum reshape).
- CI grep gate (iOS-neutrality): `grep -rE "^import AppKit" Sources/ | grep -v "#if os(macOS)"` returns zero matches. Complements the platforms-array compile-fail tripwire.
- CI iOS compile lane: `swift build -Xswiftc -sdk -Xswiftc iphoneos` clean compile required. Architecture remains macOS-15+ for testing/benchmarks.
- ~~SwiftLint custom rule: ban `case .default:` against `AnalysisIntensity`~~ **RETIRED by Story 11.2 (2026-07-16):** the premise is empirically false — `case .default:` matches `.level7` via expression-pattern `~=` (Hashable ⇒ Equatable), it does NOT mis-parse as `default:`; and a blanket regex would false-positive `EnsemblePolicy.default`. No custom rule; rely on the type checker.
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

#### Epic 12: architecture coverage is ABSENT (recorded 2026-08-01)

**`architecture.md` does not cover Epic 12.** Its frontmatter reads `date: '2026-05-25'` with `inputDocuments: prd-BoomBoomBoomKit-2026-05-25`, and its epic sections are A-E, which are Epics 6-11. A grep for `Epic 12` / `model-quality` / `octave-aware` returns two hits, both describing Epic 7's retraining — the one that failed and closed BYOW.

So the architecture-derived requirements below are the general ones that still bind, not Epic-12 decisions. There are none of the latter.

**Still binding from `architecture.md`:**

- Brownfield framing; no starter template; initialization command N/A. (Epic 12 adds no scaffolding story.)
- **SPM target layout is pinned — no new product targets.** Epic 12 work lands in the existing five targets or not at all.
- Tier-1.5 cross-cutting discipline and the enforcement mechanisms apply unchanged.

**The gap, stated so a story author does not invent decisions to fill it.** Two MVP items carry public-API surface with no architecture decision behind them:

- **FR-53** moves four `private static let` tempo bounds off `BPMAnalyzer` onto `Options` — a public API change governed by ADR-11 (Options-first configuration), with no ADR covering the bounds themselves.
- **FR-67/FR-68/FR-69** make the bin schema a public contract spanning `reference_arch.py` (**ships to main**), `dataset.py`, and `BNNSTechnique.expectedBinCount`, and define the bundle gate — neither has an architecture record.

Whether Epic 12 gets an architecture pass, and whether it happens before or during story creation, is an open decision as of extraction.

### UX Design Requirements

No standalone UX design document exists. UX is captured inline in PRD Epic D / Epic 9 (FR-36 through FR-44) and resolved via architecture KDD-D1 through KDD-D5. The demo's UX requirements appear as Epic 9 FRs above, not as separate UX-DRs.

Treat Epic 9 FRs as both functional requirements AND the UX specification — primary-view ensemble presets, advanced-sidebar diagnostics, beat-grid timeline on the shared waveform view (no new waveform engine), strategy popover with graceful degradation, confidence-label discipline.

**Epic 12: none (recorded 2026-08-01).** Epic 12 is model quality and has no UI. The single place a UX-DR could later apply is **FR-72a**, which links the bundled model card from the demo's about screen — a demo-app surface, and one that inherits the Epic 10 discipline: pin the layout before dev, and an operator GUI smoke gates `done`.

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
| FR-40 | Epic 10 | Loudness-over-time graph + labeled scalar summary, subordinate to BPM (Epic 8 dep; supersedes "single number" per 8.1 DD#5) |
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

**Epic 12 / Epic 14 coverage (PRD `prd-BoomBoomBoomKit-2026-07-26`, mapped 2026-08-02).** All 35 FRs map to exactly one epic; 26 to Epic 12, 9 to Epic 14. **The 26 is unchanged by Story 12.2 (2026-08-05):** FR-54 and FR-54a stay mapped to Epic 12, because the written reject decision IS their coverage. Coverage is not implementation; do not "correct" this count downward on the ground that no classifier was built.

| FR | Epic | Brief |
|---|---|---|
| FR-53 | Epic 12 | Tempo search range consumer-specifiable (**Story 12.1**; no classifier needed) |
| FR-54 | Epic 12 | ~~Style-conditioned prior, reweight never hard-filter (blocked by FR-54a)~~ **REJECTED 2026-08-05 (Story 12.2): superseded by FR-53's caller-declared bounds.** Still covered by Epic 12; the coverage is this decision, not an implementation |
| FR-54a | Epic 12 | The style classifier is unscoped and this PRD does not build it — ~~**a decision the epic owes**~~ **DECIDED 2026-08-05 (Story 12.2): reject.** Still covered by Epic 12; the coverage is this decision, not an implementation |
| FR-55 | Epic 12 | Per-band / per-genre measurement against the four `AccuracyFloorTests` fixtures (3 octave + 1 triplet) |
| FR-56 | Epic 12 | Reproduce Schreiber & Müller TempoCNN on our evaluation path at our annotation version (Gate 0) |
| FR-57 | Epic 12 | Written differential vs the reference, every axis labelled suspect / neutral / ruled out |
| FR-58 | Epic 12 | Rank suspected causes — **this ranking, not the charter's, drives everything after F2** |
| FR-59 | Epic 12 | Band-balanced 258-track evaluation corpus, 43 per band, six bands |
| FR-59a | Epic 12 | Source scarce bands from the non-Rekordbox pool; FR-59a.1 forbids DSP corroboration |
| FR-59b | Epic 12 | Declare one metrical-level convention — the load-bearing decision of F3 |
| FR-59c | Epic 12 | Per-band inference is a tripwire, never a significance claim (Q11) |
| FR-59d | Epic 12 | Training corpus built for volume with band-aware sampling, **not** balanced |
| FR-59e | Epic 12 | Training and evaluation corpora share convention and partition |
| FR-59f | Epic 12 | How a tag becomes ground truth without our DSP — **the one open PRD gate**, operator-owned |
| FR-60 | Epic 12 | Tag every accuracy figure with its annotation version |
| FR-61 | Epic 12 | Report `Acc2 − Acc1` as a first-class octave-error proxy |
| FR-62 | Epic 12 | Record and audit the metrical-level convention for legacy corpora |
| ~~FR-62a~~ | (struck) | Superseded 2026-07-28 by FR-59b — **must not become a story** |
| FR-67 | Epic 12 | Bin schema is a public contract (`reference_arch.py` ships to main) — split from FR-66 |
| FR-68 | Epic 12 | Bundle gate is ensemble lift on the 258-track corpus; OA300 / GiantSteps report, do not gate |
| FR-69 | Epic 12 | State the margin in tracks, not percentages |
| FR-69a | Epic 12 | Multiplicity correction — retired by Q10; `ALPHA` reverts to 0.05 |
| FR-69b | Epic 12 | Seed agreement is a guardrail, not a substitute for the paired margin |
| FR-69c | Epic 12 | Unresolved gate design risks — must be settled before the gate runs |
| FR-70 | Epic 12 | Retain DnB triplet sentinels + a confidence-calibration floor |
| FR-71 | Epic 12 | Per-band lift always, never only an aggregate |
| FR-63 | Epic 14 | Ordinal bin targets, with a smearing-vs-one-hot ablation and sigma sweep |
| FR-64 | Epic 14 | Reconsider octave-partner target mass entirely |
| FR-65 | Epic 14 | Log the complete loss configuration into run metadata |
| FR-66 | Epic 14 | Align training bin range with decode range — needs a retrain to evaluate |
| FR-72 | Epic 14 | Weights ship in the demo archive, never the repository |
| FR-72a | Epic 14 | Model card bundled into the archive and linked from the about screen |
| FR-72b | Epic 14 | Decide `Options.ensemblePolicy`'s default once a model ships |
| FR-73 | Epic 14 | Library BYOW seam unchanged; absent weights degrade to DSP-only |
| FR-74 | Epic 14 | Register the bundled model through `ModelRegistry` for SHA-256 verification |

**Coverage totals:** Epic 6 = 12 FRs · Epic 7 = 14 FRs (harnesses shipped, not outcomes achieved — see the caveat below) · Epic 8 = 10 FRs · Epic 9 = 4 FRs (demo shell) · Epic 10 = 5 FRs (demo integration) · Epic 11 = 6 FRs (per-case docs) · Total = 51 FRs · Cross-cutting NFRs = 10 · Architecture KDDs = 27 (resolved in `architecture.md`).

> **Epic 7 coverage caveat (added 2026-07-26).** The 14 above counts FRs a story shipped a *harness* for, not FRs whose *outcome* was achieved. Four did not land their outcome:
>
> - **FR-16** — the octave-aware loss was delivered and the model still octave-doubles, so the defect lives below the loss function.
> - **FR-18** — gates (b) and (c) were evaluated and both failed: OA300 43/82 against `> 55/82`, GiantSteps 348/661 against `≥ 537/661`. Gates (a) (DnB sentinels) and (d) (calibration) were never evaluated.
> - **FR-24** — structurally un-runnable; no matched two-arm pair existed at the close.
> - **FR-25** — metric and numeric floor never committed, verification never run.
>
> Epic 7 closed **BYOW** on 2026-06-09; no model bundles. Follow-up is the Epic 12 charter below, which is charter-only. Detail lives in the dated FR-18 / FR-24 / FR-25 amendments in `prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` and in the `epic-7-retro-2026-06-05.md` close-out addendum.

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

### Epic 10: Demo integration — beat-grid, LUFS, model selection (split from PRD Epic D — part 2 of 2)

> **Reconciled 2026-07-15 (post-landing).** Epic 10 shipped as commit #91 (demo-only, `Sources/`/`Tests/` byte-identical) BEFORE Epic 11 — inverting the planned dependency described below. Story 10.5's strategy popovers (FR-42) were built, rejected on live operator GUI as prematurely sequenced, and fully **reverted → deferred to Story 11.6**. The "per-case docs popovers" scope and the Epic-11 dependency in this section are the pre-execution plan, retained for audit; the popover / FR-42 lines are historical, not shipped.

The demo's deeper-integration surface — beat-grid timeline rendering, LUFS readout panel, and ML model selection from registry plus user-added models via file picker with security-scoped bookmark persistence. Builds on Epic 8 (beat-grid + LUFS + ModelRegistry public APIs). (Planned-but-reverted: strategy popovers wired to per-case authored prose from Epic 11 via FR-42 graceful degradation — that work moved to Story 11.6, see reconciliation note above.)

Beat-grid renders as a SwiftUI Canvas timeline with current-time scrubber, click-to-scrub (beat-snap), plus text readout (estimated tempo, beat count, downbeat status, grid confidence), merged onto the Epic-8 `BeatGridView` waveform overlay — no new waveform engine per FR-39 (amended 2026-07-11). LUFS displays as a primary integrated-loudness number plus a secondary panel for true-peak and LRA. Model selection draws from `ModelRegistry` (bundled + known-public + user-added); user-added models persist via security-scoped bookmark stored in `UserDefaults` (matching the Story 5-6 `MergeStrategyPersistence` precedent), with required entitlements `com.apple.security.files.user-selected.read-write` (app-level superset; the model bookmark is read-only via `.securityScopeAllowOnlyReadAccess`) + `com.apple.security.files.bookmarks.app-scope`. Strategy popovers ("?" buttons next to ensemble preset / DSP technique / merge strategy controls) anchor SwiftUI `.popover()` to `BoomBoomBoomKitDocs.attributedString(for:id:)` resolution.

**FRs covered:** FR-37, FR-38, FR-39, FR-40 (FR-42 planned but reverted → deferred to Story 11.6, 2026-07-15)

**Architecture KDDs landed in this epic:** KDD-D2 (SwiftUI `Canvas` for timeline), KDD-D3 (`UserDefaults` for bookmark persistence — matches Story 5-6 `MergeStrategyPersistence`). (KDD-D4, SwiftUI `.popover()` for strategy help, was reverted with Story 10.5 → carried to Story 11.6.)

### Epic 11: Per-case selection-strategy docs (formerly PRD Epic E; renumbered after Epic 9 split)

Every public mode case (`BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`, `DSPTechnique`, `AnalysisIntensity`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `DownbeatResult`, `*Reason` enums) carries authored prose via `case.docs: AttributedString` — Xcode autocomplete surfaces documentation without string lookups. Canonical Markdown lives at `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` (49 files — count corrected from "~46" per Paige's audit 2026-05-26; see the Epic 11 stories section), shipped via a `.copy` SPM resource bundle (amended from `.process` by Story 11.1 — see KDD-E6). Documentation renders offline, no network calls. Authoring style: three bold-lead paragraphs (`**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`), 200-400 words per case, 10 KB ceiling, no tables / code blocks / images / DocC symbol links / heading hierarchy. CI validator (`DocumentationValidatorTests.swift`) enforces per-rule + per-file via Swift Testing `@Test` + parameterized smoke test. FR-50 drift detection via exhaustive `switch` over `CaseIterable` fails CI when a new case lands without doc. DocC catalog at `BoomBoomBoomKit.docc/` generates `Cases/` build artifact via `make docc-transclude` from canonical Markdown; `Articles/` carries narrative comparisons (tables, code blocks allowed per DocC). `Mutex<T>` from Swift 6 `Synchronization` module backs the cache with double-checked locking (file I/O outside the lock).

**FRs covered:** FR-45, FR-46, FR-47, FR-49, FR-50, FR-52

**Architecture KDDs landed in this epic:** KDD-E1 (one protocol — `DocumentedCase` — pre-1.0 cap), KDD-E2 (per-instance `var docs` shape), KDD-E3 (raw-value default + exhaustive switch fallback for associated-value enums), KDD-E4 (`AnalysisIntensity` 10-level enum reshape with static-let aliases; bundles two breaking changes per Amelia — paired with KDD-A4a `ComputeBudget`), KDD-E5 (`Mutex<T>` cache + double-checked locking per Axiom Concurrency audit), KDD-E6 (SPM resource bundle for per-case Markdown — **AMENDED BY Story 11.1, 2026-07-15: use `.copy` NOT `.process`**; `.process` flattens `Documentation/<Type>/` to the bundle top level and collides same-basename files like `sourceSpecific.md`, breaking `subdirectory:`-keyed resolution — verified against SwiftPM BundlingResources docs + Codex review), KDD-E7 (minimal 2-field YAML schema + filename-matches-Swift-identifier rule), KDD-E8 (DocC + runtime Markdown as parallel surfaces with one-way transclude).

---

_Epics 12 and 14 below come from a second PRD (`prd-BoomBoomBoomKit-2026-07-26`) and were designed 2026-08-02. Epic 13 keeps its number and stays a charter; numbering remains monotonic._

### Epic 12: Measurement integrity and the DSP tempo prior (PRD `2026-07-26`, features F1 / F2 / F3 / F6-definition / FR-67)

A consumer analyzing drum-and-bass can constrain the tempo search range at the input, so the detector stops reporting 140 for a 70 BPM track without anyone training a model. Alongside that, the project gains the three things it has never had: a reproduced published baseline scored on our own evaluation path, a band-balanced 258-track corpus whose labels were never corroborated by the detector under test, and a bundle gate defined in tracks rather than percentages.

**Every deliverable in this epic survives Gate 2 firing.** That is the point of the boundary. §6's stopping rule can terminate the model programme; it cannot terminate a diagnosis, a corpus, a working prior, or a gate definition. This is the epic that makes the operator's stated MVP success condition — *we know whether a bundleable model is reachable and which lever to fund* — an outcome rather than a consolation.

**FRs covered:** FR-53, FR-54, FR-54a, FR-55, FR-56, FR-57, FR-58, FR-59, FR-59a, FR-59b, FR-59c, FR-59d, FR-59e, FR-59f, FR-60, FR-61, FR-62, FR-62a, FR-67, FR-68, FR-69, FR-69a, FR-69b, FR-69c, FR-70, FR-71 — **26 FRs**. **Still 26 after Story 12.2 (2026-08-05):** FR-54 and FR-54a remain on this list. Story 12.2 rejected the style classifier, and that written decision is their coverage. Coverage is not implementation, so the count does not drop.

**Two features split at the requirement level (party-mode review, 2026-08-02):**

- **F1 splits.** FR-53 (consumer-specifiable tempo range) needs no classifier, no model, and no corpus — it moves four `private static let` bounds off `BPMAnalyzer` onto `Options` and is testable today against the four `AccuracyFloorTests` fixtures. It is Story 12.1. **FR-54 / FR-54a (the style-conditioned soft prior) do not ship behind it**: FR-54a states plainly that the classifier F1 depends on is an unscoped second model this PRD does not build. ~~FR-54 becomes a later story or an explicit deferral, and the epic owes a written decision on whether this project builds a style classifier at all.~~ **DECIDED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`): reject.** No later story and no deferral: this project does not build a style classifier, and FR-53's caller-declared bounds supersede FR-54's delivery mechanism. FR-54 and FR-54a stay covered by Epic 12, because the decision is the coverage. Note the two are not interchangeable — FR-54 mandates *reweight, never hard-filter*, and a consumer-specifiable range is a hard filter by construction. FR-53 therefore ships opt-in, defaulting to today's bounds, so the library's default path cannot acquire the failure mode as a feature.
- **F5 splits.** FR-67 (declare the bin schema a public contract) stays here: it is a statement, it costs nothing to make, and the schema lives in `tools/coreml-convert/reference_arch.py`, which **ships to `main`**. Leaving it in a gate-conditional epic would let a public-contract defect (`#147`, 115 of 256 bins decode-dead) sit in a shipped file indefinitely if Gate 2 fires. FR-66 (align the range, or fold at decode) needs a retrain to evaluate and moves to Epic 14.

**Epic 12 owns the DSP octave levers** (operator decision, 2026-08-01). Epic 13's charter items 1 and 2 are struck, and charter item 7(a) — the `OctaveEquivalencePolicy` + `resolveOctaveAmbiguity` + `SignalPool` arbiter, currently three dead public knobs per `#138` — is re-admitted as an explicit **post-MVP** feature. Taking those levers means inheriting Epic 13's rule that a DSP-path change is not pre-committed before the `resolveOctaveAmbiguity` sweep runs: Story 12.1 either runs that sweep as its first task or the amendment retires the rule with a stated reason.

**Two traps carried into the story specs.** FR-56 must align annotation versions *before* scoring, or Gate 0 measures the ruler and reports it as the model — the exact question it exists to answer. And §6 has an evidence bound (Gate 2 stops after two failed levers) but **no cost bound**, while FR-59f alone is 258 tracks of operator hand-verification.

### Epic 14: Model retrain and delivery (PRD `2026-07-26`, features F4 / FR-66 / F7) — CHARTERED, NOT SCOPED

Consumers get a bundled model that measurably beats DSP alone, delivered inside the demo archive with a verifiable digest. Scoped **only if Gate 0 and Gate 1 pass**; if Gate 2 fires this epic is never written, and nothing in Epic 12 is wasted.

**FRs covered:** FR-63, FR-64, FR-65, FR-66, FR-72, FR-72a, FR-72b, FR-73, FR-74 — **9 FRs**

**Depends on:** Epic 12 in full. FR-58's ranking drives what F4 attempts; FR-68's gate cannot run without FR-59's corpus; FR-72b's ensemble-default decision is meaningless until a model exists. **F7 cannot start until there is a model worth shipping**, which may never be true.

**The live risk this epic carries.** FR-72b: `Options.ensemblePolicy` defaults to `.dspOnly`, the one case that is operation-inert. A model can clear every gate in F6 and change nothing any user sees.

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

Epic 10 (demo integration — beat-grid + LUFS + model selection) [SHIPPED #91, 2026-07-15]
   └─ Depended on Epic 8 (ModelRegistry, BeatGrid, LUFSReport) ONLY.
      The planned Epic 11 (per-case docs accessor) dependency did NOT materialize:
      Epic 10 shipped first, and the FR-42 strategy popovers were reverted and
      deferred to Story 11.6 — so Epic 11 is now fully DOWNSTREAM of Epic 10.
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

> **AMENDED 2026-06-10 — story spec is authoritative** (`_bmad-output/implementation-artifacts/8-1-lufs-public-api-and-lufsreport-promotion.md`). Four factual errors in the ACs below, found by the mandatory pre-spec grep, plus one operator-directed design change:
> 1. `analyzeLUFS` ALREADY EXISTS (`AudioAnalysisService.swift:1001`, `(url:maxSeconds:) throws -> Double?`) — the story is a reshape, not a new sibling.
> 2. Audio fixtures live at `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` (not `Tests/BoomBoomBoomKitTests/Fixtures/`), and no CAF fixture exists — the story generates one.
> 3. The cited Story-6.2 seam surfaces (`analyzeShared(url:options:)` helpers, `BPMDiagnosticTrace` `decodedAudio` field) were never built; the seam-mitigation AC reduces to DocC + README documentation of the new LUFS surface. `DecodedAudio` consumer wiring remains Story 8.2.
> 4. `PCMBufferReaderError.unsupportedSampleRate` is the wrong error domain (the reader CAN decode 22.05 kHz; the K-weighting coefficient table is what cannot proceed) — a new `LUFSAnalysisError.unsupportedSampleRate` is introduced instead.
> 5. **`LUFSReport` is NOT "exactly three fields."** Operator direction (2026-06-10): integrated LUFS as a single number misdescribes dynamic material (quiet intro / loud middle). The report carries the three scalars PLUS momentary (400ms) and short-term (3s) loudness series on the shared 100ms grid (EBU Tech 3341 §2.2), LRA P10/P95 band edges (EBU Tech 3342 §3.1), and a Foundation-only Swift Charts sample adapter — shape proven by rendering through Swift Charts before spec freeze. `Hashable` dropped (`EnsembleDecision` value-carrier precedent); true-peak ships as the single normative max (no time series — BS.1770-5 defines none). `LUFSOptions.maxSeconds` defaults to full-file (was 30s) so integrated/LRA are whole-program per the standard.
> Demo consumption of the chart lands in existing Story 10.4 (shipped as `LoudnessGraphView` — the LUFS-over-time graph; reworked from the originally-spec'd `LUFSReadoutView` in d3af680/#96), whose true dependency is 8.1 only — it may be pulled forward immediately after 8.1 closes. Its chart-probe seed (added in 732e59c "Land epic 8", 22 Jun) has been removed post-reconciliation, its intent realized in `LoudnessGraphView`. Original text preserved below for the audit trail.

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

> PATCHED by the Story 8-2 PR (spec-validation corrections + the DD #10 perf-AC replacement; original wording preserved in git history). Corrections applied: (1) `PCMBufferReader.read(url:)` never existed — the decode entry is `readMonoSamples(from:maxSeconds:targetSampleRate:)`, and the seam producer is the new `readDecodedAudio(from:maxSeconds:)`; (2) the original AC2's "typically a `DecodedAudio` accessor on `BPMDiagnosticTrace` plus a `decodeOnce` parameter on the service Options struct" was REJECTED at spec review (multi-MB PCM in every Sendable trace snapshot; an Options-level DI seam nothing needs) — the promotion list is the one in the story spec's DD #1; (3) the original AC6 was factually impossible — `LUFSAnalyzer` never consumes `OnsetFeatures` (it K-weights raw samples); corrected to: all three consume the SAME `DecodedAudio`, `OnsetFeatures` bit-identity applies to the onset consumers only; (4) the Tier-3 builder inversion is NOT this story (Story 8.4's step-11 insertion owns it, per Story 6.2 DD #8); (5) the ≥ 35% perf gate was asserted, not derived (Codex CRITICAL, panel unanimous) — replaced by the probe-first formulation below; the T0 probe measured the THEORETICAL ceiling (decode share of sequential) at 33.7% (mp3) / 31.3% (flac) / 6.4% (wav-class), so 35% was physically unreachable; (6) `AudioCodec` reshaped to codec semantics + `PrimingInfo` to `{codec, trimState}` (operator-approved pre-1.0 breaks).

**As a** library consumer,
**I want** `analyzeBPM` and `analyzeLUFS` (and the forthcoming `analyzeBeatGrid`) to share a single decode pass via public `DecodedAudio`-accepting overloads on `AudioAnalysisService`,
**So that** combined analysis never pays for the same decode twice (FR-35, structural), and the KDD-C4 seam is in place before Story 8.4's step-11 insertion and any unified `analyze(...)` follow-up.

**Acceptance Criteria (as corrected):**

**Given** the internal `decodeOnce(url:maxSeconds:isCancelled:observer:)` funnel,
**When** `analyzeBPM(url:)` or `analyzeLUFS(url:)` runs,
**Then** `PCMBufferReader.readDecodedAudio` is invoked exactly once per analysis (verified via the internal `decodeObserver` parameter seam), and the shared pattern — one `readDecodedAudio` + `analyzeBPM(decoded:)` + `analyzeLUFS(decoded:)` — decodes once BY CONSTRUCTION (the decoded overloads have no URL parameter).

**Given** the promotion list in the story spec DD #1 (`readDecodedAudio`, the two decoded overloads, `LUFSOptions.isCancelled`, the `AudioCodec`/`PrimingInfo` reshapes, `DecodedAudio.synthetic` in TestSupport),
**When** the PR lands,
**Then** the promotion/removal list appears verbatim in the PR description; no other public surface changes.

**Given** the removed `estimateBPM(samples:sampleRate:options:)` / `measureLoudness(samples:sampleRate:)` entries (operator no-cruft directive),
**When** the migration commit (commit 1, mechanical) lands,
**Then** the full unit suite plus all four corpus floors hold at the exact pre-migration measurement (OA300 Acc1 = 58/82, Acc2 = 74/82; GiantSteps 537/661, 546/661).

**Given** `LUFSAnalyzer` retargeted to consume `DecodedAudio`,
**When** the test suite runs,
**Then** `LUFSByteIdentityTests`' bitPattern literals are untouched and green (decode reuse cannot perturb the K-weighting filter output — Double precision preserved end-to-end), and url-vs-decoded `LUFSReport` equality holds on LPCM/FLAC fixtures at matched `maxSeconds`.

**Given** the perf instrumentation (replaces the original ≥ 35% gate),
**When** `make shared-decode-impact-report` runs in release config,
**Then** (hard, structural) decode-count == 1 on every path; (hard, directional) combined shared-path wall-clock ≤ sequential wall-clock per format within measurement noise; (probe-derived floor, reported) achieved saving ≥ 0.8 × same-run decode median on MP3 + FLAC, wav-class reported-only; the JSON report lands in `_bmad-output/implementation-artifacts/8-2-shared-decode-impact.json`.

**Given** `FeatureSubstrateTests.swift` from Story 6.2,
**When** the cross-consumer assertion runs against one `readDecodedAudio`-produced carrier,
**Then** the `OnsetFeaturesBuilder` facade and the placeholder `BeatGridAnalyzer` stub return bit-identical `OnsetFeatures` for the same `(decoded, weighting)` input, and `LUFSAnalyzer` consumes the SAME `DecodedAudio` value (LUFS shares the decode, not the onset features).

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
**Then** all three types are `public`, `Sendable`, `Hashable`; `BeatGrid` carries exactly five fields (`beats: [BeatTimestamp]`, `downbeats: DownbeatResult`, `estimatedTempo: Double`, `confidence: Float`, `tempoAgreedWithBPMStage: Bool?`); `BeatTimestamp` carries exactly three fields (`presentationTime: Double`, `confidence: Float`, `strength: Float`); `DownbeatResult` carries exactly three cases (`.notAttempted`, `.noneDetected`, `.detected(estimate: DownbeatEstimate)` — enriched from the original `.detected([BeatTimestamp])` by Story 8.5a, see line ~1089).

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

### Story 8.5a: Downbeat detection — fixed-meter downbeat-phase estimation

**As a** library consumer (Rekordbox-style DJ app doing bar/half-bar quantized launch),
**I want** `DownbeatResult.detected` populated with a first-downbeat anchor + the assumed meter when rhythmic evidence is strong, and an honest `.noneDetected` abstain otherwise,
**So that** I can extrapolate bar lines (`anchorTime + barIndex × beatsPerBar / (tempo/60)`) and snap launches to the top of the bar without the library ever fabricating a downbeat it isn't sure of.

A quick follow-up to Story 8.5 (depends on it: consumes `BeatGrid.gridOrigin`/`BeatGridAnchorSource.downbeat`). **First story to POPULATE `DownbeatResult`** — closes the gap that no Epic-8 story did so (8.5 DD #13). Conservative pure-DSP downbeat-*phase* estimator: assume 4/4 (`MeterEstimate { beatsPerBar: 4, source: .assumed }` — NOT pretend-detected), per-beat low-band/percussive accent (reuses `OnsetEnvelopes.subBands` kick/snareCrack/full-band) folded modulo `beatsPerBar` with median aggregation, margin+support confidence, and a 4-part abstain gate (≥3 bars, winner ≥1.25× runner-up, confidence ≥0.4, multi-bar support) → `.noneDetected` when weak (a wrong downbeat on a live deck is worse than none). On success: `gridOrigin.source == .downbeat`. Enriches `DownbeatResult.detected(beats:)` → `.detected(estimate: DownbeatEstimate { beats, meter, confidence, phaseIndex })` (labeled for a stable `Codable` wire-shape; additive-extensible to a future per-beat `Battito` payload). Opt-in `Options.detectDownbeats = false` → BPM byte-identical. aubio fence held — academic references only (Goto; Klapuri/Eronen/Astola; Durand et al. + Böck et al. cited as the ML direction deliberately NOT taken). Full spec: `_bmad-output/implementation-artifacts/8-5a-downbeat-detection.md`.

**FRs covered:** FR-28 (downbeat tri-state — first to populate it).
**KDDs implemented:** C2 (beat/downbeat provenance).
**Deferred:** non-4/4 meter detection, per-beat `Battito` labels, harmonic-change/section downbeats, full-track downbeat correction, ML/DBN models, variable-tempo bar tracking.
**Pressure-release valve:** If the estimator + the type enrichment can't both land in one window, ship the enriched `DownbeatResult`/`MeterEstimate`/`DownbeatEstimate` types + the opt-in flag wired to always-`.noneDetected` (types land, detection deferred), OR ship the estimator against the existing `.detected(beats:)`. Prefer landing the estimator — types without a populator repeat the 8.3 gap. Document in `8-5a-pressure-release.md`.

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

> **Reconciled 2026-07-21 (issue #113; outcome recorded 2026-06-23 in the follow-up note after Story 8.8).** The numeric targets in the ACs below were NOT met and are retained as the pre-execution plan only: measured mean F 0.37 vs the ≥ 0.75 AC, P95 last-beat drift 1652 ms vs the ≤ 30 ms AC (both over constant-tempo subsets; the drift gate is n=450 constant-tempo tracks ≥ 5 min, and it measures raw `beats` against the library's own anchor-plus-tempo extrapolation rather than against the oracle). The committed regression floors are F ≥ 0.33 and the drift harness of Story 8.10; Epic 8 closed accept-as-shipped 2026-07-01 with the accuracy-improvement work pivoted to manual hand-correction levers (8.11/8.12) after auto-refinement (8.9/8.10) did not close the gap. `MODEL_CARD.md` carries the consumer-facing disclosure, extended 2026-07-25 with the long-file divergence figure it had been missing. PRD FR-29/FR-34 and the PRD "Long-file sync drift" risk were amended 2026-07-25 (issue #111) to record this outcome in the FRs themselves.

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

> **Split 2026-06-20 (operator decision):** During spec creation a factual-claims grep found this AC understates the blast radius (real ~13 Swift + 5 Python consumers + the shipping `CorpusTracks` decoders, not the 3 named here) and that 8.7's JAMS decoder is benchmark-internal. Operator ruled "nothing shipping / no BC," so the work was split 3 ways: **8.8a** (relocate the JAMS model into public `BoomBoomBoomKitTestSupport` + add the deferred `tempo`-encode guard + `loadCorpus` adapters; no migration), **8.8b** (OA300 + DAW oracle in-place migration + consumers + `migrate-to-jams.py` + `make oracle-migrate-to-jams`), **8.8c** (DnB regression-config migration — corpus-level `sandbox` for `schema_version`/`regression_threshold`/`captured_with`). 8.8a is the prerequisite for b and c. The AC below is the combined source of truth; per-slice ACs live in `_bmad-output/implementation-artifacts/8-8{a,b,c}-*.md`.

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

---

> **Beat-grid accuracy follow-up (operator decision 2026-06-23).** Story 8.7 measured beat-grid accuracy far below the aspirational targets (F 0.37 vs 0.75; drift P95 1652 ms vs 30 ms) and its pressure-release doc recommended reopening the tracker. 8.7 is now `done` (its job — the measurement harness + regression floors — shipped). The accuracy-improvement work is scoped, via party-mode + two Codex consults (thread `019ef269`), into three focused stories below. Shared framing: keep the Rekordbox-style one-anchor + one-tempo contract; the dominant failure is **tempo precision** (a sub-BPM rate error accumulating as a lever arm across the track), not phase placement. The manual *BPM*-lock primitive already ships (`BeatGridTempoLock.bpm(Double)`, Story 8.9).

### Story 8.9: Beat-grid tempo precision refinement + manual BPM lock

> **Section added retroactively 2026-07-21 (issue #113)** — the story shipped (`done`, spec: `_bmad-output/implementation-artifacts/8-9-beat-grid-tempo-precision-refinement.md`) but never received an epics.md section. Shipped surface: the manual tempo-lock primitive `BeatGridTempoLock.bpm(Double)`. Its automatic integer-DP inter-beat-interval refinement was benchmarked net-negative and reverted (the "reverted Story 8.4/8.9 trap" cited by 8.10 below and by the Epic 13 charter's revert precedent); Story 8.10's continuous-comb approach superseded it.

### Story 8.10: Continuous beat-grid tempo refinement (sub-0.1-BPM) + drift-rate acceptance harness

**As a** Rekordbox-style beat-grid consumer,
**I want** the grid's tempo refined to sub-0.1-BPM precision from the audio's own onset evidence (seeded by the BPM detection result),
**So that** the extrapolated grid does not drift off the beat by the end of a multi-minute track.

Replace `BeatGridAnalyzer`'s `estimatedTempo = tempoBPM` (verbatim, coarse) with a continuous onset-comb period search at sub-frame resolution — NOT integer DP inter-beat intervals (the reverted Story 8.4/8.9 trap). Refined value reported AS the one BPM; residual reject-guard makes it monotonic (byte-identical when off / when the seed wins); opt-in `Options` flag with a byte-identity opt-out test. Primary acceptance = drift-rate / tempo error against the OA300 DAW-verified oracle (verified BPM suffices); Rekordbox JAMS F-measure is a secondary regression check (≥ 0.33). Full spec: `_bmad-output/implementation-artifacts/8-10-beat-grid-continuous-tempo-refinement.md`. **Out of scope:** drop-anchor (8.11), manual anchor reposition (8.12), variable-tempo/multi-segment, ML tempo.

### Story 8.11: Drop-anchored downbeat / measure-top inference

**As a** beat-grid consumer needing bar-aligned (1/1, 1/2) quantization,
**I want** the grid's downbeat / top-of-measure anchored to the track's main structural drop (typically 8/16/24/32 bars in),
**So that** bar-snap lands on the musically-correct downbeat instead of an arbitrary beat-phase guess.

Detect the main energy impact/drop and use its bar-quantized position to place the downbeat / `gridOrigin` (`BeatGridAnchorSource.downbeat`). Builds on and reconsiders the conservative Story 8.5a `DownbeatAnalyzer` (4.4% fire rate, 0.14 correctness). Scored against the Rekordbox `Battito` downbeat oracle. Status: done (reconciled 2026-07-21, issue #113 — was stale "backlog"; spec: `_bmad-output/implementation-artifacts/8-11-drop-anchored-downbeat-and-measure-top.md`).

### Story 8.12: Manual anchor reposition

**As a** DJ-app user hand-correcting a grid,
**I want** to set a new grid start position (anchor) by hand, complementing the existing manual BPM lock,
**So that** I can lock the grid in Rekordbox-style (click a new downbeat, adjust BPM) when auto-detection is off.

Add a pure-value `BeatGrid` transform that repositions `gridOrigin` to a caller-supplied time (deterministic, no re-decode, `source == .manual`), pairing with the already-shipping `BeatGridTempoLock.bpm(Double)`. Status: done (reconciled 2026-07-21, issue #113 — was stale "backlog"; spec: `_bmad-output/implementation-artifacts/8-12-manual-anchor-reposition.md`).

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

5 stories wire the Epic 8 surface (`BeatGrid`, `BeatTimestamp`, `DownbeatResult`, `LUFSReport`, `ModelRegistry`) and Epic 11 docs accessor (`BoomBoomBoomKitDocs.attributedString(for:id:)`) into the `Demo/BoomBoomBoomBPM/` Xcode app. FR-44 confidence-label discipline (from Story 9.3) applies throughout; FR-42 graceful degradation ensures Epic 10 can ship before Epic 11 closes. **Story order = build order (renumbered 2026-07-07):** the only cross-story dependency is 10.2 (ModelPickerView) consuming 10.1 (BookmarkPersistence), so the numbering was swapped to run top-to-bottom with every dependency satisfied at each step — `10.1 → 10.2 → 10.3 → 10.4 → 10.5`. Epic 10 has **zero compile-time dependency on Epic 11**: Story 10.5 declares a demo-local descriptor protocol bridged to Epic 11's library `DocumentedCase` by string `docID` (not shared type), and the docs *content* degrades via FR-42.

### Story 10.1: BookmarkPersistence — security-scoped bookmarks across launches

**As a** demo developer ensuring user-added models survive app restarts,
**I want** a `BookmarkPersistence` helper that stores security-scoped bookmark `Data` in `UserDefaults` and resolves them on launch,
**So that** user-added model URLs from the file picker continue to resolve after the demo relaunches without re-prompting the user.

**Acceptance Criteria:**

**Given** the demo's `Info.plist` and entitlements file are being audited,
**When** the operator inspects `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BoomBoomBoomBPM.entitlements`,
**Then** all three keys are present and `true`: `com.apple.security.app-sandbox` (per NFR-9), `com.apple.security.files.user-selected.read-write` (the actually-shipped app-level superset — read-only suffices for the model bookmark and is enforced at creation via `.securityScopeAllowOnlyReadAccess`, but the audio-file open path already requires read-write; Story 10.1 DD1 — do NOT downgrade), AND `com.apple.security.files.bookmarks.app-scope` — the third is the one developers commonly forget; the story spec explicitly enumerates it so the implementation cannot silently omit it.

**Given** the user picks a model file via the Story 10.2 file picker,
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
**Pressure-release valve:** If `URL.bookmarkData(options: .withSecurityScope, …)` proves unstable for `.mlmodelc` directory bundles specifically, fall back to storing the parent directory bookmark and reconstructing the bundle path on resolve; do not abandon security scope. Document the deviation in `_bmad-output/implementation-artifacts/10-1-pressure-release.md`.

### Story 10.2: ModelPickerView — registry-backed model selection

**As a** demo user evaluating BoomBoomBoomKit's ML augmentation,
**I want** to pick an ML model from a list of registry entries (bundled + known-public references + previously-added) or add a new one via file picker,
**So that** I can compare model behavior across runs without rebuilding the app.

**Acceptance Criteria:**

**Given** the demo launches with no user-added models,
**When** the user opens the model picker sheet from the main window,
**Then** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ModelPickerView.swift` renders a SwiftUI `List` populated by `ModelRegistry.allEntries()` (Epic 8 dependency — story spec cites the upstream `ModelRegistry` API), with each row showing the entry's display name, source category (`Bundled` / `Known-public` / `User-added`), and a labeled integrity status string (e.g., `Integrity: verified` — bare booleans/numerics are FR-44 violations).

**Given** the picker sheet is open,
**When** the user taps "Add model from disk…",
**Then** the view presents an `NSOpenPanel` constrained to `.mlmodelc` bundles and `.mlmodel` files, and on selection invokes `BookmarkPersistence.store(url:)` from Story 10.1 before appending the resolved entry to the registry's user-added slot.

**Given** a registry entry is highlighted,
**When** the user taps "Use this model",
**Then** the demo's analysis service options carry the resolved URL on the next `analyzeBPM(url:options:)` invocation, and the picker dismisses; the previously selected entry is visually marked with a labeled `Selected: yes` indicator.

**Given** `ModelRegistry` returns an empty list (no bundled, no known-public, no user adds),
**When** the picker sheet opens,
**Then** the view renders a non-empty-state explanatory panel ("No models available — add one to begin"), and the "Use this model" button is disabled with a labeled rationale (`Reason: no-models-available`).

**Given** the current demo grandfathers a "Load Model…" button into the primary view (Story 9.3 decision D1),
**When** Story 10.2 lands the model-picker sheet,
**Then** that primary-view "Load Model…" affordance is relocated into the picker sheet (Epic 9 retrospective action AI-3), restoring the FR-43 "primary stays primary" surface that 9.3 grandfathered.

**FRs covered:** FR-37.
**KDDs implemented:** None directly (composes Epic 8's `ModelRegistry`).
**Pressure-release valve:** If `ModelRegistry` from Epic 8 lands late, ship a stub registry that surfaces only the file-picker path; document the dependency in the story implementation artifact and reopen the AC once Epic 8 closes. Document the deviation in `_bmad-output/implementation-artifacts/10-2-pressure-release.md`.

### Story 10.3: Beat-grid timeline + text readout on the merged BeatGridView

> **Amended 2026-07-11** (Sprint Change Proposal, operator UX rework `cac4fe6`/PR #94). The originally-specced separate waveform-free `BeatGridTimelineView` and the Timeline/Waveform view-mode switch were superseded: the beat-grid timeline, scrubber, and readout are **merged into the Epic-8 `BeatGridView`** (one view, sharing its pre-existing waveform overlay), and **click-to-scrub with beat-snapping** was added. FR-39's no-new-waveform-*engine* intent is retained; its "no waveform at all" presentation letter is superseded. See `sprint-change-proposal-2026-07-11.md`.

**As a** demo user evaluating BoomBoomBoomKit's beat-grid output,
**I want** a horizontal timeline showing beats and downbeats with a current-time scrubber and click-to-scrub, on the same view as the waveform, alongside a text readout,
**So that** I can watch the grid track the audio, click to audition a beat, and read the tempo / beat-count / downbeat / confidence numbers without inspecting JSON.

**Acceptance Criteria:**

**Given** a tracked `BeatGrid` (Epic 8 dependency — `BeatGrid`, `BeatTimestamp`, `DownbeatResult`, from `CombinedAnalysisResult.beatGrid`),
**When** the merged `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift` renders,
**Then** it uses SwiftUI `Canvas` (KDD-D2 — not `Path`-in-`ZStack`, not Metal, not `UIView`/`NSView` bridging) to draw vertical tick marks for each `BeatTimestamp` and visually-distinguished marks for `DownbeatResult` positions across a horizontal, zoomable time axis, over the view's waveform overlay.

**Given** the audio is mid-playback,
**When** the playback time advances,
**Then** a vertical scrubber tracks the current time via `TimelineView(.animation)` (a positioned marker, not a per-frame Canvas raster), NOT via `Timer`-driven `@State` mutation; paused, it reads the observable `currentTime` snapshot; the scrubber x is clamped within bounds.

**Given** the timeline is visible,
**When** the user reads the text readout,
**Then** four labeled fields render (FR-44 discipline — no bare numerics): `Estimated tempo: <X> BPM` (`unavailable` for the `0.0` sentinel), `Beat count: <N>`, `Downbeat status: <detected | not-detected | not-attempted>` (the real tri-state), and `Grid confidence: <0.00-1.00>` formatted to two decimals with the literal `Grid confidence:` label.

**Given** the analysis produced a `BeatGrid` but no downbeats (`.noneDetected`),
**When** the view renders,
**Then** the Canvas draws only beat ticks (no downbeat accent marks), and the readout shows `Downbeat status: not-detected` with grid confidence still populated; no silent rendering of zero-confidence downbeats.

**Given** the timeline is visible,
**When** the user clicks the lane,
**Then** the click maps content-x → time via `pointsPerSecond` and **snaps to the nearest raw detected beat** (`clickSeekTime`; exact-midpoint tie → earlier beat; `>= 0` result); a click while stopped/paused starts playback; the transport is a bordered play/pause with a labeled disabled reason and verbatim `playbackError` render; the pure `clickSeekTime`/`scrubberX` helpers are unit-locked in `BeatGridLogicTests`.

**FRs covered:** FR-39.
**KDDs implemented:** D2.
**Pressure-release valve:** If SwiftUI `Canvas` performance degrades at high beat density (e.g., 200+ beats visible), reduce visible-tick density via downsampling at the view layer, not by switching to Metal. Document the deviation in `_bmad-output/implementation-artifacts/10-3-pressure-release.md`.

### Story 10.4: LoudnessGraphView — LUFS-over-time graph + labeled scalar summary

*(Shipped design. Originally specified as `LUFSReadoutView` — a scalar panel — and reworked to the graph in d3af680 / PR #96; reconciled 2026-07-11, see sprint-change-proposal-2026-07-11-story-10-4.md and the story spec's top note. Amendment justified by 8.1 DD#5: a single integrated number misdescribes dynamic material.)*

**As a** demo user comparing tracks for loudness alongside BPM,
**I want** a loudness-over-time graph with a compact labeled scalar summary, sharing one analysis lane with the beat grid,
**So that** loudness information surfaces without competing with the BPM-centric flow.

**Acceptance Criteria:**

**Given** a non-nil `LUFSReport` threaded onto the demo view model (via the best-effort `analyzeLUFS(url:)` wiring this story adds — Epic 8 dependency; DD1),
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/LoudnessGraphView.swift` renders,
**Then** a `Canvas` plot (X time, Y loudness on a fixed −60…+6 dB-FS axis) draws the momentary (thin red) + short-term (light-blue) series with integrated (blue) and max-true-peak (green) horizontal reference lines and a translucent LRA band (drawn only when `loudnessRangeLU` is non-nil); silence / the −100 sentinel pins to the bottom edge.

**Given** the scalar summary row beneath the plot is visible,
**When** the operator inspects the rendered text,
**Then** a compact FR-44-labeled caption row shows integrated LUFS / true-peak dBTP (with a post-mono-mixdown help caveat) / loudness range LU — each unit-labeled, one decimal; a non-finite or ≤-sentinel value renders `unavailable` (never a bare number, never `−100.0`).

**Given** the demo's main analysis result pane is laid out,
**When** the operator inspects the visual hierarchy,
**Then** loudness lives in the merged `analysisSection` lane behind a segmented **Beats | Loudness** switch, height-capped, such that the BPM hero remains the dominant visual element; loudness does NOT take center stage per FR-40 framing.

**Given** `loudnessRangeLU == nil` (the gated programme is < 60 s — LRA is the SOLE optional field; true-peak is a non-optional `Double` and unsupported sample rates *throw*, not nil — DD2),
**When** the view renders,
**Then** the LRA band is omitted and the scalar row shows `Loudness range: unavailable` (labeled fallback) rather than hiding the row or leaking the `−100.0` sentinel. *(This corrects the original AC's factually-wrong "true-peak unavailable for a particular sample rate" example.)*

**Given** the loudness plot is showing,
**When** the operator clicks it or plays back,
**Then** the plot shares the lane's `PlaybackController`; a click seeks to the clicked time (no beat snapping in this pane) and starts playback; the playhead animates via `TimelineView(.animation)`, the `BeatGridView` scrubber split.

**FRs covered:** FR-40.
**KDDs implemented:** None directly (consumes Epic 8's `LUFSReport`).
**Pressure-release valve:** None.

### Story 10.5: HelpButton + strategy popovers wired to Epic 11 docs

**As a** demo user exploring preset / policy / strategy options,
**I want** a "?" button beside each control that opens a popover showing per-case authored prose from Epic 11's docs bundle,
**So that** I can understand what `.optimal` vs `.dnbOptimized` vs `.windowVoting` actually do without leaving the app — and even if Epic 11 hasn't shipped yet.

**Acceptance Criteria:**

**Given** `DocumentedCase` is a **library** protocol Epic 11's Story 11.1 declares (KDD-E1 caps the family at one protocol, pre-1.0) — so Epic 10 must NOT compile-depend on it,
**When** `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift` is implemented,
**Then** it declares a **demo-local** descriptor protocol (e.g. `DemoDocumentedCase`, distinct from the library `DocumentedCase`) exposing `var docID: String` and `var shortDescription: String`, and is `struct HelpButton<T: DemoDocumentedCase>: View` taking a `case: T` parameter and rendering an SF Symbol `questionmark.circle` button. The demo protocol is bridged to Epic 11 by the **string `docID`**, NOT by shared type — a future dev must not make a library enum conform to this demo protocol (Epic 10 party-mode decision, 2026-07-07).

**Given** the user taps the "?" button beside a `TechniqueSet` preset control,
**When** the button's `.popover()` modifier fires (KDD-D4 — SwiftUI `.popover()`, NOT a custom overlay, NOT a sheet, NOT a tooltip-emulation),
**Then** the popover renders the result of `BoomBoomBoomKitDocs.attributedString(for:id:)` keyed by `case.docID` (Epic 11 dependency — public library accessor that hides `Bundle.module` resolution; referenced by string id, absent-until-Epic-11 per FR-42, wired at the call site when Story 11.1 lands).

**Given** Epic 11 has NOT yet shipped or `BoomBoomBoomKitDocs.attributedString(for:id:)` returns `nil` (FR-42 graceful degradation),
**When** the popover would render,
**Then** the view falls back to a two-element view: a one-line description sourced from `case.shortDescription` (declared on the demo-local descriptor protocol — demo-authored, so the fallback needs nothing from Epic 11) and a `Link` to the repo's GitHub docs URL for that case — NOT a broken `Bundle.module` lookup, NOT an empty popover, NOT a crash, NOT a hidden button.

**Given** the demo is built without Epic 11's Markdown resource bundle present (simulated by stubbing the docs accessor to return `nil` for all IDs),
**When** the operator clicks every "?" button in the demo across every wired control,
**Then** every popover opens with the fallback prose + repo URL, and zero `Bundle.module` resolution errors appear in the console — FR-42 graceful degradation is observable end-to-end.

**Given** the popover is dismissed,
**When** the user taps outside the popover or presses `Escape`,
**Then** the popover dismisses via SwiftUI's native `.popover()` behavior (KDD-D4 — no custom dismissal logic).

**FRs covered:** FR-42.
**KDDs implemented:** D4.
**Pressure-release valve:** FR-42 IS the pressure-release valve at the epic level. The demo-local descriptor protocol + string-`docID` bridge (above) already decouples Epic 10 from Epic 11's type shape, so a `DocumentedCase` divergence only touches the string-keyed accessor call site — update it there; do not abandon the popover-with-fallback contract. Document the deviation in `_bmad-output/implementation-artifacts/10-5-pressure-release.md`.

## Epic 11: Per-case selection-strategy docs (stories)

7 stories implement the `DocumentedCase` protocol and its **49** canonical Markdown files (count corrected from "~46" per Paige's audit 2026-05-26 — original miscount dropped `AbstainReason/` (4) and `DemotionReason/` (2) as separate directories). Story 11.1 lands the protocol + accessor + cache; 11.2 reshapes `AnalysisIntensity` to a 10-level enum (depends on Story 6.5 `ComputeBudget`); 11.3 split into 11.3a (24 files: `BPMSelectionPolicy` + `VotingPolicy` + `EnsemblePolicy` + `DSPTechnique`) and 11.3b (25 files: `AnalysisIntensity` + `OctaveEquivalencePolicy` + `MLExecutionPolicy` + `DownbeatResult` + `AbstainReason` + `DemotionReason`) per Amelia's sizing review; 11.4 locks drift detection; 11.5 wires the DocC parallel surface; 11.6 (added 2026-07-12) wires the demo strategy popovers to the authored docs — the FR-42 work deferred from the reverted Story 10.5.

### Story 11.1: DocumentedCase protocol, Bundle.module accessor, Mutex<T> cache

**As a** library consumer using Xcode autocomplete,
**I want** every public mode case to expose a `docs: AttributedString` property,
**So that** I can read authored guidance inline without string lookups, network calls, or runtime crashes.

**Acceptance Criteria:**

**Given** the library source tree has no `DocumentedCase` protocol yet,
**When** Story 11.1 lands,
**Then** `Sources/BoomBoomBoomKit/DocumentedCase.swift` declares `public protocol DocumentedCase: Sendable` with `static var documentedKind: String { get }`, `var documentationID: String { get }`, and `var docs: AttributedString { get }` per KDD-E2. **AMENDED BY Story 11.1 Review pass 1, 2026-07-15: `Hashable` DROPPED from the superprotocol bound** (was `Sendable, Hashable`) — 3-reviewer consensus (Blind Hunter + Edge Case Hunter + Codex): the bound is unused by the docs mechanism (the cache keys on an internal `(kind,id)`, never on `Self`) and overturns `MLExecutionPolicy`'s checked-in `Sendable, Equatable` (deliberately non-`Hashable`, NaN-bearing `Double`), a named future conformer. KDD-E2 governs only the `var docs` shape, not the bound — nothing in KDD-E2 changes.

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
**Then** `Package.swift` adds `resources: [.copy("Resources/Documentation")]` per KDD-E6 (amended 2026-07-15: `.copy`, not `.process` — preserves the `Documentation/<Type>/` subdir structure the accessor resolves against), and `Sources/BoomBoomBoomKit/Resources/Documentation/.gitkeep` reserves the directory until Story 11.3 populates it.

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

**~~Given `static let default` is NOT pattern-matchable as `case .default:`~~ — RETIRED by Story 11.2 (2026-07-16), premise empirically false.**
`case .default:` on `AnalysisIntensity` compiles and matches `.level7` via expression-pattern `~=` (Hashable ⇒ Equatable) — it does NOT parse as the `default:` keyword (verified by `swift` compile). A blanket `case .default:` SwiftLint regex would also false-positive `EnsemblePolicy.default`, a genuine case switched in the same files. **No custom SwiftLint rule, no `LintFixtures/`.** Instead, Story 11.2 adds `Comparable` (ordinal scale), a `var level: Int` accessor, and a failable `init?(level:)`. The one real nuance to document (not police): an expression pattern does not establish enum exhaustivity, and `case .default:` must precede any real `default:`.

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
**Then** every file carries `id:` matching the case identifier, `title:` as a human-readable phrase, and `payload:` for the two `sourceSpecific(String)` cases plus `whenDSPConfidenceBelow(Double)` and `detected(estimate: DownbeatEstimate)` (corrected from the stale `detected([BeatTimestamp])` — Story 8.5a enriched the payload).

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

### Story 11.6: Demo strategy popovers wired to DocumentedCase docs (FR-42 — deferred from Story 10.5)

> **Deferred from Story 10.5 (reverted 2026-07-12).** Story 10.5 built the generic demo `HelpButton` + injected docs-resolver seam, then reverted it as **prematurely sequenced**: before authored docs exist, a "?" docs-popover is redundant with the demo's always-visible inline subtitles, a UX downgrade, or confusing. It belongs here — wired to the real per-case prose from Stories 11.1/11.3. The full reverted implementation, the resolver-seam / string-`docID`-bridge pattern, and the UX rules are captured in `_bmad-output/implementation-artifacts/fr42-demo-popover-design-note.md`.

**As a** demo user exploring the analysis controls,
**I want** a "?" button that opens a popover with the authored per-case docs (graceful fallback when a doc is missing),
**So that** I can read the full "what + why" for a strategy/policy without leaving the app.

**Acceptance Criteria (stub — expand via `bmad-create-story` when 11.1 + 11.3 have landed):**

**Given** Story 11.1's `BoomBoomBoomKitDocs.attributedString(for:id:)` accessor and the authored Markdown (11.3a/11.3b) exist,
**When** the demo wires the popover,
**Then** it reintroduces the generic `HelpButton<T: DemoDocumentedCase>` + injected `@Entry docsResolver` seam (per the design note), and overrides the resolver **once** at the demo app root to split the demo `docID` (`"kind/id"`) and call the two-arg `attributedString(for:id:)` accessor — the demo bridges by the string `docID` ONLY and never conforms a library enum to the demo protocol (KDD-E1).

**Given** the "inline caption vs popover" UX rule,
**When** deciding where to attach a "?",
**Then** wire it ONLY where the authored prose **materially exceeds** the existing always-visible inline subtitle (a per-control call made against the real content — merge strategy? ensemble? maybe neither); keep inline one-liners for orientation; never add or distort a control just to host a popover; leave the graph-legend popovers (`BeatGridHelpButton`/`LoudnessHelpButton`) as separate specialized UI.

**Given** a doc is missing or the id is unknown,
**When** the popover renders,
**Then** it degrades to the case's short description + a repo docs `Link` (FR-42) — noting that 11.1's accessor is non-optional and owns its own informative fallback, so the demo fallback is the belt-and-suspenders path.

**FRs covered:** FR-42.
**Depends on:** Story 11.1 (accessor), 11.3a/11.3b (authored Markdown). Demo-only; `Sources/`/`Tests/` byte-identical.
**Reference:** `_bmad-output/implementation-artifacts/fr42-demo-popover-design-note.md`, `_bmad-output/implementation-artifacts/10-5-helpbutton-and-strategy-popovers-wired-to-epic-11-docs.md` (reverted 10.5 audit record).

---

## Epic 12: Measurement integrity and the DSP tempo prior (stories)

Nine stories, designed 2026-08-02 from `prd-BoomBoomBoomKit-2026-07-26`. Every dependency points backward — no story requires a later one. FR coverage: 25 mapped + FR-62a struck = 26.

**Binding NFRs.** NFR-11 (DSP-only output byte-identical) is hard for Story 12.1. NFR-14 (per-track impact report) binds any accuracy-affecting story. NFR-13 (`featureSetVersion` bump on any substrate change) binds 12.4 and 12.7. No UX-DRs.

**Epic-level pressure-release valve.** §6 Gate 0 can stop this epic at Story 12.4. If the reference baseline also scores near 52 on our evaluation path, stories 12.5 onward are re-planned rather than executed, and the finding is the deliverable. Document at `_bmad-output/implementation-artifacts/12-gate0-pressure-release.md`.

> **GATE 0 RAN AND DID NOT FIRE (2026-08-08).** Story 12.4 reproduced the reference baseline at 545/661 FR-18-strict on our evaluation path, against our model's 348/661 and the pre-registered midpoint threshold of 446.5; verdict `gap-attributable-to-our-model` (`_bmad-output/implementation-artifacts/12-4-tempocnn-baseline-report.md`). The pressure-release document was not needed; Story 12.5 executed as planned. The paragraph above is retained as the record of the rule as written before the measurement.

### Story 12.1: Consumer-specifiable tempo search range

As a consumer integrating BoomBoomBoomKit into a drum-and-bass application,
I want to constrain the tempo search range at the input,
So that the detector stops reporting 140 for a 70 BPM track without my having to train or supply a model.

**Acceptance Criteria:**

**Given** Epic 12 inherited Epic 13's rule that a DSP-path change is not pre-committed before the `resolveOctaveAmbiguity` sweep runs,
**When** the story begins,
**Then** that sweep runs as the first task and its per-threshold OA300 + GiantSteps results are recorded,
**And** if the sweep is skipped instead, the inherited rule is retired in writing with a stated reason — silently dropping it is not permitted.

**Given** the four tempo bounds are `private static let` on `BPMAnalyzer` and unreachable from `Options` (FR-53),
**When** the range becomes consumer-specifiable,
**Then** it is exposed through `AudioAnalysisService.Options` per ADR-11 as a non-optional defaulted field, never as an `analyzeBPM` parameter,
**And** the carrying type is `Sendable`.

**Given** default `Options`,
**When** `analyzeBPM` runs on any fixture,
**Then** output is byte-identical to the pre-story pipeline — `Double.bitPattern` equality on `bpm` and `confidence`, element-wise on `candidates` (NFR-11),
**And** a paired byte-equality opt-out test ships with the story.

**Given** an invalid range — `min >= max`, non-finite, or outside the `30...300` envelope,
**When** `Options` carries it,
**Then** the value is normalized following the `votingThreshold` precedent (silently clamped; NaN and infinity normalized) rather than throwing,
**And** the normalization is documented on the property.

**Given** the four `AccuracyFloorTests` known-failure fixtures,
**When** a range excluding the erroneous octave is supplied,
**Then** `Meta_Man` (92 → 182), `Meta_Man_La_Noche_Digital_` (96 → 191.76) and `Submerged_Lament` (70 → 140.12) resolve within tolerance,
**And** `robbyt_x-ray-120s` is **not** expected to resolve — it is a 1.5047 triplet relation, not an octave error, so the target set is three fixtures, not four (FR-55).

**Given** `AccuracyFloorTests.swift:126` **already** records that fixture as `triplet-related: reports ~115.6, two-thirds of 174 (3:2)`,
**When** the story lands,
**Then** that label is left unchanged — **(CORRECTED 2026-08-02, during Story 12.1 creation.** An earlier version of this AC read "the label is corrected", which inverted FR-55. FR-55's point is that an earlier draft of *the requirement* called all four fixtures octave errors and the file contradicts that draft; the file is right. Acting on the original AC would have sent a dev agent to change correct code.**)**

**Given** the four bounds are two pairs with different semantics — `minBPM`/`maxBPM` (40/250, candidate scan) and `perceptualMinBPM`/`perceptualMaxBPM` (60.0/200.0, the octave-normalization target consumed by `BPMAnalyzer.rangeNormalize`),
**When** they become consumer-specifiable,
**Then** each pair is exposed and documented separately, because widening the scan range and moving the octave-fold window are different operations with different blast radii,
**And** the perceptual pair carries the invariant `perceptualMax >= 2 * perceptualMin`, since `rangeNormalize`'s two sequential loops return a value below `perceptualMinBPM` when the window is narrower than one octave.

**Given** this is an accuracy-affecting change,
**When** the story lands,
**Then** a per-track impact report ships with per-band and per-genre breakdown (FR-55, NFR-14),
**And** the four unconditional corpus floors hold: OA300 Acc1 ≥ 57/82 and Acc2 ≥ 73/82, GiantSteps Acc1 ≥ 537/661 and Acc2 ≥ 546/661.

### Story 12.2: Style-classifier decision — scope it, defer it, or reject it

As the project lead,
I want a written decision on whether this project builds a style classifier,
So that FR-54's style-conditioned prior stops shadowing F1 with a dependency nothing produces.

**Acceptance Criteria:**

**Given** FR-54a states the classifier F1 depends on is an unscoped second model this PRD does not build,
**When** the decision is recorded,
**Then** it selects exactly one of: **scope it** — naming training corpus, style taxonomy, its own accuracy gate, and size/latency budget; **defer it** — with a named re-open trigger in `deferred-work.md`; or **reject it** — naming the alternative octave mechanism that replaces it.

**Given** the decision is *scope it*,
**When** it lands,
**Then** a follow-on story is created and Epic 12's FR count and MVP scope are amended in `epics.md` and the PRD.

**Given** the decision is *defer* or *reject*,
**When** it lands,
**Then** FR-54 is annotated in `epics.md` with the decision and date,
**And** no remaining Epic 12 story depends on it.

**Given** FR-54 mandates *reweight, never hard-filter* while Story 12.1 ships a range that is a hard filter by construction,
**When** the decision is recorded,
**Then** it states explicitly whether the two mechanisms coexist or one supersedes the other.

**Given** this story is a decision and not a build,
**When** it closes,
**Then** `Sources/` and `Tests/` are byte-identical.

**OUTCOME 2026-08-05: reject.** The decision artifact is `_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`. This project does not build a style classifier. The replacement octave mechanism the reject exit requires be named is FR-53's caller-declared bounds, shipped by Story 12.1 as `Options.tempoScanRange` and `Options.perceptualWindow`. The two mechanisms do not coexist: FR-53 supersedes FR-54's delivery mechanism, ~~because with no classifier there is no style left to condition on~~ **CORRECTED 2026-08-05, same day: that reason is false** (Q5 names two non-classifier style sources, and file-tag metadata is already read here) **and is replaced by the scope statement it should have been:** Epic 12 builds no style-conditioned prior of any kind, on the product-policy premise recorded in §1.1 of the decision artifact. The hard-filter objection is answered by opt-in defaults rather than dismissed. Nothing downstream is stranded: the Story 12.3 through 12.9 sections contain zero occurrences of `FR-54`, `classif`, `style`, `genre`, `taxonom` or `prior`, and no §6 gate references FR-54. The decision reverses the operator decision recorded at PRD §14 Q5 on 2026-07-28, and says so in those words. It does **not** refute Hörschläger et al. SMC 2015, but *not* for the reason first written here. ~~Story 12.1 tested a hard-filtered window where FR-54 specifies soft reweighting~~ **CORRECTED 2026-08-05, same day:** that mechanism distinction is withdrawn as unsound, because PRD §4.3 (`prd.md:101` as of 2026-08-05) states the published prior as a *range* ("DnB prior 130-180 BPM"). Note the converse does not follow either: that the prior is *stated* as a range does not establish whether it was *applied* as a search constraint or as a reweighting. That remains unverified and is filed as deferred work. The sound reason is that **Story 12.1 did not test the published configuration on either axis**: it moved `Options.perceptualWindow`, the octave-*normalization* window, rather than `Options.tempoScanRange`, which sizes the candidate *search* (the impact report's own `metric` field reads "only perceptualWindow moved"), and it moved it to `100...200` rather than the published `130-180`. ~~AS-7's transfer assumption is therefore weakened, not settled, and is annotated WEAKENED at `prd.md:485`.~~ **CORRECTED 2026-08-05, same day: AS-7 is UNTESTED, not weakened.** The WEAKENED verdict rested on calling the 12.1 report "the first direct test" of the SMC result. It is not a test of style-prior transfer at all: it inferred no style, accepted no declared style, and conditioned nothing by style. AS-7 is annotated **UNTESTED** in the PRD §15 assumptions table (`prd.md:489` as of 2026-08-05). A consequence worth stating: the published prior being a range makes FR-53's caller-declared bounds a **closer** analogue of the published mechanism than the reject rationale first implied. The residual questions, running `tempoScanRange` at the published `130...180`, and whether candidate *reweighting* beats range *bounding*, are filed in `deferred-work.md` with re-open triggers. Epic 12's FR count is unchanged at 26. Note that Story 12.1 is at `review`, not `done`, so a review change to `TempoScanRange` or `PerceptualTempoWindow` is itself a re-open condition for this decision.

> **EVIDENCE ADDENDUM 2026-08-06 (Story 12.2 SMC hard-bound replication,
> `_bmad-output/implementation-artifacts/12-2-smc-prior-replication.md`).** The residual
> experiment named above -- running `tempoScanRange` at the published `130...180` -- has
> now been run over three corpora. It is negative: drum-and-bass Acc1 falls 58 to 54 on
> OA300, 466 to 361 octave-strict on GiantSteps, and 510 to 492 on the FR-14-conformant
> Tony slice. All-tier Tony is +44, the one positive number, carried entirely by the 312
> Marginal-tier rows FR-14 excludes. **This supersedes two current-state claims in the
> paragraph above**: that AS-7 is wholly untested, and that running this bound is still
> deferred work. AS-7 is re-annotated at PRD §15 (`prd.md:489` as of 2026-08-06).
>
> **What it does NOT settle, and the paragraph above already says why.** The caution
> recorded above -- that a prior *stated* as a range does not establish whether it was
> *applied* as a search constraint or as a reweighting -- is correct and stands. This run
> used a hard filter, so it bounds the hard-filter reading and leaves the soft-reweighting
> form FR-54 actually specifies untested. The corresponding deferred-work item is
> **resolved in part, not closed**. The reject decision is unaffected: it rests on the
> product-policy premise, not on this evidence.

### Story 12.3: Annotation-version tagging and the octave-error metric

As an engineer comparing an accuracy figure across corpora and dates,
I want every reported figure tagged with its ground-truth annotation version, and `Acc2 − Acc1` reported alongside Acc1,
So that a number measured with one ruler is never silently compared against another.

**Acceptance Criteria:**

**Given** a benchmark emits an accuracy figure,
**When** it is reported,
**Then** it carries the annotation version of the ground truth it was scored against (FR-60).

**Given** historical figures whose annotation version is unknown,
**When** they are surfaced,
**Then** they are marked `untagged` rather than assumed to match current labels.

**Given** any accuracy report,
**When** it is emitted,
**Then** `Acc2 − Acc1` appears as a first-class metric alongside Acc1, not as a derived footnote (FR-61).

**Given** GiantSteps has a documented annotation swing (TISMIR 2020),
**When** its figures are reported,
**Then** the versions are distinguishable from each other by tag.

**Given** Story 12.6 will declare a single metrical-level convention that makes every old-label figure incomparable,
**When** this story closes,
**Then** the tagging scheme is already in place, so that transition is survivable rather than silently confusing.

**Given** this is measurement infrastructure,
**When** the story lands,
**Then** `Sources/` is byte-identical; changes are confined to the benchmark and test-support surface.

### Story 12.4: Reproduce the TempoCNN reference baseline (Gate 0)

As the project lead,
I want a published TempoCNN-family baseline reproduced and scored on our own evaluation path at our own annotation version,
So that Gate 0 can establish whether the thirty-point gap is our model or our ruler.

**Acceptance Criteria:**

**Given** FR-56 requires reproducing a published TempoCNN-family baseline end to end, and the baseline is Schreiber & Müller TempoCNN (settled 2026-08-01 — same 256-bin family as our design, published weights),
**When** reproduction begins,
**Then** the weights are obtained and their provenance and checksum are recorded.

**Given** TempoCNN is a Keras model and our runtime is Swift,
**When** the harness is built,
**Then** it lives under `_bmad-output/ml-training/` as develop-only Python — **not** under `tools/coreml-convert/`, which is the only Python that ships to `main` and whose scope is the consumer convert CLI.

**Given** the published figure and ours may rest on different ground-truth annotation versions,
**When** the baseline is scored,
**Then** annotation versions are aligned **first** and the alignment is recorded,
**And** the story states plainly that skipping this step makes Gate 0 measure the ruler and report it as the model — the exact question the gate exists to answer.

**Given** the baseline has been scored on our evaluation path,
**When** results are reported,
**Then** they appear alongside our DSP path's 81.2% GiantSteps Acc1 at the same annotation version.

**Given** the reference baseline also scores near 52 on our evaluation path,
**When** that result lands,
**Then** **Gate 0 fires**: the report states the problem is measurement rather than modelling, stories 12.5 onward are re-planned rather than executed, and the pressure-release artifact is written.

**Given** PRD §11 requires every literature claim to trace to primary text after a summarizer fabricated a sigma value, a decode method, and accuracy figures during Discovery,
**When** the baseline's published numbers are cited,
**Then** each traces to the paper itself, not to a summary.

**Given** this is diagnostic work,
**When** the story lands,
**Then** `Sources/` and `Tests/` are byte-identical.

### Story 12.5: Pipeline differential and cause ranking

As the project lead,
I want a written differential across every axis separating our pipeline from the reference, with suspected causes ranked,
So that no lever is funded on a guess.

**Acceptance Criteria:**

**Given** Story 12.4 produced a baseline scored on our evaluation path,
**When** the differential is written,
**Then** it covers every axis FR-57 names: input representation, window policy, bin schema, loss, augmentation, corpus composition, decode, and evaluation protocol.

**Given** each axis,
**When** it is assessed,
**Then** it carries exactly one label — `suspect`, `neutral`, or `ruled out` — with the evidence that earned it.

**Given** the axes are labelled,
**When** the ranking is produced,
**Then** suspected causes are ordered by expected contribution and cost to test (FR-58).

**Given** the ranking exists,
**When** it is recorded,
**Then** `epics.md` states that it supersedes the charter's corrected lever ranking as the driver of everything after F2, and the charter's ranking is annotated rather than deleted.

**Given** the ranking names a cause outside Epic 12's scope,
**When** it is recorded,
**Then** it becomes documented Epic 14 input and is not acted on inside this epic.

**Given** this is analysis work,
**When** the story lands,
**Then** `Sources/` and `Tests/` are byte-identical.

### Story 12.6: Metrical-level convention and the ground-truth rule

As the operator who will hand-verify 258 tracks,
I want the metrical-level convention declared and the tag-to-ground-truth rule written before any labelling starts,
So that the rule cannot change mid-verification and invalidate work already done.

**Acceptance Criteria:**

**Given** the collection's own convention is half-tempo for 71% of tagged tracks,
**When** the convention is declared,
**Then** exactly one metrical level is chosen, recorded with the corpus, and the choice is justified (FR-59b).

**Given** the convention now has measured support from two independent populations — the pool's third-party file tags and Tony's own Rekordbox entries (889 below 100 as entered against 36 octave-corrected),
**When** the declaration cites them,
**Then** it also carries the caveat that the octave-corrected column's octave came from a vote our detector participated in, so only the as-entered column is FR-59a.1-clean.

**Given** FR-59a.1 forbids corroborating a label with the detector under test,
**When** the ground-truth rule is written,
**Then** at least one qualifying method from FR-59f's list is specified, and the chosen method is recorded with the corpus.

**Given** the old 80-85 / 160-175 octave ambiguity must stay measurable after a single convention is declared,
**When** the rule lands,
**Then** those pairs are retained as a tagged sentinel subset rather than being collapsed.

**Given** legacy corpora rest on the old labels,
**When** FR-62's audit runs,
**Then** it records which convention each legacy corpus was trained toward.

**Given** FR-62a is struck and superseded by FR-59b,
**When** the convention is applied,
**Then** **no OA300 track is re-labelled in place** — OA300 stays intact as a tagged historical artifact so its figures remain interpretable.

**Given** Story 12.3 landed annotation-version tagging,
**When** the new convention is declared,
**Then** it receives its own version tag.

**Given** FR-59f is the one outstanding PRD gate and is operator-owned,
**When** this story closes,
**Then** it carries the operator's explicit signoff on the rule — it cannot close on agent work alone.

### Story 12.7: Build the 258-track band-balanced corpus

As the project lead,
I want a band-balanced evaluation corpus whose labels were never corroborated by the detector under test,
So that the bundle gate measures the model rather than the shape of the corpus.

**Acceptance Criteria:**

**Given** Story 12.6 declared the convention and the ground-truth rule, and FR-59 requires a band-balanced corpus drawn across OA300, Tony's Rekordbox collection and the Story 7.2 non-Rekordbox pool,
**When** the corpus is drawn,
**Then** it holds 43 tracks in each of six bands for 258 total, with the `175+` band kept separate per the 2026-08-01 top-edge decision.

**Given** the scarce bands are 100-120 and `175+`,
**When** they are sourced from the non-Rekordbox pool,
**Then** both of FR-59a's non-optional conditions are satisfied.

**Given** FR-59a.1,
**When** the corpus is audited,
**Then** the audit asserts that no label was selected or corroborated using our DSP, and the assertion fails closed.

**Given** FR-59a.2 requires cross-corpus partitioning,
**When** the audit runs,
**Then** it asserts no residual overlap, following the existing `check_cross_corpus_residual` precedent.

**Given** the `175+` band is 130-of-140 within 175-179 and non-separable from 160-175 at the ±4% Acc1 tolerance,
**When** the corpus is recorded,
**Then** that degeneracy is recorded with it, so a flat or noisy `175+` result is not later read as a measurement of fast-tempo performance.

**Given** the training corpus is a separate artifact,
**When** it is built,
**Then** it is sized for volume with band-aware sampling and is explicitly **not** balanced to 43 — truncating training data to 258 tracks would be strictly worse than the 595-1509 already in use (FR-59d).

**Given** FR-59e,
**When** both corpora exist,
**Then** they share Story 12.6's convention and FR-59a.2's partition.

**Given** per-band results will be reported,
**When** FR-59c is applied,
**Then** per-band is treated as a deterministic tripwire and never as a significance or noninferiority claim (Q11).

**Given** OA300 is private (PRD §11),
**When** the corpus is documented,
**Then** it is never published or referenced outward.

**Given** `train.py` carries a fail-closed signoff gate on the KDD-B4 pattern,
**When** the corpus is complete,
**Then** the equivalent signoff is wired for it — or the story records explicitly that no training story may run until it is.

### Story 12.8: Declare the bin schema a public contract

As a BYOW consumer whose model must match the runtime's expectations,
I want the 256-bin schema declared a public contract with every declaration site named,
So that a future change moves all sites together instead of breaking my model silently.

**Acceptance Criteria:**

**Given** FR-67 requires the bin schema be treated as a public contract, and it is declared in three places — `tools/coreml-convert/reference_arch.py:37-39` (**ships to `main`**), `_bmad-output/ml-training/dataset.py:59-62`, and `BNNSTechnique`'s hard-coded `expectedBinCount = 256`,
**When** the contract is declared,
**Then** all three are named in one authoritative location, and the contract states they move together.

**Given** `MLTechniqueError.binCountMismatch` is public,
**When** the contract is written,
**Then** it records that a mismatch surfaces as a consumer-visible error and that any schema change is breaking for BYOW consumers.

**Given** bins 0-29 and 171-255 — 115 of 256 — can never produce a usable result against the runtime's `60.0...200.0` abstain,
**When** the contract is written,
**Then** the dead range is recorded and cross-referenced to `#147`.

**Given** FR-66 (aligning the range, or folding out-of-range mass at decode) needs a retrain to evaluate and moved to Epic 14,
**When** this story lands,
**Then** it **declares only** — no bin count changes, no decode behaviour changes.

**Given** pre-1.0 permits breaking changes,
**When** the contract states its change policy,
**Then** it requires a named story for any schema change rather than promising compatibility.

**Given** this is a declaration,
**When** the story lands,
**Then** any `Sources/` edit is doc-comment only and behaviour is unchanged.

### Story 12.9: Define the bundle gate

As the project lead,
I want the bundle gate defined in tracks on the 258-track corpus with its unresolved design risks settled,
So that a model is accepted or rejected against a number agreed before it was trained.

**Acceptance Criteria:**

**Given** Story 12.7 built the corpus,
**When** the gate is defined,
**Then** it is stated as ensemble lift — DSP+ML beating DSP alone by a stated margin on the 258-track balanced corpus, with no regression in any band DSP already handles (FR-68).

**Given** OA300 and GiantSteps,
**When** the gate runs,
**Then** they are reported alongside as context and **do not gate**.

**Given** FR-69,
**When** the margin is stated,
**Then** it is expressed in tracks, never in percentages.

**Given** Q10 retired FR-69a's partial-conjunction correction along with the multi-corpus rule,
**When** the threshold is set,
**Then** `ALPHA` is 0.05 and `T_MIN` is 12 net tracks at 10% discordance — not the retired 14 at 0.025.

**Given** FR-69b,
**When** multi-seed results are reported,
**Then** seed agreement is treated as a robustness guardrail and never as a substitute for the paired margin.

**Given** FR-69c names unresolved design risks in the gate itself, raised by the statistical consult and not yet answered,
**When** the gate is declared final,
**Then** each risk has been answered in writing first.

**Given** FR-70,
**When** preconditions are set,
**Then** the four DnB triplet sentinels and a confidence-calibration floor both gate,
**And** FR-25's calibration metric — never committed and never run in Epic 7 — is committed and run here.

**Given** FR-71,
**When** results are reported,
**Then** per-band lift is always reported, never only an aggregate, with `gains ≥ losses` required in every predeclared DSP-handled band as a deterministic tripwire rather than a statistical claim.

**Given** a gate that has never rejected anything is not known to work,
**When** the harness is built,
**Then** it is exercised against a negative control — the Epic 7 `giantsteps_v2` model that failed the FR-18 gates — and demonstrably rejects it.

---

## Epic 12 — Model-quality redesign: octave-aware BPM model (CHARTER / UNPLANNED)

> **SUPERSEDED 2026-08-02 by the Epic 12 story breakdown above.** This charter is retained as the historical record of what was known and decided before stories existed — the two measured-and-failed octave levers, the corrected lever ranking, the AST verdicts, and the enabler list. Per the project's supersession-header convention, superseded text is annotated rather than deleted. Where the charter and the story breakdown disagree, **the story breakdown governs**; where the charter's ranking and Story 12.5's FR-58 ranking disagree, FR-58 governs once it exists. Charter item 7(a) is re-admitted as an explicit post-MVP feature and is **not** covered by any Story 12.x.


> **Status: CHARTER ONLY (added 2026-06-09 from the Epic-7 BYOW close).** Named so the gap is visible, NOT yet scoped into stories. Needs its own PRD + KDD decision gates before any Story 12.x exists. Do NOT let Epic 8 absorb this — Epic 8 is LUFS/beat-grid/ModelRegistry (plumbing + adjacent surface); it does NOT retrain or improve the BPM model.
>
> **Updated 2026-07-26 (GH-166 sequencing decision, `spec-gh-166-epic12-lever-sequencing.md`).** This charter is now the authoritative record of what has been TRIED and what remains, and is the seed for the eventual PRD. Two of the cheap levers the original scope sequenced FIRST have since been implemented, measured, and removed. The corrected ranking below supersedes the original "Provisional scope" list, which is retained beneath it marked SUPERSEDED rather than deleted. Still charter-only: no story numbers, no PRD, nothing here is a commitment.

**Why this epic exists.** Epic 7 closed BYOW: the v2 TempoCNN fails both bundle gates (OA300 43/82 vs >55; GiantSteps 348/661 vs ≥537). Three retrains proved the failure is **structural, not data-volume**, and a zero-compute diagnostic (E0) localized it: `<100` BPM is clean octave-doubling (38/60 predict exactly 2× truth; Acc2 65% vs Acc1 2%), `100-120` is genuinely mis-pulsed. FR-16's octave-aware *loss* was delivered and the model still doubles — so loss-only is insufficient; representation and decode must be tested before spending capacity. **(2026-07-26: decode has since been tested and failed — see the next section. Representation remains untested and is now the senior structural lever. Also note FR-16's loss did more than fail to help: per #146 it put ~0.075 of target mass on the 2T bin, actively rewarding the doubling.)** The library's core value prop is "drop-in BPM detection"; BYOW undercuts it. This epic is the path to a bundle-quality model. Evidence: `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md`, `epic-7-retro-2026-06-05.md` close-out addendum. (Codex review 2026-06-09 corrected two over-stated claims below — see the CAVEATS.)

### What has been measured since (2026-07-26)

**Both cheap octave levers have now been tried. Both failed net-negative. The "free first move" this epic was sequenced around does not exist.**

1. **ML posterior octave-folded decode — IMPLEMENTED, MEASURED, REMOVED (#141, PRs #177/#179).** Measured over all 661 GiantSteps tracks against `giantsteps_v2_seed_42`, 0 abstains (`_bmad-output/implementation-artifacts/141-octave-fold-impact.json`). **Every threshold from 0.0 to 1.0 is net negative on Acc1**; the best is −2, reached by folding almost nothing. At threshold 0.0 the rule fires on **604 of 661 tracks**: 38 helpful (exactly the sub-100 recoveries E0 predicted — so the mechanism works), 346 harmful, 220 accuracy-neutral, netting −308. No threshold separates helpful from harmful because the posterior mass ratio carries no information about whether a fold is correct: helpful folds (n=38) median ratio 0.199, range 0.037-0.745; harmful folds (n=346) median 0.192, range 0.014-1.700. **The helpful range sits entirely inside the harmful range**, so no single cut on this statistic can isolate the good folds. (The often-quoted "336 of 346 harmful above the smallest helpful, zero helpful above the largest harmful" pair are max-vs-min extremes, not a separability measure; the nested ranges and near-identical medians are the actual evidence.) **Mechanism: literal absence of half-tempo mass is not the problem — non-discrimination is.** The half-tempo/argmax mass ratio is at least 0.0144 in all 604 legal-fold cases, but, as the distributions above show, it furnished no useful threshold for deciding when to fold on this model. This is why the 2026-06-09 Codex caveat said the 401 oracle ceiling "cannot be replayed offline." The code, its policy type, the Python mirror and the impact harness were all deleted; only the JSON, its provenance note, and a `BNNSTechniqueTests` invariant guard survive.
2. **DSP demote-to-fundamental sub-band vote — MEASURED, FAILED, REVERTED (2026-06-28, `spec-octave-resolver-symmetry`).** Four variants of making `resolveOctaveAmbiguity`'s vote demote to the fundamental, all net negative, all reverted: OA300 Acc1 58 → 40 (un-gate-symmetric) / 39 (strict-tie) / 54 (score-guard@0.8) / 56 (score-guard@0.95); GiantSteps 537 → 503 / 507 / 534 / 536. **Mechanism: the faster-only ratchet is load-bearing compensation for ACF subharmonic bias.** A signal periodic at `T` is also periodic at `2T`, so the slow octave autocorrelates at least as strongly as the fundamental (measured ~25% stronger in all four bands for a 160 BPM click) — a strict slow win, not a tie. A score-plausibility guard cuts the damage roughly 5× but asymptotes to baseline FROM BELOW and never lifts. A unanimous Codex + agent + MIR-literature quorum was empirically wrong here and conceded. Full record: `_bmad-output/implementation-artifacts/investigations/accuracy-ceiling-sweep-investigation.md` (Follow-up 2026-06-28).

**What the two results share, and what it rules out.** Both levers tried to resolve the octave using a *single scalar derived from the same evidence that produced the error* — posterior mass in one case, autocorrelation score in the other. Neither works, and the reason is the same: that evidence is what is wrong. **Working hypothesis for the PRD: an octave lever should source its disambiguation from outside the signal that generated the candidate** — a perceptual tempo prior, beat-grid coherence, file metadata, or a learned classifier trained to the task. **Scope this honestly.** Each result is one experiment: the ML sweep tested *one scalar statistic* (posterior mass ratio) against *one model* (`giantsteps_v2_seed_42`, which already fails both bundle gates), and the DSP sweep tested four variants of *one rule*. That is enough to stop re-trying those variants — both carry explicit re-open triggers in `deferred-work.md` (`:901`, GH-141 blocks) and neither is "try it again more carefully" — but it is **not** proof that no posterior-derived rule can work on a better-calibrated model. The ledger deliberately left that open (`:1210`); the charter does not close it.

**What is still true, and is now the load-bearing evidence.** E0 stands: the `<100` BPM band is clean octave-doubling (n=60, Acc1 1/60, Acc2 39/60, **38 predicting exactly 2× truth**), and `100-120` is genuinely mis-pulsed (n=35, Acc1 == Acc2 == 1/35 — neither half nor double lands, so no octave rule of any kind helps there). The forensic harness stands: OA300's 24 misses are 16 octave + 2 triplet + 6 other, with 21/24 selection-bound and 17/24 carrying truth at candidate rank 1; GiantSteps' 124 misses are mostly non-harmonic (98 other, 19 triplet, 7 octave). The diagnosis was never wrong — the two cheapest *remedies* were.

### The octave problem is not only an ML problem (#172, 2026-07-24)

The four known-failure fixtures pinned by `AccuracyFloorTests` are **DSP-path** octave errors measured on the default path with `metadataPolicy = .disabled`, with no model involved at all: `Meta_Man` 92 → 182.00 (2×), `Meta_Man_La_Noche_Digital_` 96 → 191.76 (2×), `Submerged_Lament` 70 → 140.12 (2×), `robbyt_x-ray-120s` 174 → 115.64 (2/3× triplet). All three doublings are slow tracks; the pipeline prefers the faster octave.

**At least one is a selection failure, not a generation failure.** `Submerged_Lament` had 70 in its own candidate list, scoring 0.97 against 140 at 1.01. Nothing needs to be learned to fix that case — the right answer was generated and then not chosen. Two consequences for sequencing: (a) an ML lever cannot close this class **without also changing the ensemble policy** — these are measured under the default `.dspOnly`, where `MLTechnique.evaluate` is never invoked, so a better model changes nothing here until `.mlOnly` / `.highestConfidence` / `.weightedVoting` is on the default path, which is its own decision; selection/prior levers therefore belong in the ranking alongside representation and training work, not after it. (b) #172 (consumer-specifiable BPM search range / tempo prior) is testable **today** against these four fixtures with no model and no retrain, making it the cheapest experiment in the epic in wall-clock terms. Coordinate with Epic 13, which owns the DSP-side experiment discipline.

### Compute-constraint change (operator, 2026-07-21)

CPU-only inference is **no longer a requirement**. Larger models are acceptable if accuracy improves, and Apple's bring-your-own-model APIs are in scope. This removes the BNNSGraph latency objection that ruled out transformer-scale backbones. It does **not** remove the AST-as-regression rejection below — which rests on the measured Acc1 gap, not on head shape (corrected 2026-08-01, GH-166) — and it does not remove the deployment traps (availability gating above the macOS 15 floor, ANE scheduling being a preference not a guarantee, CPU fallback, MLProgram packaging, compile/load latency).

### AST verdicts (#166)

- **AST-as-regression: EVALUATED AND REJECTED, on the measured gap.** An externally written notebook fine-tuning `MIT/ast-finetuned-audioset-10-10-0.4593` with `num_labels=1, problem_type="regression"` scores **Acc1 40.9% (27/66), MAE 13.50** on GiantSteps validation, against the DSP path's 81.2% on the same corpus, and shows no route from one to the other. The field moved to classification (Schreiber & Müller ISMIR 2018, the source of the current 256-bin design; DeepRhythm ISMIR 2019; Böck multi-task TCNs ISMIR 2019/2020; multi-scale ISMIR 2021); a survey of the cited literature found no system doing scalar AST-BPM regression (absence in the surveyed set, not a proof of nonexistence). HuggingFace supports `problem_type="regression"` mechanically, which is not evidence it works statistically. **(CORRECTED 2026-08-01, GH-166.** This bullet previously read "~~EVALUATED AND REJECTED, on the head, not the backbone~~" and argued "~~global tempo is a multimodal target; scalar MSE averages across modes, so a track ambiguous between 87 and 174 minimizes toward roughly 130 — worse than either octave~~". Both are withdrawn by `prd.md:23` and addendum §A: MAE 20.2 / 4-of-10 was a ten-track eyeball subsample that over-draws the tails roughly threefold, the full validation set beats a constant-mean predictor by 4.24 BPM and ten tracks (R² 0.27) with two rows moving *away* from the 138.9 mean, and no ablation isolating the head was ever run — the loss curve (train 7.34 → 0.0067, held-out flat from epoch 1) points at 595 training examples. It also closed "~~Decisive locally: the measured failure structure is the multimodal kind (exact 2× doublings), which is precisely where regression is weakest~~"; E0's doublings stand, but that inference was never tested against the notebook and is a hypothesis, not local proof. The rejection itself is unaffected. **What the charter gains:** 87M parameters reaching 40.9% is *measured* corroboration for **AS-2** (capacity is not the constraint) — the PRD otherwise supports AS-2 only with published figures, and this is our own evidence.**)**
  - *External pushback and its resolution (2026-07-22):* the objection "classification calls 173 fully wrong when truth is 174" is valid against **hard** one-hot cross-entropy, but it is an argument for soft targets, not for a scalar head. Gaussian-smeared class targets give local distance-awareness while the output can still represent two peaks an octave apart. The evaluation metric already forgives the example — Acc1 tolerance is ±4%, so 173 vs 174 (0.6%) scores correct; the loss should match the metric's tolerance, which again points to smearing.
  - *Accepted as a new candidate:* a **hybrid head** — classify to select the octave/mode, plus a small regression head refining the offset within the selected bin (detection-style). Captures regression's sub-BPM precision without mode-averaging. Pure scalar regression remains rejected.
- **AST-as-classifier: ACCEPTED AS A HARNESS EXPERIMENT, gated on the CoreML backend story.** 86.6M params, ~345 MB fp32 (~90 MB int8), against the current 315,096-param CNN (`model_summary.txt`). Transfer from AudioSet tagging to periodicity is unproven either way, so this is an experiment, not a commitment, and it must A/B through the FR-18 harness like anything else.

### Corrected lever ranking (supersedes the Provisional scope below)

> **SUPERSEDED AS THE DRIVER 2026-08-08 by Story 12.5's FR-58 ranking** (`_bmad-output/implementation-artifacts/12-5-pipeline-differential.md`, section 4). The supersession header at the top of this charter already stated that FR-58 governs once it exists; it now exists, and per FR-58 it, not this list, drives everything after F2. The nine items below are retained unmodified as the historical record. Where the two orderings disagree, item by item: item 1 splits (its augmentation clause rises to FR-58 rank 2, its target-shape clause falls to rank 5, on the measured +53-of-197 octave ceiling); item 2 does not rank (the bin schema is identical on both sides and zero GiantSteps truths fall outside the 60-200 abstain range -- fold into the next `featureSetVersion` bump as hygiene, not as a gap cause); item 3 does not rank (DSP-path lever, outside the model gap the differential explains, unaffected); item 4 does not rank because it is an enabler, not an accuracy lever (its own entry says so), and it is unaffected by this supersession -- its still-binding invariant (the GH-166 note below: no retrain against a substrate the Swift runtime cannot reproduce byte-for-byte; the backend runs end-to-end before any backbone fine-tune) continues to bind FR-58 rank 3; items 6, 8 and 9 do not rank (capacity is not a suspect axis -- the reference scores 545 at 2.9M parameters); item 5 rises to FR-58 rank 3, first on expected contribution and held back only by cost; item 7 does not rank as a gap cause (the octave class it arbitrates is 53 tracks of a 197-track gap). **Corpus composition, FR-58's rank 1, appears in none of the nine items** -- the charter ranked model-side levers and the differential locates the largest cause in the training data. FR-58 rank 4 (multi-window aggregated inference) is priced by this charter's Enablers list (raw-audio evaluation path, full-posterior dumps).

Each entry is tagged **MEASURED / UNTESTED / BLOCKED**. Nothing is a commitment; the PRD assigns gates.

**This ordering is by expected leverage on the ML failure, NOT cheapest-first** — a deliberate departure from the plan doc's "evidence-ordered, cheapest-first," made because the two cheapest things were tried and failed. In pure wall-clock terms item 3 (#172) is the cheapest and could run first or in parallel; it is ranked third because it addresses the DSP path rather than the model this epic exists to fix. The PRD should decide explicitly whether to reorder on cost.

1. **Training-target repair — UNTESTED, highest expected leverage per unit cost.** Gaussian-smeared ordinal targets around the true bin, plus sub-100 augmentation/oversampling, plus **asymmetric** octave treatment. This is the surviving half of #166's original item (1) — it is training-side, not decode-side, and it now leads because the decode-side half is measured and gone. **It must be paired with #146, but #146's mechanism needs a correction the issue does not carry.** `ablation/octave_aware_loss.py:42,77` puts `octave_mass = 0.15` on the octave partners `{2T, T/2}` — so the v2 loss DID give octave partial credit, and `octave-bias-finding-and-plan.md:70` claiming "hard cross-entropy … no partial credit" is false. **But where that mass lands is tempo-dependent.** `octave_partner_bins` (`:56-71`) drops any partner outside [30, 285] before splitting (DD #2), so the ~0.075 / ~0.075 split onto `{2T, T/2}` holds only for roughly **60 ≤ T ≤ 142**. Above ~142 the 2T partner is out of range and the **full 0.15 goes to the half** — in the DnB band (174 BPM) the loss rewards the *fundamental*, not the doubling. So "the loss rewards the 2× mode" is true for the 100-142 band and **false for the fast band**; #146 states it unconditionally and that reading inverts where the corpus actually lives. What is unambiguously wrong is the absence of ordinal structure: a 1-bin miss and a 100-bin miss are penalized identically. Provenance caveat: v2 `model_metadata.json` records no loss fields, so "all three retrains used 0.15" is inferred from the `--octave-mass` default, not read off run artifacts — **log the loss config on the next retrain.** Requires a retrain to evaluate, so it is not free, but it changes no contract.
2. **Bin-range alignment — UNTESTED, and NOT as mechanical as it looks (#147).** Training bins span 30-285 BPM in 256 integer bins, declared in **two** places that must move together: `tools/coreml-convert/reference_arch.py:37-39` (which **ships to `main`** — it is on the promotion allowlist) and `_bmad-output/ml-training/dataset.py:59-62`. The runtime decodes `30 + argmax` (`BNNSTechnique.swift:884`) and abstains on anything outside `60.0...200.0` (`:889`), so bins 0-29 and 171-255 — **115 of 256** — can never produce a usable result. Mass they attract both wastes capacity and depresses `softmax_max` toward the Gate-1 abstain threshold, and the 285 ceiling drives augmentation complexity for range discarded at decode. **Scoping trap:** changing the schema is a public-contract change, not a develop-only edit — `BNNSTechnique` hard-codes `expectedBinCount = 256` (`:190`) and throws `MLTechniqueError.binCountMismatch` against it, so every BYOW consumer's model is bound to 256. Fold into whichever change next bumps `featureSetVersion`, and treat the convert tool and the error contract as in-scope. (#147's `reference_arch.py:37-39` citation is **correct**; its *other* citation, `BNNSTechnique.swift:857` for the abstain, is stale — that line is softmax arithmetic and the guard is at `:889`.)
3. **Selection/prior levers on the DSP path — UNTESTED, testable today, no model (#172).** See the #172 section above. Cheapest live experiment in the epic and the only one that addresses the measured `AccuracyFloorTests` failures. Coordinate with Epic 13 so the two epics do not both claim it.
4. **`CoreMLTechnique` conformer backed by `MLModel` with `computeUnits = .all` — UNTESTED, unblocked, but an enabler rather than an accuracy lever on its own.** Revives the existing non-conforming placeholder (`Sources/BoomBoomBoomKitML/CoreMLTechnique.swift` — deliberately does NOT adopt `MLTechnique` today) and lifts the ~315k-param budget into the 10-100M range on ANE/GPU, available on the current macOS 15 floor. Gates item 6.
5. **Input-representation redesign — UNTESTED, high-value, expensive.** The fixed `[1,1,128,512]` window is the prime suspect for poor tempo-scale invariance and corpus-prior leakage. NOTE the standing correction: a naive frame-rate argument does NOT explain the slow-tempo failure — at ~5.7 fps a 60 BPM track gets *more* frames per beat than a 174 BPM track, so if anything fast tempo is nearer temporal Nyquist. The mechanism is scale-invariance/prior, not a resample smear. Candidates: tempo-invariant hop, or a log-lag/tempogram input where 60 and 120 are equidistant. Bumps `featureSetVersion` and re-runs the Swift↔Python parity harness (FR-21). This is the only lever that plausibly touches the `100-120` band, which no octave rule can reach. May warrant its own substrate-v3 sub-epic.
6. **Fine-tune a pretrained backbone as a 256-class tempo classifier — UNTESTED, gated on item 4, and DEMOTED on evidence 2026-07-27.** EfficientAT-class AudioSet CNNs (under 10M params) first; AST (86.6M) as the high-capacity arm. A/B through the FR-18 harness. Both are experiments, and both carry an unmeasured assumption — that these architectures run acceptably on ANE — which item 4 exists to establish before either is scoped. **Capacity is very likely not the constraint, so treat this lever as low-priority until item 2's reference-gap diagnosis says otherwise.** Böck & Davies' TCN scores GiantSteps Acc1 **87.0** at roughly 33k parameters *(figure is secondary-source)* and Schreiber's TempoCNN — the family this project's 256-bin design copies — scores **82.1**, against **52.6** for our 315k-parameter model. A model an order of magnitude smaller scores ~35 points higher, and the published reference for our own architecture scores ~30 points above our implementation of it. There is also no published evaluation of EfficientAT, or any AudioSet-tagging CNN, on tempo at all; the nearest measurement on a generic music embedding is octave-BLIND (MULE 1-NN, Acc1 35.9 / Acc2 96.1).
7. **Octave arbiter from outside the posterior — UNTESTED, and the surviving half of the original item 1.** Two forms, combinable: (a) wire the idle `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as an arbiter through the SignalPool (chartered in 2026-06, never built — GH-141 measured only the decode half); (b) a multi-task beat + tempo head supervised by the Epic 8 Rekordbox beat oracle, combinable with any backbone. **Correction 2026-07-27:** an earlier draft of this entry called (b) "the strongest published octave disambiguator". That is not supportable. The only clean controlled single-versus-multi-task tempo ablation (Sun et al., ISMIR 2021) reports +2.5pp / +0.7pp / **−4.1pp on GiantSteps** — it HURT on the EDM set closest to this corpus. Böck & Davies 2020's larger octave-gap closure is real but confounded with downbeat modelling, a conv reorder, TCN dilation changes and tempo augmentation; the authors state there is "no magic bullet." The better-evidenced direction is tempo → beat metrical level, not beat → tempo octave. Both forms still satisfy the outside-evidence hypothesis. Overlaps the Epic 13 beat-grid-support rescoring idea (W53/W74) — coordinate so both epics do not build it.
8. **Core AI (`.aimodel`, `AIModel`/`InferenceFunction`) — DEPLOYMENT FOLLOW-UP, not an experiment vehicle.** A candidate macOS 27-cycle path if a transformer-scale model wins the bake-off. **Unverified against current Apple documentation** — confirm the API surface, availability, and packaging story before scoping. Would need availability gating above the macOS 15 floor and a specialization/first-load story.
9. **Genre/tempo mixture-of-experts — EXPLICITLY LAST RESORT.** Router-error surface, N model loads, re-bundling. Unchanged from the original scope.

### Enablers the experimentation framework needs (each a small story)

- **Raw-audio access on the evaluation path.** The feature transport currently locks conformers to the 128-mel v2 substrate: `MLTechnique.evaluate(trace:)` plus `MLFeatureFrames` is the only input path, and the signature froze at Story 4-5 DD #18. A backbone wanting its own front end (AST fbank) cannot be tested without a pre-1.0 signature change, which needs its own story per the freeze note.
- **C5 — tunable abstain thresholds: ALREADY LANDED, do not re-scope.** GH-167 item 6 (commit `997982b`) made these per-instance: `BNNSTechnique.confidenceThreshold` and `.marginThreshold` are `public let`, set via `init(modelURL:options:)`. #166 lists C5 as an outstanding enabler; it is not.
- **C3 — model-bound feature version**, so a model and its substrate cannot drift apart silently.
- **C6 — convert-tool featurize contract**, so `tools/coreml-convert/` and the runtime agree by construction.
- **D3 — live BNNS/CoreML technique tests.**
- **Full-posterior diagnostic dumps.** Retained from the SUPERSEDED Provisional-scope item 2 (not #166's item 2) and still unbuilt: the FR-18 dumps carry only decoded BPM + `softmaxMax`. GH-141 had to build a bespoke harness to measure one rule; any future posterior-derived experiment will need the same thing again.

### SUPERSEDED — original Provisional scope (2026-06-09), retained for the record

> The list below is the sequencing this epic was chartered with, kept so the diff shows what changed. **Item 1 is only PARTIALLY superseded**: its posterior-decode clause is measured-and-failed (see "What has been measured since" above) — the "+53 GiantSteps tracks of headroom (348 → 401 oracle ceiling)" was an *oracle* figure never achievable, and the decode meant to claim it is net-negative at every threshold and deleted — but its second clause, wiring `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as an arbiter via the SignalPool, was **never built** and is now corrected-ranking item 7. Item 2 (diagnostic-dump expansion) is still unbuilt and moved to the Enablers list rather than the ranking. Items 3-5 survive reordered as corrected-ranking items 5, 1 and 6/9. Every line below is verbatim except item 1, which carries an inline status prefix.

**Provisional scope (sequenced — each gates the next; bigger model is LAST):**
1. **[PARTIALLY SUPERSEDED — the posterior-decode half was MEASURED AND FAILED (#141); the SignalPool/`OctaveEquivalencePolicy` arbiter half was NEVER BUILT and survives as corrected-ranking item 7]** **Octave-aware decode** (cheap, no retrain — an EXPERIMENT, not a guaranteed fix) — replace `30 + argmax` with an octave-folded posterior; wire the idle `OctaveEquivalencePolicy` + DSP `resolveOctaveAmbiguity` as octave arbiter via the SignalPool. E0's Acc2 exposes up to **+53 GiantSteps tracks of octave-confusion *headroom*** (348→401 oracle ceiling) — actual no-retrain recovery must be MEASURED, not assumed, and gated on **per-band net impact** (an aggressive "prefer fundamental" rule can damage the currently-correct 120–175 bands), not just `<100` recovery.
2. **(E1b) Diagnostic-dump expansion** — BEFORE any redesign, and cheaper than it: dump full per-track logits / top-k posterior, decoded BPM + truth, DSP candidate BPMs, segment/window metadata, per-band confusion. Required because the current dumps carry only decoded BPM + `softmaxMax` — you cannot validate an octave-folded posterior decode (step 1) or confirm whether half-tempo softmax mass even exists without this.
3. **Input-representation redesign** — the fixed 30/60/90s-window→512-frame representation is the **prime suspect for poor tempo-scale invariance + corpus-prior leakage** (the model learning the DnB-dominant metrical level as a prior). NOTE: a naive frame-rate argument does NOT explain the slow-tempo failure — at ~5.7 fps a 60-BPM track gets *more* frames/beat than a 174-BPM track, so if anything fast tempo is nearer temporal Nyquist; the mechanism is scale-invariance/prior, not a resample "smear." Candidate fix: tempo-invariant hop or a log-lag/tempogram input. Bumps `featureSetVersion`; re-runs the Swift↔Python parity harness (FR-21). May warrant splitting into its own substrate-v3 sub-epic.
4. **Octave-aware training target + tempo-class rebalance** — soft/Gaussian target, explicit octave penalty, sub-120 oversample.
5. **Bigger model on the Apple Neural Engine** — CoreML/MLProgram `MLTechnique` conformer (the protocol froze at 4-5 DD #18 to allow exactly this), *preferring* `.cpuAndNeuralEngine`, off the current CPU-only BNNS path. The model is ~1.2 MB, so size/bundling is NOT the constraint. Capacity is the *amplifier*, applied only after 1-4 make the signal correct. Deployment traps to scope: ANE scheduling is a *preference not a guarantee* (CPU fallback required), platform/availability gating, simulator behavior, MLProgram packaging as an SPM resource, compile/load latency, model signing posture.

**Dependencies / sequencing.** Comes AFTER Epic 8: Epic 8's ModelRegistry is the distribution channel for whatever this epic produces (bundled or BYOW, a config flip not a `main`-history event), and Epic 8's beat-grid (`SignalSource.beatGrid`, W53) is an independent tempo signal that can cross-check octave errors in the ensemble. The bigger-model training run does not start until step 2 lands with parity green and the ANE inference path (step 4 skeleton) is proven end-to-end — training on a substrate the runtime can't reproduce, or for a backend that can't run it, is wasted compute (the exact Epic-7 mistake). **(2026-07-26, GH-166: the step numbers in the preceding sentence were already wrong against the list they index — in the SUPERSEDED list, parity/`featureSetVersion` is step 3 (not 2) and the ANE path is step 5 (not 4). Do not carry the indices forward. The *invariant* is what matters and it is unchanged and still binding: no backbone fine-tune (corrected-ranking item 6) starts before the `CoreMLTechnique` backend (item 4) runs end-to-end, and no retrain starts against a substrate the Swift runtime cannot reproduce byte-for-byte. Note also that Epic 8 has since closed, so "Comes AFTER Epic 8" is satisfied.)**

**Open scoping questions for the PRD:** does the representation redesign stand alone as a substrate epic between 8 and 12? new corpus signoff on par with KDD-B4 against the new representation? does GiantSteps' own sub-120 annotation set need an octave-cleanliness audit (the ruler vs the lens)? Genre/tempo mixture-of-experts is explicitly the LAST resort, not a first move (router-error surface + N model loads + re-bundling). **Added 2026-07-26 (GH-166):** given two measured octave failures, what is the PRD's stopping rule — how many net-negative levers before the epic's premise (that a bundle-quality model is reachable) is itself re-examined? Does the octave work split into a DSP-selection track (#172, overlapping Epic 13) and an ML track, and who owns the overlap? Should the training-target repair (item 1) and bin-range alignment (item 2) land as ONE retrain, since both are cheap and both need a retrain to evaluate?

**Measurement infrastructure landed (2026-06-27, `spec-accuracy-forensics`, branch `rterhaar/accuracy-forensics`).** The forensic-accuracy harness (`make accuracy-forensics`) now supplies exactly the per-band / octave-isolated / recall-aware attribution this epic's step 1 gate demands ("per-band net impact, MEASURED not assumed"): octave vs triplet vs other error-type histograms, a candidate-recall oracle (true BPM in top-1/3/5/10 + factor + score-margin), a recall split (selection- vs generation-bound), and a DSP-confidence reliability curve — all reproducing the committed floors exactly (reporting-only). **First read:** OA300 misses are octave/**selection**-bound (16/24 octave, 21/24 with truth in top-5, 17/24 with truth at candidate rank 1) — the octave-aware DECODE (step 1) is the indicated cheap first move and its headroom is now directly measurable; GiantSteps misses are mostly non-harmonic "other" (98/124) with a cleanly monotonic confidence curve, so octave decode pays off mostly on OA300. Use `accuracy-forensics-*.json` as the step-1 / step-2 diagnostic substrate before any retrain. **(Correction 2026-07-26, GH-166: the "indicated cheap first move" half of this read is superseded. The decode was built and measured under #141 and is net-negative at every threshold; the DSP-side vote variant was measured and reverted in 2026-06-28. The *attribution* stands unchanged and is more useful than ever — it is what establishes the misses as selection-bound, which now points at the #172 selection/prior lever rather than at a decode rule. The harness itself is unaffected: it is reporting-only and reproduces the committed floors exactly.)**

## Epic 13 — DSP accuracy experiments (CHARTER / UNPLANNED)

> **Status: CHARTER ONLY (added 2026-06-27 from the GLM/Gemini/ChatGPT external-audit triage).** Named so the gap is visible; NOT scoped into stories. Distinct from Epic 12 (which redesigns the ML *model*): Epic 13 is hand-DSP experiments on the existing pipeline. Each is a flagged, ablation-gated `DSPTechnique`-style experiment with a revert clause — the project reverted Stories 8.4 and 8.9 this way; nothing here ships on a flag-off default without a measured ≥2-track OA300 lift and no GiantSteps regression.

**Why this epic exists.** Three external LLM audits (`docs/{glm,gemini,chatgpt}-audit.md`) were triaged against the source (every verifiable claim confirmed; many framings context-blind — "algorithm hidden", "no harness", "causal-DP = switch to Viterbi" all refuted). The surviving signal is a cluster of pipeline experiments, now measurable via the Epic-12 forensic harness.

> **AMENDED 2026-08-02 — items 1 and 2 transferred to Epic 12 (operator decision, 2026-08-01).** Epic 12 owns the DSP octave levers. The PRD's §14 Q6 already asserted this, but the assertion lived only inside that document, so a reader starting from `epics.md` saw Epic 13 still holding both. That contradiction is closed here. **Item 1's sequencing rule travelled with item 1**: Story 12.1's first acceptance criterion requires the `resolveOctaveAmbiguity` sweep to run, or the do-not-pre-commit rule to be retired in writing with a stated reason — Epic 12 could not take the lever and evict the covenant. **Item 2 was the only duplication both charters flagged bilaterally and by name**, and the Epic 12 PRD does not mention beat-grid at all; it now lives in Epic 12's post-MVP charter item 7(a) rather than being claimed by two epics or by neither.
>
> **Open, and nobody in the 2026-08-02 planning room could answer it:** with items 1 and 2 gone, four items remain and none is octave-related. Whether what is left is still an epic, or belongs folded into Epic 12's post-MVP surface, is undecided.

**Provisional scope (sequenced — ~~Phase 0.5 ceiling sweep CHOOSES the first move; do NOT pre-commit~~ — the sequencing rule moved to Epic 12 with item 1):**
1. ~~**Phase 0.5 — offline ceiling sweep** (no shipped DSP): from the forensic JSON, compute the octave-resolver ceiling (sweep the hand-tuned `0.3`/`0.5` `resolveOctaveAmbiguity` thresholds + sub-band vote weights on an OA300 dev slice, report OA300 holdout + GiantSteps once) vs the candidate-recall ceiling. Whichever is higher picks Phase 1.~~ **TRANSFERRED 2026-08-02 to Epic 12, Story 12.1 AC #1.**
2. ~~**Beat-grid-support candidate rescoring** (W53/W74 — the `.beatGrid` `SignalSource` has no producer): score each top-N candidate's grid support INDEPENDENTLY (coverage + inter-beat stability at that candidate's tempo, never seeded by the winner — circular otherwise), with an ABSTAIN path (override only when grid evidence is decisive). Overlaps Epic 12's beat-grid-arbiter idea — coordinate.~~ **TRANSFERRED 2026-08-02 to Epic 12 charter item 7(a) (post-MVP).**
3. **Sliding/aggregated tempogram + tempo-stability** (today a single 8s local window, `BPMAnalyzer.swift:113/1425`).
4. **subBandEmphasis / adaptive sub-band weighting** (W64/W71; `OnsetFeaturesBuilder.build` throws for `.subBandEmphasis`; fixed kick/snare/hat weights) — validate on GiantSteps (a hand-tuned ratio rule is likely OA300-specific).
5. **Multi-region anchor** vs the single `findEnergyTransition` first-drop (`BPMAnalyzer.swift:1376`) — demoted unless forensics show localized intro/transition locks.
6. **Normalized ACF** (LAST, not cheap: octave fusion + sub-band thresholds are tuned against the current biased ACF → a full 256-combo re-tune).

**Discipline (gate, from `3-3-click-track-cross-correlation.md`).** ≥2-track OA300 margin (1 track ≈ 1.2pp, below the ~5pp binomial SE); no GiantSteps regression for a default-path change (flagged experiments may be "OA300 lift, GiantSteps neutral-or-explained" while default-off); freeze OA300-tuned changes before re-measuring GiantSteps (no tuning on both); report per-track deltas + the error-type/recall split. Product surface (split `audio`/`metadata`/`final` confidence + an "ambiguous" result signal) belongs in Epic 10/11, gated on the reliability curve.

---

## Epic 14: Model retrain and delivery — CHARTERED, NO STORIES YET

**Deliberately unscoped as of 2026-08-02 (operator decision).** Epic 14 covers FR-63, FR-64, FR-65, FR-66, FR-72, FR-72a, FR-72b, FR-73 and FR-74 — 9 FRs — and is conditional on §6's Gate 0 and Gate 1 both passing.

Stories are not written because **Story 12.5's FR-58 ranking, not the charter's, drives everything after F2**. Writing acceptance criteria for a retrain whose direction that ranking will set would be inventing scope, and the PRD's own authoring record shows the cost of that mistake: four rounds of self-review, nine defects found, and **seven corrections that stranded their own dependents**.

Re-open trigger: Gate 1 passes — training-target repair produces ensemble lift. If Gate 2 fires instead, this epic is never written, and nothing in Epic 12 is wasted. That is the reason the epic boundary sits where it does.

**The live risk it inherits.** FR-72b: `Options.ensemblePolicy` defaults to `.dspOnly`, the one case that is operation-inert. A model can clear every gate in Story 12.9 and change nothing any user sees.
