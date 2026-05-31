//
//  SubBandCutoff.swift
//  BoomBoomBoomKit
//
//  Closed-set sub-band cutoff identifier consumed by SubBandWeights.
//

import Foundation

extension FeatureSubstrate {

  public enum SubBandCutoff: String, Sendable, Hashable, CaseIterable, Equatable, Codable {
    case standard
    case dnbOptimized
  }
}
