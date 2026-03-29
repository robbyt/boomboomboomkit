---
project_name: 'BoomBoomBoomKit'
user_name: 'robbyt'
date: '2026-03-29'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'critical_rules']
status: 'complete'
rule_count: 52
optimized_for_llm: true
validated_with: ['apple-docs-mcp', 'axiom-swift-concurrency-ref', 'axiom-swift-modern', 'axiom-swift-testing', 'axiom-swift-performance', 'axiom-avfoundation-ref']
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Swift 6.0** — strict concurrency (`swift-tools-version: 6.0`), macOS 15+. All new public types MUST conform to `Sendable`
- **Zero external dependencies** — hard constraint, not observation. Only Apple system frameworks (Foundation, Accelerate, AVFoundation). Do not introduce third-party packages
- **Accelerate/vDSP** — ALL bulk numeric operations must use vDSP. No manual `for` loops over signal buffers. Float precision for signals; **Double precision mandatory for IIR filters** (K-weighting biquads — Float causes measurable errors near unit circle poles)
- **AVFoundation** — audio file I/O only (PCMBufferReader). Imported via `@preconcurrency import AVFoundation` — do NOT remove this annotation (Apple types are not yet Sendable-annotated; this is the SE-0337 migration path)
- **Swift Testing** — `@Suite`, `@Test`, `#expect`, `#require`. NOT XCTest
- **SwiftLint + swift format** — run `make fmt` BEFORE `make lint` (formatter can introduce lint violations). Formatter wins when rules irreconcilably conflict
- **SPM targets** — `BoomBoomBoomKit` (library), `BoomBoomBoomKitTestSupport` (shared fixtures for consuming packages — new test utilities go here, not in the test target), `BoomBoomBoomKitTests`

## Critical Implementation Rules

### Language-Specific Rules

- **All types are value types** — structs and enums only, zero classes. Analyzers are stateless structs with `static` methods — no instantiation, no lifecycle, no dependency injection. Call methods directly (e.g., `BPMAnalyzer.estimateBPM(samples:sampleRate:options:)`)
- **Implicit nil** — never write `var x: T? = nil`. Swift optionals default to nil. The explicit `= nil` is redundant
- **Options struct pattern** — group related parameters into structs with defaulted fields. Do not grow function parameter lists. Recent example: `TempogramBuffers` groups 3 pointer params; `bpmMin`/`bpmMax` became `bpmRange: ClosedRange<Int>`
- **Error handling: one error enum** — `PCMBufferReaderError` is the only error type. Analyzers (BPM, LUFS) return `nil` for no-result cases (silence, too-short, unsupported rate) — they do NOT throw. `throws` is reserved for file I/O failures in PCMBufferReader
- **Access control boundaries** — public: `AudioAnalysisService`, `AnalysisIntensity`, `CandidateMergeStrategy`, `DSPTechnique`, `TechniqueSet`, `PCMBufferReader`, `BPMDiagnosticTrace`. Internal: `BPMAnalyzer`, `BPMResult`, `LUFSAnalyzer`, `LUFSResult`, `MelFilterbank`. Do not promote internal types without explicit design decision
- **`nonisolated(unsafe)` in PCMBufferReader** — `AVAudioConverterInputBlock` is `@Sendable`, so Swift 6 forbids the closure from capturing mutable local variables. Since the converter calls the block synchronously (not concurrently), the capture of `var inputConsumed` is safe in practice. `nonisolated(unsafe)` on the variable suppresses this false-positive. Do NOT refactor to `withCheckedContinuation` or wrap in a `Task` — that introduces real concurrency where none exists
- **vDSP_Length wrapping** — all count parameters to vDSP functions require `vDSP_Length` (UInt, not Int). Always wrap: `vDSP_Length(count)`. Forgetting this causes compiler errors or silent truncation
- **CaseIterable** — `DSPTechnique` and `CandidateMergeStrategy` conform for ablation/enumeration. Maintain when adding new cases. `Hashable` on `AnalysisIntensity`, `DSPTechnique`, `TechniqueSet`, `CandidateMergeStrategy` (used as dictionary keys/Set members)
- **Code organization** — every file uses `// MARK: - Section` headers consistently. Public API gets `///` doc comments with `- Parameters:` and `- Returns:`. Internal helpers get minimal or no doc comments

### Framework-Specific Rules (Accelerate/vDSP)

