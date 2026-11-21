// swift-tools-version: 6.2
import PackageDescription

/// The what's-new card a `whats_new` campaign shows, and one pure order for what appears at launch.
///
/// **It does not decide which version shows what, or to whom.** That is the `whats_new` campaign's
/// job in swift-app-campaign (its `app_updated` trigger and its limits). This package draws the card
/// from the campaign's values and orders the app's own launch screens.
///
/// **No external dependencies.** SwiftPM resolves dependencies per package, so anything declared
/// here lands on every consumer. The card's values decode from the campaign's JSON as they are, so
/// nothing here imports the campaign SDK.
let package = Package(
    name: "swift-app-launch",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The order of what appears at launch, and the card's values. Foundation only.
        .library(name: "AppLaunchCore", targets: ["AppLaunchCore"]),
        // The what's-new card. The app may draw the illustration.
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
