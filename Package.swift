// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "StoreKitHelper",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "StoreKitHelper", targets: ["StoreKitHelper"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(name: "StoreKitHelper", dependencies: [])
    ]
)
