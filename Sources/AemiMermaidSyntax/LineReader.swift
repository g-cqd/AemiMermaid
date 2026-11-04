internal import AemiMermaidScene

/// The cursor both parsers share: a source cut into lines, the position in the line being read, and what went wrong so far. It never reads past a line, and a line over the limit
/// is dropped with a diagnostic before a parser sees it.
struct LineReader {
    let source: [UInt8]
    let limits: MermaidLimits
    var diagnostics = MermaidDiagnostics()
    var refusal: MermaidRefusal?
    /// The line number (from 1), the start of the line, the position in it and its end (without the line ending).
    var line = 0
    var lineStart = 0
    var pos = 0
    var end = 0
    private var next = 0

    init(source: [UInt8], limits: MermaidLimits) {
        self.source = source
        self.limits = limits
    }

    /// Starts at `offset`, the start of line number `firstLine`.
    mutating func start(at offset: Int, firstLine: Int) {
        next = offset
        line = firstLine - 1
    }

    /// Moves to the next line that is short enough to read; false at the end of the source or after a refusal.
    mutating func advance() -> Bool {
        while next < source.count, refusal == nil {
            line += 1
            var stop = next
            while stop < source.count, source[stop] != 0x0A { stop += 1 }
            lineStart = next
            pos = next
            end = stop > next && source[stop - 1] == 0x0D ? stop - 1 : stop
            next = stop + 1
            if end - pos <= limits.maxLineBytes { return true }
            diagnostics.add(.init(kind: .limit, line: line, limit: .lineBytes, figure: end - pos))
        }
        return false
    }

    mutating func skipSpaces() {
        while pos < end, source[pos] == 0x20 || source[pos] == 0x09 { pos += 1 }
    }

    func startsComment() -> Bool {
        pos + 1 < end && source[pos] == UInt8(ascii: "%") && source[pos + 1] == UInt8(ascii: "%")
    }

    /// Drops the rest of the line, with a diagnostic at the cursor.
    mutating func unsupported() {
        diagnostics.add(.init(kind: .unsupportedLine, line: line, column: pos - lineStart + 1))
        pos = end
    }

    mutating func refuse(_ limit: MermaidLimitKind, figure: Int) {
        diagnostics.add(.init(kind: .limit, line: line, limit: limit, figure: figure))
        refusal = .limit(limit, figure: figure)
    }

    /// Adds a label for `raw` to `arena`, noting in the diagnostics what cleaning it had to do.
    mutating func label(_ raw: ArraySlice<UInt8>, in arena: inout LabelArena) -> LabelRef {
        let (ref, outcome) = arena.add(raw, maxBytes: limits.maxLabelBytes)
        if outcome.contains(.truncated) {
            diagnostics.add(.init(kind: .labelTruncated, line: line, limit: .labelBytes, figure: raw.count))
        }
        if outcome.contains(.replaced) { diagnostics.add(.init(kind: .labelSanitized, line: line)) }
        return ref
    }

    /// The text between the `byte` at `open` and the next one on the line, or nil if there is no next one.
    func enclosed(by byte: UInt8, at open: Int) -> Range<Int>? {
        var cursor = open + 1
        while cursor < end, source[cursor] != byte { cursor += 1 }
        return cursor < end ? (open + 1) ..< cursor : nil
    }

    /// As ``enclosed(by:at:)`` at the cursor, which moves past the closing `byte`.
    mutating func takeEnclosed(by byte: UInt8) -> Range<Int>? {
        guard let text = enclosed(by: byte, at: pos) else { return nil }
        pos = text.upperBound + 1
        return text
    }

    /// The rest of the line from the cursor, trimmed; the cursor moves to the end.
    mutating func rest() -> ArraySlice<UInt8> {
        skipSpaces()
        var stop = end
        while stop > pos, source[stop - 1] == 0x20 || source[stop - 1] == 0x09 { stop -= 1 }
        let text = source[pos ..< stop]
        pos = end
        return text
    }

    /// Whether the word `word` stands at the cursor followed by white space, a colon or the end of the line; the cursor moves past it.
    mutating func take(_ word: String) -> Bool {
        let bytes = Array(word.utf8)
        guard pos + bytes.count <= end, source[pos ..< (pos + bytes.count)].elementsEqual(bytes) else { return false }
        let after = pos + bytes.count
        guard after == end || source[after] == 0x20 || source[after] == 0x09 || source[after] == UInt8(ascii: ":")
        else { return false }
        pos = after
        return true
    }
}
