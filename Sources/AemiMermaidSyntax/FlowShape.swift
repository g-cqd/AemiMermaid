/// The outline of a flowchart node.
public enum FlowShape: UInt8, Sendable, Equatable {
    /// `A[text]`
    case rectangle
    /// `A(text)`
    case rounded
    /// `A([text])`
    case stadium
    /// `A[[text]]`
    case subroutine
    /// `A[(text)]`
    case cylinder
    /// `A((text))`
    case circle
    /// `A(((text)))`
    case doubleCircle
    /// `A{text}`
    case diamond
    /// `A{{text}}`
    case hexagon
    /// `A[/text/]`
    case parallelogram
    /// `A[\text\]`
    case parallelogramAlt
    /// `A[/text\]`
    case trapezoid
    /// `A[\text/]`
    case trapezoidAlt
    /// `A>text]`
    case asymmetric
}
