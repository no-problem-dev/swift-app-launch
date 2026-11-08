// swift-tools-version: 6.2
import PackageDescription

/// Telling people what changed after an update, and deciding in one place what appears at launch
/// and in what order.
///
/// **No external dependencies.** SwiftPM resolves dependencies per package, so anything declared
/// here lands on every consumer. Versions are taken as strings, so an app that already has a
/// version type (such as `swift-review`'s `AppVersion`) passes its `description`; analytics leave
/// through a closure, so no analytics package is needed either.
let package = Package(
    name: "swift-app-launch",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The version change, the release declarations and which one is due, the stored record,
        // the order of what appears at launch, and the analytics events. Foundation only.
        .library(name: "AppLaunchCore", targets: ["AppLaunchCore"]),
        // The pager that shows a release's pages. The app draws the illustrations.
        .library(name: "WhatsNewUI", targets: ["WhatsNewUI"])
    ],
    targets: [
        .target(name: "AppLaunchCore"),
        .target(
            name: "WhatsNewUI",
            dependencies: ["AppLaunchCore"],
            resources: [.process("Resources")]
        ),

        .testTarget(name: "AppLaunchCoreTests", dependencies: ["AppLaunchCore"]),
        .testTarget(name: "WhatsNewUITests", dependencies: ["WhatsNewUI", "AppLaunchCore"])
    ]
)
