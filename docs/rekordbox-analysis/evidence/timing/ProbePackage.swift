// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "TimingProbe", platforms: [.macOS(.v15)], targets: [
 .target(name: "BoomBoomBoomKit", path: "Sources/BoomBoomBoomKit", exclude: ["Resources/README.md", "Resources/_template.md"], resources: [.copy("Resources/Documentation")]),
 .testTarget(name: "TimingProbeTests", dependencies: ["BoomBoomBoomKit"], path: "ProbeTests")
])
