# AemiMermaid

Mermaid diagram parser, layout engine, and terminal/SVG renderers written in Swift 6. Takes UTF-8 source bytes and produces a flat, semantic `DiagramScene` with bounded time and memory and total, non-failing parsing.

```swift
import AemiMermaidLayout
import AemiMermaidScene
import AemiMermaidSyntax
import AemiMermaidText

let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
var scene = DiagramScene()
if case .drawn = MermaidLayout.lay(parse, into: &scene, limits: .terminal) {
    let text = MermaidTextRenderer.render(scene)
    print(text)
}
```

## Requirements

- Swift 6.4+ (Swift 6 language mode)
- macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+, or Linux

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/g-cqd/AemiMermaid.git", branch: "main")
]
```

## Products

| Product | Description |
| --- | --- |
| `AemiMermaidSyntax` | Flowchart, sequence, and front-matter parser with explicit limits and diagnostics |
| `AemiMermaidScene` | Flat display list with semantic roles and text metrics |
| `AemiMermaidLayout` | Layered flowchart and sequence diagram layout |
| `AemiMermaidText` | Unicode box-drawing and ASCII terminal renderer |
| `AemiMermaidSVG` | SVG renderer |
| `aemi-mermaid` | CLI: `aemi-mermaid [--ascii] [--width N] [file]` |

## Documentation

- [Architecture Decisions](docs/adr/)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

## License

[MIT](LICENSE)
