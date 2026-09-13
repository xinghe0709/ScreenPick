// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ScreenPick",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenPick", targets: ["ScreenPick"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenPick",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ImageIO"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        )
    ]
)
