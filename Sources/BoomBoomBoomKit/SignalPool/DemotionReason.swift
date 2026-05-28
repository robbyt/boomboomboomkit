//
//  DemotionReason.swift
//  BoomBoomBoomKit
//
//  Reason a signal source's contribution was demoted in the unified pool.
//

public enum DemotionReason: Sendable, Equatable, Codable {
  case implausibleForContext
  case sourceSpecific(String)
}
