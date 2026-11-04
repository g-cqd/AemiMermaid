import Testing

@testable import AemiMermaidSyntax

/// The accepted subset of flowchart syntax (Appendix B of the plan), line by line.
@Suite("A flowchart is read as the subset says")
struct FlowchartParserTests {
    private func flowchart(_ source: String, limits: MermaidLimits = .default) -> (
        FlowchartDiagram, MermaidDiagnostics
    )? {
        let parse = MermaidParse.parse(Array(source.utf8), limits: limits)
        guard case .flowchart(let diagram) = parse.result else { return nil }
        return (diagram, parse.diagnostics)
    }

    private func label(_ diagram: FlowchartDiagram, _ node: Int) -> String {
        diagram.labels.string(diagram.nodes[node].label)
    }

    @Test(arguments: [
        ("TD", FlowDirection.topDown), ("TB", .topDown), ("BT", .bottomUp), ("LR", .leftRight), ("RL", .rightLeft)
    ])
    func `directions`(name: String, direction: FlowDirection) {
        #expect(flowchart("flowchart \(name)\nA-->B")?.0.direction == direction)
        #expect(flowchart("graph \(name)\nA-->B")?.0.direction == direction)
    }

    @Test func `a header with no direction is top down, and an unknown one is refused`() {
        #expect(flowchart("graph\nA-->B")?.0.direction == .topDown)
        #expect(flowchart("pie\n\"a\": 1") == nil)
        if case .refused(.unknownKind) = MermaidParse.parse(Array("graph XX\nA-->B".utf8)).result {
        } else {
            Issue.record("graph XX is not a direction")
        }
    }

    @Test(arguments: [
        ("A[t]", FlowShape.rectangle), ("A(t)", .rounded), ("A([t])", .stadium), ("A[[t]]", .subroutine),
        ("A[(t)]", .cylinder), ("A((t))", .circle),
        ("A(((t)))", .doubleCircle), ("A{t}", .diamond), ("A{{t}}", .hexagon), ("A[/t/]", .parallelogram),
        ("A[\\t\\]", .parallelogramAlt),
        ("A[/t\\]", .trapezoid), ("A[\\t/]", .trapezoidAlt), ("A>t]", .asymmetric)
    ])
    func `shapes`(source: String, shape: FlowShape) throws {
        let (diagram, _) = try #require(flowchart("flowchart TD\n  \(source)"))
        #expect(diagram.nodes.count == 1 && diagram.nodes[0].shape == shape && label(diagram, 0) == "t")
    }

    @Test func `a quoted label may hold the characters that close a shape`() throws {
        let (diagram, _) = try #require(flowchart("flowchart TD\n  A[\"a ] b (c)\"] --> B(\"x)y\")"))
        #expect(label(diagram, 0) == "a ] b (c)" && label(diagram, 1) == "x)y")
    }

    @Test(arguments: [
        ("A --> B", FlowLineStyle.solid, FlowEnd.arrow, FlowEnd.none, 1), ("A --- B", .solid, .none, .none, 1),
        ("A -.-> B", .dotted, .arrow, .none, 1),
        ("A -.- B", .dotted, .none, .none, 1), ("A ==> B", .thick, .arrow, .none, 1),
        ("A === B", .thick, .none, .none, 1), ("A --o B", .solid, .circle, .none, 1),
        ("A --x B", .solid, .cross, .none, 1), ("A <--> B", .solid, .arrow, .arrow, 1),
        ("A o--o B", .solid, .circle, .circle, 1),
        ("A x--x B", .solid, .cross, .cross, 1), ("A ~~~ B", .invisible, .none, .none, 1),
        ("A ----> B", .solid, .arrow, .none, 3)
    ])
    func `links`(source: String, line: FlowLineStyle, head: FlowEnd, tail: FlowEnd, length: Int) throws {
        let (diagram, diagnostics) = try #require(flowchart("flowchart TD\n  \(source)"))
        #expect(diagnostics.isEmpty && diagram.edges.count == 1)
        let edge = diagram.edges[0]
        #expect(edge.line == line && edge.head == head && edge.tail == tail && Int(edge.length) == length, "\(source)")
        #expect(edge.from == 0 && edge.to == 1)
    }

