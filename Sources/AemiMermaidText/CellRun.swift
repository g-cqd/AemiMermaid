public import AemiMermaidScene

/// A stretch of one row in one role: what a host maps to one style.
public struct CellRun: Sendable, Equatable {
    public var text: String
    public var role: SceneRole?

    public init(text: String, role: SceneRole?) {
        self.text = text
        self.role = role
    }
}
