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
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.6.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Prompty",
            dependencies: [
                "KeyboardShortcuts",
                "Sparkle"
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
