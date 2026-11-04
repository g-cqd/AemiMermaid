/// Reads the lines of a sequence diagram into a ``SequenceDiagram``: one line at a time, fragments on a counter bounded by `maxNesting`, participants created
/// where they first appear. A line it cannot read is dropped with a diagnostic.
struct SequenceParser: LineParser {
    var reader: LineReader
    var diagram = SequenceDiagram()
    let symbols = SymbolTable()
    var participantOf = SlotMap()
    var depth = 0
    var messages = 0

    init(source: [UInt8], limits: MermaidLimits) { reader = LineReader(source: source, limits: limits) }

    mutating func finishLines() {
        if depth > 0 { reader.diagnostics.add(.init(kind: .unclosedBlock, line: line)) }
    }

    mutating func readLine() {
        skipSpaces()
        guard pos < end, !reader.startsComment() else { return }
        if readKeyword() { return }
        readMessage()
    }
}
