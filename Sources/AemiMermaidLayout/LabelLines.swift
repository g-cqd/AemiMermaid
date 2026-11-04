internal import AemiMermaidScene

/// A label cut into lines no wider than a number of columns: at the `\n` it has, then at spaces, and inside a word only when the word alone is too wide.
struct LabelLines {
    /// The lines as ranges of the label's bytes.
    private(set) var lines: [Range<Int>] = []
    private(set) var width = 0

    init(_ label: ArraySlice<UInt8>, maxColumns: Int, metrics: MermaidMetrics) {
        let limit = Swift.max(1, maxColumns)
        var lineStart = label.startIndex
        var index = label.startIndex
        var columns = 0
        var lastSpace: (index: Int, columns: Int)?
        func close(_ stop: Int) {
            lines.append(lineStart ..< stop)
            width = Swift.max(width, metrics.width(of: label[lineStart ..< stop]))
        }
        while index < label.endIndex {
            let byte = label[index]
            if byte == 0x0A {
                close(index)
                index += 1
                lineStart = index
                (columns, lastSpace) = (0, nil)
                continue
            }
            // One scalar: its length from the lead byte, its columns from the metrics.
            let length = byte < 0x80 ? 1 : (byte >= 0xF0 ? 4 : (byte >= 0xE0 ? 3 : 2))
            let stop = Swift.min(label.endIndex, index + length)
            let scalarColumns = metrics.width(of: label[index ..< stop])
            if columns + scalarColumns > limit, index > lineStart {
                if let space = lastSpace {
                    close(space.index)
                    lineStart = space.index + 1
                    columns -= space.columns + 1
                    lastSpace = nil
                } else {
                    close(index)
                    lineStart = index
                    columns = 0
                }
            }
            if byte == 0x20 { lastSpace = (index, columns) }
            columns += scalarColumns
            index = stop
        }
        close(label.endIndex)
    }
}
