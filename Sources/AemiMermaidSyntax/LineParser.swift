internal import AemiMermaidScene

/// A parser that reads a diagram a line at a time with a ``LineReader``: the cursor's names, forwarded, and the loop over the lines.
protocol LineParser {
    associatedtype Diagram: LabelledDiagram
    var reader: LineReader { get set }
    var diagram: Diagram { get set }
    /// Reads the line the reader stands at.
    mutating func readLine()
    /// Called after the last line.
    mutating func finishLines()
}

extension LineParser {
    var labels: LabelArena {
        get { diagram.labels }
        set { diagram.labels = newValue }
    }
    var source: [UInt8] { reader.source }
    var limits: MermaidLimits { reader.limits }
    var diagnostics: MermaidDiagnostics { reader.diagnostics }
    var refusal: MermaidRefusal? { reader.refusal }
    var line: Int { reader.line }
    var lineStart: Int { reader.lineStart }
    var end: Int { reader.end }
    var pos: Int {
        get { reader.pos }
        set { reader.pos = newValue }
    }

    mutating func run(from offset: Int, firstLine: Int) {
        reader.start(at: offset, firstLine: firstLine)
        while reader.advance() { readLine() }
        if reader.refusal == nil { finishLines() }
    }

    mutating func skipSpaces() { reader.skipSpaces() }
    mutating func unsupported() { reader.unsupported() }
    mutating func refuse(_ limit: MermaidLimitKind, figure: Int) { reader.refuse(limit, figure: figure) }
    mutating func rest() -> ArraySlice<UInt8> { reader.rest() }
    mutating func take(_ word: String) -> Bool { reader.take(word) }

    mutating func label(_ raw: ArraySlice<UInt8>) -> LabelRef {
        var arena = labels
        labels = LabelArena()  // let the arena be unique while it grows
        defer { labels = arena }
        return reader.label(raw, in: &arena)
    }
}
