// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GYLTCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GYLTCore", targets: ["GYLTCore"]),
    ],
    targets: [
        .target(name: "GYLTCore"),
        .testTarget(name: "GYLTCoreTests", dependencies: ["GYLTCore"]),
    ]
)
