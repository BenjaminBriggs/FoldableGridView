// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FoldableGrid",
    // Low floors on purpose: the fold APIs are iOS 27.1 and are checked where they are used, so an app
    // on an older target still builds, and simply never sees a fold.
    platforms: [.iOS(.v18), .macOS(.v15), .visionOS(.v2)],
    products: [
        .library(name: "FoldableGrid", targets: ["FoldableGrid"])
    ],
    targets: [
        .target(name: "FoldableGrid"),
        .testTarget(
            name: "FoldableGridTests",
            dependencies: ["FoldableGrid"]
        ),
    ]
)
