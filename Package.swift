// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TinodeSDK",
    defaultLocalization: "en", products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TinodeSDK",
            targets: ["TinodeSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", exact: "1.23.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", exact: "7.9.1"),
        .package(url: "https://github.com/instaply/MobileVLCKit.git", exact: "3.4.0"),
        .package(url: "https://github.com/stasel/WebRTC", exact: "116.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "10.15.0"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit", exact: "3.6.8"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", exact: "0.15.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TinodeSDK",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "MobileVLCKit", package: "MobileVLCKit"),
                .product(name: "WebRTC", package: "WebRTC"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .testTarget(
            name: "TinodeSDKTests",
            dependencies: ["TinodeSDK"]),
    ]
)
