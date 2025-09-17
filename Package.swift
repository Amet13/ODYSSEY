// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ODYSSEY",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // macOS Menu Bar Application
        .executable(name: "ODYSSEY", targets: ["ODYSSEY"]),
        // Shared Backend Library
        .library(name: "ODYSSEYBackend", targets: ["ODYSSEYBackend"])
    ],
    targets: [
        .executableTarget(
            name: "ODYSSEY",
            dependencies: ["ODYSSEYBackend"],
            path: "Sources",
            exclude: ["AppCore/Info.plist"],
            sources: ["AppCore", "Views", "Controllers"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "ODYSSEYBackend",
            path: "Sources",
            exclude: ["AppCore", "Views", "Controllers", "AppCore/Info.plist"],
            sources: ["Models", "Services", "SharedUtils", "SharedCore", "Infrastructure", "Domain", "Application", "Presentation"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
