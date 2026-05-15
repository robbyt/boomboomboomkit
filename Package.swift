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
      path: "Sources/BoomBoomBoomKitML",
      resources: [.copy("Resources")]
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
