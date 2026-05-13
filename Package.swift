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
      // Story 4-5: BoomBoomBoomKitML added so BNNSTechniqueTests and
      // MLTechniqueProtocolTests can link against the BNNSTechnique
      // conformance. NOT a new external dependency — BoomBoomBoomKitML
      // is a sibling target already in this package since Story 4.1.
      // The "no new deps" framing in AC #10 was about external packages;
      // a sibling-target test dependency does not affect the zero-
      // external-deps posture verified by
      // `swift package show-dependencies --format json | jq '.dependencies | length'`.
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport", "BoomBoomBoomKitML"],
      resources: [.copy("Fixtures")]
    ),
    .testTarget(
      name: "BoomBoomBoomKitBenchmarkTests",
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
