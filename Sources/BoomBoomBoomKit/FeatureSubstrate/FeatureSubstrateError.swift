//
//  FeatureSubstrateError.swift
//  BoomBoomBoomKit
//
//  Substrate-domain failures distinct from MLTechniqueError.invalidFeatureShape.
//

import Foundation

extension FeatureSubstrate {

  public enum FeatureSubstrateError: Error, Sendable {
    case weightingNotYetImplemented(WeightingProfile)
    case featurizationFailed(reason: String)
  }
}
