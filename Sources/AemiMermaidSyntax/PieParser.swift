internal import AemiMermaidScene

/// Reads `pie [showData] [title …]`, `title …`, `showData` and `"label" : value` lines into a ``PieDiagram``. A value that is not a positive finite number drops its line.
struct PieParser: LineParser {
    var reader: LineReader
    var diagram = PieDiagram()

    init(source: [UInt8], limits: MermaidLimits) { reader = LineReader(source: source, limits: limits) }

    /// Takes what follows `pie` on the header line.
    mutating func readHeaderRest(_ rest: ArraySlice<UInt8>) {
        var words = rest[...]
        while words.first == 0x20 { words = words.dropFirst() }
        if words.starts(with: "showData".utf8) {
            diagram.showData = true
            words = words.dropFirst(8)
            while words.first == 0x20 { words = words.dropFirst() }
        }
        if words.starts(with: "title".utf8) { setTitle(words.dropFirst(5)) }
    }

    private mutating func setTitle(_ text: ArraySlice<UInt8>) {
        var title = text
        while title.first == 0x20 || title.first == 0x09 { title = title.dropFirst() }
        if !title.isEmpty { diagram.title = label(title) }
    }

    mutating func finishLines() {}

    mutating func readLine() {
        skipSpaces()
        guard pos < end, !reader.startsComment() else { return }
        if take("showData") {
            diagram.showData = true
        } else if take("title") {
            setTitle(rest())
        } else if source[pos] == UInt8(ascii: "\"") {
            readSlice()
        } else {
            unsupported()
        }
    }

    private mutating func readSlice() {
        guard let name = reader.takeEnclosed(by: UInt8(ascii: "\"")) else { return unsupported() }
        skipSpaces()
        guard pos < end, source[pos] == UInt8(ascii: ":") else { return unsupported() }
        pos += 1
        let text = String(decoding: rest(), as: UTF8.self)
        guard let value = Double(text), value.isFinite, value > 0 else { return unsupported() }
        guard diagram.slices.count < limits.maxNodes else { return refuse(.nodes, figure: diagram.slices.count + 1) }
        diagram.slices.append(.init(label: label(source[name]), value: value))
    }
}
