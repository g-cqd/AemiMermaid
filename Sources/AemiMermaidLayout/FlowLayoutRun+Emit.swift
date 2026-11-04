internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension FlowLayoutRun {
    private func kind(of shape: FlowShape) -> SceneShapeKind {
        switch shape {
            case .rectangle: .rectangle
            case .rounded: .rounded
            case .stadium: .stadium
            case .subroutine: .subroutine
            case .cylinder: .cylinder
            case .circle: .circle
            case .doubleCircle: .doubleCircle
            case .diamond: .diamond
            case .hexagon: .hexagon
            case .parallelogram: .parallelogram
            case .parallelogramAlt: .parallelogramAlt
            case .trapezoid: .trapezoid
            case .trapezoidAlt: .trapezoidAlt
            case .asymmetric: .asymmetric
        }
    }

    private func marker(_ end: FlowEnd) -> SceneMarker {
        switch end {
            case .none: .none
            case .arrow: .arrow
            case .circle: .circle
            case .cross: .cross
        }
    }

    /// How deeply clusters nest at most: the margin the frames need around the drawing.
    private var clusterDepth: Int {
        var depth = [Int](repeating: 1, count: diagram.clusters.count)
        var most = 0
        for (index, cluster) in diagram.clusters.enumerated() {
            if cluster.parent >= 0 { depth[index] = depth[Int(cluster.parent)] + 1 }
            most = Swift.max(most, depth[index])
        }
        return most
    }

    /// The abstract plane (rank axis, order axis) put on the page: where the direction says, flipped for bottom up and right to left, inside the margin the frames need.
    struct Placement {
        var vertical: Bool
        var flipped: Bool
        var extentA: Int32
        var margin: Int32
        /// Cells added before the order axis for what sticks out of it.
        var shiftB: Int32 = 0

        /// A box of the abstract plane, as x, y, width, height.
        func box(_ posA: Int32, _ posB: Int32, _ sizeA: Int32, _ sizeB: Int32) -> (
            origin: ScenePoint, width: Int32, height: Int32
        ) {
            let along = flipped ? extentA - posA - sizeA : posA
            return vertical
                ? (ScenePoint(x: posB + margin + shiftB, y: along + margin), sizeB, sizeA)
                : (ScenePoint(x: along + margin, y: posB + margin + shiftB), sizeA, sizeB)
        }

        func point(_ pointA: Int32, _ pointB: Int32) -> ScenePoint {
            let along = flipped ? extentA - 1 - pointA : pointA
            return vertical
                ? ScenePoint(x: pointB + margin + shiftB, y: along + margin)
                : ScenePoint(x: along + margin, y: pointB + margin + shiftB)
        }
    }

    /// Phase 8 and 9: the scene, with the axes put where the direction says and the frames of the clusters around their nodes.
    func emit(into scene: inout DiagramScene) {
        scene.reset()
        let placement = Placement(
            vertical: diagram.direction.isVertical,
            flipped: diagram.direction == .bottomUp || diagram.direction == .rightLeft,
            extentA: extent.a,
            margin: Int32(clusterDepth * 2),
            shiftB: overhang
        )
        scene.width = (placement.vertical ? extent.b + overhang : extent.a) + 2 * placement.margin
        scene.height = (placement.vertical ? extent.a : extent.b + overhang) + 2 * placement.margin
        emitFrames(placement, into: &scene)
        emitNodes(placement, into: &scene)
        emitEdges(placement, into: &scene)
    }

    /// The frames of the clusters, first, so they are behind what they hold: the box of each cluster's nodes and of the clusters in it, two cells out.
    private func emitFrames(_ placement: Placement, into scene: inout DiagramScene) {
        var frames = [SceneRect?](repeating: nil, count: diagram.clusters.count)
        for (index, node) in diagram.nodes.enumerated() where node.cluster >= 0 {
            let (origin, w, h) = placement.box(
                graph.posA[index],
                graph.posB[index],
                graph.sizeA[index],
                graph.sizeB[index]
            )
            let rect = SceneRect(minX: origin.x - 2, minY: origin.y - 2, maxX: origin.x + w + 1, maxY: origin.y + h + 1)
            frames[Int(node.cluster)] = frames[Int(node.cluster)]?.union(rect) ?? rect
        }
        for index in diagram.clusters.indices.reversed() {
            let parent = Int(diagram.clusters[index].parent)
            guard parent >= 0, let frame = frames[index] else { continue }
            let rect = SceneRect(minX: frame.minX - 2, minY: frame.minY - 2, maxX: frame.maxX + 2, maxY: frame.maxY + 2)
            frames[parent] = frames[parent]?.union(rect) ?? rect
        }
        for (index, cluster) in diagram.clusters.enumerated() {
            guard let frame = frames[index] else { continue }
            let title = diagram.labels.slice(cluster.title)
            let frameWidth = Swift.max(frame.maxX - frame.minX + 1, Int32(metrics.width(of: title) + 4))
            scene.width = Swift.max(scene.width, frame.minX + frameWidth)
            scene.shapes.append(
                SceneShape(
                    kind: .frame,
                    role: .cluster,
                    x: frame.minX,
                    y: frame.minY,
                    width: frameWidth,
                    height: frame.maxY - frame.minY + 1,
                    text: scene.addLabel(title),
                    order: Int32(scene.shapes.count)
                )
            )
        }
    }

    private func emitNodes(_ placement: Placement, into scene: inout DiagramScene) {
        for (index, node) in diagram.nodes.enumerated() {
            let (origin, w, h) = placement.box(
                graph.posA[index],
                graph.posB[index],
                graph.sizeA[index],
                graph.sizeB[index]
            )
            let label = diagram.labels.slice(node.label)
            var text: [UInt8] = []
            for (number, range) in lines[index].lines.enumerated() {
                if number > 0 { text.append(0x0A) }
                text.append(contentsOf: label[range])
            }
            scene.shapes.append(
                SceneShape(
                    kind: kind(of: node.shape),
                    role: .node,
                    x: origin.x,
                    y: origin.y,
                    width: w,
                    height: h,
                    text: scene.addLabel(text[...]),
                    order: Int32(scene.shapes.count)
                )
            )
        }
    }

    /// Each edge as a path with its markers, and its label where the routing put it. An edge turned round to break a cycle is drawn from the other end.
    private func emitEdges(_ placement: Placement, into scene: inout DiagramScene) {
        for (index, edge) in diagram.edges.enumerated() where edge.line != .invisible {
            let route = routes[index].map { placement.point($0.a, $0.b) }
            guard route.count >= 2 else { continue }
            var start = marker(edge.tail)
            var end = marker(edge.head)
            if graph.reversed[index] { swap(&start, &end) }
            if edge.from == edge.to { (start, end) = (.none, marker(edge.head)) }
            let stroke: SceneStroke = edge.line == .dotted ? .dashed : (edge.line == .thick ? .thick : .solid)
            scene.addPath(route, role: .edge, stroke: stroke, start: start, end: end)
            guard let at = labelAt[index], !edge.label.isEmpty else { continue }
            let place = placement.point(at.a, at.b)
            let text = scene.addLabel(diagram.labels.slice(edge.label))
            scene.texts.append(SceneText(x: place.x, y: place.y, anchor: .leading, role: .label, text: text))
        }
    }
}
