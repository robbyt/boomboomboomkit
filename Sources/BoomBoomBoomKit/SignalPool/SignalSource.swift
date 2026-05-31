//
//  SignalSource.swift
//  BoomBoomBoomKit
//
//  Tag identifying which subsystem produced a unified-pool signal.
//

public enum SignalSource: String, CaseIterable, Sendable, Hashable, Codable {
  case dsp
  case ml
  case fileMetadata
  case beatGrid
}
