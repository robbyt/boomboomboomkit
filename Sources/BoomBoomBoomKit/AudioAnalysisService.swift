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
}

/// Stateless service that coordinates PCM reading and BPM estimation.
///
/// Story 32-3: Composes `PCMBufferReader` and `BPMAnalyzer` into a single call.
/// Story 32-8: Added `analyzeLUFS()` below.
public struct AudioAnalysisService {

  // MARK: - Progressive Analysis Constants (Epic 34, S2)

  /// Confidence threshold below which progressive analysis retries with longer windows.
  /// Empirically validated against 21-track corpus: catches all low-confidence wrong results
  /// with zero false positives at this threshold.
  private static let progressiveConfidenceThreshold: Double = 0.40

  /// Progressive window sizes in seconds. PCMBufferReader reads 120s by default,
  /// which is enough for energy scan + 90s analysis window.
  private static let progressiveWindowSizes: [Double] = [30, 60, 90]

  /// BPM convergence tolerance: if consecutive windows agree within this range, accept.
  private static let convergenceTolerance: Double = 2.0

  /// Analyzes the BPM of an audio file using progressive analysis.
  ///
  /// Starts with a 30s analysis window. If confidence is below threshold,
  /// retries with 60s and 90s windows. Accepts early if consecutive windows
  /// converge (agree within ±2 BPM).
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - maxSeconds: Maximum seconds of audio to read for energy scan (default: 120).
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeBPM(
    url: URL,
    maxSeconds: Double = 120,
    strategy: BPMDisambiguationStrategy = .subBandVoting
  ) throws -> AudioAnalysisResult? {
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: maxSeconds
    )

    var previousBPM: Double?
    var bestResult: BPMResult?

    for windowSeconds in progressiveWindowSizes {
      guard
        let bpmResult = BPMAnalyzer.estimateBPM(
          samples: samples, sampleRate: sampleRate,
          analysisWindowSeconds: windowSeconds,
          strategy: strategy
        )
      else {
        continue
      }

      // Keep the highest-confidence result across all windows.
      // Longer windows may find a different BPM with higher confidence —
      // e.g., resolving a 2:3 ratio lock to a clean half-time relationship.
      if bestResult == nil || bpmResult.confidence > bestResult!.confidence {
        bestResult = bpmResult
      }

      // Accept if confidence is high enough
      if bpmResult.confidence >= progressiveConfidenceThreshold {
        break
      }

      // Accept if consecutive windows converge (±2 BPM)
      if let prev = previousBPM,
        abs(bpmResult.bpm - prev) <= convergenceTolerance {
        break
      }

      previousBPM = bpmResult.bpm
    }

    guard let result = bestResult else { return nil }
    return AudioAnalysisResult(
      bpm: result.bpm, confidence: result.confidence, candidates: result.candidates)
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
