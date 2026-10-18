//
//  WaveformOptions.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — configuration for ``WaveformAnalyzer``.
//

import Foundation

/// Options for ``WaveformAnalyzer``. All fields have sensible defaults; most
/// callers can use `.init()`.
public struct WaveformOptions: Sendable {

  // MARK: Resolution

  /// Detail envelope cadence, in columns per second. Default `150` matches
  /// the handoff's suggested interoperability resolution. Any strictly
  /// positive integer is accepted; the actual bin count is derived with
  /// rational integer math (see ``WaveformDetailEnvelope`` doc).
  public var columnsPerSecond: Int = 150

  // MARK: Channels

  /// How to handle stereo input (reserved; only ``WaveformChannelPolicy/mono``
  /// is implemented in Phase 1 of Story 15.4).
  public var channelPolicy: WaveformChannelPolicy = .mono

  // MARK: Energy-band crossovers

  /// Low / mid crossover in Hz. Default `250` Hz splits kick-fundamental
  /// energy from the lower midrange.
  public var lowMidCutoffHz: Double = 250

  /// Mid / high crossover in Hz. Default `4000` Hz separates the midrange
  /// (vocals, snare body) from the top band (hi-hats, cymbals, air).
  public var midHighCutoffHz: Double = 4000

  // MARK: Streaming (reserved for follow-up Story 15.4a)

  /// Block size in samples for streaming decode. Phase 1 of Story 15.4
  /// processes a `DecodedAudio` in-memory and ignores this field; it is
  /// reserved for the follow-up that adds bounded-memory streaming.
  public var blockSize: Int = 65536

  // MARK: Cancellation and progress

  /// Closure consulted at block boundaries. Phase 1 of Story 15.4 is a
  /// single pass over an in-memory `DecodedAudio` and consults this once
  /// at the start; follow-up streaming will consult between blocks.
  public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }

  /// Receives a `[0.0, 1.0]` progress fraction. Phase 1 fires at `0.0` and
  /// `1.0`; the streaming follow-up fires at each block boundary.
  public var onProgress: (@Sendable (Double) -> Void)?

  public init() {}
}
