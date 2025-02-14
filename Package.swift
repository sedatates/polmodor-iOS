// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Polmodor",
    platforms: [
        .iOS(.v16),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "Polmodor",
            targets: ["Polmodor"]
        ),
        .library(
            name: "PolmodorWidget",
            targets: ["PolmodorWidget"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Polmodor",
            dependencies: [],
            path: "polmodor/Sources"
        ),
        .target(
            name: "PolmodorWidget",
            dependencies: ["Polmodor"],
            path: "widget"
        ),
        .testTarget(
            name: "PolmodorTests",
            dependencies: ["Polmodor"],
            path: "polmodorTests"
        ),
    ]
)
