import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

/// Every diagram at every width from 1 to 120 (ADR 0004): drawn within the width, or refused for it; never wider, never different for the widths asked before.
@Suite("A width is a limit, and the result does not depend on earlier widths")
struct WidthSweepTests {
    @Test(arguments: DiagramCorpus.all)
    func `drawn within the width or shown as source, at every width`(source: String) throws {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var reused = DiagramScene()
        let renderer = TextRenderer()
        for width in 1 ... 120 {
            var fresh = DiagramScene()
            if case .refused = parse.result { return }
            let outcomeFresh = MermaidLayout.lay(parse.result, maxWidth: width, into: &fresh)
            let outcomeReused = MermaidLayout.lay(parse.result, maxWidth: width, into: &reused)
            #expect(outcomeFresh == outcomeReused && fresh == reused, "width \(width)")
            switch outcomeFresh {
                case .drawn(let drawnWidth, _):
                    #expect(drawnWidth <= width, "width \(width) drew \(drawnWidth)")
                    let lines = try #require(renderer.text(fresh))
                    #expect(
                        lines.allSatisfy { renderer.metrics.width(of: ArraySlice($0.utf8)) <= width },
                        "a row is wider than \(width)"
                    )
                case .source(.tooWide(let needed, let available)): #expect(needed > available && available == width)
                case .source: Issue.record("width \(width): \(outcomeFresh)")
            }
        }
    }

    @Test func `a left to right chart that is too wide turns top down`() throws {
        let parse = MermaidParse.parse(
            Array("flowchart LR\n  A[One] --> B[Two] --> C[Three] --> D[Four] --> E[Five]".utf8)
        )
        guard case .flowchart(let diagram) = parse.result else {
            Issue.record("expected a flowchart")
            return
        }
        var wide = DiagramScene()
        var narrow = DiagramScene()
        _ = FlowLayout.lay(diagram, maxWidth: 200, into: &wide)
        _ = FlowLayout.lay(diagram, maxWidth: 20, into: &narrow)
        #expect(wide.width > 40 && narrow.width <= 20 && narrow.height > wide.height)
    }

    @Test func `long labels are wrapped to fit`() throws {
        let parse = MermaidParse.parse(
            Array("flowchart TD\n  A[This label is much too long for a narrow terminal window] --> B".utf8)
        )
        guard case .flowchart(let diagram) = parse.result else {
            Issue.record("expected a flowchart")
            return
        }
        var scene = DiagramScene()
        let outcome = FlowLayout.lay(diagram, maxWidth: 30, into: &scene)
        guard case .drawn(let width, _) = outcome else {
            Issue.record("expected the label to wrap: \(outcome)")
            return
        }
        #expect(width <= 30 && scene.string(scene.shapes[0].text).contains("\n"))
    }
}
