/// A rectangle by its corners, in cells: the extent of a frame being grown.
struct SceneRect {
    var minX: Int32
    var minY: Int32
    var maxX: Int32
    var maxY: Int32

    func union(_ other: SceneRect) -> SceneRect {
        SceneRect(
            minX: Swift.min(minX, other.minX),
            minY: Swift.min(minY, other.minY),
            maxX: Swift.max(maxX, other.maxX),
            maxY: Swift.max(maxY, other.maxY)
        )
    }
}
