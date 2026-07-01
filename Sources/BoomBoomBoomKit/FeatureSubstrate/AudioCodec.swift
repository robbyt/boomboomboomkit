//
//  AudioCodec.swift
//  BoomBoomBoomKit
//
//  Content-true source-audio codec carried on DecodedAudio.codecPriming.
//

import Foundation

extension FeatureSubstrate {

  /// The codec of the encoded on-disk audio that a ``DecodedAudio`` was
  /// produced from — CODEC semantics, not container semantics (Story 8-2
  /// DD #7 reshape; the pre-8.2 container cases `.wav`/`.aiff`/`.caf` are
  /// deleted because a container name says nothing about priming: `.m4a`
  /// can carry ALAC, `.caf` can carry AAC, AIFF-C can carry compressed
  /// payloads).
  ///
  /// Populated by `PCMBufferReader.readDecodedAudio(from:maxSeconds:)` from
  /// `AVAudioFile.fileFormat.streamDescription.pointee.mFormatID` — the
  /// encoded on-disk format, never the decoded-PCM `processingFormat` (which
  /// would tag everything `.linearPCM`). Formats outside the mapped set
  /// surface as ``unknown`` rather than a guess.
  public enum AudioCodec: String, Sendable, Hashable, CaseIterable, Codable {
    /// Uncompressed linear PCM payload (WAV, AIFF, CAF-with-LPCM, BWF).
    case linearPCM
    /// MPEG-4 AAC family — baseline LC plus the HE/LD/ELD/HE_V2 profiles
    /// (`kAudioFormatMPEG4AAC`, `_HE`, `_LD`, `_ELD`, `_HE_V2`).
    case aac
    /// Apple Lossless (`kAudioFormatAppleLossless`).
    case alac
    /// MPEG Layer 3 (`kAudioFormatMPEGLayer3`).
    case mp3
    /// Free Lossless Audio Codec (`kAudioFormatFLAC`).
    case flac
    /// Any `mFormatID` outside the mapped set, or a carrier constructed
    /// without codec provenance.
    case unknown
  }
}
