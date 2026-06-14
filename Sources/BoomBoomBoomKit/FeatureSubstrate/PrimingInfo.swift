//
//  PrimingInfo.swift
//  BoomBoomBoomKit
//
//  Codec + trim-state provenance carried on DecodedAudio.
//

import Foundation

extension FeatureSubstrate {

  /// Provenance of encoder/decoder priming-frame handling for a
  /// ``DecodedAudio``'s samples (Story 8-2 DD #7a reshape).
  ///
  /// The pre-8.2 `leadingTrimFrames`/`trailingTrimFrames` integer fields are
  /// deleted: nothing could populate them honestly. `AVAudioFile` (layered on
  /// `ExtAudioFile`, which per Apple Technical Note TN2258 removes priming /
  /// remainder frames) is OBSERVED to present already-trimmed PCM for
  /// DECLARED priming (CAF `pakt` packet tables, MP4 edit info, LAME/Xing
  /// headers) before any sample is visible to the reader — but this pre-trim is
  /// empirical, NOT a published `AVAudioFile` contract — while headerless
  /// ADTS/MP3 streams leak their ~2112-frame encoder delay undetectably — so
  /// a zero could mean "no priming" or "priming leaked, we can't tell".
  /// ``TrimState`` makes that distinction explicit instead of encoding it as
  /// a magic zero. The C-level `kAudioFilePropertyPacketTableInfo` query that
  /// can report DECLARED trim counts (a separate `AudioToolbox` open, since
  /// `AVAudioFile` does not expose its `AudioFileID`) is deferred to a later
  /// release (Story 8.7) and will land as an additive `TrimState` case; Story
  /// 8.5 keeps the timestamp contract decoded-PCM-relative and never subtracts
  /// priming.
  public struct PrimingInfo: Sendable, Hashable, Codable {

    /// Content-true codec of the encoded source. See ``AudioCodec``.
    public let codec: AudioCodec

    /// What is known about priming-frame trimming for these samples.
    public let trimState: TrimState

    public init(codec: AudioCodec, trimState: TrimState) {
      self.codec = codec
      self.trimState = trimState
    }
  }

  /// Trim-state provenance for ``PrimingInfo`` (Story 8-2 DD #7a).
  public enum TrimState: Sendable, Hashable, Codable {
    /// The samples are known to carry no codec priming — true only for
    /// linear PCM, which has no priming concept.
    case knownNone
    /// Trim was already applied by the decoder, or priming leaked
    /// undetectably (headerless ADTS/MP3 encoder delay) — the caller must
    /// not assume either. This is the honest state for every non-LPCM
    /// codec until the declared-trim query lands (Story 8.7).
    case unknown
  }
}
