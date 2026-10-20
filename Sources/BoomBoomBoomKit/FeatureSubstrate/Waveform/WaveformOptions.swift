//
//  WaveformOptions.swift
//  BoomBoomBoomKit
//
//  Story 15.4: configuration for ``WaveformAnalyzer``.
//

import Foundation

/// Options for ``WaveformAnalyzer``. All fields have sensible defaults; most
/// callers can use `.init()`.
public struct WaveformOptions: Sendable {

  // MARK: Resolution

  /// Detail envelope cadence, in columns per second. Default `150` matches
  /// the handoff's suggested interoperability resolution. Must lie between 1
  /// and the sample rate of the input being analyzed; the analyzer throws
  /// ``WaveformAnalyzerError/columnsPerSecondOutOfRange(columnsPerSecond:sampleRate:)``
  /// otherwise. The actual bin count is derived with rational integer math
  /// (see ``WaveformDetailEnvelope`` doc).
  public var columnsPerSecond: Int = 150

  // MARK: Energy-band crossovers

  /// Low / mid crossover in Hz. Default `250` Hz splits kick-fundamental
  /// energy from the lower midrange. Must be finite, positive, and below
  /// ``midHighCutoffHz``.
  public var lowMidCutoffHz: Double = 250

  /// Mid / high crossover in Hz. Default `4000` Hz separates the midrange
  /// (vocals, snare body) from the top band (hi-hats, cymbals, air). Must be
  /// finite, positive, and below the input's Nyquist frequency, so the
  /// default throws
  /// ``WaveformAnalyzerError/midHighCutoffOutOfRange(midHighCutoffHz:nyquistHz:)``
  /// on 8 kHz input; lower it for low-rate sources.
  public var midHighCutoffHz: Double = 4000

  // MARK: Cancellation and progress

  /// Closure consulted before the pass starts, before each biquad filter
  /// pass, and before each 256-bin chunk of every per-bin pass. Returning
  /// `true` makes the analyzer throw ``WaveformAnalyzerError/cancelled``
  /// with no partial result. Default reads `Task.isCancelled`.
  public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }

  /// Receives a `[0.0, 1.0]` progress fraction: `0.0` once at the start,
  /// then once after each 256-bin chunk of the four per-bin passes (detail /
  /// overview, then low, mid, and high band RMS). Values are non-decreasing
  /// and the last report of a completed run is `1.0`. No further reports
  /// follow a cancellation.
  public var onProgress: (@Sendable (Double) -> Void)?

  public init() {}
}
