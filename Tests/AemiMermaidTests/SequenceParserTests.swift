import Testing

@testable import AemiMermaidSyntax

@Suite("A sequence diagram is read as the subset says")
struct SequenceParserTests {
    private func sequence(_ source: String) -> (SequenceDiagram, MermaidDiagnostics)? {
        let parse = MermaidParse.parse(Array(source.utf8))
        guard case .sequence(let diagram) = parse.result else { return nil }
        return (diagram, parse.diagnostics)
    }

    @Test func `participants and actors with aliases, and participants created by a message`() throws {
        let (diagram, diagnostics) = try #require(
            sequence("sequenceDiagram\n  participant A as Alice\n  actor B as Bob the Builder\n  A->>C: hi")
        )
        #expect(diagnostics.isEmpty && diagram.participants.count == 3)
        #expect(diagram.participants.map { diagram.labels.string($0.label) } == ["Alice", "Bob the Builder", "C"])
        #expect(diagram.participants.map(\.isActor) == [false, true, false])
    }

    @Test(arguments: [
        ("->", SequenceArrow.solid), ("->>", .solidArrow), ("-->", .dashed), ("-->>", .dashedArrow),
        ("-x", .solidCross), ("--x", .dashedCross),
        ("-)", .solidAsync), ("--)", .dashedAsync)
    ])
    func `arrows`(token: String, arrow: SequenceArrow) throws {
        let (diagram, diagnostics) = try #require(sequence("sequenceDiagram\n  A\(token)B: text"))
        #expect(diagnostics.isEmpty && diagram.events.count == 1)
        #expect(
            diagram.events[0].arrow == arrow && diagram.events[0].from == 0 && diagram.events[0].to == 1
                && diagram.labels.string(diagram.events[0].text) == "text"
        )
    }

    @Test func `activation marks, notes and fragments are events in order`() throws {
        let (diagram, diagnostics) = try #require(
            sequence(
                "sequenceDiagram\n  A->>+B: go\n  Note over A,B: n\n  Note left of A: l\n  loop each\n    B-->>-A: back\n  else other\n    A->>B: x\n  end\n  activate A\n  deactivate A"
            )
        )
        #expect(diagnostics.isEmpty)
        #expect(
            diagram.events.map(\.kind) == [
                .message, .noteOver, .noteLeft, .blockStart, .message, .blockBranch, .message, .blockEnd, .activate,
                .deactivate
            ]
        )
        #expect(diagram.events[0].activation == 1 && diagram.events[4].activation == -1)
        #expect(diagram.events[1].from == 0 && diagram.events[1].to == 1)
    }

    @Test func `autonumber and a title`() throws {
        let (diagram, _) = try #require(sequence("sequenceDiagram\n  title Orders\n  autonumber\n  A->>B: x"))
        #expect(diagram.autonumber && diagram.title.map { diagram.labels.string($0) } == "Orders")
    }

    @Test func `an unreadable line is dropped, a stray end is reported, an open fragment is closed`() throws {
        let (diagram, diagnostics) = try #require(
            sequence("sequenceDiagram\n  A->>B: x\n  nonsense here\n  end\n  loop forever\n  A->>B: y")
        )
        #expect(diagram.events.filter { $0.kind == .message }.count == 2)
        #expect(
            diagnostics.contains(.unsupportedLine) && diagnostics.contains(.strayEnd)
                && diagnostics.contains(.unclosedBlock)
        )
    }

    @Test func `the message limit refuses the diagram`() {
        let source = "sequenceDiagram\n" + String(repeating: "A->>B: x\n", count: 50)
        if case .refused(.limit(.messages, _)) =
            MermaidParse.parse(Array(source.utf8), limits: MermaidLimits(maxMessages: 10)).result
        {
        } else {
            Issue.record("expected the message limit")
        }
    }
}
