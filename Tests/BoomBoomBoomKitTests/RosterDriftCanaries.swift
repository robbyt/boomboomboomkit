//
//  RosterDriftCanaries.swift
//  BoomBoomBoomKitTests
//
//  Compile-time drift tripwires for the five hand-rostered `DocumentedCase`
//  enums whose per-case doc rosters (and the `.md` files) are maintained by hand
//  because they carry associated values and so cannot get `allCases` for free:
//  EnsemblePolicy (11.3a), and MLExecutionPolicy / DownbeatResult / AbstainReason /
//  DemotionReason (11.3b). Kept in a dedicated file because those rosters live in
//  two different docs suites — this describes the cross-story purpose in one place.
//

// Plain import (NOT @testable): every exercised symbol is public.
import BoomBoomBoomKit
import Testing

@Suite("Roster drift canaries")
struct RosterDriftCanaries {

  /// These `switch`es have NO `default:` arm, so adding a case to any of the five
  /// enums breaks the test-target build here. That forces EXPLICIT test-target
  /// acknowledgment — whoever adds the case must then update the per-case doc
  /// rosters + author the `.md` file (checked by the docs suites) and revisit this
  /// canary. It does NOT by itself guarantee a doc was authored: the LIBRARY build
  /// already breaks via each enum's own no-`default:` `documentationID` /
  /// `stableKey` switch. This is the independent test-side reminder that survives
  /// until Story 11.4's drift validator lands. (Relies on the current
  /// non-library-evolution build, where a cross-module exhaustive switch needs no
  /// `@unknown default`; do NOT add `@frozen` to these enums to satisfy this test.)
  @Test func handRosteredEnumsHaveNoUndocumentedCases() {
    func ml(_ p: MLExecutionPolicy) {
      switch p {
      case .never, .always, .whenDSPConfidenceBelow: break
      }
    }
    func ens(_ p: EnsemblePolicy) {
      switch p {
      case .default, .dspOnly, .mlOnly, .highestConfidence, .weightedVoting: break
      }
    }
    func db(_ p: DownbeatResult) {
      switch p {
      case .notAttempted, .noneDetected, .detected: break
      }
    }
    func ab(_ p: AbstainReason) {
      switch p {
      case .policyDisabled, .inputBelowMinimum, .confidenceBelowFloor, .sourceSpecific: break
      }
    }
    func dm(_ p: DemotionReason) {
      switch p {
      case .implausibleForContext, .sourceSpecific: break
      }
    }
    // Reference each with a representative value so the helpers are not dead code.
    ml(.never)
    ens(.dspOnly)
    db(.notAttempted)
    ab(.policyDisabled)
    dm(.implausibleForContext)
  }
}
