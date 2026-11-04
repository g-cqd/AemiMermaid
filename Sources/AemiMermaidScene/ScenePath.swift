/// A polyline of the scene: the points are `DiagramScene.points[first ..< first + count]`, joined by horizontal and vertical segments only.
public struct ScenePath: Sendable, Equatable {
    public var first: Int32
    public var count: Int32
    public var role: SceneRole
    public var stroke: SceneStroke
    public var startMarker: SceneMarker
    public var endMarker: SceneMarker

    public init(
        first: Int32,
        count: Int32,
        role: SceneRole,
        stroke: SceneStroke,
        startMarker: SceneMarker,
        endMarker: SceneMarker
    ) {
        self.first = first
        self.count = count
        self.role = role
        self.stroke = stroke
        self.startMarker = startMarker
        self.endMarker = endMarker
    }
}
