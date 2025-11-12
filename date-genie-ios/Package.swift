// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DateGenie",
    platforms: [
        .iOS(.v16),      // iOS 16+ for iPhone
        .macOS(.v12)     // macOS 12+ for Catalyst builds
    ],
    products: [
        .library(
            name: "DateGenie",
            targets: ["DateGenie"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "DateGenie",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "PostHog", package: "posthog-ios")
            ],
            path: "DateGenie"
        )
    ]
)
