# BoomBoomBoomKit - Source Tree Analysis

## Directory Structure

```
BoomBoomBoomKit/
├── Package.swift                    # SPM manifest (swift-tools-version: 6.0, macOS 15+)
├── CLAUDE.md                        # AI agent instructions (develop branch only)
├── Makefile                         # Build/test/benchmark commands
├── .swiftlint.yml                   # SwiftLint configuration
│
├── Sources/
│   ├── BoomBoomBoomKit/             # Library target (ships to main)
│   │   ├── AudioAnalysisService.swift   # Public facade -- BPM + LUFS analysis entry point
│   │   ├── ProgressUpdate.swift         # Public Sendable struct for progress callbacks
│   │   ├── AnalysisIntensity.swift      # Public struct (1-10) controlling pipeline depth
│   │   ├── BPMSelectionPolicy.swift # Public enum (8 strategies) for multi-window merge
│   │   ├── DSPTechnique.swift           # Public enum (6 DSP technique cases)
│   │   ├── BPMDiagnosticTrace.swift     # Public struct for per-step pipeline state
│   │   ├── BPMAnalyzer.swift            # Internal -- 10-step DSP pipeline (~1400 lines)
│   │   ├── LUFSAnalyzer.swift           # Internal -- ITU-R BS.1770-5 loudness
│   │   ├── MelFilterbank.swift          # Internal -- Hz/mel conversion + filterbank matrix
│   │   └── PCMBufferReader.swift        # Public -- audio file I/O to mono [Float]
│   │
│   └── BoomBoomBoomKitTestSupport/  # Shared test fixtures target
│       ├── AudioFixtures.swift          # Resolves bundled audio files
│       ├── TestSignalGenerators.swift   # Click track generation + deterministic PRNG
│       └── Resources/AudioFixtures/     # Bundled audio files (MP3, WAV, FLAC, M4A, AIFF)
│
├── Tests/
│   └── BoomBoomBoomKitTests/        # Test target
│       ├── AudioAnalysisServiceTests.swift  # Service layer + cancellation + progress tests
│       ├── BPMAnalyzerTests.swift           # DSP pipeline unit tests
│       ├── LUFSAnalyzerTests.swift          # LUFS measurement tests
│       ├── MelFilterbankTests.swift         # Filterbank construction tests
│       ├── PCMBufferReaderTests.swift       # Audio I/O tests
│       ├── AblationTests.swift              # 64-combination technique matrix
│       ├── OA300BenchmarkTests.swift        # OA300 corpus accuracy benchmark
│       ├── GiantStepsBenchmarkTests.swift   # GiantSteps 664-track benchmark
│       ├── DAWOracleBenchmarkTests.swift    # Three-way DAW oracle comparison
│       └── Fixtures/                        # Test-only fixtures (ground truth JSON, etc.)
│
├── scripts/
│   └── dawproject-bpm.py            # DAWproject BPM extraction (run via uv)
│
├── docs/                            # Project documentation (this folder)
│
├── _bmad-output/                    # BMad planning/implementation artifacts (develop only)
│   ├── bpm.md                           # BPM pipeline deep-dive
│   ├── ablation-results.md              # Technique matrix results
│   ├── project-context.md               # AI agent implementation rules
│   ├── planning-artifacts/              # PRD, architecture, epics, roadmap
│   └── implementation-artifacts/        # Stories, sprint status, retrospectives
│
└── _bmad/                           # BMad module configuration (develop only)
```

## Critical Folders

| Folder | Purpose | Ships to main? |
|--------|---------|---------------|
| `Sources/BoomBoomBoomKit/` | Library source -- all DSP and public API | Yes |
| `Sources/BoomBoomBoomKitTestSupport/` | Shared fixtures for consuming packages | Yes |
| `Tests/BoomBoomBoomKitTests/` | All tests including benchmarks | Yes |
| `scripts/` | Python utilities | No |
| `_bmad-output/` | Planning and implementation artifacts | No |
| `_bmad/` | BMad agent/skill configuration | No |
| `.claude/` | Claude Code skills and settings | No |

## Entry Points

- **Library consumers:** `AudioAnalysisService.analyzeBPM(url:options:)` and `AudioAnalysisService.analyzeLUFS(url:)`
- **Build:** `swift build` or `make build`
- **Test:** `swift test` or `make test`
- **Benchmark:** `make benchmark` (OA300), `make benchmark-giantsteps` (GiantSteps)
- **Ablation:** `make ablation`
