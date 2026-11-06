/// What reading a source gave: a diagram of one of the kinds, or the reason it is not drawn; the diagnostics either way.
public struct MermaidParse: Sendable {
    public enum Result: Sendable {
        case flowchart(FlowchartDiagram)
        case sequence(SequenceDiagram)
        case pie(PieDiagram)
        case refused(MermaidRefusal)
    }

    public var result: Result
    public var diagnostics: MermaidDiagnostics
    /// The diagram's front matter (`---` … `---` before the header), read: its title and configuration.
    public var head: MermaidHead?

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
        var parse = diagram(source, limits, header)
        parse.head = header.frontMatter.map { MermaidHead($0, in: source) }
        return parse
    }

    private static func diagram(_ source: [UInt8], _ limits: MermaidLimits, _ header: MermaidHeader) -> MermaidParse {
        switch header.kind {
            case .flowchart: return flowchart(source, limits, header)
            case .state:
                return flowchart(
                    translate(StateTranslator(direction: StateTranslator.direction(in: source)), source),
                    limits,
                    nil
                )
            case .classes:
                return flowchart(
                    translate(ClassTranslator(direction: ClassTranslator.direction(in: source)), source),
                    limits,
                    nil
                )
            case .entities: return flowchart(translate(EntityTranslator(), source), limits, nil)
            case .sequence:
                var parser = SequenceParser(source: source, limits: limits)
                parser.run(from: header.restOffset, firstLine: header.firstLine)
                return conclude(parser.reader, isEmpty: parser.diagram.participants.isEmpty, .sequence(parser.diagram))
            case .pie:
                var parser = PieParser(source: source, limits: limits)
                parser.readHeaderRest(header.rest)
                parser.run(from: header.restOffset, firstLine: header.firstLine)
                return conclude(parser.reader, isEmpty: parser.diagram.slices.isEmpty, .pie(parser.diagram))
        }
    }

    private static func translate(_ translator: some LineTranslator, _ source: [UInt8]) -> [UInt8] {
        var translator = translator
        return translator.run(source)
    }

    /// A flowchart, or a diagram written as one by a translator (its header is then the flowchart's, found again).
    private static func flowchart(_ source: [UInt8], _ limits: MermaidLimits, _ known: MermaidHeader?) -> MermaidParse {
        guard let header = known ?? MermaidHeader.find(in: source) else {
            return MermaidParse(result: .refused(.unknownKind), diagnostics: MermaidDiagnostics())
        }
        var parser = FlowchartParser(source: source, limits: limits, direction: header.direction)
        parser.run(from: header.restOffset, firstLine: header.firstLine)
        return conclude(parser.reader, isEmpty: parser.diagram.nodes.isEmpty, .flowchart(parser.diagram))
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
