// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HintEngine",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "HintEngine", targets: ["HintEngine"]),
    ],
    targets: [
        .target(name: "HintEngine"),
        .testTarget(name: "HintEngineTests", dependencies: ["HintEngine"]),
    ]
)
