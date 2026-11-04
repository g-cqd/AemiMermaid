/// A box in the scene, in the scene's units: cells for a terminal, points for a window.
public struct SceneShape: Sendable, Equatable {
    public var kind: SceneShapeKind
    public var role: SceneRole
    public var x: Int32
    public var y: Int32
    public var width: Int32
    public var height: Int32
    /// The text inside the shape: a range of the scene's label arena, with `\n` between lines.
    public var text: SceneText.Ref
    /// The shape's index in the order drawn; a frame comes before what it holds.
    public var order: Int32

    public init(
        kind: SceneShapeKind,
        role: SceneRole,
        x: Int32,
        y: Int32,
        width: Int32,
        height: Int32,
        text: SceneText.Ref,
        order: Int32
    ) {
        self.kind = kind
        self.role = role
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.text = text
        self.order = order
    }
}
