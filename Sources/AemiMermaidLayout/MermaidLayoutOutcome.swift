/// What a layout came to: a scene of this size, or the reason the diagram is shown as source.
public enum MermaidLayoutOutcome: Equatable, Sendable {
    case drawn(width: Int, height: Int)
    case source(MermaidLayoutRefusal)
}

/// Why a diagram was not laid out.
public enum MermaidLayoutRefusal: Equatable, Sendable {
    /// Long edges need more room on the ranks they cross than the limit allows.
    case virtualNodes(Int)
    /// The narrowest layout is wider than the width given.
    case tooWide(needed: Int, available: Int)
    /// Nothing to draw.
    case empty
}
