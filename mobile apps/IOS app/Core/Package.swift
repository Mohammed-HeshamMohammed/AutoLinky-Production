// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "AutoLinkyCore", platforms: [.iOS(.v17), .macOS(.v14)], products: [.library(name: "AutoLinkyCore", targets: ["AutoLinkyCore"])], targets: [.target(name: "AutoLinkyCore"), .testTarget(name: "AutoLinkyCoreTests", dependencies: ["AutoLinkyCore"])], swiftLanguageModes: [.v5])
