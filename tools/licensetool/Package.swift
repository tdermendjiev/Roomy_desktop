// swift-tools-version: 5.9
//
// roomy-licensetool — developer-only tool to mint and verify Roomy Fleet license tokens.
// Lives outside RoomyCore so the public export does not carry it. Not shipped.
//
//   cd tools/licensetool && swift run roomy-licensetool keygen
//
import PackageDescription

let package = Package(
    name: "licensetool",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "roomy-licensetool", targets: ["roomy-licensetool"]),
    ],
    dependencies: [
        .package(path: "../../RoomyCore"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "3.0.0"..<"5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "roomy-licensetool",
            dependencies: [
                .product(name: "RoomyFleet", package: "RoomyCore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
    ]
)
