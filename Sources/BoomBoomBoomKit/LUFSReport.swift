//
//  LUFSReport.swift
//  BoomBoomBoomKit
//
//  Chart-ready loudness report (ITU-R BS.1770-5 / EBU R 128) returned by
//  AudioAnalysisService.analyzeLUFS(url:options:).
//

import Foundation

// MARK: - LUFSReport

/// Loudness measurement report per ITU-R BS.1770-5 and EBU R 128.
///
/// Carries the headline scalars (integrated loudness, max true-peak, loudness
/// range) AND chart-ready momentary/short-term loudness time series on the
/// shared 100ms grid (EBU Tech 3341 §2.2), so a single
/// ``AudioAnalysisService/analyzeLUFS(url:options:)`` call supports both
/// normalization and LUFS-over-time visualization.
///
/// Value carrier only — deliberately NOT `Hashable` (same rationale as
/// `EnsembleDecision`: never a `Set`/`Dictionary` key, and the
/// multi-thousand-element series fields make hashing pointless).
///
/// Non-finite inputs (NaN/±Inf) are clamped to the documented `-100.0`
/// sentinel floor in every stored field at construction.
public struct LUFSReport: Sendable, Equatable, CustomStringConvertible {

  /// Sentinel floor for non-finite or below-measurable values (matches the
  /// analyzer's block-loudness display floor).
  public static let sentinelFloor: Double = -100.0

  // MARK: Stored — scalars

  /// Integrated (programme) loudness in LUFS per ITU-R BS.1770-5 Annex 1
  /// gating (400ms blocks, absolute gate −70 LUFS, relative gate −10 LU).
  ///
  /// Computed over the mono mixdown — see ``maxTruePeakDBTP`` for the shared
  /// mono-pipeline caveat.
  public let integratedLUFS: Double

  /// Maximum true-peak level in dBTP per ITU-R BS.1770-5 Annex 2
  /// (polyphase 4× oversampling at 44.1/48 kHz, 2× at 96 kHz; 4× at 44.1 kHz
  /// yields 176.4 kHz — under the literal "≥192 kHz" wording, a standard,
  /// documented deviation).
  ///
  /// - Warning: Computed post-mono-mixdown; may understate per-channel
  ///   inter-sample peaks. NOT suitable for delivery-compliance certification
  ///   against a per-channel ceiling (e.g., EBU R 128's −1 dBTP). Per-channel
  ///   measurement is deferred to the Story 8.2 `DecodedAudio` seam.
  public let maxTruePeakDBTP: Double

  /// Loudness range (LRA) in LU per EBU Tech 3342 §3.1: P95 − P10 of the
  /// gated short-term distribution (absolute gate −70 LUFS, relative gate
  /// −20 LU below the absolute-gated mean).
  ///
  /// `nil` when the gated programme is shorter than 60s (EBU R 128 notes LRA
  /// is unreliable below ~1 min) or the gated set is empty — never a wrong
  /// number.
  public let loudnessRangeLU: Double?

  /// P10 of the gated short-term distribution in LUFS — the lower edge of
  /// the LRA band for charting. Sentinel `-100.0` when ``loudnessRangeLU``
  /// is `nil`.
  public let lraLowLUFS: Double

  /// P95 of the gated short-term distribution in LUFS — the upper edge of
  /// the LRA band for charting. Sentinel `-100.0` when ``loudnessRangeLU``
  /// is `nil`.
  public let lraHighLUFS: Double

  // MARK: Stored — series (shared 100ms grid, EBU Tech 3341 §2.2)

  /// Momentary loudness series in LUFS: 400ms window stepped every 100ms.
  /// Element `i` covers the window starting at `Double(i) * stepSeconds`.
  /// Silent blocks are floored at `-100.0`.
  public let momentaryLUFS: [Double]

  /// Short-term loudness series in LUFS: exact 3.0s rectangular window
  /// stepped every 100ms on the same grid. Element `i` covers the window
  /// starting at `Double(i) * stepSeconds`. Empty for input shorter than 3s.
  /// Silent windows are floored at `-100.0`.
  public let shortTermLUFS: [Double]

  /// Time step between consecutive series elements in seconds (0.1 — the
  /// ≥10 Hz update rate EBU Tech 3341 §2.2 requires). Non-finite or
  /// non-positive values are replaced with 0.1 at construction.
  public let stepSeconds: Double

  // MARK: Init

  /// Creates a report, clamping NaN/±Inf in every stored loudness field to
  /// the `-100.0` sentinel floor (`nil` ``loudnessRangeLU`` is preserved as
  /// nil). ``stepSeconds`` is a time grid, not a loudness — non-finite or
  /// non-positive values fall back to the documented 0.1s grid instead
  /// (a zero step would collide every ``LoudnessSample/id``).
  public init(
    integratedLUFS: Double,
    maxTruePeakDBTP: Double,
    loudnessRangeLU: Double?,
    lraLowLUFS: Double,
    lraHighLUFS: Double,
    momentaryLUFS: [Double],
    shortTermLUFS: [Double],
    stepSeconds: Double
  ) {
    func clamp(_ value: Double) -> Double {
      value.isFinite ? value : Self.sentinelFloor
    }
    self.integratedLUFS = clamp(integratedLUFS)
    self.maxTruePeakDBTP = clamp(maxTruePeakDBTP)
    self.loudnessRangeLU = loudnessRangeLU.map(clamp)
    self.lraLowLUFS = clamp(lraLowLUFS)
    self.lraHighLUFS = clamp(lraHighLUFS)
    self.momentaryLUFS = momentaryLUFS.map(clamp)
    self.shortTermLUFS = shortTermLUFS.map(clamp)
    self.stepSeconds =
      (stepSeconds.isFinite && stepSeconds > 0) ? stepSeconds : 0.1
  }

