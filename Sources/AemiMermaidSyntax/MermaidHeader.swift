internal import AemiFrontMatter

/// The first meaningful line of a source: what it declares, where the rest starts, and the line number the rest starts at.
struct MermaidHeader {
    var kind: MermaidKind
    var direction: FlowDirection
    var restOffset: Int
    var firstLine: Int
    /// What follows the first word on the header line (`pie title Pets`).
    var rest: ArraySlice<UInt8>
    /// The `---` head before the header (Mermaid's front matter), if there is one.
    var frontMatter: FrontMatter?

    /// Mermaid's front matter (`diagram-api/regexes.ts`): YAML between `---` fences, which may be indented if the closing one is
    /// indented the same; AemiMermaid also lets blank lines come first.
    static let headOptions = FrontMatterOptions(formats: [.yaml], leadingBlankLines: true, indentedFences: true)

    /// Skips a front matter head (AemiFrontMatter's rules), then blank lines and comments; nil if the first other line is not a
    /// header this engine reads.
    static func find(in source: [UInt8]) -> MermaidHeader? {
        var cursor = 0
        var line = 0
        let frontMatter = FrontMatter(in: source, options: headOptions)
        if let frontMatter {
            cursor = frontMatter.bodyStart
            line = source[..<cursor].count { $0 == 0x0A }
        }
        while cursor < source.count {
            line += 1
            var stop = cursor
            while stop < source.count, source[stop] != 0x0A { stop += 1 }
            var text = source[cursor ..< stop]
            while text.last == 0x0D || text.last == 0x20 || text.last == 0x09 { text = text.dropLast() }
            while text.first == 0x20 || text.first == 0x09 { text = text.dropFirst() }
            cursor = stop + 1
            if text.isEmpty || text.starts(with: "%%".utf8) {
                continue
            } else if let header = MermaidKind.header(text) {
                return MermaidHeader(
                    kind: header.kind,
                    direction: header.direction,
                    restOffset: Swift.min(cursor, source.count),
                    firstLine: line + 1,
                    rest: text.drop { $0 != 0x20 && $0 != 0x09 },
                    frontMatter: frontMatter
                )
            } else {
                return nil
            }
        }
        return nil
    }
}
