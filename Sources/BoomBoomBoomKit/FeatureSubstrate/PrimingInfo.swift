//
//  PrimingInfo.swift
//  BoomBoomBoomKit
//
//  Per-codec encoder/decoder priming-frame counts carried on DecodedAudio.
//

import Foundation

extension FeatureSubstrate {

  public struct PrimingInfo: Sendable, Hashable, Equatable, Codable {

    public let codec: AudioCodec
    public let leadingTrimFrames: Int
    public let trailingTrimFrames: Int

    public init(codec: AudioCodec, leadingTrimFrames: Int, trailingTrimFrames: Int) {
      self.codec = codec
      self.leadingTrimFrames = leadingTrimFrames
      self.trailingTrimFrames = trailingTrimFrames
    }
  }
}
