// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StadiaMapsAutocompleteSearch",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StadiaMapsAutocompleteSearch",
            targets: ["StadiaMapsAutocompleteSearch"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stadiamaps/stadiamaps-api-swift", from: "4.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "StadiaMapsAutocompleteSearch",
            dependencies: [
                .product(name: "StadiaMaps", package: "stadiamaps-api-swift"),
            ]
        ),
        .testTarget(
            name: "StadiaMapsAutocompleteSearchTests",
            dependencies: ["StadiaMapsAutocompleteSearch"]
        ),
    ]
)
