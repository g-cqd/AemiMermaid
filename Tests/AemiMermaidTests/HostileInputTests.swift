import AemiTestKit
import Testing

@testable import AemiMermaidSyntax

/// Inputs made to cost: nesting, size, labels, and the quadratic shapes of the syntax. Each finishes, within its limit, on a stack of 512 KiB.
@Suite("Hostile sources finish within their limits")
struct HostileInputTests {
    private func parse(_ source: String, limits: MermaidLimits = .default) -> MermaidParse {
        MermaidParse.parse(Array(source.utf8), limits: limits)
    }

    @Test func `three thousand nested subgraphs are refused at the nesting limit`() {
        let source =
            "flowchart TD\n" + String(repeating: "subgraph s\n", count: 3000) + "A\n"
            + String(repeating: "end\n", count: 3000)
        let result = runOnConstrainedStack { MermaidParse.parse(Array(source.utf8)).result }
        if case .refused(.limit(.nesting, let figure)) = result {
            #expect(figure == 17)
        } else {
            Issue.record("expected the nesting limit, got \(result)")
        }
    }

    @Test func `three thousand nested fragments are refused at the nesting limit`() {
        let source = "sequenceDiagram\nA->>B: x\n" + String(repeating: "loop x\n", count: 3000)
        let result = runOnConstrainedStack { MermaidParse.parse(Array(source.utf8)).result }
        if case .refused(.limit(.nesting, _)) = result {
        } else {
            Issue.record("expected the nesting limit, got \(result)")
        }
    }

    @Test func `a source over the size limit is refused before it is read`() {
        let result = parse(
            "flowchart TD\n" + String(repeating: "A-->B\n", count: 100),
            limits: MermaidLimits(maxSourceBytes: 64)
        )
        .result
        if case .refused(.limit(.sourceBytes, _)) = result {
        } else {
            Issue.record("expected the size limit, got \(result)")
        }
    }

    @Test func `more nodes than the limit are refused with the figure`() {
        let source = "flowchart TD\n" + (0 ..< 300).map { "n\($0) --> n\($0 + 1)" }.joined(separator: "\n")
        if case .refused(.limit(.nodes, let figure)) = parse(source, limits: MermaidLimits(maxNodes: 200)).result {
            #expect(figure == 201)
        } else {
            Issue.record("expected the node limit")
        }
    }

    @Test func `the quadratic form of groups stops at the edge limit`() {
        let side = (0 ..< 200).map { "a\($0)" }.joined(separator: " & ")
        let other = (0 ..< 200).map { "b\($0)" }.joined(separator: " & ")
        if case .refused(.limit(.edges, _)) = parse(
            "flowchart TD\n\(side) --> \(other)",
            limits: MermaidLimits(maxEdges: 1000)
        )
        .result {
        } else {
            Issue.record("expected the edge limit")
        }
    }

    @Test func `a two megabyte label is cut at the label limit, in time`() {
        let long = String(repeating: "x", count: 2_000_000)
        let parsed = MermaidParse.parse(
            Array("flowchart TD\nA[\(long)] --> B".utf8),
            limits: MermaidLimits(maxSourceBytes: 4_000_000, maxLineBytes: 4_000_000)
        )
        guard case .flowchart(let diagram) = parsed.result else {
            Issue.record("expected a flowchart")
            return
        }
        #expect(
            diagram.labels.slice(diagram.nodes[0].label).count == 2048 && parsed.diagnostics.contains(.labelTruncated)
        )
    }

    @Test func `a line over the line limit is dropped and the rest stands`() {
        let parsed = MermaidParse.parse(
            Array(("flowchart TD\nA --> B\n" + String(repeating: "x", count: 9000) + "\nB --> C").utf8)
        )
        guard case .flowchart(let diagram) = parsed.result else {
            Issue.record("expected a flowchart")
            return
        }
        #expect(
            diagram.edges.count == 2 && parsed.diagnostics.entries.contains { $0.limit == .lineBytes && $0.line == 3 }
        )
    }

    @Test func `brackets that never close, links that never end, and quotes left open`() {
        for source in [
            "flowchart TD\nA[" + String(repeating: "(", count: 5000),
            "flowchart TD\nA" + String(repeating: "-", count: 5000),
            "flowchart TD\nA --" + String(repeating: " ", count: 5000) + "text",
            "flowchart TD\nA[\"" + String(repeating: "a", count: 5000),
            "flowchart TD\nA -->|" + String(repeating: "|", count: 5000),
            "flowchart TD\n" + String(repeating: "A & ", count: 3000),
            "flowchart TD\n" + String(repeating: "A --> ", count: 3000),
            "sequenceDiagram\n" + String(repeating: "A->>", count: 3000)
        ] {
            let result = runOnConstrainedStack { MermaidParse.parse(Array(source.utf8)).result }
            switch result {
                case .flowchart, .sequence, .pie, .refused: break
            }
        }
    }

    @Test func `escape sequences in a label never reach the diagram`() throws {
        let parsed = parse("flowchart TD\nA[\"\u{1B}[2J\u{1B}]52;c;aGk=\u{07}x\"] --> B")
        guard case .flowchart(let diagram) = parsed.result else {
            Issue.record("expected a flowchart")
            return
        }
        #expect(!diagram.labels.bytes.contains(0x1B) && !diagram.labels.bytes.contains(0x07))
        #expect(parsed.diagnostics.contains(.labelSanitized))
    }

    @Test func `the number of diagnostics kept is bounded`() {
        let source = "flowchart TD\n" + String(repeating: "$$\n", count: 1000) + "A --> B"
        let parsed = parse(source)
        #expect(parsed.diagnostics.entries.count == 16 && parsed.diagnostics.dropped == 984)
    }
}
