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
            exclude: ["AppCore/Info.plist", "CLIApp"],
            sources: ["AppCore", "Views", "Controllers"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ODYSSEYCLI",
            dependencies: ["ODYSSEYBackend"],
            path: "Sources/CLIApp",
            sources: ["CLIEntryPoint.swift"]
        ),
        .target(
            name: "ODYSSEYBackend",
            path: "Sources",
            exclude: ["AppCore", "Views", "Controllers", "CLIApp", "AppCore/Info.plist"],
            sources: ["Models", "Services", "SharedUtils", "SharedCore"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