    @Test func `edge labels in both forms`() throws {
        let (diagram, _) = try #require(
            flowchart("flowchart TD\n  A -->|yes| B\n  B -- no --> C\n  C == maybe ==> D\n  D -. dotted .-> E")
        )
        #expect(diagram.edges.map { diagram.labels.string($0.label) } == ["yes", "no", "maybe", "dotted"])
        #expect(diagram.edges.map(\.head) == [.arrow, .arrow, .arrow, .arrow])
        #expect(diagram.edges.map(\.line) == [.solid, .solid, .thick, .dotted])
    }

    @Test func `chains and groups`() throws {
        let (diagram, _) = try #require(flowchart("flowchart TD\n  A --> B --> C\n  D & E --> F & G"))
        #expect(diagram.nodes.count == 7)
        #expect(diagram.edges.map { [$0.from, $0.to] } == [[0, 1], [1, 2], [3, 5], [3, 6], [4, 5], [4, 6]])
    }

    @Test func `statements separated by semicolons, comments, and blank lines`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart("%% a comment\nflowchart TD\n\n  A --> B; B --> C %% trailing\n  %% another\n")
        )
        #expect(diagnostics.isEmpty && diagram.edges.count == 2)
    }

    @Test func `front matter before the header is skipped`() {
        #expect(flowchart("---\ntitle: x\n---\nflowchart TD\nA-->B")?.0.edges.count == 1)
    }

    @Test func `a node defined again keeps its place and takes the new text`() throws {
        let (diagram, _) = try #require(flowchart("flowchart TD\n  A --> B\n  A[First]\n  A(Second)"))
        #expect(diagram.nodes.count == 2 && label(diagram, 0) == "Second" && diagram.nodes[0].shape == .rounded)
    }

    @Test func `hyphens inside an id are not arrows`() throws {
        let (diagram, _) = try #require(flowchart("flowchart TD\n  my-node --> other-node"))
        #expect(diagram.nodes.map { diagram.labels.string($0.id) } == ["my-node", "other-node"])
    }

    @Test func `subgraphs hold the nodes first written inside them, and nest`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart("flowchart TD\n  subgraph one [First]\n    A\n    subgraph two\n      B\n    end\n  end\n  C")
        )
        #expect(diagnostics.isEmpty && diagram.clusters.count == 2)
        #expect(
            diagram.labels.string(diagram.clusters[0].title) == "First"
                && diagram.labels.string(diagram.clusters[1].title) == "two"
        )
        #expect(diagram.clusters[1].parent == 0 && diagram.nodes.map(\.cluster) == [0, 1, -1])
    }

    @Test func `unsupported lines are dropped with their line number and the rest stands`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart("flowchart TD\n  A --> B\n  this is $$ not valid\n  B --> C")
        )
        #expect(diagram.edges.count == 2)
        #expect(diagnostics.entries.contains { $0.kind == .unsupportedLine && $0.line == 3 })
    }

    @Test func `styling lines are read and ignored`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart(
                "flowchart TD\n  A --> B\n  classDef c fill:#f9f\n  class A c\n  style B fill:#fff\n  linkStyle 0 stroke:red\n  click A callback\n  A:::c --> B"
            )
        )
        #expect(diagnostics.isEmpty && diagram.edges.count == 2)
    }

    @Test func `a stray end and an unclosed subgraph are reported`() throws {
        #expect(try #require(flowchart("flowchart TD\n  A\n  end")).1.contains(.strayEnd))
        #expect(try #require(flowchart("flowchart TD\n  subgraph s\n  A")).1.contains(.unclosedBlock))
    }

    @Test func `a source with no node is refused as empty`() {
        if case .refused(.empty) = MermaidParse.parse(Array("flowchart TD\n".utf8)).result {
        } else {
            Issue.record("expected an empty refusal")
        }
    }
}
