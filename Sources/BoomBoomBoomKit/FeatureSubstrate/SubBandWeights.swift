//
//  SubBandWeights.swift
//  BoomBoomBoomKit
//
//  Per-band Float weights consumed by WeightingProfile.subBandEmphasis.
//

import Foundation

extension FeatureSubstrate {

  public struct SubBandWeights: Sendable, Equatable {

    public let kickBandWeight: Float
    public let snareBandWeight: Float
    public let cymbalBandWeight: Float
    public let cutoff: SubBandCutoff

    public init(
      kickBandWeight: Float,
      snareBandWeight: Float,
      cymbalBandWeight: Float,
      cutoff: SubBandCutoff
    ) {
      self.kickBandWeight = kickBandWeight
      self.snareBandWeight = snareBandWeight
      self.cymbalBandWeight = cymbalBandWeight
      self.cutoff = cutoff
    }
  }
}
