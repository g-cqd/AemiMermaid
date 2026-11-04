/// The first meaningful line of a source: what it declares, where the rest starts, and the line number the rest starts at.
struct MermaidHeader {
    var kind: MermaidKind
    var direction: FlowDirection
    var restOffset: Int
    var firstLine: Int

    /// Skips blank lines, comments and a front matter block (`---` to `---`); nil if the first other line is not a header this engine reads.
    static func find(in source: [UInt8]) -> MermaidHeader? {
        var cursor = 0
        var line = 0
        var frontMatter = false
        while cursor < source.count {
            line += 1
            var stop = cursor
            while stop < source.count, source[stop] != 0x0A { stop += 1 }
            var text = source[cursor ..< stop]
            while text.last == 0x0D || text.last == 0x20 || text.last == 0x09 { text = text.dropLast() }
            while text.first == 0x20 || text.first == 0x09 { text = text.dropFirst() }
            cursor = stop + 1
            if text.elementsEqual("---".utf8) {
                frontMatter = !frontMatter
            } else if frontMatter || text.isEmpty || text.starts(with: "%%".utf8) {
                continue
            } else if let header = MermaidKind.header(text) {
                return MermaidHeader(
                    kind: header.kind,
                    direction: header.direction,
                    restOffset: Swift.min(cursor, source.count),
                    firstLine: line + 1
                )
            } else {
                return nil
            }
        }
        return nil
    }
}
