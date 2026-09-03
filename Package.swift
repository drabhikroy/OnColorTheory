// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OnColorTheory",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OnColorTheoryApp", targets: ["OnColorTheoryApp"])
    ],
    dependencies: [
        // Pinned to one minor line. "from:" would let a later resolve pull any
        // 1.x, so a single compromised or broken release upstream would land in
        // a build without anyone choosing it.
        .package(url: "https://github.com/mgriebling/SwiftMath.git", .upToNextMinor(from: "1.7.3"))
    ],
    targets: [
        .executableTarget(
            name: "OnColorTheoryApp",
            dependencies: [
                .product(name: "SwiftMath", package: "SwiftMath")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "OnColorTheoryAppTests",
            dependencies: ["OnColorTheoryApp"]
        )
    ]
)
