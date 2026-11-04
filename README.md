# AemiMermaid

Mermaid diagrams for terminals and windows, read and laid out by our own code: UTF-8 bytes in, a flat scene out, bounded in time and memory, never failing. No other package is
needed to read, lay out or draw a diagram; the renderers that exist (mermaid.js, `mermaid-ascii`, `mermaid-swift` and the others in the survey) are oracles run from scripts.

```
flowchart LR
  A[Parse] --> B[Layout] --> C[Draw]
  B -->|too wide| D{{Wrap}}
  D --> B
```

| Target | Does | Imports |
|---|---|---|
| `AemiMermaidSyntax` | reads a source into a flowchart or a sequence diagram; limits, diagnostics, label cleaning | Aemi (`AemiInterner`) |
| `AemiMermaidScene` | the display list a layout produces, roles instead of colours, the text metrics | nothing |
| `AemiMermaidLayout` | flowcharts (layered, in cells) and sequence diagrams | Syntax, Scene |
| `AemiMermaidText` | draws a scene in character cells: box characters or ASCII | Scene |
| `aemi-mermaid` | `aemi-mermaid [--ascii] [--width N] [file]` draws a diagram in the terminal | all |

```swift
let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
var scene = DiagramScene()
if case .flowchart(let diagram) = parse.result,
    case .drawn = FlowLayout.lay(diagram, maxWidth: 80, into: &scene),
    let lines = TextRenderer().text(scene)
{
    print(lines.joined(separator: "\n"))
}
```

What it accepts (flowchart: the headers, shapes, links, labels, chains, groups and subgraphs of the plan's Appendix B; sequence: participants, actors, the eight arrows, activations,
notes, fragments, autonumber, title) and how it degrades are in `docs/adr/0001-the-engine.md`. A line it cannot read is dropped with a diagnostic naming it; a diagram it cannot
draw within the limits is refused with the figure, and the host shows the source.

Not done yet: state, class, ER, pie and Gantt diagrams; the vector backend and the SwiftUI view; the Quick Look extension (ask's roadmap 0199 to 0201).

## Guarantees, each with a test

- **No recursion, linear time.** Nesting is a counter or a stack with a limit; the growth test fits instructions against 100 to 800 nodes for chains, trees, sparse graphs and clusters
  and fails when a doubling costs more than three times; the corpus runs on a 512 KiB stack.
- **Nothing a terminal could act on.** Labels are cleaned when read (controls, C1, bidirectional controls, byte order marks, invalid UTF-8) and the cell backend cleans again; a
  fuzz test checks every row of mutated diagrams.
- **Bounded.** `MermaidLimits` caps source, nodes, edges, labels, nesting, messages and virtual nodes; each limit has a test that hits it.
- **Within the width.** A width sweep draws every corpus diagram at every width from 1 to 120, wider than it never, and the same whatever width was asked before.

## Developing

`swift test` (the allocation and growth tests are meaningful in debug and release alike). Style is Aemi's (`.swift-format`, `.swiftlint.yml`); one primary type per file, under 250 lines.
