// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChargingUnicorn",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk.git", from: "4.38.0")
    ],
    targets: [
        .executableTarget(
            name: "ChargingUnicorn",
            dependencies: [
                .product(
                    name: "Adjust",
                    package: "ios_sdk"
                )
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