- **No manual loops over signal data** — every bulk numeric operation on audio buffers must use vDSP (`vDSP_vmul`, `vDSP_vadd`, `vDSP_vsdiv`, `vDSP_vthres`, `vDSP_vswsum`, `vDSP_rmsqv`, `vDSP_meanv`, `vDSP_dotpr`, `vDSP_vsq`, etc.). Loops over *control flow* (iterating candidates, tracks, BPM values) wrapping vDSP calls inside are fine — the prohibition is on `for i in 0..<count` over sample arrays
- **FFT** — 2048 samples (power of 2 for radix-2), ~46ms frames at 44.1kHz. Use `vDSP.FFT` with split-complex format (`DSPSplitComplex`). **DC/Nyquist packing**: bin 0 of split-complex output packs DC in the real part and Nyquist in the imaginary part. Extract both BEFORE calling `vDSP_zvmags`, which otherwise computes `sqrt(DC^2 + Nyquist^2)` — neither value
- **Stride** — always explicit in vDSP calls (stride=1 for contiguous). Never assume default
- **Mel filterbank** — row-major dense matrix applied via `vDSP_mmul`. Constructed by `MelFilterbank` (enum namespace, no cases). Hz-to-mel uses O'Shaughnessy (1987)
- **K-weighting (LUFSAnalyzer)** — two cascaded biquad sections (high-shelf + high-pass) via `vDSP.Biquad<Double>`. Input samples converted Float-to-Double via `vDSP_vspdp` (vectorized, not per-element cast). Pre-computed coefficients for 44.1/48/96kHz ONLY — unsupported rates return nil, do not interpolate
- **BPM pipeline order** — 10 steps in sequence: (1) energy scan, (2) silence check, (3) mel-spectrogram onset, (4) adaptive thresholding, (5) autocorrelation, (6) Fourier tempogram, (7) periodicity fusion, (8) peak selection, (9) range normalization 60-200 BPM, (10) sub-band voting + fine-grid refinement. Steps 3/4/5/10 are technique-gated via `TechniqueSet`. New DSP stages must identify where they fit and whether they should be gated

### Testing Rules

- **Swift Testing only** — `@Suite`, `@Test`, `#expect`, `#require`. Never XCTest. Use `#require` when a nil/failure would make subsequent assertions meaningless; use `#expect` for validating properties of a known-good value
- **Test fixtures** — accessed via `AudioFixtures.url(for:extension:)` from BoomBoomBoomKitTestSupport. Synthetic click tracks via `createClickTrackWAV(bpm:sampleRate:durationSeconds:url:)` or `TestSignalGenerators.generateClickTrack()` in TestSupport
- **Suite initializers** — `init() throws` loads fixtures and ground truth. Each `@Test` gets a fresh suite instance, so init runs per-test (not per-suite). Fixture loading is fast (JSON parse); expensive work (audio analysis) happens within each test. See `OA300BenchmarkTests`, `DAWOracleBenchmarkTests` for the pattern
- **Env-gated benchmarks** — OA300 tests require `OA300_CORPUS_PATH`. Pattern: `@Suite("Name", .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))`
- **Two levels of parallelism** — `make test` runs `swift test --parallel` (SPM-level suite parallelism). Within benchmarks, `withTaskGroup` parallelizes track analysis. Use `make test-verbose` (no `--parallel`) when debugging failures
- **Accuracy metrics** — Acc1: within 2% of expected BPM. Acc2: Acc1 OR octave-correct (half/double). Current baselines maintained in CLAUDE.md (drift with algorithm changes — do not hardcode). Regressions should be flagged
- **Bad BPM subset** — `benchmarkBadBPMSubset` runs with `enableTrace: true` on the hardest tracks (`subdir: "Bad BPM"`). First place to look when debugging accuracy failures
- **Merge strategy testing pattern** — `benchmarkMergeStrategies` pre-reads all audio once into `[TrackAudio]`, then iterates all 8 `CandidateMergeStrategy.allCases`. Follow this pattern when adding new strategies — do not re-read audio per strategy
- **Ablation testing** — `AblationTests` exhaustively tests all 2^6=64 DSP technique combinations via `TechniqueSet.allDSPCombinations()`. New techniques must be added to the ablation matrix
- **DAW oracle** — `daw-oracle.json` in OA300 corpus (not committed). Three-way comparison: ours vs Rekordbox (benchmark target) vs DAW-verified (diagnostic truth). Uses `convertFromSnakeCase` key decoding. Generated by `uv run scripts/dawproject-bpm.py`

### Code Quality & Style Rules

