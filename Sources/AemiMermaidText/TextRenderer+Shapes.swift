internal import AemiMermaidScene

extension TextRenderer {
    private func scalar(_ character: Character) -> UInt32 { character.unicodeScalars.first?.value ?? 0x20 }

    func drawBorder(_ shape: SceneShape, in grid: inout CellGrid) {
        let (x, y, w, h) = (Int(shape.x), Int(shape.y), Int(shape.width), Int(shape.height))
        guard w >= 2, h >= 2 else { return }
        let weight: CellWeight = (shape.kind == .subroutine || shape.kind == .doubleCircle) ? .double : .light
        let role = shape.role
        let style = CellGrid.LineStyle(weight: weight, role: role, dashed: shape.kind == .frame)
        for row in [y, y + h - 1] { grid.run(horizontal: true, along: row, from: x, to: x + w - 1, style: style) }
        for column in [x, x + w - 1] {
            grid.run(horizontal: false, along: column, from: y, to: y + h - 1, style: style)
        }
        switch shape.kind {
            case .rounded, .stadium, .circle, .cylinder, .frame, .note:
                for (cx, cy) in [(x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)] { grid.round(cx, cy) }
            default: break
        }
        func corner(_ cx: Int, _ cy: Int, _ light: Character, _ plain: Character) {
            grid.put(scalar(ascii ? plain : light), cx, cy, role: role)
        }
        switch shape.kind {
            case .diamond, .hexagon:
                corner(x, y, "╱", "/")
                corner(x + w - 1, y, "╲", "\\")
                corner(x, y + h - 1, "╲", "\\")
                corner(x + w - 1, y + h - 1, "╱", "/")
            case .parallelogram:
                corner(x, y, "╱", "/")
                corner(x + w - 1, y + h - 1, "╱", "/")
            case .parallelogramAlt:
                corner(x, y, "╲", "\\")
                corner(x + w - 1, y + h - 1, "╲", "\\")
            case .trapezoid:
                corner(x, y, "╱", "/")
                corner(x + w - 1, y, "╲", "\\")
            case .trapezoidAlt:
                corner(x, y + h - 1, "╲", "\\")
                corner(x + w - 1, y + h - 1, "╱", "/")
            case .asymmetric: corner(x, y + h / 2, "▷", ">")
            case .cylinder:
                grid.line(x, y + 1, 2, weight: .light, role: role)
                grid.line(x + w - 1, y + 1, 8, weight: .light, role: role)
                for column in (x + 1) ..< (x + w - 1) { grid.line(column, y + 1, 10, weight: .light, role: role) }
            case .frame, .note, .actor, .bar, .rectangle, .rounded, .stadium, .subroutine, .circle, .doubleCircle: break
        }
    }

    /// A shape's text: a frame's title in its top border, any other shape's lines centred inside it.
    func drawLabel(_ shape: SceneShape, scene: DiagramScene, in grid: inout CellGrid) {
        let text = scene.string(shape.text)
        guard !text.isEmpty else { return }
        if shape.kind == .frame {
            put(
                " " + text + " ",
                x: Int(shape.x) + 2,
                y: Int(shape.y),
                anchor: .leading,
                role: .clusterTitle,
                in: &grid
            )
            return
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let top = Int(shape.y) + 1 + (shape.kind == .cylinder ? 1 : 0)
        let room = Int(shape.height) - 2 - (shape.kind == .cylinder ? 1 : 0)
        let first = top + Swift.max(0, (room - lines.count) / 2)
        for (index, line) in lines.enumerated() {
            let width = metrics.width(of: ArraySlice(line.utf8))
            let column = Int(shape.x) + 1 + Swift.max(0, (Int(shape.width) - 2 - width) / 2)
            put(String(line), x: column, y: first + index, anchor: .leading, role: shape.role, in: &grid)
        }
    }
}
