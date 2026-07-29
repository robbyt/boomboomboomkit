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
      path: "Sources/BoomBoomBoomKit",
      // `Resources/README.md` documents the doc-authoring format for contributors,
      // and `Resources/_template.md` is the `make new-case` scaffolding stub. Both
      // are repo artifacts, not bundled resources, so they are excluded to avoid an
      // SPM unhandled-file warning (and to keep them out of `Bundle.module`). The
      // template sits BESIDE the copied tree, not inside it — `exclude:` cannot
      // reach into a `.copy`'d directory, which is why it is not under `Documentation/`.
      exclude: ["Resources/README.md", "Resources/_template.md"],
      // `.copy` (NOT `.process`): `.process` copies unprocessed `.md` files to
      // the bundle top level, flattening `Documentation/<kind>/` and colliding
      // same-basename files — which breaks the `subdirectory:`-keyed accessor in
      // BoomBoomBoomKitDocs. `.copy` retains the directory structure verbatim.
      resources: [.copy("Resources/Documentation")]
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
        // `_bmad-output/ml-models/` (develop-only), alongside its model card
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
