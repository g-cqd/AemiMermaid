/// A piece of text placed in the scene: an edge's label, a title, a message.
public struct SceneText: Sendable, Equatable {
    /// A range of the scene's label arena.
    public typealias Ref = TextRef

    public var x: Int32
    public var y: Int32
    public var anchor: SceneAnchor
    public var role: SceneRole
    public var text: Ref

    public init(x: Int32, y: Int32, anchor: SceneAnchor, role: SceneRole, text: Ref) {
        self.x = x
        self.y = y
        self.anchor = anchor
        self.role = role
        self.text = text
    }
}
