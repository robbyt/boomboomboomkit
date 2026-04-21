// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "BoomBoomBoomKit",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "BoomBoomBoomKit", targets: ["BoomBoomBoomKit"]),
    .library(name: "BoomBoomBoomKitTestSupport", targets: ["BoomBoomBoomKitTestSupport"]),
  ],
  targets: [
    .target(
      name: "BoomBoomBoomKit",
      path: "Sources/BoomBoomBoomKit"
    ),
    .target(
      name: "BoomBoomBoomKitTestSupport",
      path: "Sources/BoomBoomBoomKitTestSupport",
      resources: [.copy("Resources/AudioFixtures")]
    ),
    .testTarget(
      name: "BoomBoomBoomKitTests",
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport"],
      resources: [.copy("Fixtures")]
    ),
    .testTarget(
      name: "BoomBoomBoomKitBenchmarkTests",
      dependencies: ["BoomBoomBoomKit", "BoomBoomBoomKitTestSupport"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
