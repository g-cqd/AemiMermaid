import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

@Suite("The cell backend draws only what a terminal can be trusted with")
struct TextRendererTests {
    private func render(_ source: String, ascii: Bool = false, width: Int? = nil) throws -> [String] {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        _ = MermaidLayout.lay(parse.result, maxWidth: width, into: &scene)
        return try #require(TextRenderer(ascii: ascii).text(scene))
    }

    @Test func `a chain, drawn in full`() throws {
        let lines = try render("flowchart TD\n  A --> B")
        #expect(lines == ["┌───┐", "│ A │", "└─┬─┘", "  │", "  ▼", "┌───┐", "│ B │", "└───┘"])
    }

    @Test func `the same chart in ASCII`() throws {
        let lines = try render("flowchart TD\n  A --> B", ascii: true)
        #expect(lines == ["+---+", "| A |", "+-+-+", "  |", "  v", "+---+", "| B |", "+---+"])
    }

    @Test func `ASCII mode holds only ASCII for every diagram of the corpus`() throws {
        for source in DiagramCorpus.all {
            #expect(
                try render(source, ascii: true).allSatisfy { $0.unicodeScalars.allSatisfy { $0.value < 0x80 } },
                "\(source.prefix(40))"
            )
        }
    }

    @Test func `no control, no escape and no bidirectional control in any output`() throws {
        let hostile =
            "flowchart TD\n  A[\"\u{1B}[31mred\u{1B}[0m \u{202E}evil\u{202C} \u{85}\"] --> B[\"\u{07}bell \u{9B}2J\"]\n  B -->|\"\u{1B}]0;t\u{07}\"| C"
        for ascii in [false, true] {
            for line in try render(hostile, ascii: ascii) {
                #expect(
                    line.unicodeScalars.allSatisfy {
                        $0.value >= 0x20 && $0.value != 0x7F && !(0x80 ... 0x9F).contains($0.value)
                            && !(0x202A ... 0x202E).contains($0.value)
                    }
                )
            }
        }
    }

    @Test func `a scene that was not made by the layout is cleaned again`() throws {
        var scene = DiagramScene()
        scene.width = 30
        scene.height = 3
        let text = scene.addLabel(Array("a\u{1B}[2Jb\u{202E}c\u{0}d".utf8)[...])
        scene.shapes.append(
            SceneShape(kind: .rectangle, role: .node, x: 0, y: 0, width: 30, height: 3, text: text, order: 0)
        )
        let lines = try #require(TextRenderer().text(scene))
        #expect(lines.joined().unicodeScalars.allSatisfy { $0.value >= 0x20 && $0.value != 0x1B && $0.value != 0x202E })
    }

    @Test func `wide characters take two cells and keep every row within the scene`() throws {
        let source = "flowchart TD\n  A[日本語のラベル] --> B[Ünï 🙂 text]"
        let parse = MermaidParse.parse(Array(source.utf8))
        guard case .flowchart(let diagram) = parse.result else {
            Issue.record("expected a flowchart")
            return
        }
        var scene = DiagramScene()
        _ = FlowLayout.lay(diagram, into: &scene)
        let renderer = TextRenderer()
        for line in try #require(renderer.text(scene)) {
            #expect(renderer.metrics.width(of: ArraySlice(line.utf8)) <= Int(scene.width), "\(line)")
        }
    }

    @Test(arguments: DiagramCorpus.all)
    func `every row of every diagram is within the scene's width`(source: String) throws {
        let renderer = TextRenderer()
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        if case .refused = parse.result { return }
        _ = MermaidLayout.lay(parse.result, into: &scene)
        for line in try #require(renderer.text(scene)) {
            #expect(renderer.metrics.width(of: ArraySlice(line.utf8)) <= Int(scene.width))
        }
    }

    @Test func `a scene over the cell limit is not drawn`() {
        var scene = DiagramScene()
        scene.width = 5000
        scene.height = 5000
        #expect(TextRenderer(maxCells: 1_000_000).rows(scene) == nil)
    }
}
