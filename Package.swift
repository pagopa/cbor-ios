// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IOWalletCBOR",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "IOWalletCBOR",
            targets: ["IOWalletCBOR"]),
    ],
    dependencies: [
        .package(url: "https://github.com/niscy-eudiw/SwiftCBOR.git", from: "0.6.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IOWalletCBOR",
            dependencies: [
                .product(name: "SwiftCBOR", package: "SwiftCBOR")
            ],
            path: "IOWalletCBOR/IOWalletCBOR"
        ),

    ]
)
