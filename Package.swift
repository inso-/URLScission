// swift-tools-version:5.2
import PackageDescription
let package = Package(
    name: "URLScission",
    platforms: [
        .macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)
    ],
    products: [
        .library(name: "URLScission", targets: ["URLScission"])
    ],
    targets: [
        .target(name: "URLScission", path: "URLScission"),
        .testTarget(
                   name: "URLScissionTests",
                   dependencies: ["URLScission"]),
    ]
)
