// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ODYSSEY",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ODYSSEY", targets: ["ODYSSEY"])
    ],
    targets: [
        .executableTarget(
            name: "ODYSSEY",
            path: "Sources",
            exclude: ["App/Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ODYSSEYTests",
            dependencies: ["ODYSSEY"],
            path: "Tests/ODYSSEYTests"
        )
    ]
)
