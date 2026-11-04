import Foundation
import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidSVG
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax

/// The vector backend draws what the cell backend draws (ADR 0006), as markup that is well formed and carries nothing a label could have put there.
@Suite("A scene as SVG")
struct SVGTests {
    /// Counts the elements of a document, or nil if it is not well-formed XML.
    private final class Elements: NSObject, XMLParserDelegate {
        var names: [String: Int] = [:]
        var attributes: [String] = []
        func parser(
            _ parser: XMLParser,
            didStartElement name: String,
            namespaceURI: String?,
            qualifiedName: String?,
            attributes attributeDict: [String: String]
        ) {
            names[name, default: 0] += 1
            attributes.append(contentsOf: attributeDict.keys)
        }
    }

    private func inspect(_ markup: String) -> Elements? {
        let delegate = Elements()
        let parser = XMLParser(data: Data(markup.utf8))
        unsafe parser.delegate = delegate
        return parser.parse() ? delegate : nil
    }

    private func svg(_ source: String, width: Int? = 100) -> String {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        _ = MermaidLayout.lay(parse.result, maxWidth: width, into: &scene)
        if case .pie(let pie) = parse.result { return PieSVG().svg(pie) }
        return SVGRenderer().svg(scene)
    }

    @Test(arguments: DiagramCorpus.all)
    func `every diagram of the corpus is well-formed SVG with a view box and no script`(source: String) throws {
        let markup = svg(source)
        let found = try #require(inspect(markup), "not well-formed: \(markup.prefix(200))")
        #expect(found.names["svg"] == 1 && markup.contains("viewBox="))
        #expect(found.names["script"] == nil && found.names["foreignObject"] == nil && found.names["image"] == nil)
        #expect(!found.attributes.contains { $0.hasPrefix("on") || $0 == "href" || $0 == "xlink:href" })
    }

    @Test func `a flowchart has a shape for each node, a line for each edge, and its text`() throws {
        let markup = svg("flowchart TD\n  A[Start] --> B{Ready?}\n  B -->|yes| C((Go))")
        let found = try #require(inspect(markup))
        #expect(found.names["polyline"] == 2 && found.names["polygon"] != nil)
        #expect(
            markup.contains(">Start<") && markup.contains(">Ready?<") && markup.contains(">yes<")
                && markup.contains(">Go<")
        )
        #expect(found.names["polygon"] ?? 0 >= 3, "a diamond and two arrowheads")
    }

    @Test func `text is escaped, and controls and bidirectional controls are dropped`() throws {
        let markup = svg("flowchart TD\n  A[\"<script>alert(1)</script> & \u{202E}evil \u{1B}[2J\"] --> B")
        let found = try #require(inspect(markup))
        #expect(found.names["script"] == nil && markup.contains("&lt;script&gt;") && markup.contains("&amp;"))
        #expect(!markup.contains("\u{202E}") && !markup.contains("\u{1B}"))
        let escaped = SVGText.escaped("a\u{0}b\u{8}c\u{FFFE}d\u{1F}e'\"")
        #expect(escaped == "abcde&#39;&quot;")
    }

    @Test func `the same scene gives the same markup`() {
        #expect(svg(DiagramCorpus.flowcharts[0]) == svg(DiagramCorpus.flowcharts[0]))
    }

    @Test func `dashed links, thick links and open links are classes of their own`() {
        let markup = svg("flowchart LR\n  A -.-> B\n  B ==> C\n  C --- D")
        #expect(markup.contains("class=\"e d\"") && markup.contains("class=\"e t\"") && markup.contains("class=\"e\""))
    }

    @Test func `a sequence diagram has lifelines, an activation bar and a note`() throws {
        let markup = svg("sequenceDiagram\n  A->>+B: go\n  Note right of B: busy\n  B-->>-A: done")
        _ = try #require(inspect(markup))
        #expect(markup.contains("class=\"u\"") && markup.contains("class=\"a\"") && markup.contains("class=\"nt\""))
    }

    @Test func `a pie chart is one sector for each slice and a legend`() throws {
        let markup = svg("pie showData title Pets\n  \"Dogs\" : 3\n  \"Cats\" : 1")
        let found = try #require(inspect(markup))
        #expect(found.names["path"] == 2 && markup.contains("75.0%") && markup.contains(">Pets<"))
        #expect(try #require(inspect(svg("pie\n  \"Only\" : 1"))).names["circle"] == 1)
    }

    @Test func `an empty scene is nothing`() {
        #expect(SVGRenderer().svg(DiagramScene()).isEmpty)
    }
}
