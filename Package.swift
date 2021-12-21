// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NzCovidPass",
    platforms: [
        .iOS(.v12)
        // macOS not currenly supported as we use SecKeyRawVerify
    ],
    products: [
        .library(name: "NzCovidPass", targets: ["NzCovidPass"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NzCovidPass",
            dependencies: []),
        .testTarget(
            name: "NzCovidPassTests",
            dependencies: ["NzCovidPass"]),
    ]
)
