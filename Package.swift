// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PullUpController",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "PullUpController",
            targets: ["PullUpController"]
        )
    ],
    targets: [
        .target(
            name: "PullUpController",
            path: "PullUpController"
        )
    ]
)
