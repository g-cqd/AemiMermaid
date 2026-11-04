import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

@Suite("A sequence diagram is laid out in cells")
struct SequenceLayoutTests {
    private func scene(_ source: String) throws -> DiagramScene {
        guard case .sequence(let diagram) = MermaidParse.parse(Array(source.utf8), limits: .terminal).result else {
            Issue.record("not a sequence diagram")
            return DiagramScene()
        }
        var scene = DiagramScene()
        let outcome = SequenceLayout.lay(diagram, into: &scene)
        guard case .drawn = outcome else {
            Issue.record("not drawn: \(outcome)")
            return scene
        }
        return scene
    }

    @Test(arguments: DiagramCorpus.sequences)
    func `the corpus obeys the geometric rules`(source: String) throws {
        let scene = try scene(source)
        #expect(
            SceneLinter.problems(scene, checkEdges: false).isEmpty,
            "\(SceneLinter.problems(scene, checkEdges: false))"
        )
    }

    @Test func `participants are columns in the order they appear and messages go down in order`() throws {
        let scene = try scene("sequenceDiagram\n  A->>B: one\n  B->>C: two\n  C->>A: three")
        let boxes = scene.shapes.filter { $0.role == .node }
        #expect(boxes.count == 3 && boxes.map(\.x) == boxes.map(\.x).sorted() && Set(boxes.map(\.y)).count == 1)
        let rows = scene.paths.filter { $0.role == .edge }.map { scene.points[Int($0.first)].y }
        #expect(rows == rows.sorted() && Set(rows).count == 3)
    }

    @Test func `a long message widens the gap between its columns`() throws {
        let narrow = try scene("sequenceDiagram\n  A->>B: hi")
        let wide = try scene("sequenceDiagram\n  A->>B: a message with quite a lot of text in it")
        #expect(wide.width > narrow.width + 30)
    }

    @Test func `dashed replies, activation bars and notes are drawn`() throws {
        let scene = try scene("sequenceDiagram\n  A->>+B: go\n  Note right of B: busy\n  B-->>-A: done")
        #expect(scene.paths.contains { $0.stroke == .dashed && $0.role == .edge })
        #expect(scene.paths.contains { $0.role == .activation && $0.stroke == .thick })
        #expect(scene.shapes.contains { $0.kind == .note })
    }

    @Test func `a fragment is a frame around its rows`() throws {
        let scene = try scene("sequenceDiagram\n  loop daily\n    A->>B: ping\n  end")
        let frame = try #require(scene.shapes.first { $0.kind == .frame })
        #expect(scene.string(frame.text) == "loop [daily]")
        let message = try #require(scene.paths.first { $0.role == .edge })
        let y = scene.points[Int(message.first)].y
        #expect(y > frame.y && y < frame.y + frame.height - 1)
    }

    @Test func `a note to the left of the first column makes room`() throws {
        let scene = try scene("sequenceDiagram\n  A->>B: x\n  Note left of A: a long note on the left")
        #expect(SceneLinter.problems(scene, checkEdges: false).isEmpty)
    }
}
