# BPM Detection Pipeline

Genre-agnostic BPM estimation using pure vDSP/Accelerate. No external dependencies.

**Implementation:** `MediaDiffCore/Sources/MediaDiffCore/Audio/BPMAnalyzer.swift`
**Mel filterbank:** `MediaDiffCore/Sources/MediaDiffCore/Audio/MelFilterbank.swift`
**Benchmark:** `MediaDiffCore/Tests/MediaDiffCoreTests/AudioTests/BPMBenchmarkTests.swift`

---

## Pipeline Overview

```
AudioAnalysisService.analyzeBPM(url:strategy:)
  → PCMBufferReader.readMonoSamples() (120s)
  → BPMAnalyzer.estimateBPM(samples:sampleRate:analysisWindowSeconds:strategy:)
  → Progressive retry at 60s/90s if confidence < 0.40 (keeps best)
  → AudioAnalysisResult?
```

All BPM steps are stateless static functions on `BPMAnalyzer`. Input is `[Float]` mono samples at native sample rate. Output is `BPMResult(bpm: Double, confidence: Double, candidates: [...])` or `nil` for silence/noise/too-short.

`AudioAnalysisService` wraps `BPMAnalyzer` with progressive analysis (Epic 34, S2): if confidence is below 0.40 on the initial 30s window, retries with 60s and 90s windows. Keeps the highest-confidence result across all windows. Accepts early if consecutive windows converge (±2 BPM).

### Disambiguation Strategy

`BPMDisambiguationStrategy` enum controls octave disambiguation at Step 10:
- `.subBandVoting` (default): Sub-band voting + fused periodicity heuristic (Steps 10+10b)
- `.beatPhase`: Reserved for future experiments (see Appendix)

The CLI exposes `--bpm-strategy` flag. Both strategies currently use the same code path.

---

## Pipeline Steps (as implemented)

### Step 1: Energy Scan
`findEnergyTransition(samples:sampleRate:)` — Scans 1-second RMS windows (up to 120s) to find the first significant energy transition ("drop"). Selects a 30-second analysis window starting at the drop. This avoids intros, fade-ins, and silence that confuse periodicity detection.

### Step 2: Silence Check
RMS threshold check (`0.001`) on the analysis window. Returns `nil` if silent.

### Step 3: Mel-Spectrogram Onset Detection with Sub-Bands
`computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:)` — Full pipeline:

1. **STFT**: 2048-sample Hann window, adaptive 10ms hop (native sample rate, no resampling)
2. **Mel filterbank**: 128 bands (30–16000 Hz) via `MelFilterbank.buildFilterbank()`, applied per frame with `vDSP_mmul`
3. **Log compression**: `log(1 + 100 * S)` via `vvlogf` — equalizes loud/quiet frequency regions
4. **Temporal differencing**: `vDSP_vsub` between consecutive frames
5. **Half-wave rectification**: `vDSP_vthres` keeps only positive differences (energy increases = onsets)
6. **Aggregation**: `vDSP_sve` sums across all 128 mel bands → 1D onset envelope

Simultaneously produces 4 sub-band onset envelopes by summing within mel bin ranges:
- **Kick** (bins 0–20, ~30–200 Hz)
- **Snare body** (bins 20–50, ~200–1000 Hz)
- **Snare crack** (bins 50–80, ~1000–4000 Hz)
- **Hi-hat** (bins 80–128, ~4000–16000 Hz)

### Step 4: FFT-Based Autocorrelation
`computeAutocorrelation(_:)` — Zero-padded FFT → `vDSP_zvmags` (power spectrum) → inverse FFT. O(N log N) vs O(N^2) for `vDSP_conv`. Applied to full-band onset envelope.

### Step 4b: Sub-Band Autocorrelations
Same autocorrelation applied independently to each of the 4 sub-band onset envelopes. Used downstream for voting.

