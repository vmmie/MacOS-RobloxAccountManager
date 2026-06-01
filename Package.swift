// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MacOS-RobloxAccountManager",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RobloxAccountManagerCore",
            targets: ["RobloxAccountManagerCore"]
        ),
        .executable(
            name: "MacOS-RobloxAccountManager",
            targets: ["MacOS-RobloxAccountManager"]
        )
    ],
    targets: [
        .target(
            name: "RobloxAccountManagerCore",
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .executableTarget(
            name: "MacOS-RobloxAccountManager",
            dependencies: ["RobloxAccountManagerCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "RobloxAccountManagerCoreTests",
            dependencies: ["RobloxAccountManagerCore"]
        )
    ]
)
