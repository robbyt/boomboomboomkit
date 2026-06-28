# Adversarial Review: BoomBoomBoomKit BPM Detection Library

After analyzing this codebase, I have significant concerns. The library exhibits a pattern I'll call **"infrastructure-first, accuracy-second"** — elaborate type systems and validation wrapping algorithms I can't even see.

---

## CRITICAL ISSUES (Accuracy-Killing)

### 1. Core Detection Algorithm Is Hidden/Missing
**The `BPMAnalyzer.swift` file — which presumably contains the actual onset detection, autocorrelation, or comb filter logic — is NOT in this review.** What I see instead is ~800 lines of type-safe wrappers around a black box.

**Why this matters:** You've built an elaborate "FeatureSubstrate" with versioned feature contracts, but I cannot evaluate whether the underlying DSP is even competent. The entire accuracy question is unanswerable.

**Action:** Provide `BPMAnalyzer.swift` for review. If the algorithm is simple spectral flux + autocorrelation without octave correction, that explains any accuracy problems.

---

### 2. Octave Error Correction Appears Stubbed/Nonexistent
The file list shows `OctaveEquivalencePolicy.swift` exists, but I see zero evidence of actual octave error handling in the visible code. The metadata corroborator checks for "octave 1.92-2.08" ratios, but that's matching against *file tags*, not correcting *detected* BPM.

**Why this matters:** Octave errors (detecting 140 BPM instead of 70 BPM, or vice versa) are the #1 failure mode in BPM detection. Without robust octave correction, your accuracy ceiling is ~70% on real-world music.

**Action:** Implement proper octave error correction:
```swift
// Pseudocode for what's missing
func resolveOctaveAmbiguity(candidates: [BPMCandidate]) -> BPMCandidate {
    // For each candidate, check if half or double tempo also has strong evidence
    // Prefer the tempo that:
    // 1. Has consistent inter-onset intervals
    // 2. Matches typical genre ranges (60-180 BPM for most music)
    // 3. Has better sub-band consistency (kick on 1, snare on 3)
}
```

---

### 3. `subBandEmphasis` Weighting Is Stubbed Out
```swift
case .subBandEmphasis:
    throw FeatureSubstrateError.weightingNotYetImplemented(weighting)
```

You have `SubBandWeights` with `kickBandWeight`, `snareBandWeight`, `cymbalBandWeight` — exactly the right structure for frequency-aware BPM detection — **and it throws at runtime.**

**Why this matters:** Kick drums (60-150 Hz) and snares (150-500 Hz) have different temporal patterns. A kick-heavy EDM track needs different weighting than a cymbal-heavy jazz track. Without this, you're treating all frequency content equally, which destroys accuracy on genre-varied datasets.

**Action:** Implement sub-band emphasis:
- Separate onset functions per frequency band
- Weight band contributions based on energy distribution
- Use band-specific tempo hypotheses that vote in the signal pool

---

### 4. No Multi-Resolution Onset Detection Visible
The fixed parameters suggest single-resolution analysis:
- `fftSize: 2048` (~46ms at 44.1kHz)
- `hopSize: Int(sampleRate / 100)` (~10ms)

**Why this matters:** 
- Slow tempos (60-80 BPM) need longer windows to capture beat periodicity
- Fast tempos (140-180 BPM) need shorter windows for precise onset timing
- Single-resolution analysis creates a fundamental accuracy/tempo-range tradeoff

**Action:** Implement multi-resolution analysis:
```swift
func multiResolutionOnsets(samples: [Float], sampleRate: Double) -> [OnsetFunction] {
    let resolutions = [
        (fftSize: 1024, hopSize: 256),  // Fast transients
        (fftSize: 2048, hopSize: 512),  // Standard
        (fftSize: 4096, hopSize: 1024), // Slow beats, bass
    ]
    // Combine with evidence fusion
}
```

---

### 5. Metadata Corroboration Is Not Accuracy Improvement
```swift
// From MetadataCorroborator.swift
// "Boosts every candidate whose BPM matches any participating tag"
```