### Step 5: Fourier Tempogram
`computeFourierTempogram(onsetEnvelope:onsetRate:bpmMin:bpmMax:)` — Non-uniform DFT evaluated at each integer BPM (40–250). 8-second Hann window over onset envelope. Produces magnitude array indexed by BPM.

### Step 6: Periodicity Fusion
`fusePeriodicity(autocorrelation:fourierTempogram:bpmMin:bpmMax:onsetRate:)` — Maps autocorrelation from lag-domain to BPM-domain with parabolic (3-point quadratic) interpolation, normalizes both ACF and tempogram to [0, 1], then element-wise multiplies. Peaks strong in both representations survive; noise is suppressed. Parabolic interpolation (Epic 34, C1) eliminates the "picket fence effect" where linear interpolation systematically underestimates ACF peaks at 0.5 fractional lag positions.

### Step 7: TPS2 Harmonic Enhancement
`applyTPS2Enhancement(periodicity:bpmMin:bpmMax:)` — Ellis's technique: `TPS2(i) = P(i) + 0.5*P(i_half) + 0.25*P(i_half-1) + 0.25*P(i_half+1)`. Rewards candidates whose subharmonics are also present. A true 160 BPM gets a bonus from its subharmonic at 80 BPM.

### Steps 8–9: Multi-Peak Extraction + Range Normalization
`extractTopCandidates(enhanced:bpmMin:count:)` — Finds top 3 local maxima from enhanced periodicity. Each candidate is range-normalized to 60–200 BPM by doubling/halving (`rangeNormalize`).

### Step 9b: Fine-Grid Tempogram Refinement
`refineCandidates(candidates:onsetEnvelope:autocorrelation:onsetRate:bpmMin:bpmMax:)` — After disambiguation selects the winner at integer BPM resolution, refines it to 0.1 BPM using a ±4 BPM fine scan. Re-evaluates the tempogram DFT at each 0.1 BPM step, fuses with parabolic ACF interpolation, and selects the highest fused value. ~80 additional DFT evaluations per candidate. Applied after disambiguation (not before) to preserve the integer BPMs that octave/sub-band logic depends on.

### Step 10: Octave Disambiguation
`resolveOctaveAmbiguity(candidates:fused:bpmMin:subBandACFs:onsetRate:)` — For each octave pair (2:1 ratio within 4%):
1. **Sub-band vote**: Each of 4 sub-band ACFs votes for the candidate with stronger peak at its lag. Weighted: kick=0.5, snare body=1.0, snare crack=1.5, hi-hat=2.0. If bands favor the faster tempo, promote it.
2. **Fused-periodicity fallback**: If sub-bands vote slow, check whether the faster candidate has ≥30% of the slower candidate's fused energy and ≥50% of its score.

### Step 10b: Sub-Band Periodicity Confirmation
`confirmWithSubBandPeaks(winner:subBandACFs:onsetRate:)` — Post-processing for winners in 80–130 BPM range (suspect half/two-thirds time). Scans hi-hat sub-band ACF for peaks in 140–200 BPM range. If hi-hat clearly prefers a faster tempo and either (a) weighted vote agrees or (b) both treble bands (snare crack + hi-hat) independently prefer the faster candidate, promotes to the faster BPM. This handles the DnB failure mode where kick is half-time but hi-hats carry the true breakbeat tempo.

### Step 11: Confidence Scoring
`computeConfidence(fused:winnerBPM:bpmMin:)` — Combines two metrics:
- **PAR** (Peak-to-Average Ratio): `max(fused) / mean(fused)`, normalized to [0, 1]
- **Periodicity clarity**: ratio of winner peak to strongest non-octave-related peak, normalized to [0, 1]
- Combined through exponential saturation: `1 - exp(-combined * 5)`

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| No resampling to 22050 Hz | Adaptive 10ms hop achieves consistent onset rate at any native sample rate |
| Flat prior (no Rayleigh) | Rayleigh centered at 120 BPM penalizes DnB (160–180) and hip-hop (70–100) |
| Fusion (ACF x tempogram) | ACF shows subharmonics, tempogram shows harmonics — multiplying suppresses noise, retains true periodicity |
| Sub-band voting weights | Hi-hat up-weighted (2.0) because hi-hat patterns are more reliable tempo indicators than kick patterns in syncopated music |
| Treble override in Step 10b | DnB/jungle has half-time kick (80 BPM) with full-speed hi-hats (160 BPM) — treble bands break the tie |
| Range normalization to 60–200 | Reflects perceptual range of "normal" tempos without genre bias |

