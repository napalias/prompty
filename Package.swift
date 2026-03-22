// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AITextTool",
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
            name: "AITextTool",
            dependencies: [
                "KeyboardShortcuts",
                "Sparkle"
            ],
            path: "Sources/AITextTool",
            exclude: ["Sidecar"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "AITextToolTests",
            dependencies: ["AITextTool"],
            path: "Tests/AITextToolTests"
        )
    ]
)
