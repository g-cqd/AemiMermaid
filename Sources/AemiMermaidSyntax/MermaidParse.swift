/// What reading a source gave: a diagram of one of the kinds, or the reason it is not drawn; the diagnostics either way.
public struct MermaidParse: Sendable {
    public enum Result: Sendable {
        case flowchart(FlowchartDiagram)
        case sequence(SequenceDiagram)
        case refused(MermaidRefusal)
    }

    public var result: Result
    public var diagnostics: MermaidDiagnostics

    /// Reads `source`, a diagram in Mermaid's syntax, within `limits`. Never fails and never takes more than a fixed multiple of the source's size.
    /// - Complexity: O(source.count) apart from the quadratic step of `A & B --> C & D`, which the edge limit bounds.
    public static func parse(_ source: [UInt8], limits: MermaidLimits = .default) -> MermaidParse {
        guard source.count <= limits.maxSourceBytes else {
            var diagnostics = MermaidDiagnostics()
            diagnostics.add(.init(kind: .limit, line: 0, limit: .sourceBytes, figure: source.count))
            return MermaidParse(result: .refused(.limit(.sourceBytes, figure: source.count)), diagnostics: diagnostics)
        }
        guard let header = MermaidHeader.find(in: source) else {
            return MermaidParse(result: .refused(.unknownKind), diagnostics: MermaidDiagnostics())
        }
        switch header.kind {
            case .flowchart:
                var parser = FlowchartParser(source: source, limits: limits, direction: header.direction)
                parser.run(from: header.restOffset, firstLine: header.firstLine)
                return conclude(parser.reader, isEmpty: parser.diagram.nodes.isEmpty, .flowchart(parser.diagram))
            case .sequence:
                var parser = SequenceParser(source: source, limits: limits)
                parser.run(from: header.restOffset, firstLine: header.firstLine)
                return conclude(parser.reader, isEmpty: parser.diagram.participants.isEmpty, .sequence(parser.diagram))
        }
    }

    /// The parse once the lines are read: a refusal if a limit was passed, or the diagram is empty.
    private static func conclude(_ reader: LineReader, isEmpty: Bool, _ result: @autoclosure () -> Result)
        -> MermaidParse
    {
        if let refusal = reader.refusal {
            return MermaidParse(result: .refused(refusal), diagnostics: reader.diagnostics)
        }
        if isEmpty { return MermaidParse(result: .refused(.empty), diagnostics: reader.diagnostics) }
        return MermaidParse(result: result(), diagnostics: reader.diagnostics)
    }
}
