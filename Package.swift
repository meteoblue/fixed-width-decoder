// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "FW.swift",
    products: [
        .library(name: "FW", targets: ["FW"])
    ],
    targets: [
        .target(name: "FW"),
        .testTarget(name: "FWTests", dependencies: ["FW"])
    ],
    swiftLanguageVersions: [.v5]
)
