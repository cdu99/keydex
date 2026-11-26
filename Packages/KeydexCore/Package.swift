// swift-tools-version: 6.2
import PackageDescription

/// Keydex core, split along Clean Architecture boundaries:
/// - `KeydexDomain`: pure model and business rules (depends on Foundation only).
/// - `KeydexInfrastructure`: adapters to macOS (Accessibility, AppKit, workspace).
let package = Package(
    name: "KeydexCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "KeydexDomain", targets: ["KeydexDomain"]),
        .library(name: "KeydexInfrastructure", targets: ["KeydexInfrastructure"]),
        .executable(name: "keydex-dump", targets: ["KeydexDump"]),
    ],
    targets: [
        .target(name: "KeydexDomain"),
        .target(name: "KeydexInfrastructure", dependencies: ["KeydexDomain"]),
        // Developer tool: prints what Keydex reads from an app (needs the terminal to have
        // the Accessibility permission). Not shipped in the app.
        .executableTarget(name: "KeydexDump", dependencies: ["KeydexDomain", "KeydexInfrastructure"]),
        .testTarget(name: "KeydexDomainTests", dependencies: ["KeydexDomain"]),
        .testTarget(name: "KeydexInfrastructureTests", dependencies: ["KeydexInfrastructure"]),
    ]
)
