extension FlowchartParser {
    /// `subgraph id [Title]`, `subgraph "Title"` or `subgraph Title`.
    mutating func openSubgraph() {
        skipSpaces()
        guard open.count < limits.maxNesting else { return refuse(.nesting, figure: open.count + 1) }
        var rest = source[pos ..< end]
        pos = end
        while rest.last == 0x20 || rest.last == 0x09 { rest = rest.dropLast() }
        var idBytes = rest
        var titleBytes = rest
        if let bracket = rest.firstIndex(of: UInt8(ascii: "[")), rest.last == UInt8(ascii: "]") {
            idBytes = rest[rest.startIndex ..< bracket]
            while idBytes.last == 0x20 { idBytes = idBytes.dropLast() }
            titleBytes = rest[(bracket + 1) ..< (rest.endIndex - 1)]
        }
        if titleBytes.count >= 2, titleBytes.first == UInt8(ascii: "\""), titleBytes.last == UInt8(ascii: "\"") {
            titleBytes = titleBytes.dropFirst().dropLast()
            if idBytes.first == UInt8(ascii: "\"") { idBytes = titleBytes }
        }
        if idBytes.isEmpty { idBytes = titleBytes }
        let symbol = symbols.symbol(idBytes)
        var index = clusterOf.get(symbol)
        if index < 0 {
            index = Int32(diagram.clusters.count)
            diagram.clusters.append(FlowCluster(id: label(idBytes), title: label(titleBytes), parent: open.last ?? -1))
            clusterOf.set(symbol, index)
        }
        open.append(index)
    }

    mutating func closeSubgraph() {
        if open.popLast() == nil { reader.diagnostics.add(.init(kind: .strayEnd, line: line)) }
    }
}
