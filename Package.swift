// swift-tools-version: 5.7
import PackageDescription
let package = Package(name: "FitnessPlannerCore", products: [.library(name: "FitnessPlannerCore", targets: ["FitnessPlannerCore"])], targets: [.target(name: "FitnessPlannerCore", path: "Sources/Core"), .testTarget(name: "FitnessPlannerCoreTests", dependencies: ["FitnessPlannerCore"], path: "Tests")])
