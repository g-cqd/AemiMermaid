// swift-tools-version: 6.4
import PackageDescription

// Swift 6 language mode, warnings as errors, and the upcoming features that tighten existentials and imports. No unsafe flags, so the library can be
// consumed through a version-pinned requirement. Same strictness as AemiMarkdown.
let strictSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .strictMemorySafety()
]

let aemiDependency: Package.Dependency = .package(
    url: "https://github.com/Aemi-Studio/aemi.git",
    revision: "528804643f693104656a02449cfa59131556f616"
)

let package = Package(
    name: "AemiMermaid",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)],
    products: [
        .library(name: "AemiMermaidSyntax", targets: ["AemiMermaidSyntax"]),
        .library(name: "AemiMermaidScene", targets: ["AemiMermaidScene"]),
        .library(name: "AemiMermaidLayout", targets: ["AemiMermaidLayout"]),
        .library(name: "AemiMermaidText", targets: ["AemiMermaidText"]),
        .library(name: "AemiMermaidSVG", targets: ["AemiMermaidSVG"]),
        .executable(name: "aemi-mermaid", targets: ["aemi-mermaid"])
    ],
    dependencies: [aemiDependency],
    targets: [
        .target(
            name: "AemiMermaidSyntax",
            dependencies: ["AemiMermaidScene", .product(name: "AemiInterner", package: "aemi")],
            swiftSettings: strictSettings
        ),
        .target(name: "AemiMermaidScene", swiftSettings: strictSettings),
        .target(
            name: "AemiMermaidLayout",
            dependencies: ["AemiMermaidSyntax", "AemiMermaidScene"],
            swiftSettings: strictSettings
        ),
        .target(
            name: "AemiMermaidText",
            dependencies: ["AemiMermaidScene"],
            swiftSettings: strictSettings
        ),
        .target(
            name: "AemiMermaidSVG",
            dependencies: ["AemiMermaidScene", "AemiMermaidSyntax"],
            swiftSettings: strictSettings
        ),
        .executableTarget(
            name: "aemi-mermaid",
            dependencies: [
                "AemiMermaidSyntax", "AemiMermaidScene", "AemiMermaidLayout", "AemiMermaidText", "AemiMermaidSVG"
            ],
            swiftSettings: strictSettings
        ),
        // Alone in its process: it counts instructions, and a count is only a count of this test when no other test runs beside it.
        .testTarget(
            name: "AemiMermaidGrowthTests",
            dependencies: [
                "AemiMermaidSyntax", "AemiMermaidScene", "AemiMermaidLayout", "AemiMermaidText",
                .product(name: "AemiTestKit", package: "aemi"),
                .product(name: "AemiMetrics", package: "aemi")
            ],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "AemiMermaidTests",
            dependencies: [
                "AemiMermaidSyntax", "AemiMermaidScene", "AemiMermaidLayout", "AemiMermaidText", "AemiMermaidSVG",
                .product(name: "AemiTestKit", package: "aemi")
            ],
            swiftSettings: strictSettings
        )
    ]
)
