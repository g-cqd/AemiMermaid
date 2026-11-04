/// One thing the parser or the layout did not take as written: where, what, and for a limit, which one and the figure it reached.
public struct MermaidDiagnostic: Sendable, Equatable {
    public enum Kind: UInt8, Sendable, Equatable {
        /// A line that is not in the grammar subset, dropped.
        case unsupportedLine
        /// A label was cut at the limit.
        case labelTruncated
        /// A label had a control, a bidirectional control or invalid UTF-8, replaced.
        case labelSanitized
        /// A `subgraph` or a fragment was never closed; it is closed at the end.
        case unclosedBlock
        /// An `end` with nothing to close, dropped.
        case strayEnd
        /// A limit was reached; `limit` and `figure` say which and how far.
        case limit
        /// An edge named a subgraph, drawn as an edge to the subgraph's own node.
        case clusterEdgeApproximated
    }

    public var kind: Kind
    /// The line in the source, from 1; 0 for a diagnostic that belongs to no line.
    public var line: Int32
    /// The column in the line, from 1; 0 when not known.
    public var column: Int32
    public var limit: MermaidLimitKind?
    public var figure: Int32

    public init(kind: Kind, line: Int, column: Int = 0, limit: MermaidLimitKind? = nil, figure: Int = 0) {
        self.kind = kind
        self.line = Int32(clamping: line)
        self.column = Int32(clamping: column)
        self.limit = limit
        self.figure = Int32(clamping: figure)
    }
}
