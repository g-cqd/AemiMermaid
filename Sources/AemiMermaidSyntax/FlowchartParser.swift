/// Reads the lines of a flowchart into a ``FlowchartDiagram`` (ADR 0001): one pass over the lines, a statement at a time, the open subgraphs on an explicit stack.
/// Nothing recurses and every loop is bounded by the line, by `MermaidLimits`, or both. A line it cannot read is dropped with a diagnostic; a limit that is passed
/// stops the parse and refuses the diagram.
struct FlowchartParser: LineParser {
    var reader: LineReader
    var diagram = FlowchartDiagram()
    /// The ids seen, as dense symbols; `nodeOf` and `clusterOf` say what each names.
    let symbols = SymbolTable()
    var nodeOf = SlotMap()
    var clusterOf = SlotMap()
    /// The subgraphs that are open, innermost last.
    var open: [Int32] = []

    init(source: [UInt8], limits: MermaidLimits, direction: FlowDirection) {
        reader = LineReader(source: source, limits: limits)
        diagram.direction = direction
    }

    mutating func finishLines() {
        if !open.isEmpty { reader.diagnostics.add(.init(kind: .unclosedBlock, line: line)) }
    }

    mutating func readLine() {
        while refusal == nil {
            skipSpaces()
            if pos >= end || reader.startsComment() { return }
            readStatement()
            skipSpaces()
            if pos >= end || reader.startsComment() { return }
            guard source[pos] == UInt8(ascii: ";") else {
                unsupported()
                return
            }
            pos += 1
        }
    }

    /// The words that start a line which is not a chain of nodes: the two that open and close a subgraph, and the styling statements that are read and ignored.
    private static func isKeyword(_ word: String) -> Bool {
        switch word {
            case "subgraph", "end": true
            case "direction", "classDef", "class", "style", "linkStyle", "click": true
            case "accTitle", "accDescr", "title", "callback", "default": true
            default: false
        }
    }

    private mutating func readStatement() {
        switch keyword() {
            case "subgraph": openSubgraph()
            case "end": closeSubgraph()
            case "": readChain()
            default: pos = end  // read and ignored
        }
    }

    /// The keyword at the cursor, if a word of letters stands there alone (followed by white space, `;` or the end of the line); the cursor moves past it.
    private mutating func keyword() -> String {
        var cursor = pos
        while cursor < end, (source[cursor] | 0x20) >= UInt8(ascii: "a"), (source[cursor] | 0x20) <= UInt8(ascii: "z") {
            cursor += 1
        }
        guard cursor > pos,
            cursor == end || source[cursor] == 0x20 || source[cursor] == 0x09 || source[cursor] == UInt8(ascii: ";")
        else { return "" }
        let word = String(decoding: source[pos ..< cursor], as: UTF8.self)
        guard Self.isKeyword(word) else { return "" }
        pos = cursor
        return word
    }
}
