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
  //
  // The dependency is named explicitly: a path dependency's identity is otherwise
  // the last path component, which is the checkout directory's name (a worktree
  // such as `.claude/worktrees/<branch>`), and `package: "BoomBoomBoomKit"` below
  // would not resolve there.
  dependencies: [
    .package(name: "BoomBoomBoomKit", path: "../../..")
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
    // dump-fixed-time-input: Story 15.5. Depends on BoomBoomBoomKit for the
    // substrate log-mel, then mirrors the fixed-time crop preprocessing (1200-frame
    // crops, tail crop, per-crop z-score, no resize) and records the library's
    // rhythm score per crop (`@testable import`, debug builds) for the
    // test_feature_parity.py stages 6 and 7. Writes its own 20 s click and 40 s
    // click / silence / noise mix signals to ../parity_signals/. Develop-only —
    // never ships to main.
    .executableTarget(
      name: "dump-fixed-time-input",
      dependencies: [
        .product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit")
      ],
      path: "Sources/dump-fixed-time-input",
      linkerSettings: [.linkedFramework("Accelerate")]
    ),
    // dump-real-track: Phase 1.5 (Epic 7 close-out). Runs the FULL
    // AudioAnalysisService path on one REAL audio file and dumps the selected
    // window's log-mel + model-input tensor + window manifest, so the Python
    // feature_substrate_v2 z-score+resample is verified against the runtime on a
    // real multi-minute track (large F), not just the short parity fixtures.
    // Develop-only — never ships to main.
    .executableTarget(
      name: "dump-real-track",
      dependencies: [
        .product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit"),
        .product(name: "BoomBoomBoomKitML", package: "BoomBoomBoomKit"),
      ],
      path: "Sources/dump-real-track"
    ),
    // matched-eval-run: Story 15.9. Runs the shipped pipeline, the Story 15.7
    // joint tempo and phase fit, and the comb best-phase re-anchored grid on every
    // track of an input manifest, with per-pass runtime and task_info peak memory.
    // Reaches internal types through `@testable import`, so a release build needs
    // `-Xswiftc -enable-testing`. Driven by `make matched-eval`. Develop-only.
    .executableTarget(
      name: "matched-eval-run",
      dependencies: [
        .product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit")
      ],
      path: "Sources/matched-eval-run"
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
