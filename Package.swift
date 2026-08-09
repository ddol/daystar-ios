// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "daystar-ios",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "daystar-ios",
            targets: ["daystar-ios"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "daystar-ios"
        ),
        .testTarget(
            name: "daystar-iosTests",
            dependencies: ["daystar-ios"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
