/// The arrow of a sequence diagram message.
public enum SequenceArrow: UInt8, Sendable, Equatable {
    /// `->`: a solid line, no arrowhead.
    case solid
    /// `->>`: a solid line with an arrowhead.
    case solidArrow
    /// `-->`: a dashed line, no arrowhead.
    case dashed
    /// `-->>`: a dashed line with an arrowhead.
    case dashedArrow
    /// `-x`
    case solidCross
    /// `--x`
    case dashedCross
    /// `-)`: an asynchronous message.
    case solidAsync
    /// `--)`
    case dashedAsync

    public var isDashed: Bool {
        switch self {
            case .dashed, .dashedArrow, .dashedCross, .dashedAsync: true
            default: false
        }
    }
}