  // MARK: Computed extremes

  /// Loudest momentary value, or `nil` when the series is empty.
  public var maxMomentaryLUFS: Double? { momentaryLUFS.max() }

  /// Quietest momentary value, or `nil` when the series is empty.
  /// Silent blocks read the `-100.0` floor.
  public var minMomentaryLUFS: Double? { momentaryLUFS.min() }

  /// Loudest short-term value, or `nil` when the series is empty.
  public var maxShortTermLUFS: Double? { shortTermLUFS.max() }

  // MARK: Charting adapter

  /// Both series flattened into `(time, lufs, series)` points for plotting —
  /// e.g., Swift Charts `ForEach` + `LineMark` with
  /// `.foregroundStyle(by: .value("Series", sample.series.rawValue))`.
  ///
  /// Foundation-only: the library imports no UI framework; consumers bind
  /// `series.rawValue` to their chart's style scale.
  ///
  /// - Important: Computed on every access in O(momentary + shortTerm).
  ///   Materialize once (e.g., into view state) rather than calling per frame.
  public var samples: [LoudnessSample] {
    let momentary = momentaryLUFS.enumerated().map { pair in
      LoudnessSample(
        time: Double(pair.offset) * stepSeconds,
        lufs: pair.element,
        series: .momentary)
    }
    let shortTerm = shortTermLUFS.enumerated().map { pair in
      LoudnessSample(
        time: Double(pair.offset) * stepSeconds,
        lufs: pair.element,
        series: .shortTerm)
    }
    return momentary + shortTerm
  }

  // MARK: CustomStringConvertible

  /// One-line summary of the headline scalars and series sizes, for logs and
  /// trace dumps.
  public var description: String {
    let lra = loudnessRangeLU.map { String(format: "%.1f LU", $0) } ?? "n/a"
    return String(
      format: "LUFSReport(integrated: %.1f LUFS, truePeak: %.1f dBTP, LRA: %@, "
        + "momentary: %d, shortTerm: %d @ %.1fs step)",
      integratedLUFS, maxTruePeakDBTP, lra,
      momentaryLUFS.count, shortTermLUFS.count, stepSeconds)
  }
}

// MARK: - LoudnessSample

/// One plottable loudness point: a `(time, lufs)` pair tagged with the
/// series it belongs to. See ``LUFSReport/samples``.
public struct LoudnessSample: Sendable, Identifiable, Hashable {
  /// Stable identity within a report: series + window start time.
  public var id: String { "\(series.rawValue)@\(time)" }

  /// Window start time in seconds from the start of the analyzed audio.
  public let time: Double

  /// Loudness in LUFS (floored at `-100.0` for silent windows).
  public let lufs: Double

  /// Which series this point belongs to.
  public let series: LoudnessSeries

  /// Creates a plottable loudness point.
  public init(time: Double, lufs: Double, series: LoudnessSeries) {
    self.time = time
    self.lufs = lufs
    self.series = series
  }
}

/// The loudness series a ``LoudnessSample`` belongs to. `rawValue` doubles as
/// the human-readable chart legend label.
public enum LoudnessSeries: String, Sendable, Hashable, CaseIterable {
  /// 400ms momentary window (EBU Tech 3341 §2.2).
  case momentary = "Momentary"
  /// 3.0s short-term window (EBU Tech 3341 §2.2).
  case shortTerm = "Short-term"
}

// MARK: - LUFSAnalysisError

/// Errors thrown by ``AudioAnalysisService/analyzeLUFS(url:options:)`` for
/// environmental/configuration failures (DD #8 nil-vs-throw contract:
/// throw = cannot measure; `nil` = measured but no result).
public enum LUFSAnalysisError: Error, Sendable {
  /// The file's sample rate has no pre-computed K-weighting coefficient set
  /// (ITU-R BS.1770-5 filters are rate-specific; coefficients ship for
  /// 44.1/48/96 kHz only). The file itself was readable — this is a
  /// measurement-configuration limit, not an I/O failure.
  case unsupportedSampleRate(sampleRate: Double, supported: [Double])
}

// MARK: - LUFSOptions

/// Options for ``AudioAnalysisService/analyzeLUFS(url:options:)``
/// (ADR-11 options-first configuration).
public struct LUFSOptions: Sendable {
  /// Maximum seconds of audio to analyze. `nil` (the default) analyzes the
  /// full file — integrated loudness is whole-programme by definition
  /// (ITU-R BS.1770-5), and LRA needs ≥60s of gated programme. Set a value
  /// only as a bounded-cost escape hatch; a truncated measurement is not the
  /// programme loudness.
  ///
  /// Non-finite, non-positive, or absurdly large (≥1e9 s) values are ignored
  /// and treated as `nil` (full file).
  public var maxSeconds: Double?

  /// Creates options with the defaults (full-file analysis).
  public init() {}
}
