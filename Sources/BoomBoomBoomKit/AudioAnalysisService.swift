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

  /// Configuration options for BPM analysis.
  ///
  /// All fields have sensible defaults. Most callers can use `.init()`.
  public struct Options: Sendable {
    /// Maximum seconds of audio to read from the file (default: 120).
    /// This caps the PCM buffer size, not the analysis window. The pipeline
    /// performs energy scan on this buffer to find the musical onset, then
    /// takes analysis windows (30s/60s/90s) from that point. The default of
    /// 120s covers ~30s of intro headroom plus the longest 90s analysis window.
    public var maxSeconds: Double = 120

    /// Analysis intensity level (default: `.default`, which is level 7).
    /// Controls pipeline depth: which DSP stages run, how many candidates
    /// are considered, and whether progressive retry across multiple windows is used.
    public var intensity: AnalysisIntensity = .default

    /// Strategy for combining candidates across analysis windows (default: `.maxConfidence`).
    /// Only applies at intensity 6+ where multiple windows are analyzed.
    public var mergeStrategy: CandidateMergeStrategy = .maxConfidence

    /// When `true`, populates `result.trace` with per-step diagnostic data.
    public var enableTrace: Bool = false

    public init(
      maxSeconds: Double = 120,
      intensity: AnalysisIntensity = .default,
      mergeStrategy: CandidateMergeStrategy = .maxConfidence,
      enableTrace: Bool = false
    ) {
      self.maxSeconds = maxSeconds
      self.intensity = intensity
      self.mergeStrategy = mergeStrategy
      self.enableTrace = enableTrace
    }
  }

  /// Analyzes the BPM of an audio file with default options.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeBPM(
    url: URL
  ) throws -> AudioAnalysisResult? {
    try analyzeBPM(url: url, options: .init())
  }

  /// Analyzes the BPM of an audio file using intensity-controlled progressive analysis.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  ///   - options: Configuration controlling read length, intensity, merge strategy, and tracing.
  /// - Returns: An `AudioAnalysisResult` with BPM and confidence, or `nil`
  ///   for silence, too-short input, or non-musical content.
  /// - Throws: `PCMBufferReaderError` if the file cannot be read.
  public static func analyzeBPM(
    url: URL,
    options: Options
  ) throws -> AudioAnalysisResult? {
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: options.maxSeconds
    )

    // Collect results from all windows.
    var windowResults: [BPMResult] = []

    for windowSeconds in options.intensity.windowSizes {
      guard
        let bpmResult = BPMAnalyzer.estimateBPM(
          samples: samples, sampleRate: sampleRate,
          options: .init(
            analysisWindowSeconds: windowSeconds,
            intensity: options.intensity,
            enableTrace: options.enableTrace)
        )
      else {
        continue
      }

      windowResults.append(bpmResult)

      // Non-progressive intensities (1-5): single window, break immediately.
      if options.intensity.progressiveThreshold == nil {
        break
      }
    }

    // Merge candidates across windows using the selected strategy.
    let candidateCount = options.intensity.techniqueSet.candidateCount
    guard
      let result = CandidateMergeStrategy.merge(
        windowResults: windowResults,
        candidateCount: candidateCount,
        strategy: options.mergeStrategy)
    else { return nil }

    return AudioAnalysisResult(
      bpm: result.bpm, confidence: result.confidence,
      candidates: result.candidates, trace: result.trace)
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
