/// Which way a flowchart's ranks run.
public enum FlowDirection: UInt8, Sendable, Equatable {
    case topDown, bottomUp, leftRight, rightLeft

    /// Whether ranks run along the vertical axis.
    public var isVertical: Bool { self == .topDown || self == .bottomUp }
}
