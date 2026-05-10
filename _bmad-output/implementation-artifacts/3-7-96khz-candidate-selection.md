# Story 3-7: 96 kHz × 126 BPM Candidate Selection Failure

**Epic:** Epic 3 — Fine-Grid Precision & Sample-Rate Robustness
**Parent Story:** 3-2 (Fine-Grid Precision Fix — `refineCandidates` introduced)
**Status:** Draft / Not Started
**Priority:** Medium
**Filed:** 2026-05-10 (deferred follow-up from Story 3-2 code review, 2026-04-25)

---

## Story

**As a** user submitting 96 kHz audio containing a 126 BPM track,
**I want** `BPMAnalyzer.estimateBPM` to return a result within ±2 BPM of the true tempo,
**So that** the BPM detector is reliable across professional studio sample rates, not just
the consumer rates (44.1 kHz, 48 kHz) tested today.

---

## Background

Story 3-2 introduced `refineCandidates` (fine-grid tempogram, ±4 BPM at 0.1 BPM steps)
to correct coarse integer-BPM estimates. The call site at
`BPMAnalyzer.swift:184` passes **only the disambiguated winner**:

```swift
let refinedCandidates = refineCandidates(
    candidates: [winner],          // ← single candidate; cannot recover a bad selection
    onsetEnvelope: onsetEnvelope,
    ...
)
```

The 3-2 code review (2026-04-25) flagged that at 96 kHz the mel-onset pipeline
distributes energy differently across mel bands because the FFT bin width doubles
(96000 / 2048 ≈ 47 Hz vs 44100 / 2048 ≈ 22 Hz). Fewer FFT bins fall in the
musically useful range (30–16000 Hz), shrinking the effective mel filterbank coverage.
This degrades coarse peak scores for mid-tempo signatures (e.g., 126 BPM) relative
to their octave relatives (63 BPM, 252 BPM), causing the wrong candidate to win
disambiguation — after which the fine-grid step, working on a single candidate, cannot
recover.

**Root-cause chain:**
1. 96 kHz → coarser FFT bins → altered mel energy distribution
2. Altered energy → coarse scores favour wrong octave of 126 BPM
3. `resolveOctaveAmbiguity` selects wrong winner
4. `refineCandidates([winner])` refines the wrong BPM — cannot recover

**No test coverage exists** for 96 kHz BPM detection; the only 96 kHz tests in the
repo are in `LUFSAnalyzer` (sample-rate coefficient checks).

---

## Acceptance Criteria

1. `BPMAnalyzer.estimateBPM(samples:sampleRate: 96000)` on a synthetic 126 BPM click
   track returns a result with `result.bpm` in `[124, 128]`.
2. The fix does not regress the existing 120 BPM / 140 BPM / 160 BPM tests at 44.1 kHz
   or the 120 BPM test at 48 kHz (all currently passing).
3. Confidence for the 96 kHz / 126 BPM case is ≥ 0.5.
4. No new `XCTSkip` or equivalent exclusion is introduced.

---

## Dev Notes / Architecture Requirements

### FFT bin-width issue at 96 kHz

`BPMAnalyzer.fftSize = 2048` is constant. At 96 kHz the bin width is
`96000 / 2048 ≈ 46.9 Hz`, vs `44100 / 2048 ≈ 21.5 Hz` at 44.1 kHz. The mel
filterbank cap `melFmax = 16000 Hz` uses only `≈341` of 1024 bins at 96 kHz vs
`≈743` at 44.1 kHz. Onset energy patterns, particularly for kick (60–150 Hz) and snare
(150–400 Hz), compress into fewer mel bands.

### Fix candidate A — Refine top-K and re-select (preferred starting point)

Change the `refineCandidates` call site (`BPMAnalyzer.swift:184`) to pass all coarse
candidates before disambiguation, then select the winner from the refined set:

