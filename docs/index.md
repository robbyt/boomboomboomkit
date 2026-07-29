# BoomBoomBoomKit - Documentation Index

## Project Overview

- **Type:** Monolith (single Swift package)
- **Primary Language:** Swift 6.0 (strict concurrency, macOS 15+)
- **Architecture:** Stateless DSP pipeline with public facade
- **Dependencies:** Zero external (Apple system frameworks only)

### Quick Reference

- **Entry Point:** `AudioAnalysisService.analyzeBPM(url:options:)`
- **Tech Stack:** Swift 6.0, Accelerate/vDSP, AVFoundation, Swift Testing
- **Tests:** 153 across 47 suites
- **Accuracy:** OA300 Acc1=69.5%, GiantSteps Acc1=70.0%

## Generated Documentation

- [Project Overview](./project-overview.md) -- Tech stack, architecture summary, key metrics
- [Architecture](./architecture.md) -- Type hierarchy, pipeline steps, ADRs, accuracy baselines
- [Source Tree Analysis](./source-tree-analysis.md) -- Annotated directory structure with critical folders
- [Development Guide](./development-guide.md) -- Build, test, benchmark commands, code style, branching

## Existing Project Documentation

### DSP & Algorithm

- [BPM Detection Pipeline](../_bmad-output/bpm.md) -- Detailed 11-step pipeline with vDSP function reference, accuracy data, failure analysis
- [Ablation Results](../_bmad-output/ablation-results.md) -- Full 64-combination technique matrix, key findings, named presets

### Planning Artifacts

- [PRD](../_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md) -- 51 functional requirements, 10 non-functional requirements
- [Architecture (Planning)](../_bmad-output/planning-artifacts/architecture.md) -- 10 ADRs, implementation patterns, cancellation/progress design
- [Epics & Stories](../_bmad-output/planning-artifacts/epics.md) -- 5 epics, 22 stories, FR coverage map
- [Phase 3 Roadmap (archived)](../_bmad-output/planning-artifacts/archive/phase3-roadmap-2026-03-29.md) -- Phases 3A-3D plan from 2026-03-29, superseded by epics.md

### Implementation Artifacts

- [Story 1-1: Buffer Reuse](../_bmad-output/implementation-artifacts/1-1-internal-buffer-reuse-in-bpm-pipeline.md) -- PipelineBuffers, ACFBuffers, TempogramBuffers
- [Story 1-2: Cancellation & Progress](../_bmad-output/implementation-artifacts/1-2-cooperative-cancellation-and-progress-reporting.md) -- isCancelled, onProgress, Options refactor
- [Epic 1 Retrospective](../_bmad-output/implementation-artifacts/epic-1-retro-2026-04-05.md) -- Lessons learned, action items
- [Deferred Work](../_bmad-output/implementation-artifacts/deferred-work.md) -- Known issues and future work
- [Sprint Status](../_bmad-output/implementation-artifacts/sprint-status.yaml) -- Epic/story tracking

### AI Agent Context

- [Project Context](../_bmad-output/project-context.md) -- 60 critical implementation rules for AI agents
- [CLAUDE.md](../CLAUDE.md) -- Architecture overview, key types, build commands

### Tech Specs

- [Phase 1: Intensity, Trace, Accuracy](../_bmad-output/implementation-artifacts/tech-spec-phase-1-intensity-trace-accuracy.md)
- [Phase 2: Technique Protocol, Ablation](../_bmad-output/implementation-artifacts/tech-spec-phase-2-technique-protocol-ablation.md)
- [Multi-Window Candidate Merging](../_bmad-output/implementation-artifacts/spec-multi-window-candidate-merging.md)
- [Post-Disambiguation Voting](../_bmad-output/implementation-artifacts/spec-post-disambiguation-voting.md)

## Getting Started

```bash
# Clone and build
git clone <repo-url>
cd BoomBoomBoomKit
swift build

# Run tests
swift test

# Run benchmarks (requires corpus)
OA300_CORPUS_PATH=/path/to/OA300 make benchmark
```

See [Development Guide](./development-guide.md) for full setup instructions.
