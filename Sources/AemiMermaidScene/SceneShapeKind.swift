/// The outline of a ``SceneShape``.
public enum SceneShapeKind: UInt8, Sendable, Equatable {
    case rectangle, rounded, stadium, subroutine, cylinder, circle, doubleCircle, diamond, hexagon
    case parallelogram, parallelogramAlt, trapezoid, trapezoidAlt, asymmetric
    /// A subgraph or a fragment: a frame with a title, behind what it holds.
    case frame
    /// A note: a box with a folded corner.
    case note
    /// An actor: a figure above its name.
    case actor
    /// An activation bar on a lifeline.
    case bar
}
