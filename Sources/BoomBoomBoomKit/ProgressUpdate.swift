//
//  ProgressUpdate.swift
//  BoomBoomBoomKit
//
//  Progress reporting for multi-window BPM analysis.
//

/// Reports progress during multi-window BPM analysis.
///
/// Each update is emitted *before* a window begins analysis, so
/// `windowsCompleted == 0` means "about to start the first window."
/// There is no final "done" callback — the function return signals completion.
public struct ProgressUpdate: Sendable {
  /// Number of analysis windows already completed (0-based).
  public let windowsCompleted: Int

  /// Total number of analysis windows that will be attempted.
  public let windowsTotal: Int
}
