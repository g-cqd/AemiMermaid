internal import AemiMermaidScene

extension FlowchartParser {
    /// What a link is, before it joins two groups of nodes.
    struct Link {
        var line: FlowLineStyle = .solid
        var head: FlowEnd = .none
        var tail: FlowEnd = .none
        var length: UInt8 = 1
        var text: Range<Int>?
    }

    /// A chain of groups joined by links: `A --> B & C -.-> D`.
    mutating func readChain() {
        var left = readGroup()
        guard !left.isEmpty else { return refusal == nil ? unsupported() : () }
        while refusal == nil {
            skipSpaces()
            guard var link = readLink() else { break }
            if link.text == nil, pos < end, source[pos] == UInt8(ascii: "|") {
                link.text = reader.takeEnclosed(by: UInt8(ascii: "|"))
                if link.text == nil { return unsupported() }
            }
            skipSpaces()
            let right = readGroup()
            guard !right.isEmpty else { return refusal == nil ? unsupported() : () }
            join(left, right, link)
            left = right
        }
    }

    private mutating func join(_ from: [Int32], _ to: [Int32], _ link: Link) {
        let text = link.text.map { label(source[$0]) } ?? .empty
        for source in from {
            for target in to {
                guard diagram.edges.count < limits.maxEdges else {
                    return refuse(.edges, figure: diagram.edges.count + 1)
                }
                diagram.edges.append(
                    FlowEdge(
                        from: source,
                        to: target,
                        line: link.line,
                        head: link.head,
                        tail: link.tail,
                        length: link.length,
                        label: text
                    )
                )
            }
        }
    }

    private func isEndMark(_ byte: UInt8) -> Bool { byte == UInt8(ascii: "o") || byte == UInt8(ascii: "x") }

    private func endOf(_ byte: UInt8) -> FlowEnd {
        switch byte {
            case UInt8(ascii: ">"), UInt8(ascii: "<"): .arrow
            case UInt8(ascii: "o"): .circle
            default: .cross
        }
    }

    /// The link at the cursor (`-->`, `---`, `-.->`, `==>`, `~~~`, `--o`, `<-->`, `-- text -->`), or nil. The cursor moves past it.
    mutating func readLink() -> Link? {
        var cursor = pos
        var link = Link()
        func peek(_ offset: Int) -> UInt8 { cursor + offset < end ? source[cursor + offset] : 0 }
        // A tail: `<`, or `o` or `x` right before the line.
        if peek(0) == UInt8(ascii: "<")
            || (isEndMark(peek(0)) && [UInt8(ascii: "-"), UInt8(ascii: "=")].contains(peek(1)))
        {
            link.tail = endOf(peek(0))
            cursor += 1
        }
        let body = peek(0)
        guard body == UInt8(ascii: "-") || body == UInt8(ascii: "=") || body == UInt8(ascii: "~") else { return nil }
        if body == UInt8(ascii: "~") {
            var count = 0
            while peek(count) == UInt8(ascii: "~") { count += 1 }
            guard count >= 3 else { return nil }
            link.line = .invisible
            link.length = UInt8(clamping: count - 2)
            pos = cursor + count
            return link
        }
        var count = 0
        var dotted = false
        while true {
            let byte = peek(count)
            if byte == body {
                count += 1
            } else if body == UInt8(ascii: "-"), byte == UInt8(ascii: "."), count >= 1 {
                dotted = true
                count += 1
            } else {
                break
            }
        }
        let dashes = (0 ..< count).filter { peek($0) == body }.count
        guard dashes >= 2 || (dotted && dashes >= 1) else { return nil }
        link.line = body == UInt8(ascii: "=") ? .thick : (dotted ? .dotted : .solid)
        let after = peek(count)
        let afterNext = peek(count + 1)
        if after == UInt8(ascii: ">") || ((isEndMark(after)) && !Self.isIdentifier(afterNext)) {
            link.head = endOf(after)
            link.length = UInt8(clamping: Swift.max(1, dashes - 1))
            pos = cursor + count + 1
            return link
        }
        // `-- text -->`: the line opens, the text follows a space, and a longer line closes it.
        if after == 0x20, dotted ? (dashes == 1 && count == 2) : dashes == 2,
            let finished = readTextLink(from: cursor + count + 1, body: body, dotted: dotted, link: link)
        {
            return finished
        }
        link.length = UInt8(clamping: Swift.max(1, dashes - 2))
        pos = cursor + count
        return link
    }

    /// The rest of `-- text -->`: the text up to the closing line, and its end.
    private mutating func readTextLink(from start: Int, body: UInt8, dotted: Bool, link: Link) -> Link? {
        var link = link
        var scan = start
        while scan + 1 < end {
            let isCloser =
                dotted
                ? (source[scan] == UInt8(ascii: ".") && source[scan + 1] == UInt8(ascii: "-"))
                : (source[scan] == body && source[scan + 1] == body)
            if isCloser { break }
            scan += 1
        }
        guard scan + 1 < end else { return nil }
        var cursor = scan
        var dashes = 0
        while cursor < end, source[cursor] == body || (dotted && source[cursor] == UInt8(ascii: ".")) {
            if source[cursor] == body { dashes += 1 }
            cursor += 1
        }
        if cursor < end,
            source[cursor] == UInt8(ascii: ">")
                || (isEndMark(source[cursor]) && (cursor + 1 >= end || !Self.isIdentifier(source[cursor + 1])))
        {
            link.head = endOf(source[cursor])
            cursor += 1
        }
        link.text = start ..< scan
        link.length = UInt8(clamping: Swift.max(1, dashes - (link.head == .none ? 2 : 1)))
        pos = cursor
        return link
    }
}
