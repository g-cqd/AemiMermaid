import AemiHMMMLCore
import AemiYAML
import Testing

@testable import AemiMermaidSyntax

/// The `---` head before a diagram's header, located by AemiHMMML's front matter rules and read as YAML.
@Suite("A diagram's head is read")
struct MermaidHeadTests {
    private func parse(_ source: String) -> MermaidParse { MermaidParse.parse(Array(source.utf8)) }

    @Test func `the title and the configuration are read, and the diagram after them`() throws {
        let parse = parse(
            "---\ntitle: Checkout\nconfig:\n  theme: forest\n  flowchart:\n    curve: basis\n---\nflowchart LR\nA-->B"
        )
        let head = try #require(parse.head)
        #expect(head.title == "Checkout")
        #expect(head.config?["theme"]?.string == "forest")
        #expect(head.config?["flowchart"]?["curve"]?.string == "basis")
        #expect(head.diagnostics.isEmpty)
        guard case .flowchart(let diagram) = parse.result else {
            Issue.record("not a flowchart: \(parse.result)")
            return
        }
        #expect(diagram.edges.count == 1)
    }

    @Test func `lines are counted from the top of the source, head included`() throws {
        let source = "---\ntitle: x\n---\nflowchart TD\nA-->B"
        let header = try #require(MermaidHeader.find(in: Array(source.utf8)))
        #expect(header.firstLine == 5)
        #expect(header.restOffset == source.utf8.count - "A-->B".utf8.count)
    }

    @Test(arguments: [
        "\n\n---\ntitle: T\n---\npie\n\"a\": 1",  // blank lines first, as AemiMermaid allowed before
        "  ---\n  title: T\n  ---\npie\n\"a\": 1",  // indented, closed at the same indent (Mermaid's \1)
        "---\r\ntitle: T\r\n---\r\npie\r\n\"a\": 1",
        "---\ntitle: T\n...\npie\n\"a\": 1"
    ])
    func `heads written in each accepted way are read`(source: String) {
        let parse = parse(source)
        #expect(parse.head?.title == "T", "\(source.debugDescription)")
        guard case .pie = parse.result else {
            Issue.record("not a pie: \(parse.result)")
            return
        }
    }

    @Test func `a broken head is reported, not a refusal`() {
        let parse = parse("---\ntitle: Use this: when\nconfig: [unclosed\n---\nflowchart TD\nA-->B")
        #expect(parse.head?.title == "Use this: when")
        #expect(parse.head?.diagnostics.isEmpty == false)
        guard case .flowchart = parse.result else {
            Issue.record("refused: \(parse.result)")
            return
        }
    }

    @Test func `no head, no reading`() {
        #expect(parse("flowchart TD\nA-->B").head == nil)
        // An opening fence that nothing closes is not a head; the line is not a header either.
        #expect(parse("---\ntitle: x\nflowchart TD\nA-->B").head == nil)
    }
}
