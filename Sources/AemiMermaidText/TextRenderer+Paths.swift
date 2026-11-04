internal import AemiMermaidScene

extension TextRenderer {
    func drawLines(_ path: ScenePath, scene: DiagramScene, in grid: inout CellGrid) {
        let points = scene.points[Int(path.first) ..< Int(path.first + path.count)]
        let style = CellGrid.LineStyle(
            weight: path.stroke == .thick ? .heavy : .light,
            role: path.role,
            dashed: path.stroke == .dashed
        )
        for (from, point) in zip(points, points.dropFirst()) {
            if from.y == point.y {
                grid.run(horizontal: true, along: Int(point.y), from: Int(from.x), to: Int(point.x), style: style)
            } else if from.x == point.x {
                grid.run(horizontal: false, along: Int(point.x), from: Int(from.y), to: Int(point.y), style: style)
            }
        }
    }

    /// The heading from `from` to `to` as a direction bit (north 1, east 2, south 4, west 8).
    private func heading(from: ScenePoint, to: ScenePoint) -> Int {
        if to.x > from.x { return 2 }
        if to.x < from.x { return 8 }
        return to.y > from.y ? 4 : 1
    }

    func drawMarkers(_ path: ScenePath, scene: DiagramScene, in grid: inout CellGrid) {
        guard path.count >= 2 else { return }
        let first = Int(path.first)
        let count = Int(path.count)
        let points = scene.points
        func glyph(_ marker: SceneMarker, heading: Int) -> Character? {
            switch marker {
                case .none: nil
                case .arrow: CellGlyphs.arrow(direction: heading, ascii: ascii)
                case .circle: ascii ? "o" : "○"
                case .cross: ascii ? "x" : "×"
                case .async: ascii ? ")" : "⟩"
            }
        }
        if let character = glyph(
            path.endMarker,
            heading: heading(from: points[first + count - 2], to: points[first + count - 1])
        ),
            let value = character.unicodeScalars.first?.value
        {
            grid.put(value, Int(points[first + count - 1].x), Int(points[first + count - 1].y), role: path.role)
        }
        if let character = glyph(path.startMarker, heading: heading(from: points[first + 1], to: points[first])),
            let value = character.unicodeScalars.first?.value
        {
            // One cell out along the first segment, so the node's border stays whole.
            let next = points[first + 1]
            let step = heading(from: points[first], to: next)
            let dx = step == 2 ? 1 : (step == 8 ? -1 : 0)
            let dy = step == 4 ? 1 : (step == 1 ? -1 : 0)
            grid.put(value, Int(points[first].x) + dx, Int(points[first].y) + dy, role: path.role)
        }
    }
}
