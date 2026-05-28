//
//  WeightingProfile.swift
//  BoomBoomBoomKit
//
//  Onset-feature weighting selector consumed by OnsetFeaturesBuilder.build.
//

import Foundation

extension FeatureSubstrate {

  public enum WeightingProfile: Sendable, Equatable {
    case uniform
    case subBandEmphasis(SubBandWeights)
  }
}
