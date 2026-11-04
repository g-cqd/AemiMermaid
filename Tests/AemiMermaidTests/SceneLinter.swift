@testable import AemiMermaidScene

/// The geometric rules every scene obeys (ADR 0004): returns what is broken, empty when nothing is.
enum SceneLinter {
    static func problems(_ scene: DiagramScene, checkEdges: Bool = true) -> [String] {
        var problems: [String] = []
        let width = Int(scene.width)
        let height = Int(scene.height)
        func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < width && y < height }
        for (index, shape) in scene.shapes.enumerated() {
            let (x, y, w, h) = (Int(shape.x), Int(shape.y), Int(shape.width), Int(shape.height))
            if !(inside(x, y) && inside(x + w - 1, y + h - 1)) {
                problems.append("shape \(index) \(shape.kind) leaves the scene")
            }
        }
        let nodes = scene.shapes.enumerated().filter { $0.element.role == .node }
        for (a, left) in nodes {
            for (b, right) in nodes where b > a {
                let separate =
                    left.x + left.width <= right.x || right.x + right.width <= left.x || left.y + left.height <= right.y
                    || right.y + right.height <= left.y
                if !separate { problems.append("nodes \(a) and \(b) overlap") }
            }
        }
        for (index, path) in scene.paths.enumerated() {
            let points = scene.points[Int(path.first) ..< Int(path.first + path.count)]
            for point in points where !inside(Int(point.x), Int(point.y)) {
                problems.append("path \(index) leaves the scene at \(point)")
            }
            for (a, b) in zip(points, points.dropFirst()) where a.x != b.x && a.y != b.y {
                problems.append("path \(index) has a slanted segment")
            }
        }
        for (index, text) in scene.texts.enumerated() where !inside(Int(text.x), Int(text.y)) {
            problems.append("text \(index) starts outside the scene")
        }
        guard checkEdges else { return problems }
        for (index, path) in scene.paths.enumerated() where path.role == .edge {
            let points = Array(scene.points[Int(path.first) ..< Int(path.first + path.count)])
            guard let first = points.first, let last = points.last else { continue }
            func contains(_ shape: SceneShape, _ x: Int, _ y: Int, margin: Int = 0) -> Bool {
                x >= Int(shape.x) - margin && x < Int(shape.x + shape.width) + margin && y >= Int(shape.y) - margin
                    && y < Int(shape.y + shape.height) + margin
            }
            let own =
                nodes.filter {
                    contains($0.element, Int(first.x), Int(first.y))
                        || contains($0.element, Int(last.x), Int(last.y), margin: 1)
                }
                .map(\.offset)
            for (a, b) in zip(points, points.dropFirst()) {
                for x in Swift.min(a.x, b.x) ... Swift.max(a.x, b.x) {
                    for y in Swift.min(a.y, b.y) ... Swift.max(a.y, b.y) {
                        for (node, shape) in nodes where !own.contains(node) && contains(shape, Int(x), Int(y)) {
                            problems.append("path \(index) passes through node \(node) at (\(x), \(y))")
                        }
                    }
                }
            }
        }
        return problems
    }
}
