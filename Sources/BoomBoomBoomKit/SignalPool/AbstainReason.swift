//
//  AbstainReason.swift
//  BoomBoomBoomKit
//
//  Reason a signal source declined to participate in the unified pool.
//

public enum AbstainReason: Sendable, Equatable, Codable {
  case policyDisabled
  case inputBelowMinimum
  case confidenceBelowFloor
  case sourceSpecific(String)
}
