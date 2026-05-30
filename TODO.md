# BoomBoomBoomKit — TODO

Enhancement backlog for BPM estimation and LUFS measurement. Items migrated from MetaMan (mediadiff) project on 2026-03-21 after library extraction.

## High Priority

### Improve BPM Candidate Generation Quality
**Origin:** MetaMan Epic 34 retro (2026-03-08)
**Severity:** High
**Status:** Partially addressed in Phase 1 (2026-03-24)

11/30 OA300 Acc1 failures have the correct BPM absent from the top 3 candidates entirely. The disambiguation layer cannot fix what the candidate generator never surfaces.

**Phase 1 changes (implemented 2026-03-24):**
- ✅ Expanded candidate selection from top 3 to top 5 (intensity 5+) — brainstorming #24
- ✅ Added `AnalysisIntensity` (1-10) API controlling pipeline depth — brainstorming #15/16/17
- ✅ Added `BPMDiagnosticTrace` for per-step pipeline introspection — brainstorming #47
- ✅ ACF peak sharpening via `vDSP_vsq` (intensity 3+) — brainstorming #39
- ✅ Adaptive thresholding on onset envelope (intensity 4+) — brainstorming #60
- ✅ Per-sub-band max normalization (intensity 3+) — brainstorming #38
- ✅ OA300 benchmark suite (env-gated, `make benchmark`)

**Phase 2 changes (implemented 2026-03-26):**
- ✅ Replaced `BPMPipelineConfiguration` with `DSPTechnique` enum + `TechniqueSet` composition
- ✅ Added `MLTechnique` protocol extension point for future CoreML (definition only)
- ✅ Revised intensity mapping based on 64-combination ablation matrix
- ✅ Validated presets: `.optimal` (sharp+vote+fine, Acc1=67.1%), `.dnbOptimized` (sharp+norm+vote+fine, 67.1%)
- ✅ Removed adaptive threshold and expanded candidates from default path (both hurt accuracy)
- ✅ Full ablation results committed at `_bmad-output/ablation-results.md`
- OA300 results: `.optimal` Acc1=67.1%, Acc2=81.7% (was 59.8% with all techniques enabled)

**Phase 3 changes (implemented 2026-03-27):**
- ✅ Added `BPMSelectionPolicy` enum with 7 pluggable strategies for multi-window candidate merging
- ✅ Removed early exit for intensity 6+ (all windows now run); `maxConfidence` picks best
- ✅ OA300 results: Acc1=69.5% (was 68.3%), Acc2=89.0% (was 85.4%) — +1 Acc1, +3 Acc2
- ✅ Ablation showed clustering-based strategies all hurt (lose per-window disambiguation)
- ✅ Key insight: merging raw candidates loses octave disambiguation; future strategies need to merge post-disambiguation results
- Full ablation results at `_bmad-output/ablation-results.md`

**Remaining investigation:**
- Spectral flux weighting to improve onset detection sensitivity for breakbeat patterns — brainstorming #27
- Post-disambiguation merge strategies (merge final BPMs across windows, not raw candidates) — ablation finding 2026-03-27

**Files:** `BPMAnalyzer.swift`, `AnalysisIntensity.swift`, `BPMDiagnosticTrace.swift`, `AudioAnalysisService.swift`

## Medium Priority

### Non-Octave BPM Error Investigation
**Origin:** MetaMan Epic 33 retro (2026-03-07)
**Severity:** Medium

Two Prodigy tracks fail at non-octave tempos:
- 171 BPM — triplet lock (correct tempo is 3:2 ratio of detected)
- 107.5 BPM — 2/3-time lock (correct tempo is 3:2 ratio of detected)

Sub-band voting currently only handles 2:1 (octave) ratios. Investigate ratio-aware disambiguation for 3:2, 3:1, and other common musical ratios.

**Files:** `BPMAnalyzer.swift` (octave disambiguation step)

### BPM Tag Hint API
**Origin:** MetaMan Epic 33 retro (2026-03-07)
**Severity:** Medium (was Low in MetaMan backlog)

Callers may already have BPM metadata from embedded tags (ID3 TBPM, iTunes tmpo). The library should accept an optional tag hint parameter to skip full PCM analysis when a trusted tag value exists.

**Possible API:**
```swift
static func analyzeBPM(
    url: URL,
    existingTagBPM: Double? = nil,  // Skip analysis if provided and trusted
    maxSeconds: Double = 120,
    intensity: AnalysisIntensity = .default
) throws -> AudioAnalysisResult?
```

Alternatively, provide a `validateTagBPM(url:tagBPM:)` method that does a quick analysis to confirm or reject a tag value (useful for detecting incorrect tags).

**Files:** `AudioAnalysisService.swift`, `BPMAnalyzer.swift`

### Combined Analysis API (Single PCM Read)
**Origin:** MetaMan Epic 33 retro (2026-03-07)
**Severity:** Medium (was Low in MetaMan backlog)

BPM and LUFS currently require separate `PCMBufferReader` calls, duplicating ~100ms of file I/O per file. Provide a combined analysis function that reads PCM once and runs both analyzers.

**Possible API:**
```swift
public struct FullAnalysisResult {
    let bpm: AudioAnalysisResult?
    let lufs: Double?
}

static func analyzeAll(
    url: URL,
    maxSeconds: Double = 120
) throws -> FullAnalysisResult
```

**Files:** `AudioAnalysisService.swift`, `PCMBufferReader.swift`

### LUFS Arbitrary Sample Rate Support
**Origin:** In-code TODO (LUFSAnalyzer.swift:94)
**Severity:** Medium

K-weighting filter coefficients are currently pre-computed for 44.1kHz, 48kHz, and 96kHz only. Implement bilinear transform derivation for arbitrary sample rates to support less common rates (22.05kHz, 88.2kHz, 192kHz, etc.).

**Files:** `LUFSAnalyzer.swift`

## Low Priority / Research

### Evaluate Small ML BPM Tiebreaker Model
**Origin:** MetaMan Epic 34 retro (2026-03-08)
**Severity:** Deferred

Investigate a distilled CNN or hybrid DSP+ML approach for BPM disambiguation. Constraints:
- Model size < 5MB (library must remain lightweight)
- Only triggers when DSP confidence is low
- Must not require network access (on-device only)

**Trigger:** DSP-only improvements plateau below ~80% Acc1 on the OA300 benchmark corpus. Do not pursue until candidate generation quality (High priority item above) is addressed first.

**Integration point:** `MLTechnique` protocol is defined in `DSPTechnique.swift` (Phase 2). Conformances receive `BPMDiagnosticTrace` and evaluate candidates post-pipeline.

**Files:** New module (e.g., `BPMMLTiebreaker.swift`), would add CoreML dependency
