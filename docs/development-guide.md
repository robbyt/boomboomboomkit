# BoomBoomBoomKit - Development Guide

## Prerequisites

- macOS 15+
- Swift 6.0 (Xcode 16+)
- SwiftLint (for linting)
- uv (for Python scripts, optional)

## Quick Start

```bash
# Build
swift build          # or: make build
make build-release   # Release configuration

# Test
swift test           # or: make test (parallel)
make test-verbose    # Full streaming output

# Single test suite
swift test --filter BPMAnalyzer120BPMTests
swift test --filter BPMAnalyzer120BPMTests/detect120BPM

# Format and lint (always in this order)
make fmt
make lint
```

## Benchmarks (require corpus paths)

```bash
# OA300 corpus (82 tracks, Rekordbox ground truth)
OA300_CORPUS_PATH=/path/to/OA300 make benchmark

# GiantSteps Tempo Dataset (664 EDM tracks)
GIANTSTEPS_CORPUS_PATH=/path/to/giantsteps make benchmark-giantsteps

# Full ablation matrix (64 technique combinations)
OA300_CORPUS_PATH=/path/to/OA300 make ablation

# Three-way DAW oracle comparison
OA300_CORPUS_PATH=/path/to/OA300 make oracle

# Regenerate DAW oracle JSON from .dawproject file
make oracle-generate
```

## Build Commands Reference

| Command | Description |
|---------|-------------|
| `make build` | Debug build |
| `make build-release` | Release build |
| `make test` | Run all tests (parallel) |
| `make test-verbose` | Run tests with full output |
| `make test-filter SUITE=Name` | Run specific test suite |
| `make benchmark` | OA300 accuracy benchmark |
| `make benchmark-giantsteps` | GiantSteps accuracy benchmark |
| `make ablation` | Full 64-combination technique matrix |
| `make oracle` | Three-way DAW oracle comparison |
| `make fmt` | Format Swift code |
| `make lint` | Run SwiftLint |
| `make lint-fix` | SwiftLint with auto-fix |
| `make clean` | Remove build artifacts |
| `make deps` | Resolve SPM dependencies |

## Testing Strategy

- **Framework:** Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`) -- NOT XCTest
- **Fixtures:** Real audio (MP3, FLAC, M4A) via `AudioFixtures.url(for:extension:)` + synthetic click tracks
- **Benchmarks:** Env-gated via `@Suite(.enabled(if: ...))` pattern
- **Ablation:** Exhaustive 2^6=64 DSP technique combinations
- **Accuracy:** Acc1 (2% tolerance), Acc2 (octave-correct). Baselines in CLAUDE.md

## Standard Gating Checklist (per-story)

Before committing any change:

1. `make fmt` -- format code
2. `make lint` -- check lint rules
3. `make test` -- all tests pass
4. `make benchmark` -- no Acc1/Acc2 regression (if DSP changes)
5. `make ablation` -- no crashes (if technique changes)
6. Update `///` doc comments for modified public API
7. Update CLAUDE.md if public types or behaviors change

## Branch Model

- **main** -- clean library releases (no AI tooling)
- **develop** -- active development with AI scaffolding
- Ships to main: `Package.swift`, `Sources/`, `Tests/`, `.swiftlint.yml`, `LICENSE`, `README.md`
- Stays on develop: `.claude/`, `_bmad/`, `_bmad-output/`, `CLAUDE.md`, `Makefile`, `scripts/`

## Code Style

- `make fmt` BEFORE `make lint` (formatter can introduce lint violations)
- PascalCase file names matching primary type
- Six-line file headers
- `// MARK: - Section` headers in every file
- `///` doc comments on public API with `- Parameters:` and `- Returns:`
- Academic references in doc comments (e.g., `/// ... (Ellis 2007)`)