```swift
// Step 10c (revised): refine all coarse candidates first, then disambiguate
let refinedCandidates = refineCandidates(
    candidates: candidates,        // top-3 from extractTopCandidates
    onsetEnvelope: onsetEnvelope,
    autocorrelation: acf,
    onsetRate: onsetRate,
    bpmMin: bpmMin,
    bpmMax: bpmMax)

var winner = resolveOctaveAmbiguity(
    candidates: refinedCandidates, fused: fused, bpmMin: bpmMin,
    subBandACFs: subBandACFs, onsetRate: onsetRate)

// Step 10b confirmation still on winner
if !subBandACFs.isEmpty {
    winner = confirmWithSubBandPeaks(
        winner: winner, subBandACFs: subBandACFs, onsetRate: onsetRate)
}
// No second call to refineCandidates needed
```

**Upside:** Disambiguation now works on fine-grid scores, reducing sensitivity to
integer-BPM scoring artefacts at 96 kHz.
**Risk:** `resolveOctaveAmbiguity` uses `fused[]` indexed by integer BPM
(`let fasterIdx = Int(faster.bpm) - bpmMin`). After fine-grid refinement, `faster.bpm`
may be non-integer (e.g., 125.8). Add rounding before the index lookup, or pass the
pre-refinement integer BPMs alongside fine-grid scores.

### Fix candidate B — 96 kHz-aware tie-break in coarse candidate ranking

Detect when `sampleRate ≥ 88200` and apply an additional penalty/boost in
`extractTopCandidates` or `resolveOctaveAmbiguity` based on the expected onset-rate
lag alignment: at 96 kHz, lags for mid-tempo BPMs (100–160 BPM) are not contaminated
by FFT spectral leakage; cross-check candidate scores against the raw ACF value at the
expected lag and prefer the candidate whose ACF peak is sharpest.

**Upside:** Targeted fix, zero impact on 44.1/48 kHz paths.
**Downside:** Adds a sample-rate branch; needs empirical threshold tuning.

### Recommendation

Implement Fix A first — it is structurally cleaner and tests more naturally. Validate
with a synthetic 96 kHz / 126 BPM click track test. If Fix A causes regressions in
the 44.1 kHz suite (possible if `resolveOctaveAmbiguity` is sensitive to fine-grid BPM
jitter), fall back to Fix B as a targeted patch.

### Key call sites to modify (Fix A)

| File | Lines | Change |
|---|---|---|
| `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` | 167–193 | Reorder: refine before disambiguate; remove second `refineCandidates` call |
| `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` | 954–966 | Guard against non-integer `.bpm` in `fused[]` index |

---

## Tasks / Subtasks

- [ ] **T1 — Reproduce** Write a failing test: `detect126BPMat96kHz()` in
  `BPMAnalyzerTests.swift` using `generateClickTrack(bpm: 126, sampleRate: 96000, ...)`.
  Confirm it fails on `main` before any fix.
- [ ] **T2 — Fix A implementation** Restructure Steps 10–10c in `estimateBPM` to refine
  all candidates before octave disambiguation (see Dev Notes above). Guard non-integer
  BPM indexing in `resolveOctaveAmbiguity`.
- [ ] **T3 — Regression sweep** Run full test suite; confirm all prior tests still pass.
- [ ] **T4 — Confidence check** Assert `confidence >= 0.5` for 96 kHz / 126 BPM case.
- [ ] **T5 — (Optional) Fix B fallback** If Fix A causes regressions, implement the
  ACF sharpness tie-break as a 96 kHz-only code path and re-run.
- [ ] **T6 — Update deferred-work.md** Remove the Story 3-7 entry once AC are all green.

---

## References

- Parent story: `_bmad-output/implementation-artifacts/3-2-fine-grid-precision-fix.md`
  (file not yet present in repo as of 2026-05-10; _bmad-output/ was absent)
- Call site: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:184`
- `refineCandidates` implementation: `BPMAnalyzer.swift:640–712`
- `extractTopCandidates`: `BPMAnalyzer.swift:796–848`
- `resolveOctaveAmbiguity`: `BPMAnalyzer.swift:915–972`
- `rangeNormalize`: `BPMAnalyzer.swift:851–856` (folds all octaves into 60–200 BPM)
- FFT constants: `BPMAnalyzer.swift:39–43` (`fftSize = 2048`, `log2n = 11`)
- Mel filterbank cap: `BPMAnalyzer.swift:213` (`melFmax = 16000.0`)
