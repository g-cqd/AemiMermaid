// swift-tools-version: 6.4
import PackageDescription

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
    revision: "04cfb910446f446476c0c853317931f3444b1323"
)

let hmmmlDependency: Package.Dependency = .package(
    url: "https://github.com/g-cqd/AemiHMMML.git",
    revision: "37aa42a4a121ad2e50177d5310794a44d46bb995"
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
    dependencies: [aemiDependency, hmmmlDependency],
    targets: [
        .target(
            name: "AemiMermaidSyntax",
            dependencies: [
                "AemiMermaidScene",
                .product(name: "AemiInterner", package: "aemi"),
                .product(name: "AemiFrontMatter", package: "AemiHMMML"),
                .product(name: "AemiHMMMLCore", package: "AemiHMMML"),
                .product(name: "AemiYAML", package: "AemiHMMML")
            ],
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
                .product(name: "AemiTestKit", package: "aemi"),
                .product(name: "AemiHMMMLCore", package: "AemiHMMML"),
                .product(name: "AemiYAML", package: "AemiHMMML")
            ],
            swiftSettings: strictSettings
        )
    ]
)
