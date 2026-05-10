// swift-tools-version: 6.0
//
// Story 4-4b dev-only Swift CLI tool.
//
// Lives at _bmad-output/ml-training/swift_feature_extractor/ — NOT under
// Sources/ or Tests/. Dumps the shared feature_pipeline_v1 fixture
// (mel filterbank matrix + Hann STFT window + DSP constants) AND emits per-stage
// outputs from the canonical Swift DSP pipeline against a deterministic test
// signal. Python's test_feature_parity.py compares its own per-stage outputs
// against these emitted JSONs at staged tolerance contracts (AC #3 Part B).
//
// Why a standalone Swift package and not @testable import:
//   - The MelFilterbank.buildFilterbank algorithm and the BPMAnalyzer STFT
//     pipeline are re-implemented here line-for-line from
//     Sources/BoomBoomBoomKit/MelFilterbank.swift and BPMAnalyzer.swift §490-585.
//     This is the only way to avoid modifying Sources/ (AC #1 forbids any
//     internal-to-public promotion in this story; @testable import requires
//     the dependency to be compiled with -enable-testing, which only happens
//     for test targets).
//   - Drift between the CLI re-implementation and the canonical BoomBoomBoomKit
//     code is caught loudly by the 4-stage parity harness — Stage 1 verifies
//     the dumped filterbank round-trips through .npz at 1e-6, Stages 2-4 verify
//     downstream outputs at staged tolerances. Any silent algorithm change in
//     Sources/ breaks the parity harness on next dev run.

import PackageDescription

let package = Package(
  name: "swift-feature-extractor",
  platforms: [.macOS(.v15)],
  targets: [
    .executableTarget(
      name: "dump-fixture",
      path: "Sources/dump-fixture"
    )
  ]
)
