//
//  AudioAnalysisService.swift
//  BoomBoomBoomKit
//
//  Stateless service coordinating PCM read + BPM analysis.
//  Zero coupling to MediaDiffCore types.
//  Allowed imports: Foundation only (uses PCMBufferReader and BPMAnalyzer from same module).
//

import Foundation

/// Result of audio analysis containing BPM and confidence.
public struct AudioAnalysisResult: Sendable {
  /// Estimated tempo in beats per minute.
  public let bpm: Double
  /// Confidence score (0.0 - 1.0) indicating reliability of the estimate.
  public let confidence: Double
  /// Top candidates pre-disambiguation (for benchmark analysis).
  public let candidates: [(bpm: Double, score: Float)]
  /// Diagnostic trace capturing per-step pipeline state. Nil unless `enableTrace` was true.
  public let trace: BPMDiagnosticTrace?
}

/// Stateless service that coordinates PCM reading and BPM estimation.
public struct AudioAnalysisService {

  /// BPM convergence tolerance: if consecutive windows agree within this range, accept.
  private static let convergenceTolerance: Double = 2.0

  /// Analyzes the BPM of an audio file using intensity-controlled progressive analysis.
  ///
  /// The intensity level controls pipeline depth: which DSP stages run,
  /// how many candidates are considered, and whether progressive retry is used.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - maxSeconds: Maximum seconds of audio to read for energy scan (default: 120).
  ///   - intensity: Analysis intensity level (default: `.default`, which is level 7).
  ///   - enableTrace: When true, populates `result.trace` with per-step diagnostic data.
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeBPM(
    url: URL,
    maxSeconds: Double = 120,
    intensity: AnalysisIntensity = .default,
    enableTrace: Bool = false
  ) throws -> AudioAnalysisResult? {
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: maxSeconds
    )

    var previousBPM: Double?
    var bestResult: BPMResult?

    for windowSeconds in intensity.windowSizes {
      guard
        let bpmResult = BPMAnalyzer.estimateBPM(
          samples: samples, sampleRate: sampleRate,
          analysisWindowSeconds: windowSeconds,
          intensity: intensity,
          enableTrace: enableTrace
        )
      else {
        continue
      }

      // Keep the highest-confidence result across all windows.
      if bestResult == nil || bpmResult.confidence > bestResult!.confidence {
        bestResult = bpmResult
      }

      // Accept if confidence exceeds progressive threshold
      if let threshold = intensity.progressiveThreshold,
        bpmResult.confidence >= threshold
      {
        break
      }

      // Accept if consecutive windows converge (±2 BPM)
      if intensity.progressiveThreshold != nil,
        let prev = previousBPM,
        abs(bpmResult.bpm - prev) <= convergenceTolerance
      {
        break
      }

      previousBPM = bpmResult.bpm

      // Non-progressive intensities: single window, break immediately
      if intensity.progressiveThreshold == nil {
        break
      }
    }

    guard let result = bestResult else { return nil }
    return AudioAnalysisResult(
      bpm: result.bpm, confidence: result.confidence,
      candidates: result.candidates, trace: result.trace)
  }

  /// Analyzes the BPM of an audio file using the specified disambiguation strategy.
  ///
  /// - Note: Deprecated. Use `analyzeBPM(url:maxSeconds:intensity:enableTrace:)` instead.
  @available(*, deprecated, renamed: "analyzeBPM(url:maxSeconds:intensity:enableTrace:)")
  public static func analyzeBPM(
    url: URL,
    maxSeconds: Double = 120,
    strategy: BPMDisambiguationStrategy = .subBandVoting
  ) throws -> AudioAnalysisResult? {
    try analyzeBPM(url: url, maxSeconds: maxSeconds, intensity: .default, enableTrace: false)
  }

  /// Measures integrated loudness per ITU-R BS.1770-5.
  /// Returns the integrated loudness in LUFS, or nil for silence/too-short/unsupported sample rate.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - maxSeconds: Maximum seconds of audio to analyze (default: 30).
  /// - Returns: Integrated loudness in LUFS, or `nil` for silence, too-short, or unsupported input.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeLUFS(
    url: URL,
    maxSeconds: Double = 30
  ) throws -> Double? {
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: maxSeconds
    )
    return LUFSAnalyzer.measureLoudness(
      samples: samples, sampleRate: sampleRate
    )?.integratedLoudness
  }
}
