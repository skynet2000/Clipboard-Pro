// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MClipboard",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "MClipboard",
            path: "Sources/MClipboard",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("Translation")
            ]
        )
    ]
)
