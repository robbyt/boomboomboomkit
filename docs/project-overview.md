# BoomBoomBoomKit - Project Overview

BoomBoomBoomKit is a standalone audio analysis library for BPM estimation and LUFS loudness measurement. Pure Swift, zero external dependencies -- only Apple system frameworks (Accelerate/vDSP, AVFoundation, Foundation).

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| Language | Swift | 6.0 | Strict concurrency, macOS 15+ |
| DSP | Accelerate/vDSP | System | All bulk numeric operations |
| Audio I/O | AVFoundation | System | PCM reading (WAV, AIFF, MP3, FLAC, M4A, CAF) |
| Build | Swift Package Manager | 6.0 | 3 targets: library, test support, tests |
| Testing | Swift Testing | Built-in | @Suite, @Test, #expect, #require |
| Linting | SwiftLint + swift format | Latest | `make fmt` then `make lint` |
| Scripts | Python (via uv) | 3.x | DAWproject BPM extraction |

## Architecture

**Pattern:** Stateless DSP pipeline with public facade

```
PCMBufferReader --> fan-out --> BPMAnalyzer   (mel-spectrogram onset + autocorrelation)
                             --> LUFSAnalyzer  (ITU-R BS.1770-5 K-weighted loudness)
```

**Public facade:** `AudioAnalysisService` composes PCMBufferReader + analyzers. Implements intensity-controlled progressive BPM analysis with configurable merge strategy, cooperative cancellation, and per-window progress reporting.

**All types are value types** -- structs and enums with static methods. No classes, no instantiation, no dependency injection.

## Repository Structure

- **Monolith** -- single cohesive Swift package
- **Branch model:** `main` (clean library releases), `develop` (active development + AI tooling)
- **SPM targets:** `BoomBoomBoomKit` (library), `BoomBoomBoomKitTestSupport` (shared fixtures), `BoomBoomBoomKitTests`

## Key Metrics

- **Source files:** 10 (library) + 2 (test support) + 9 (tests)
- **Tests:** 153 across 47 suites
- **Accuracy:** OA300 Acc1=69.5%, GiantSteps Acc1=70.0%
- **Dependencies:** Zero external (Apple system frameworks only)

## Links to Detailed Documentation

- [Architecture](./architecture.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)

## Existing Project Documentation

- [BPM Detection Pipeline](../_bmad-output/bpm.md) -- Detailed 11-step pipeline description with vDSP function reference
- [Ablation Results](../_bmad-output/ablation-results.md) -- Full 64-combination technique matrix results
- [Project Context (AI Rules)](../_bmad-output/project-context.md) -- 60 critical implementation rules for AI agents
- [PRD](../_bmad-output/planning-artifacts/prd.md) -- Product requirements (45 FRs, 20 NFRs)
- [Architecture (Planning)](../_bmad-output/planning-artifacts/architecture.md) -- ADRs and architectural decisions
- [Epics](../_bmad-output/planning-artifacts/epics.md) -- 5 epics, 22 stories
- [Phase 3 Roadmap](../_bmad-output/planning-artifacts/phase3-roadmap.md) -- Implementation phases 3A-3D
- [Deferred Work](../_bmad-output/implementation-artifacts/deferred-work.md) -- Known issues and future work