**This is not improving detection accuracy — it's cheating by trusting file tags that are often wrong.** Spotify/Beatport BPM tags have ~15-30% error rates. You're boosting confidence on potentially incorrect values.

**Action:** Either:
1. Remove metadata corroboration from accuracy claims, OR
2. Use metadata only as a *prior* that gets overridden by strong DSP evidence, not a boost

---

## MEDIUM ISSUES (Accuracy-Limiting)

### 6. No Tempo Stability Analysis
Real music has tempo fluctuations. I see no evidence of:
- Tempo drift detection
- Section-based analysis (verse vs. chorus may have different feels)
- Confidence penalty for unstable tempos

**Action:** Add tempo consistency scoring:
```swift
struct TempoStability {
    let globalBPM: Double
    let localBPMs: [Double]  // Per-segment
    let stabilityScore: Double  // 0-1, low = high variance
    let dominantBPM: Double
}
```

---

### 7. Beat Grid Anchor Logic Unknown
`BeatGridAnalyzer.swift`, `BeatGridAnchor.swift` exist but aren't shown. Without seeing how beats are placed relative to onsets, I can't evaluate whether:
- Beats are phase-locked to actual transients
- There's correction for galloping/swing feels
- The grid degrades gracefully on syncopated material

**Action:** Show this code. Verify beats align to onsets within ±20ms tolerance.

---

### 8. No Visible Autocorrelation Implementation
Standard BPM detection uses autocorrelation or comb filters to find periodicity. I see references to "onset envelope" but not the periodicity detection that converts onsets → BPM.

**Action:** Verify you're using proper autocorrelation:
```swift
// Essential: normalized autocorrelation to avoid loudness bias
func autoCorrelate(onsetEnvelope: [Float], lagRange: Range<Int>) -> [Float] {
    // Must normalize by energy at each lag
    // Must handle edge effects
    // Should use parabolic interpolation for sub-bin accuracy
}
```

---

### 9. Signal Pool Voting Weights Unknown
`SignalWeights.swift`, `UnifiedSignalPool.swift` exist but I can't see:
- How different techniques are weighted
- Whether weights are adaptive or fixed
- If there's any calibration data behind the weights

**Action:** Make voting weights configurable and document their derivation.

---

## LOW ISSUES (Code Quality, Not Accuracy)

### 10. Absurd Validation Overkill
```swift
let (expectedCount, overflow) = melBands.multipliedReportingOverflow(by: frames)
guard !overflow else { ... }
```

**128 × 12000 = 1,536,000.** `Int.max` is 9,223,372,036,854,775,807. This check will never fire in any realistic scenario. It's defensive programming theater.

**Action:** Remove overflow checks for bounded values. Keep the `allSatisfy(\.isFinite)` check — that one's actually useful.

---

### 11. `featureSetVersion` String Checking Is Fragile
```swift
public static let currentFeatureSetVersion = "v2"
// Consumer checks: if version != "v2" { abstain }
```

Version strings are a band-aid for lack of integration tests that would catch pipeline drift at build time.

**Action:** Replace with compile-time checks where possible. Keep version for BYOW consumers only.

---

### 12. `@TaskLocal` Test Override Has Propagation Caveats
The 15-line comment explaining unstructured `Task {}` propagation failure is a red flag that the test infrastructure is fighting Swift concurrency.

**Action:** Restructure tests to use structured concurrency consistently.

---

## Summary: Accuracy Improvement Priority

| Priority | Action | Expected Accuracy Gain |
|----------|--------|----------------------|
| 1 | Show/implement core BPM detection algorithm | Unknown (can't evaluate) |
| 2 | Implement octave error correction | +15-25% |
| 3 | Implement sub-band emphasis | +5-10% |
| 4 | Add multi-resolution onset detection | +5-8% |
| 5 | Remove/fix metadata corroboration | +0% (removes false confidence) |
| 6 | Add tempo stability analysis | +3-5% on variable-tempo tracks |

**Bottom line:** This library has invested heavily in type safety infrastructure but the actual DSP accuracy — which is the only thing that matters for a BPM detector — is opaque and likely deficient in the standard failure modes (octave errors, genre variation, tempo instability).
