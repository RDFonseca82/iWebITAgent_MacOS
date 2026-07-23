// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "iWebITCore",
    defaultLocalization: "pt",
    platforms: [
        .macOS(.v11),
        .iOS(.v15)
    ],
    products: [
        .library(name: "iWebITCore", targets: ["iWebITCore"]),
        .executable(name: "iwebit-update-manifest", targets: ["UpdateManifestSigner"])
    ],
    targets: [
        .target(
            name: "iWebITCore",
            path: "Sources"
        ),
        .executableTarget(
            name: "UpdateManifestSigner",
            dependencies: ["iWebITCore"],
            path: "Tools/UpdateManifestSigner"
        ),
        .testTarget(
            name: "iWebITCoreTests",
            dependencies: ["iWebITCore"],
            path: "Tests",
            resources: [.process("Fixtures")]
        )
    ]
)
