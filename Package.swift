// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "carthage_cache",
    products: [
        .executable(name: "carthage_cache", targets: ["carthage_cache"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Carthage/Carthage.git", from: "0.35.0"),
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.16.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "carthage_cache",
            dependencies: [
                "Commandant",
                .product(name: "CarthageKit", package: "Carthage")
        ]),
        .testTarget(
            name: "carthage_cacheTests",
            dependencies: ["carthage_cache"]),
    ],
    swiftLanguageVersions: [.v5]
)