- **`make fmt` then `make lint`** — always in this order. swift format may introduce lint violations (verified: `closure_parameter_position` conflict). Run both before committing
- **SwiftLint disabled rules** — 11 rules disabled in `.swiftlint.yml`. Only disable rules that irreconcilably conflict with swift format or are impractical for DSP-heavy code (file_length, function_body_length, cyclomatic_complexity). Do not disable rules just because they are inconvenient
- **TODO comments** — `// TODO:` triggers SwiftLint warnings intentionally. These are visible reminders of future work. Do NOT suppress with `swiftlint:disable:next todo`
- **File naming** — PascalCase matching the primary type (`BPMAnalyzer.swift`, `DSPTechnique.swift`). Test files: `<TypeName>Tests.swift`
- **Header format** — six-line standard: `//` / `//  FileName.swift` / `//  BoomBoomBoomKit` / `//` / `//  Brief description` / `//`
- **Imports** — explicit per file. `Foundation`, `Accelerate`, `AVFoundation` imported only where directly used. Do not add redundant imports or remove seemingly-unnecessary ones
- **Academic references** — cite papers and standards inside `///` doc comments on the relevant declaration (e.g., `/// ... (Davies & Plumbley 2007)`, `/// ITU-R BS.1770-5`)

### Development Workflow Rules

- **Branch model** — `main` (clean library releases), `develop` (active development + all AI tooling). `develop` carries everything: library source, tests, AND AI scaffolding (`.claude/`, `_bmad/`, `CLAUDE.md`, `Makefile`, `scripts/`, `_bmad-output/`). Squash merges from `develop` to `main` EXCLUDE all AI/agent files — `main` contains only the shippable library
- **What goes to main** — `Package.swift`, `Sources/`, `Tests/`, `.swiftlint.yml`, `LICENSE`, `README.md`. Nothing else
- **What stays on develop** — `.claude/`, `_bmad/`, `_bmad-output/`, `CLAUDE.md`, `Makefile`, `scripts/`, all BMad/skill/agent configuration
- **File placement rule** — when creating files, ask: "does this ship with the library?" If yes: `Sources/` or `Tests/`. If no: `.claude/`, `_bmad/`, `scripts/`, or `_bmad-output/`
- **No coupling** — library code (`Sources/`) must never reference or depend on AI tooling paths. The library must build and test cleanly from `main` with only SPM (`swift build`, `swift test`)
- **Release process** — manual: `git checkout main && git merge --squash develop`, then delete AI files from the staging area before committing. The public `main` branch must not reflect LLM-aided development tooling
- **Build verification** — `make build` + `make test` must pass before committing. `make benchmark` for OA300 accuracy (requires corpus)
- **Commit messages** — imperative mood, focus on "why" not "what". First line concise
- **Python scripts** — use `uv run` not `python3` (e.g., `uv run scripts/dawproject-bpm.py`)

### Critical Don't-Miss Rules

**Silent correctness failures:**
- **Never use Float for IIR filter coefficients** — K-weighting biquads require Double. Float32 causes measurable LUFS errors near unit circle poles. Code compiles fine; results are silently wrong
- **Accuracy regressions** — any change to BPMAnalyzer must be validated against OA300 corpus (`make benchmark`). Acc1 and Acc2 must not decrease. Run `make oracle` for three-way DAW comparison on ambiguous cases
- **In-place signal mutation** — pipeline steps should mutate `[Float]` arrays in-place where possible (vDSP supports overlapping input/output). Do not copy signal buffers between steps — 120s of audio at 44.1kHz is ~10MB per copy

**Memory safety:**
- **UnsafeMutablePointer discipline** — every `.allocate(capacity:)` MUST have a corresponding `.deallocate()` in a defer block or explicit cleanup. See `TempogramBuffers` for the pattern (struct with `allocate()` factory and `deallocate()` method)
- **OGG is NOT supported** — `AVAudioFile` supports WAV, AIFF, CAF, MP3, AAC/M4A, FLAC. OGG/Vorbis has no native Core Audio codec on macOS. CLAUDE.md reference to OGG is incorrect

**API contract violations:**
- **Never add `throws` to analyzers** — BPM/LUFS analyzers return nil for no-result. Only PCMBufferReader throws
- **Never promote internal types to public** — `BPMAnalyzer`, `BPMResult`, `LUFSAnalyzer`, `LUFSResult`, `MelFilterbank` are internal by design. Public facade is `AudioAnalysisService`

**Release process:**
- **Never commit AI tooling to main** — `.claude/`, `_bmad/`, `CLAUDE.md`, `Makefile`, `scripts/`, `_bmad-output/` stay on `develop` only. Public `main` must not reflect LLM-aided development

**Future optimization notes:**
- `ContiguousArray` is NOT needed for `[Float]` — Swift's `Array` is already contiguous for value types (no ObjC bridging check). The ~15% `ContiguousArray` improvement only applies to arrays of class types. Current `[Float]` usage is optimal
- `reserveCapacity` on intermediate arrays when size is known ahead of vDSP operations

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code in BoomBoomBoomKit
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Validate DSP changes against OA300 corpus (`make benchmark`)

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack or API boundaries change
- Remove rules that become obvious over time
- Accuracy baselines live in CLAUDE.md, not here

Last Updated: 2026-03-29
