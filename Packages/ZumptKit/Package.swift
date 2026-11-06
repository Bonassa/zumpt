// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ZumptKit",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "ZumptKit", targets: ["ZumptKit"])
    ],
    targets: [
        .target(
            name: "ZumptKit",
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "ZumptKitTests",
            dependencies: ["ZumptKit"],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
    ]
)
