# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

See @Makefile for all targets (`make help`). Key ones: `make build`, `make test`, `make fmt`, `make lint`, `make benchmark`.

Run a single test suite: `swift test --filter BPMAnalyzer120BPMTests`
Run a single test: `swift test --filter BPMAnalyzer120BPMTests/detect120BPM`

## Release Process — what ships to `main` vs stays on `develop`

**This repo is multi-branch.** `main` is the public open-source release target; `develop` carries everything else, including all LLM-aided-development tooling. Read this section before authoring or moving any file. **When in doubt, default to develop.**

### Ships to `main` (the public open-source library)

| Path | Why |
|---|---|
| `Package.swift` | SPM manifest |
| `Sources/` | All three SPM targets (`BoomBoomBoomKit`, `BoomBoomBoomKitTestSupport`, `BoomBoomBoomKitML`), including the bundled `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` reference model |
| `Tests/` | Unit tests + the env-gated benchmark target |
| `tools/coreml-convert/` | Consumer-facing PyTorch → CoreML conversion CLI. This is **the only Python tooling that ships to main** (Story 4-4b DD #13 exception, recorded in `_bmad-output/implementation-artifacts/4-4b-tempo-classifier-training.md`) |
| `README.md` | Public-facing readme |
| `MODEL_CARD.md` | Authoritative bundled-model accuracy disclosure (per Story 4-4b party-mode follow-up) |
| `LICENSE` | License text |
| `.swiftlint.yml` | Lint config |
| `.gitignore` | Ignored-path rules (must include the develop-only patterns so they don't accidentally land on main) |
| `Makefile` | Build/test targets. `ml-*` shortcut targets remain in the file even though their underlying scripts live in `_bmad-output/`; they fail loudly on a main-only checkout, which is intentional — consumers shouldn't run them |

### Stays on `develop` ONLY — NEVER shipped to `main`

These are the LLM-aided-development scaffolding directories. They MUST be excluded from the squash-merge to main.

- **`CLAUDE.md`** — this file. Public consumers do not need it; shipping it advertises the AI-agent workflow inappropriately and exposes internal conventions
- **`.claude/`** — Claude Code configuration: settings, skills, projects, scheduled tasks, worktrees
- **`.agents/`** — agent skill directory
- **`_bmad/`** — BMAD framework installation: `bmm` module, hooks, config TOMLs, scripts
- **`_bmad-output/`** — every BMAD output:
  - `_bmad-output/implementation-artifacts/` — story specs, regression snapshots, diff-scope proofs, sprint-status.yaml
  - `_bmad-output/ml-training/` — Python training pipeline + Swift CLI fixture extractor + parity harness + reports + `model.pt`
  - `_bmad-output/ml-models/` — uncompiled `.mlmodel` source bundle (the input to `make compile-model`; the *compiled* output `.mlmodelc` ships under `Sources/`)
  - `_bmad-output/perf-baselines/` — performance benchmark history
  - `_bmad-output/planning-artifacts/` — epics + architecture docs
  - `_bmad-output/project-context.md` — internal AI-agent context
- **`scripts/`** — non-shipping Python utilities (e.g., `scripts/dawproject-bpm.py` for DAW oracle ground-truth generation)

### Squash-merge protocol (`develop` → `main`)

Manual; the release operator does this by hand. There is no automation.

1. `git checkout main`
2. `git merge --squash develop`
3. **Before committing, `git rm --cached -r` every path in the "Stays on `develop` ONLY" list above**, plus any other develop-only artifact that landed (`*.trace`, etc. — see `.gitignore`)
4. Verify with `git status` that the staged tree contains only paths from the "Ships to `main`" table
5. Commit with a clean public release message — no references to BMAD, Claude Code, party mode, story specs, AI agents, or any LLM-aided-development concept

**`main`'s history must never reflect the LLM-aided development workflow.** No story-spec commit messages. No `Story 4-4b: ...` subjects. The release commit on main is one squash with a public-facing message; the audit trail of *how* the work happened lives on develop.

### Why this matters

- **Consumers cloning from `main`** should see a clean Swift package + a consumer convert tool. Seeing `.claude/`, `_bmad/`, or `CLAUDE.md` would be confusing, would expose internal workflow, and would create an implicit commitment to support development tooling that is project-internal.
- **`develop` is the audit trail.** Story specs, regression evidence, training reproducibility, and AI-agent collaboration history all live there. That's intentional and should remain so.
- **Pre-1.0 framing.** This discipline applies *now*, even pre-1.0; it tightens further at 1.0. Don't let main drift.

### Authoring a new file — decision tree

1. **Does it ship with the library?** → `Sources/` or `Tests/`. Lands on main.
2. **Is it consumer-facing infrastructure** that consumers need at clone time (e.g., a CLI for converting their own ML models)? → `tools/coreml-convert/` (currently the only such directory). Lands on main *only* with explicit story-spec authorization (DD #13 was the precedent — do not add more without one).
3. **Is it project planning, training, ML reproducibility, or AI-agent tooling?** → `_bmad-output/`, `_bmad/`, `.claude/`, `.agents/`, or `scripts/`. Stays on develop.
4. **Anything else?** Default to develop. Ask before promoting.

## Architecture

BoomBoomBoomKit is a standalone audio analysis library for BPM estimation and LUFS loudness measurement. Pure Swift, zero external dependencies — only Apple system frameworks (Accelerate/vDSP, AVFoundation, Foundation). Swift 6.0 strict concurrency, macOS 15+.

### Pipeline

```
PCMBufferReader → fan-out → BPMAnalyzer   (mel-spectrogram onset + autocorrelation)
                           → LUFSAnalyzer  (ITU-R BS.1770-5 K-weighted loudness)
```

All types are stateless structs/enums with static methods. Shared currency type is `[Float]` mono samples.

### Key Types (Sources/BoomBoomBoomKit/)

- **AudioAnalysisService** — Public facade. Composes PCMBufferReader + analyzers. Implements intensity-controlled progressive BPM analysis with configurable merge strategy. Supports cooperative cancellation (via injectable `isCancelled` closure, default `Task.isCancelled`) and per-window progress reporting (via `onProgress` callback). Primary API: `analyzeBPM(url:options:)`.
- **ProgressUpdate** — Public struct (`Sendable`) with `windowsCompleted: Int` and `windowsTotal: Int`. Emitted before each analysis window begins.
- **CandidateMergeStrategy** — Public enum (8 cases): `maxConfidence` (default), `dedup`, `quorum`, `average`, `median`, `weightedAverage`, `union`, `windowVoting`. Controls how candidates from multiple analysis windows are combined. `windowVoting` votes on each window's final disambiguated BPM (post-disambiguation) instead of raw candidates; falls back to `maxConfidence` when no consensus. `windowVoting` is parameterizable via `VotingPolicy` (`.simpleMajority` default; `.confidenceWeighted`, `.thresholdGated` for benchmark sweeps) — see `VotingPolicy.swift`. `CaseIterable` for ablation.
- **VotingPolicy** — Public enum (3 cases): `simpleMajority` (default), `confidenceWeighted`, `thresholdGated`. Resolution policy used ONLY when `mergeStrategy == .windowVoting` (the `CandidateMergeStrategy` value held by `AudioAnalysisService.Options`). It is NOT a `DSPTechnique` (no DSP changes; no ablation matrix expansion) and NOT a new `CandidateMergeStrategy` case (still 8 cases). Future stories must not promote it into either family without explicit story authorization. Threshold (`Options.votingThreshold`, range `[0.0, 1.0]`, silently clamped, NaN/Inf normalize to 0.0) is consulted only by `.thresholdGated`. `CaseIterable, Sendable, Hashable`.
- **AnalysisIntensity** — Public struct (1-10) controlling pipeline depth via `techniqueSet: TechniqueSet`. Named constants: `.fastest` (1), `.default` (7), `.thorough` (8), `.maximum` (10). Levels 1-7 are DSP-only; 8-10 reserved for future ML. Intensity mapping validated by 128-combination ablation matrix.
- **DSPTechnique** — Public enum (7 cases): `acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`, `subBandVoting`, `clickTrackCorrelation`. Closed set, `CaseIterable`.
- **TechniqueSet** — Public struct composing `Set<DSPTechnique>` with named presets: `.baseline` (vote+fine), `.optimal` (sharp+vote+fine, Acc1=67.1%), `.dnbOptimized` (sharp+norm+vote+fine), `.clickAugmented` (optimal + click, opt-in rhythmic-alignment rescoring), `.full` (all 7). `allDSPCombinations()` generates 2^7=128 combos for ablation.
- **MLTechnique** — Public protocol for future CoreML integration (Phase 3). Evaluates candidates post-pipeline via `BPMDiagnosticTrace`. Definition only, no conformances yet.
- **BPMDiagnosticTrace** — Public struct capturing per-step pipeline intermediate state. Populated when `enableTrace: true`. Evolving API.
- **BPMAnalyzer** — 10-step DSP pipeline with technique-gated stages: energy scan → silence check → mel-spectrogram onset (with optional sub-band normalization) → adaptive thresholding → autocorrelation (with optional ACF sharpening) → Fourier tempogram → periodicity fusion → peak selection → range normalization (60-200 BPM) → step 9b: click-track cross-correlation (optional, rescores candidates) → step 9.7: duration-derived BPM hint (optional, default-on via `Options.durationHint`, boosts candidates matching common bar-count BPMs when file duration ≥ `Options.durationHintMinFileSeconds`) → sub-band voting octave disambiguation → fine-grid refinement. Internal type (not public). Uses three internal buffer structs (`PipelineBuffers`, `ACFBuffers`, `TempogramBuffers`) following ADR-3 allocate/deallocate pattern to avoid per-step heap allocations. All buffer lifetimes are scoped to a single `estimateBPM()` invocation.
- **MelFilterbank** — Caseless enum namespace for Hz↔mel conversion and triangular filterbank matrix construction. Used by BPMAnalyzer.
- **LUFSAnalyzer** — ITU-R BS.1770-5 integrated loudness. K-weighting via vDSP.Biquad (Double precision). Pre-computed coefficients for 44.1/48/96kHz only. Internal type.
- **PCMBufferReader** — Reads audio files (WAV, AIFF, MP3, FLAC, M4A, CAF) into mono `[Float]` via AVFoundation. OGG/Vorbis is NOT supported (no Core Audio codec). Supports partial reads and downsampling.
- **MetadataPolicy** — Public struct (`Sendable, Hashable`) configuring file-tag BPM corroboration (Story 3.6). Fields: `enabledSources: Set<MetadataSource>` (default all three), `consensusTolerance` (0.5 BPM absolute), `corroborationTolerance` (0.03 relative), `corroborationBoost` (1.25), `maxBoostedConfidence` (0.95), `skepticismPenalty` (0.85), `allowOctaveCorroboration` (true), `allowTripletCorroboration` (false — gated until validated by follow-up story), `valueRange` (30.0...300.0), `parsing: ParsingOptions`. Two presets: `.default` (all sources on) and `.disabled` (empty `enabledSources`, fully suppresses I/O and merge-stage boost — byte-identical pre-Story-3.6 behavior).
- **MetadataSource** — Public enum (`String, CaseIterable, Sendable, Hashable`, 3 cases): `.iTunesTmpo` (MP4/M4A `tmpo` atom), `.id3TBPM` (ID3v2 `TBPM` text frame in MP3 and AIFF `ID3 ` chunks), `.vorbisBPM` (FLAC Vorbis `BPM=` comment, case-insensitive). Closed set; AVFoundation is never consulted for metadata (deprecated/async-only on macOS 13+).
- **MetadataBPMEvidence** — Public struct (`Sendable`) emitted on `AudioAnalysisResult.metadataEvidence` for every parsed tag. Fields: `source`, `rawValue`, `parsedBPM` (NaN for parse-phase rejections), `corroboratedWith: Double?`, `ratioMatched: HarmonicRatio?`, `boostApplied: Double`, `rejectionReason: String?` (parse-phase: `sentinel-zero`, `out-of-range`, `non-numeric`; decision-phase: `intra-file-conflict`, `dsp-disagreement`, `uncorroborated-single-tag`).
- **HarmonicRatio** — Public enum (`Sendable, Hashable`, 5 cases): `.one` (same-tempo placeholder; never set in evidence — `nil` represents same-tempo), `.double`, `.half` (octave), `.threeHalf`, `.twoThird` (triplet, gated). Story 3.1 detects 3:2 / 3:1 in `BPMAnalyzer.resolveOctaveAmbiguity` as trace-only evidence; Story 3.6 introduces the first metadata-driven *winner-promotion* via these ratios.
- **FileMetadataReader** — Internal caseless enum namespace. Direct container parsing for embedded BPM tags: MP4 atom walker, ID3v2.3/v2.4 frame walker (MP3 + AIFF/AIFC `ID3 ` chunk), FLAC Vorbis comment parser. Never throws — metadata absence is not an error. Bounds-checked, FileHandle-defer-closed.
- **MetadataCorroborator** — Internal caseless enum namespace. `apply(to:input:)` runs AFTER `CandidateMergeStrategy.merge` returns: boosts every candidate matching any participating tag, re-selects the winner from the boosted pool (allows tag-driven winner-promotion), and applies confidence boost (×1.25 clamp 0.95) or skepticism penalty (×0.85). Lives outside `merge` to keep that signature stable across 41 call sites and to ensure single-window paths (intensity 1-5) still apply corroboration. The internal `MetadataCorroborationInput` struct (also in this file) carries the consensus signal from the service to `apply`.

### Test Support (Sources/BoomBoomBoomKitTestSupport/)

Separate library target providing shared fixtures for consuming packages:
- **AudioFixtures** — Resolves bundled audio files from `Resources/AudioFixtures/`
- **TestSignalGenerators** — `generateClickTrack(bpm:sampleRate:durationSeconds:)` and `SplitMix64` deterministic PRNG

### Test Patterns

Tests use Swift Testing framework (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`) — not XCTest. Test fixtures include real audio files (MP3, FLAC, M4A) in `Tests/BoomBoomBoomKitTests/Fixtures/` and synthetic click tracks generated at runtime. DAW oracle (`daw-oracle.json`) lives in the OA300 corpus directory (not committed); generated by `scripts/dawproject-bpm.py` from `.dawproject` files; provides manually verified BPMs as diagnostic ground truth alongside Rekordbox benchmark target. Run `make oracle` for three-way comparison, `make oracle-generate` to regenerate from DAW. GiantSteps Tempo Dataset (664 EDM tracks, crowdsourced ground truth v2) benchmarked via `make benchmark-giantsteps`. Both corpus benchmarks are env-gated and track wall-clock time + accuracy across Epic 1 stories.

## Design Constraints

- All DSP uses Apple's Accelerate (vDSP) — no manual loops for bulk numeric operations
- K-weighting filters use Double precision throughout (Float causes measurable errors near unit circle poles)
- `BPMResult` and `LUFSResult` are internal; `AudioAnalysisResult`, `AnalysisIntensity`, `DSPTechnique`, `TechniqueSet`, `MLTechnique`, `BPMDiagnosticTrace`, `ProgressUpdate`, and `VotingPolicy` are public
- Default intensity mapping uses `.optimal` preset (sharp+vote+fine) with `maxConfidence` merge — validated by ablation on OA300 corpus (Acc1=69.5%, Acc2=89.0%)
- `@preconcurrency import AVFoundation` is used in PCMBufferReader for Swift 6 concurrency compatibility
- `nonisolated(unsafe)` in PCMBufferReader.downsample is intentional — AVAudioConverter calls its block synchronously
