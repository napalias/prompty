// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Prompty",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts",
            "2.0.0"..<"2.4.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Prompty",
            dependencies: [
                "KeyboardShortcuts"
            ],
            path: "Sources/Prompty",
            exclude: ["Sidecar"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "PromptyTests",
            dependencies: ["Prompty"],
            path: "Tests/PromptyTests"
        )
    ]
)
