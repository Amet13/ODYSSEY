// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ODYSSEY",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // GUI Version: macOS Menu Bar App
        .executable(name: "ODYSSEY", targets: ["ODYSSEY"]),
        // CLI Version: Command Line Interface
        .executable(name: "odyssey-cli", targets: ["ODYSSEYCLI"]),
        // Shared Backend Library
        .library(name: "ODYSSEYBackend", targets: ["ODYSSEYBackend"])
    ],
    targets: [
        .executableTarget(
            name: "ODYSSEY",
            dependencies: ["ODYSSEYBackend"],
            path: "Sources",
            exclude: ["App/Info.plist", "CLI"],
            sources: ["App", "Views", "AppControllers"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ODYSSEYCLI",
            dependencies: ["ODYSSEYBackend"],
            path: "Sources/CLI",
            sources: ["CLI.swift"]
        ),
        .target(
            name: "ODYSSEYBackend",
            path: "Sources",
            exclude: ["App", "Views", "AppControllers", "CLI", "App/Info.plist"],
            sources: ["Models", "Services", "Utils"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
