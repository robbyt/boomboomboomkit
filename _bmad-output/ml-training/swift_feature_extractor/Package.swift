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
  // tony-dsp-prepass depends on BoomBoomBoomKit. Reached via local SPM path
  // back to the repo root (this package sits 3 dirs deeper). dump-fixture
  // intentionally has NO BoomBoomBoomKit dependency — it re-implements DSP
  // line-for-line so the Story 4-4b parity harness can detect Sources/ drift.
  dependencies: [
    .package(path: "../../..")
  ],
  targets: [
    .executableTarget(
      name: "dump-fixture",
      path: "Sources/dump-fixture"
    ),
    // tony-dsp-prepass: develop-only CLI that runs BoomBoomBoomKit DSP against
    // every resolved track in a Rekordbox survey JSON and dumps per-track
    // {bpm, confidence, top candidates} to JSON. Consumed by
    // scripts/tony-tunes-labels.py as the DSP signal in the weighted-ensemble
    // labeler. Stays out of Sources/ / Tests/ — never ships to main.
    .executableTarget(
      name: "tony-dsp-prepass",
      dependencies: [
        .product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit")
      ],
      path: "Sources/tony-dsp-prepass"
    ),
    // dump-model-input: Story 7.5 Task 1 / DD #15. Depends on BoomBoomBoomKit
    // + BoomBoomBoomKitML; single-sources BNNSTechnique.modelInputTensor to dump
    // the post-featurize [1,1,128,512] model-input tensor (mel-major + z-scored
    // + resampled-to-512) for the test_feature_parity.py stage-5 model-input
    // parity check. Reads the parity signals dump-fixture emits to
    // ../parity_signals/. Develop-only — never ships to main.
    .executableTarget(
      name: "dump-model-input",
      dependencies: [
        .product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit"),
        .product(name: "BoomBoomBoomKitML", package: "BoomBoomBoomKit"),
      ],
      path: "Sources/dump-model-input"
    ),
    // bnns-probe: Story 4-5 Task 1.5b + 1.5d verification probe. Loads a
    // .mlmodelc via raw BNNSGraph C API, probes graph.data's malloc zone
    // to determine whether `free(graph.data)` is the correct destructor
    // primitive, then runs a single deterministic inference to detect
    // whether the model emits probabilities or logits. Develop-only.
    .executableTarget(
      name: "bnns-probe",
      path: "Sources/bnns-probe",
      linkerSettings: [.linkedFramework("Accelerate")]
    ),
  ]
)