---

## Accuracy

### Prodigy Benchmark (21 tracks, 160 BPM DnB)

| Epic | Strategy | Acc1 | Acc2 |
|------|----------|------|------|
| Epic 33 | subBandVoting | 81.0% (17/21) | 81.0% (17/21) |
| Epic 34 | subBandVoting | 85.7% (18/21) | 90.5% (19/21) |

### OA300 Benchmark (78 tracks, mixed genres/tempos)

Rekordbox v6 ground truth. Measured with `subBandVoting` strategy.

| Epic | Strategy | Acc1 | Acc2 |
|------|----------|------|------|
| Epic 34 | subBandVoting | 61.5% (48/78) | 80.8% (63/78) |

### OA300 "Bad BPM" Subset (10 tracks)

Files in `OA300_OnsetAudio300/Bad BPM/` — tracks where our detection disagrees with Rekordbox. Tested post-Epic 34 at `4ffc05a` (2026-03-08).

| Track | Rekordbox BPM | Our BPM | Diff % | Notes |
|-------|--------------|---------|--------|-------|
| TVR | 130.00 | 129.0 | -0.77% | From embedded tag |
| Self Immolation | 126.00 | 126.1 | +0.08% | Close match |
| Echtoo - Chakra (Seminal Sounds) | 160.00 | 79.9 | -50.06% | Octave error (half-time) |
| Echtoo - Chakra | 160.00 | 80.0 | -50.00% | Octave error (half-time) |
| Echtoo - The Mummy (Seminal Sounds) | 160.00 | 159.5 | -0.31% | Close match |
| Fixate - Conundrum | 130.00 | 168.0 | +29.23% | Wrong candidate selected (130.0 was top candidate) |
| Icicle - Condense | 126.00 | 126.1 | +0.08% | Close match |
| Nautical Divine - Makara | 128.00 | 127.9 | -0.08% | Close match |
| Proxima - Trapped | 140.00 | 140.0 | 0.00% | From embedded tag |
| Skylined (Neekeetone 160 Rework) | 160.00 | 196.0 | +22.50% | Wrong; confidence 0.26, 160 absent from candidates |

**Failure analysis:**
- **4 close matches** (Self Immolation, The Mummy, Icicle, Makara): Within ±0.5% — effectively correct
- **2 tag-sourced** (TVR, Trapped): BPM from embedded metadata, not detection
- **2 octave errors** (Chakra x2): Half-time detection (80 vs 160) — classic DnB octave ambiguity
- **1 candidate selection error** (Conundrum): Correct BPM (130.0) was the top candidate by score (1.015) but final selection picked 168.0
- **1 upstream miss** (Skylined): 160 BPM absent from all candidates; very low confidence (0.26)

### Known Limitations

Remaining failure modes:
- **Near-miss precision errors**: ~3 tracks off by >4% but close (rounding/drift)
- **Upstream candidate generation**: ~11 tracks where the correct BPM is absent from top 3 candidates — beat-phase cannot help, requires improved candidate generation
- **Genuinely ambiguous tracks**: Some DnB/breakbeat with no clear dominant tempo

---

## vDSP Function Reference

