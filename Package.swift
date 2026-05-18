// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "BoomBoomBoomKit",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "BoomBoomBoomKit", targets: ["BoomBoomBoomKit"]),
    .library(name: "BoomBoomBoomKitTestSupport", targets: ["BoomBoomBoomKitTestSupport"]),
    .library(name: "BoomBoomBoomKitML", targets: ["BoomBoomBoomKitML"]),
  ],
  targets: [
    .target(
      name: "BoomBoomBoomKit",
      path: "Sources/BoomBoomBoomKit"
    ),
    .target(
      name: "BoomBoomBoomKitTestSupport",
      dependencies: ["BoomBoomBoomKit"],
      path: "Sources/BoomBoomBoomKitTestSupport",
      resources: [.copy("Resources/AudioFixtures")]
    ),
    .target(
      name: "BoomBoomBoomKitML",
      dependencies: ["BoomBoomBoomKit"],
      path: "Sources/BoomBoomBoomKitML"
        // Story 4-6 Branch C: `resources: [.copy("Resources")]` removed.
        // The previously-bundled `giantsteps_v1.mlmodelc` was moved to
        // `_bmad-output/ml-models/` (develop-only); see MODEL_CARD.md
        // Status section for the full rationale. Re-add this line when a
        // higher-quality bundled model returns.
    ),
    .testTarget(
      name: "BoomBoomBoomKitTests",
      // Tests cover the ML sibling target's public conformances.
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport", "BoomBoomBoomKitML"],
      resources: [.copy("Fixtures")]
    ),
    .testTarget(
      name: "BoomBoomBoomKitBenchmarkTests",
      // Benchmark target links the ML sibling for impact-report coverage.
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport", "BoomBoomBoomKitML"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
