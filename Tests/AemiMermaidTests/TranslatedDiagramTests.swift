import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

/// State, class and entity diagrams are read as flowcharts (ADR 0005), and a pie chart as bars.
@Suite("Diagrams written as flowcharts, and pie charts")
struct TranslatedDiagramTests {
    private func flowchart(_ source: String) -> (FlowchartDiagram, MermaidDiagnostics)? {
        let parse = MermaidParse.parse(Array(source.utf8))
        guard case .flowchart(let diagram) = parse.result else { return nil }
        return (diagram, parse.diagnostics)
    }

    private func texts(_ diagram: FlowchartDiagram) -> [String] {
        diagram.nodes.map { diagram.labels.string($0.label) }
    }

    private func rows(_ source: String, width: Int? = 80) throws -> [String] {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        _ = MermaidLayout.lay(parse.result, maxWidth: width, into: &scene)
        return try #require(TextRenderer().text(scene))
    }

    @Test func `states and transitions, start and end nodes, and transition text`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart("stateDiagram-v2\n  [*] --> Still\n  Still --> Moving : push\n  Moving --> [*]")
        )
        #expect(diagnostics.isEmpty && diagram.nodes.count == 4 && diagram.edges.count == 3)
        #expect(diagram.labels.string(diagram.edges[1].label) == "push")
        #expect(diagram.nodes[0].shape == .circle && diagram.nodes[3].shape == .doubleCircle)
    }

    @Test func `a composite state is a subgraph, a described state has its text, a choice is a diamond`() throws {
        let (diagram, _) = try #require(
            flowchart(
                "stateDiagram-v2\n  state \"Long name\" as L\n  state Group {\n    [*] --> Inner\n  }\n  Inner : doing things\n  state pick <<choice>>\n  L --> pick"
            )
        )
        #expect(diagram.clusters.count == 1 && diagram.labels.string(diagram.clusters[0].id) == "Group")
        #expect(texts(diagram).contains("Inner\ndoing things"))
        #expect(diagram.nodes.contains { $0.shape == .diamond })
    }

    @Test func `the line numbers of a translated source are the ones the author wrote`() throws {
        let parse = MermaidParse.parse(Array("stateDiagram-v2\n  A --> B\n  this is not valid at all\n  B --> C".utf8))
        #expect(parse.diagnostics.entries.contains { $0.kind == .unsupportedLine && $0.line == 3 })
    }

    @Test func `classes with members, annotations, relations and their cardinalities`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart(
                "classDiagram\n  class Shape {\n    <<interface>>\n    +area() double\n  }\n  Shape <|-- Circle\n  Circle : +radius\n  Owner \"1\" --> \"*\" Shape : owns\n  A ..> B"
            )
        )
        #expect(diagnostics.isEmpty)
        let shape = try #require(diagram.nodes.firstIndex { diagram.labels.string($0.id) == "Shape" })
        #expect(diagram.labels.string(diagram.nodes[shape].label).contains("«interface»"))
        #expect(diagram.labels.string(diagram.nodes[shape].label).contains("+area() double"))
        #expect(diagram.edges.count == 3)
        #expect(diagram.edges.contains { diagram.labels.string($0.label) == "1 owns *" })
        let inheritance = diagram.edges[0]
        #expect(
            diagram.labels.string(diagram.nodes[Int(inheritance.from)].id) == "Shape" && inheritance.tail == .arrow,
            "the parent is on top, with the arrow"
        )
        #expect(diagram.edges[2].line == .dotted)
    }

    @Test func `entities with attributes and relationships with their cardinalities`() throws {
        let (diagram, diagnostics) = try #require(
            flowchart("erDiagram\n  CUSTOMER ||--o{ ORDER : places\n  CUSTOMER {\n    string name PK\n  }")
        )
        #expect(diagnostics.isEmpty && diagram.direction == .leftRight)
        #expect(diagram.labels.string(diagram.edges[0].label) == "places [1 : 0..*]")
        #expect(diagram.labels.string(diagram.nodes[0].label).contains("string name PK"))
    }

    @Test func `a non-identifying relationship is dotted`() throws {
        let (diagram, _) = try #require(flowchart("erDiagram\n  A }|..|{ B : uses"))
        #expect(
            diagram.edges[0].line == .dotted && diagram.labels.string(diagram.edges[0].label) == "uses [1..* : 1..*]"
        )
    }

    @Test func `text that could break out of the flowchart it is written as stays a label`() throws {
        let hostile = "classDiagram\n  class A {\n    +x\"] --> Evil[\"pwned\n  }\n  A --> B"
        let (diagram, _) = try #require(flowchart(hostile))
        #expect(!texts(diagram).contains("Evil") && diagram.edges.count == 1)
    }

    @Test func `a pie chart is bars with their shares`() throws {
        let lines = try rows("pie showData title Pets\n  \"Dogs\" : 386\n  \"Cats\" : 85\n  \"Rats\" : 15")
        #expect(lines[0] == "Pets")
        #expect(lines[2].hasPrefix("Dogs") && lines[2].contains("79.4% (386)") && lines[4].contains("3.1% (15)"))
        #expect(lines[2].count(where: { $0 == "█" }) > lines[3].count(where: { $0 == "█" }))
    }

    @Test func `a pie chart drops a value that is not a positive number, and is refused when empty`() throws {
        let parse = MermaidParse.parse(Array("pie\n  \"A\" : 5\n  \"B\" : -3\n  \"C\" : nan\n  \"D\" : 1e999".utf8))
        guard case .pie(let diagram) = parse.result else {
            Issue.record("expected a pie")
            return
        }
        #expect(diagram.slices.count == 1 && parse.diagnostics.entries.count == 3)
        if case .refused(.empty) = MermaidParse.parse(Array("pie\n  title Nothing".utf8)).result {
        } else {
            Issue.record("expected empty")
        }
    }

    @Test func `a pie chart fits the width or is refused for it`() throws {
        let parse = MermaidParse.parse(Array("pie\n  \"A very long label indeed\" : 5\n  \"B\" : 3".utf8))
        var scene = DiagramScene()
        #expect(MermaidLayout.lay(parse.result, maxWidth: 24, into: &scene) != .source(.empty))
        let outcome = MermaidLayout.lay(parse.result, maxWidth: 30, into: &scene)
        if case .drawn(let width, _) = outcome { #expect(width <= 30) }
    }
}
