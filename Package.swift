// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoodMap",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MoodMap", targets: ["MoodMap"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MoodMap",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
