public import AemiMermaidScene

/// Draws a ``DiagramScene`` in character cells (ADR 0004): lines as box-drawing characters or ASCII, text where the scene puts it, every character one the metrics
/// knows the width of.
public struct TextRenderer: Sendable {
    public var metrics: MermaidMetrics
    /// Only ASCII characters, for a terminal or a log that cannot draw box characters.
    public var ascii: Bool
    /// The most cells a scene may take; a larger one is not drawn.
    public var maxCells: Int

    public init(metrics: MermaidMetrics = MermaidMetrics(), ascii: Bool = false, maxCells: Int = 1_000_000) {
        self.metrics = metrics
        self.ascii = ascii
        self.maxCells = maxCells
    }

    /// The rows of `scene`, each as runs of one role; nil if the scene is larger than `maxCells`.
    public func rows(_ scene: DiagramScene) -> [[CellRun]]? {
        guard let grid = draw(scene) else { return nil }
        var rows: [[CellRun]] = []
        for y in 0 ..< grid.rows {
            var runs: [CellRun] = []
            var current = ""
            var currentRole: SceneRole?
            for x in 0 ..< grid.columns {
                guard let character = grid.character(x, y, ascii: ascii) else { continue }
                let role = grid.roleAt(x, y)
                if role != currentRole, !current.isEmpty {
                    runs.append(CellRun(text: current, role: currentRole))
                    current = ""
                }
                currentRole = role
                current.append(character)
            }
            if !current.isEmpty { runs.append(CellRun(text: current, role: currentRole)) }
            // No trailing blank run.
            while let last = runs.last, last.role == nil, last.text.allSatisfy({ $0 == " " }) { runs.removeLast() }
            rows.append(runs)
        }
        return rows
    }

    /// The scene as lines of plain text.
    public func text(_ scene: DiagramScene) -> [String]? {
        rows(scene)?.map { $0.map(\.text).joined() }
    }

    func draw(_ scene: DiagramScene) -> CellGrid? {
        let columns = Int(scene.width)
        let rows = Int(scene.height)
        guard columns > 0, rows > 0, columns <= maxCells / rows else { return nil }
        var grid = CellGrid(columns: columns, rows: rows)
        for shape in scene.shapes { drawBorder(shape, in: &grid) }
        for path in scene.paths { drawLines(path, scene: scene, in: &grid) }
        for shape in scene.shapes { drawLabel(shape, scene: scene, in: &grid) }
        for path in scene.paths { drawMarkers(path, scene: scene, in: &grid) }
        for text in scene.texts {
            put(
                scene.string(text.text),
                x: Int(text.x),
                y: Int(text.y),
                anchor: text.anchor,
                role: text.role,
                in: &grid
            )
        }
        return grid
    }

    /// Puts `text` in a row, its anchor at `x`. A character without a known width, or a control, becomes U+FFFD.
    func put(_ text: String, x: Int, y: Int, anchor: SceneAnchor, role: SceneRole, in grid: inout CellGrid) {
        var width = 0
        var scalars: [(UInt32, Int)] = []
        for scalar in text.unicodeScalars {
            var value = scalar.value
            if value < 0x20 || value == 0x7F || (0x80 ... 0x9F).contains(value)
                || [0x061C, 0x200E, 0x200F, 0xFEFF].contains(value)
                || (0x202A ... 0x202E).contains(value) || (0x2066 ... 0x2069).contains(value)
            {
                value = 0xFFFD
            }
            let columns = metrics.columns(Unicode.Scalar(value) ?? "\u{FFFD}")
            guard columns > 0 else { continue }
            if ascii, value > 0x7E { value = 0x3F }
            scalars.append((value, columns))
            width += columns
        }
        var column = anchor == .leading ? x : (anchor == .center ? x - width / 2 : x - width)
        for (value, columns) in scalars {
            grid.put(value, column, y, role: role)
            if columns == 2 { grid.markContinuation(column + 1, y) }
            column += columns
        }
    }
}
