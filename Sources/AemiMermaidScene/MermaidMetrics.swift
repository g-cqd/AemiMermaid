/// How big text is, and how much room a layout leaves: in character cells for a terminal (ADR 0004).
///
/// `columns` answers for one scalar: 0 for a combining mark, 1 for most, 2 for a wide character. A host passes its own (ask passes TerminalKit's `UnicodeWidth`), so the
/// diagram agrees with the terminal about where the cursor is.
public struct MermaidMetrics: Sendable {
    /// The columns a scalar takes.
    public var columns: @Sendable (Unicode.Scalar) -> Int
    /// The widest a label's line may be before the label is wrapped.
    public var maxLabelColumns: Int
    /// The empty columns between two nodes of a rank, and the empty rows between two ranks beyond the lanes edges need.
    public var nodeGap: Int
    public var rankGap: Int

    public init(
        columns: @escaping @Sendable (Unicode.Scalar) -> Int = MermaidMetrics.defaultColumns,
        maxLabelColumns: Int = 40,
        nodeGap: Int = 2,
        rankGap: Int = 0
    ) {
        self.columns = columns
        self.maxLabelColumns = maxLabelColumns
        self.nodeGap = nodeGap
        self.rankGap = rankGap
    }

    /// Cells as a terminal commonly draws them: combining marks and format characters take none, East Asian wide blocks and emoji take two, the rest one.
    public static let defaultColumns: @Sendable (Unicode.Scalar) -> Int = { scalar in
        let value = scalar.value
        switch value {
            case 0x0300 ... 0x036F, 0x200B ... 0x200D, 0xFE00 ... 0xFE0F, 0x20D0 ... 0x20FF: return 0
            case 0x1100 ... 0x115F, 0x2E80 ... 0xA4CF, 0xAC00 ... 0xD7A3, 0xF900 ... 0xFAFF, 0xFE30 ... 0xFE6F,
                0xFF00 ... 0xFF60, 0xFFE0 ... 0xFFE6,
                0x1F300 ... 0x1F64F, 0x1F900 ... 0x1F9FF, 0x20000 ... 0x3FFFD:
                return 2
            default: return 1
        }
    }

    /// The columns of `bytes`, a cleaned UTF-8 label line.
    public func width(of bytes: ArraySlice<UInt8>) -> Int {
        var total = 0
        for scalar in String(decoding: bytes, as: UTF8.self).unicodeScalars { total += columns(scalar) }
        return total
    }
}
