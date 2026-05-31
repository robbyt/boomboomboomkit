//
//  AudioCodec.swift
//  BoomBoomBoomKit
//
//  Source-audio container identifier carried on DecodedAudio.codecPriming.
//

import Foundation

extension FeatureSubstrate {

  public enum AudioCodec: String, Sendable, Hashable, CaseIterable, Equatable, Codable {
    case aac
    case mp3
    case flac
    case wav
    case aiff
    case caf
  }
}
