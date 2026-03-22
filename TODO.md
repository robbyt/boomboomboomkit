# BoomBoomBoomKit — TODO

Enhancement backlog for BPM estimation and LUFS measurement. Items migrated from MetaMan (mediadiff) project on 2026-03-21 after library extraction.

## High Priority

### Improve BPM Candidate Generation Quality
**Origin:** MetaMan Epic 34 retro (2026-03-08)
**Severity:** High

11/30 OA300 Acc1 failures have the correct BPM absent from the top 3 candidates entirely. The disambiguation layer cannot fix what the candidate generator never surfaces.

**Investigate:**
- Expand candidate selection from top 3 to top 5
- Multi-window candidate merging (combine candidates from 30s/60s/90s windows before disambiguation)
- Spectral flux weighting to improve onset detection sensitivity for breakbeat patterns

**Files:** `BPMAnalyzer.swift` (peak selection step, progressive analysis)

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
    strategy: BPMDisambiguationStrategy = .subBandVoting
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

**Files:** New module (e.g., `BPMMLTiebreaker.swift`), would add CoreML dependency
