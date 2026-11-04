internal import AemiMermaidScene

extension SVGRenderer {
    private func polygon(_ points: [(Double, Double)], class name: String) -> String {
        let list = points.map { SVGText.number($0.0) + "," + SVGText.number($0.1) }.joined(separator: " ")
        return "<polygon class=\"\(name)\" points=\"\(list)\"/>"
    }

    private func rect(
        _ left: Double,
        _ top: Double,
        _ width: Double,
        _ height: Double,
        radius: Double,
        class name: String
    ) -> String {
        let box =
            "x=\"\(SVGText.number(left))\" y=\"\(SVGText.number(top))\" width=\"\(SVGText.number(width))\" height=\"\(SVGText.number(height))\""
        return "<rect class=\"\(name)\" \(box) rx=\"\(SVGText.number(radius))\"/>"
    }

    private func stroke(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> String {
        "<path class=\"e\" d=\"M\(SVGText.number(x1)) \(SVGText.number(y1))L\(SVGText.number(x2)) \(SVGText.number(y2))\"/>"
    }

    /// A shape's outline and its text: the lines run through the middle of the cells at the shape's edge, as they do in the cell backend.
    func shapeMarkup(_ shape: SceneShape, _ scene: DiagramScene) -> String {
        let left = cx(shape.x)
        let right = cx(shape.x + shape.width - 1)
        let top = cy(shape.y)
        let bottom = cy(shape.y + shape.height - 1)
        let (width, height) = (right - left, bottom - top)
        let (midX, midY) = ((left + right) / 2, (top + bottom) / 2)
        let slant = Swift.min(12, width / 4)
        var out: String
        switch shape.kind {
            case .rectangle, .actor, .bar: out = rect(left, top, width, height, radius: 0, class: "n")
            case .rounded: out = rect(left, top, width, height, radius: 6, class: "n")
            case .stadium, .circle: out = rect(left, top, width, height, radius: height / 2, class: "n")
            case .doubleCircle:
                out = rect(left, top, width, height, radius: height / 2, class: "n")
                out += rect(left + 3, top + 3, width - 6, height - 6, radius: height / 2 - 3, class: "n")
            case .subroutine:
                out = rect(left, top, width, height, radius: 0, class: "n") + stroke(left + 9, top, left + 9, bottom)
                out += stroke(right - 9, top, right - 9, bottom)
            case .cylinder:
                out = rect(left, top, width, height, radius: 6, class: "n") + stroke(left, top + 9, right, top + 9)
            case .diamond: out = polygon([(midX, top), (right, midY), (midX, bottom), (left, midY)], class: "n")
            case .hexagon:
                let corners = [
                    (left + slant, top), (right - slant, top), (right, midY), (right - slant, bottom),
                    (left + slant, bottom), (left, midY)
                ]
                out = polygon(corners, class: "n")
            case .parallelogram:
                out = polygon([(left + slant, top), (right, top), (right - slant, bottom), (left, bottom)], class: "n")
            case .parallelogramAlt:
                out = polygon([(left, top), (right - slant, top), (right, bottom), (left + slant, bottom)], class: "n")
            case .trapezoid:
                out = polygon([(left + slant, top), (right - slant, top), (right, bottom), (left, bottom)], class: "n")
            case .trapezoidAlt:
                out = polygon([(left, top), (right, top), (right - slant, bottom), (left + slant, bottom)], class: "n")
            case .asymmetric:
                out = polygon(
                    [(left, top), (right, top), (right, bottom), (left, bottom), (left + slant, midY)],
                    class: "n"
                )
            case .frame: out = rect(left, top, width, height, radius: 6, class: "c")
            case .note:
                out = polygon(
                    [(left, top), (right - 9, top), (right, top + 9), (right, bottom), (left, bottom)],
                    class: "nt"
                )
        }
        let text = scene.string(shape.text)
        guard !text.isEmpty else { return out }
        if shape.kind == .frame {
            return out + line(text, x: left + 14, baseline: top + 4.5, anchor: "start", class: "ct")
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let first = midY - Double(lines.count - 1) * cellHeight / 2 + 4.5
        for (index, piece) in lines.enumerated() {
            out += line(
                String(piece),
                x: midX,
                baseline: first + Double(index) * cellHeight,
                anchor: "middle",
                class: "l"
            )
        }
        return out
    }
}
