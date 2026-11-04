internal import AemiMermaidScene

extension SVGRenderer {
    /// A direction as a unit step on the page.
    private func direction(from: ScenePoint, to: ScenePoint) -> (dx: Double, dy: Double) {
        (to.x > from.x ? 1 : (to.x < from.x ? -1 : 0), to.y > from.y ? 1 : (to.y < from.y ? -1 : 0))
    }

    /// A path as a polyline through the middle of its cells, its markers drawn at the ends: an end with a marker runs on to the edge of the cell that holds it, so the tip touches
    /// the shape it points at.
    func pathMarkup(_ path: ScenePath, _ scene: DiagramScene) -> String {
        let points = Array(scene.points[Int(path.first) ..< Int(path.first + path.count)])
        guard points.count >= 2 else { return "" }
        var coordinates = points.map { (cx($0.x), cy($0.y)) }
        let last = points[points.count - 1]
        let heading = direction(from: points[points.count - 2], to: last)
        let tip = (
            coordinates[coordinates.count - 1].0 + heading.dx * cellWidth,
            coordinates[coordinates.count - 1].1 + heading.dy * cellHeight
        )
        if path.endMarker != .none { coordinates.append(tip) }
        let list = coordinates.map { SVGText.number($0.0) + "," + SVGText.number($0.1) }.joined(separator: " ")
        let name: String
        switch (path.role, path.stroke) {
            case (.activation, _): name = "a"
            case (.muted, _): name = "u"
            case (.cluster, _): name = "c"
            case (_, .dashed): name = "e d"
            case (_, .thick): name = "e t"
            default: name = "e"
        }
        var out = "<polyline class=\"\(name)\" points=\"\(list)\"/>"
        out += marker(path.endMarker, at: tip, heading: heading)
        let first = coordinates[0]
        let outward = direction(from: points[1], to: points[0])
        out += marker(path.startMarker, at: first, heading: outward)
        return out
    }

    /// An arrowhead, a circle, a cross or an open head with its tip at `tip`, pointing along `heading`.
    private func marker(_ kind: SceneMarker, at tip: (Double, Double), heading: (dx: Double, dy: Double)) -> String {
        let (px, py) = (tip.0, tip.1)
        // Perpendicular, and the point 8 units back from the tip.
        let (nx, ny) = (-heading.dy, heading.dx)
        let (bx, by) = (px - heading.dx * 8, py - heading.dy * 8)
        func point(_ x: Double, _ y: Double) -> String { SVGText.number(x) + "," + SVGText.number(y) }
        switch kind {
            case .none: return ""
            case .arrow:
                return
                    "<polygon class=\"m\" points=\"\(point(px, py)) \(point(bx + nx * 4, by + ny * 4)) \(point(bx - nx * 4, by - ny * 4))\"/>"
            case .async:
                return
                    "<polyline class=\"e\" points=\"\(point(bx + nx * 4, by + ny * 4)) \(point(px, py)) \(point(bx - nx * 4, by - ny * 4))\"/>"
            case .circle:
                return
                    "<circle class=\"n\" cx=\"\(SVGText.number(px - heading.dx * 5))\" cy=\"\(SVGText.number(py - heading.dy * 5))\" r=\"4.5\"/>"
            case .cross:
                let (cx, cy) = (px - heading.dx * 5, py - heading.dy * 5)
                return
                    "<path class=\"e\" d=\"M\(point(cx - 4, cy - 4))L\(point(cx + 4, cy + 4))M\(point(cx - 4, cy + 4))L\(point(cx + 4, cy - 4))\"/>"
        }
    }
}
