extension FlowchartParser {
    /// A group of nodes joined by `&`: `A & B`. Empty if no node stands at the cursor.
    mutating func readGroup() -> [Int32] {
        var group: [Int32] = []
        guard let first = readNode() else { return group }
        group.append(first)
        while refusal == nil {
            let mark = pos
            skipSpaces()
            guard pos < end, source[pos] == UInt8(ascii: "&") else {
                pos = mark
                break
            }
            pos += 1
            skipSpaces()
            guard let next = readNode() else { break }
            group.append(next)
            if group.count > limits.maxNodes {
                refuse(.nodes, figure: group.count)
                break
            }
        }
        return group
    }

    static func isIdentifier(_ byte: UInt8) -> Bool {
        (byte | 0x20) >= UInt8(ascii: "a") && (byte | 0x20) <= UInt8(ascii: "z")
            || byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
            || byte == UInt8(ascii: "_") || byte >= 0x80
    }

    /// One node: its id, then optionally a shape with its text. Returns its index, creating the node if it is new.
    mutating func readNode() -> Int32? {
        let idStart = pos
        while pos < end {
            let byte = source[pos]
            if Self.isIdentifier(byte) {
                pos += 1
            } else if byte == UInt8(ascii: "-"), pos + 1 < end, Self.isIdentifier(source[pos + 1]), pos > idStart {
                pos += 1  // a hyphen inside an id, not the start of an arrow
            } else {
                break
            }
        }
        guard pos > idStart else { return nil }
        let id = source[idStart ..< pos]
        let symbol = symbols.symbol(id)
        if clusterOf.get(symbol) >= 0, nodeOf.get(symbol) < 0 {
            reader.diagnostics.add(.init(kind: .clusterEdgeApproximated, line: line, column: idStart - lineStart + 1))
        }
        var index = nodeOf.get(symbol)
        if index < 0 {
            guard diagram.nodes.count < limits.maxNodes else {
                refuse(.nodes, figure: diagram.nodes.count + 1)
                return nil
            }
            let ref = label(id)
            index = Int32(diagram.nodes.count)
            diagram.nodes.append(FlowNode(id: ref, label: ref, shape: .rectangle, cluster: open.last ?? -1))
            nodeOf.set(symbol, index)
        }
        if pos + 2 < end, source[pos] == UInt8(ascii: ":"), source[pos + 1] == UInt8(ascii: ":"),
            source[pos + 2] == UInt8(ascii: ":")
        {
            pos += 3  // `:::class`, read and ignored
            while pos < end, Self.isIdentifier(source[pos]) { pos += 1 }
        }
        if pos < end { readShape(of: Int(index)) }
        return index
    }

    /// How shapes open and close: the opening bytes, a closing sequence and the shape it means. Longest openers first, so that `(((` is not read as `(`; an opener with two
    /// rows is one whose closing sequence says which shape it is (`[/text/]` and `[/text\]`).
    private static let shapes: [(open: String, close: String, shape: FlowShape)] = zip(
        [
            "((( )))", "[[ ]]", "[( )]", "[/ /]", "[/ \\]", "[\\ \\]", "[\\ /]", "(( ))", "([ ])", "{{ }}", "[ ]",
            "( )", "{ }", "> ]"
        ],
        [
            FlowShape.doubleCircle, .subroutine, .cylinder, .parallelogram, .trapezoid, .parallelogramAlt,
            .trapezoidAlt, .circle, .stadium, .hexagon,
            .rectangle, .rounded, .diamond, .asymmetric
        ]
    )
    .map { pair in
        let sides = pair.0.split(separator: " ")
        return (open: String(sides[0]), close: String(sides[1]), shape: pair.1)
    }

    /// The opening bytes at the cursor, and every closing sequence that can end the shape they open.
    private func opener() -> (open: Int, closers: [(String, FlowShape)])? {
        guard let first = Self.shapes.first(where: { matches($0.open) }) else { return nil }
        return (first.open.utf8.count, Self.shapes.filter { $0.open == first.open }.map { ($0.close, $0.shape) })
    }

    private func matches(_ text: String) -> Bool {
        let bytes = Array(text.utf8)
        return pos + bytes.count <= end && source[pos ..< (pos + bytes.count)].elementsEqual(bytes)
    }

    /// The shape and text that follow an id: `[text]`, `("text")`, `{{text}}` and the rest.
    private mutating func readShape(of node: Int) {
        guard let opener = opener() else { return }
        var cursor = pos + opener.open
        while cursor < end, source[cursor] == 0x20 { cursor += 1 }
        var textRange: Range<Int>
        var searchFrom = cursor
        if cursor < end, source[cursor] == UInt8(ascii: "\"") {
            guard let quoted = reader.enclosed(by: UInt8(ascii: "\""), at: cursor) else { return unsupported() }
            textRange = quoted
            searchFrom = quoted.upperBound + 1
        } else {
            textRange = cursor ..< cursor
        }
        // The first closing sequence at or after the text.
        var found: (position: Int, length: Int, shape: FlowShape)?
        var scan = searchFrom
        search: while scan < end {
            for (closer, shape) in opener.closers {
                let bytes = Array(closer.utf8)
                if scan + bytes.count <= end, source[scan ..< (scan + bytes.count)].elementsEqual(bytes) {
                    found = (scan, bytes.count, shape)
                    break search
                }
            }
            scan += 1
        }
        guard let found else { return unsupported() }
        if textRange.isEmpty, searchFrom == cursor { textRange = cursor ..< found.position }
        var text = source[textRange]
        if text.count >= 2, text.first == UInt8(ascii: "`"), text.last == UInt8(ascii: "`") {
            text = text.dropFirst().dropLast()
        }
        diagram.nodes[node].shape = found.shape
        diagram.nodes[node].label = label(text)
        pos = found.position + found.length
    }
}