| Stage | Functions |
|-------|-----------|
| Windowing | `vDSP_hann_window`, `vDSP_vmul` |
| FFT | `vDSP.FFT`, `vDSP_ctoz`, `vDSP_ztoc`, `fft.forward`, `fft.inverse` |
| Power spectrum | `vDSP_zvmags` |
| Mel filterbank | `vDSP_mmul` (matrix multiply) |
| Log compression | `vDSP_vsmul`, `vDSP_vsadd`, `vvlogf` |
| Differencing | `vDSP_vsub` |
| Half-wave rectification | `vDSP_vthres` |
| Aggregation | `vDSP_sve`, `vDSP_meanv` |
| Trigonometry | `vvcosf`, `vvsinf` (Fourier tempogram) |
| Dot product | `vDSP_dotpr` (Fourier tempogram) |
| Normalization | `vDSP_maxv`, `vDSP_vsdiv` |
| RMS | `vDSP_rmsqv` (energy scan, silence check) |

---

## Appendix: Techniques Considered But Not Implemented

These were described in the original research document and may be useful for future work:

**Comb filter bank (Approach B):** IIR comb filter per BPM candidate (`y[t] = onset[t] + 0.8 * y[t-P]`). Naturally reinforces persistent periodicities. Not needed after fusion approach proved sufficient.

**Log-Gaussian regularizer:** Very wide log-Gaussian (`sigma = 2.0 octaves`) as gentle tiebreaker. Omitted in favor of pure flat prior — TPS2 + sub-band voting handle disambiguation without any prior.

**Return both candidates:** Displaying "80/160 BPM" when ambiguous. Single BPM with confidence score chosen instead — simpler UX, confidence communicates uncertainty.

**SuperFlux max filter:** Frequency-axis max filter to reduce false positives from vibrato. Not needed — mel-spectrogram aggregation already smooths pitched content.

**Dynamic programming beat tracking (Ellis):** Produces beat positions, not just tempo. Not needed — MediaDiff only requires BPM, not beat markers.

**Beat-phase cross-correlation (Percival & Tzanetakis 2014):** FFT-based cross-correlation of onset envelope with impulse trains at candidate BPMs. Theoretically breaks octave symmetry — a 160 BPM impulse train aligns with more onsets than an 80 BPM train if the true tempo is 160. Implemented as post-Step 10 augmentation with confidence-adaptive thresholds. Tested extensively on OA300 corpus (78 tracks):

| Configuration | Improved | Regressed | Net |
|---------------|----------|-----------|-----|
| Full replacement (Steps 10+10b) | 5 | 12 | -7 |
| Augment, 1.3x threshold | ~5 | 5 | ~0 |
| Augment, confidence-adaptive (1.15x–2.0x) | 3 | 4 | -1 |
| Augment, promote-only + octave-only guards | 0 | 1 | -1 |

**Root cause of failure:** Cross-correlation inherently biases toward slower tempos in syncopated DnB/breakbeat music. Loud downbeats produce strong correlation at half-time, causing the algorithm to make the same class of octave demotion on both wrong and correct results. No threshold can isolate wins from losses because the signal is not discriminative — it correlates with the "wrong" octave for the same acoustic reason it correlates with the "right" one. The `BPMDisambiguationStrategy.beatPhase` enum case is retained for future experiments with different approaches (e.g., weighted vote integration before Steps 10+10b rather than post-hoc augmentation).

---

## References

- Ellis, D.P.W. (2007). "Beat Tracking by Dynamic Programming." JNMR 36(1).
- Grosche & Muller (2011). "Extracting Predominant Local Pulse Information from Music Recordings." IEEE TASLP 19(6).
- Percival & Tzanetakis (2014). "Streamlined Tempo Estimation Based on Autocorrelation and Cross-correlation With Pulses." IEEE/ACM TASLP 22(12). [Primary basis for beat-phase scoring]
- librosa (ISC/BSD): `librosa/onset.py`, `librosa/beat.py` — canonical Python reference
- Essentia: `percivalbpmestimator.cpp` — reference C++ implementation of Percival & Tzanetakis
- Apple: "Generating a mel spectrogram" sample code (confirms `vDSP_mmul` approach)

**Note:** Apple SoundAnalysis provides no tempo/beat/rhythm APIs. Custom vDSP pipeline is the correct approach.
