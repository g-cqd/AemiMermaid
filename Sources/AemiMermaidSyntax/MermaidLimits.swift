/// What a diagram may cost before it is refused (ADR 0002). Every loop of the parser and of the layout is bounded by one of these, so no input takes more than a
/// fixed multiple of its size; the defaults are for a diagram in a transcript or a document, `terminal` for one drawn in cells.
public struct MermaidLimits: Sendable, Equatable {
    /// The longest source, in bytes.
    public var maxSourceBytes: Int
    /// The most nodes, states, classes or participants.
    public var maxNodes: Int
    /// The most edges, transitions or relations.
    public var maxEdges: Int
    /// The longest label, in bytes of the cleaned text; a longer one is cut and reported.
    public var maxLabelBytes: Int
    /// The deepest nesting of subgraphs, composite states and fragments.
    public var maxNesting: Int
    /// The most messages in a sequence diagram.
    public var maxMessages: Int
    /// The longest line, in bytes; a longer one is dropped and reported.
    public var maxLineBytes: Int
    /// The most nodes a layout may add to give long edges a place on each rank they cross.
    public var maxVirtualNodes: Int

    public init(
        maxSourceBytes: Int = 256 * 1024,
        maxNodes: Int = 2000,
        maxEdges: Int = 8000,
        maxLabelBytes: Int = 2048,
        maxNesting: Int = 16,
        maxMessages: Int = 5000,
        maxLineBytes: Int = 8192,
        maxVirtualNodes: Int = 50_000
    ) {
        self.maxSourceBytes = maxSourceBytes
        self.maxNodes = maxNodes
        self.maxEdges = maxEdges
        self.maxLabelBytes = maxLabelBytes
        self.maxNesting = maxNesting
        self.maxMessages = maxMessages
        self.maxLineBytes = maxLineBytes
        self.maxVirtualNodes = maxVirtualNodes
    }

    /// For a diagram drawn with pixels.
    public static let `default` = MermaidLimits()

    /// For a diagram drawn in character cells: a screenful, not a poster.
    public static let terminal = MermaidLimits(
        maxNodes: 500,
        maxEdges: 2000,
        maxMessages: 1000,
        maxVirtualNodes: 10_000
    )
}
