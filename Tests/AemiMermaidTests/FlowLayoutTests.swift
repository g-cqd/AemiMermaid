import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

@Suite("A flowchart is laid out in cells")
struct FlowLayoutTests {
    static func diagram(_ source: String) -> FlowchartDiagram? {
        guard case .flowchart(let diagram) = MermaidParse.parse(Array(source.utf8), limits: .terminal).result else {
            return nil
        }
        return diagram
    }

    private func lay(_ source: String, width: Int? = nil) -> (DiagramScene, MermaidLayoutOutcome)? {
        guard let diagram = Self.diagram(source) else { return nil }
        var scene = DiagramScene()
        let outcome = FlowLayout.lay(diagram, maxWidth: width, into: &scene)
        return (scene, outcome)
    }

    @Test(arguments: DiagramCorpus.flowcharts)
    func `every diagram in the corpus is laid out, and the scene obeys the geometric rules`(source: String) throws {
        let (scene, outcome) = try #require(lay(source))
        guard case .drawn(let width, let height) = outcome else {
            Issue.record("not drawn: \(outcome)")
            return
        }
        #expect(Int(scene.width) == width && Int(scene.height) == height)
        #expect(SceneLinter.problems(scene).isEmpty, "\(SceneLinter.problems(scene))")
    }

    @Test(arguments: DiagramCorpus.flowcharts)
    func `the same input gives the same scene, into a fresh scene or a reused one`(source: String) throws {
        let diagram = try #require(Self.diagram(source))
        var first = DiagramScene()
        var second = DiagramScene()
        _ = FlowLayout.lay(diagram, into: &first)
        _ = FlowLayout.lay(try #require(Self.diagram("flowchart TD\nX-->Y")), into: &second)
        _ = FlowLayout.lay(diagram, into: &second)
        #expect(first == second)
    }

    @Test func `a chain goes down one rank at a time`() throws {
        let (scene, _) = try #require(lay("flowchart TD\n  A --> B --> C"))
        let ys = scene.shapes.map(\.y)
        #expect(ys == ys.sorted() && Set(ys).count == 3)
        #expect(Set(scene.shapes.map(\.x)).count == 1, "a chain is straight")
    }

    @Test func `left to right puts ranks along the row`() throws {
        let (scene, _) = try #require(lay("flowchart LR\n  A --> B --> C"))
        let xs = scene.shapes.map(\.x)
        #expect(xs == xs.sorted() && Set(xs).count == 3 && Set(scene.shapes.map(\.y)).count == 1)
    }

    @Test func `bottom up and right to left flip the order`() throws {
        let (up, _) = try #require(lay("flowchart BT\n  A --> B"))
        #expect(up.shapes[0].y > up.shapes[1].y)
        let (left, _) = try #require(lay("flowchart RL\n  A --> B"))
        #expect(left.shapes[0].x > left.shapes[1].x)
    }

    @Test func `a cycle is laid out, with the edge that closes it turned round`() throws {
        let (scene, outcome) = try #require(lay("flowchart TD\n  A --> B --> C --> A"))
        #expect(outcome != .source(.empty) && SceneLinter.problems(scene).isEmpty)
        #expect(scene.paths.count == 3)
    }

    @Test func `an edge that skips ranks goes round the nodes between`() throws {
        let (scene, _) = try #require(lay("flowchart TD\n  A --> B --> C --> D\n  A --> D"))
        #expect(SceneLinter.problems(scene).isEmpty)
    }

    @Test func `clusters are frames behind their nodes`() throws {
        let (scene, _) = try #require(lay("flowchart TD\n  subgraph s [Group]\n    A --> B\n  end\n  B --> C"))
        let frame = try #require(scene.shapes.first { $0.kind == .frame })
        #expect(scene.shapes.first?.kind == .frame)
        for node in scene.shapes where node.role == .node {
            if scene.string(node.text) == "C" { continue }
            #expect(
                node.x > frame.x && node.x + node.width < frame.x + frame.width && node.y > frame.y
                    && node.y + node.height < frame.y + frame.height
            )
        }
    }

    @Test func `edge labels sit inside the scene and do not meet`() throws {
        let (scene, _) = try #require(lay("flowchart TD\n  A -->|one| B\n  A -->|two| C\n  A -->|three| D"))
        #expect(scene.texts.count == 3 && SceneLinter.problems(scene).isEmpty)
        #expect(Set(scene.texts.map { [$0.x, $0.y] }).count == 3)
    }

    @Test func `too many virtual nodes refuse the layout with the figure`() throws {
        let diagram = try #require(
            Self.diagram("flowchart TD\n  A --> B\n  B --> C\n  C --> D\n  D --> E\n  A --> E\n  A --> E")
        )
        var scene = DiagramScene()
        let outcome = FlowLayout.lay(diagram, limits: MermaidLimits(maxVirtualNodes: 5), into: &scene)
        #expect(outcome == .source(.virtualNodes(6)))
    }
}
