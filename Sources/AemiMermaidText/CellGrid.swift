internal import AemiMermaidScene

/// A grid of character cells (ADR 0004): each cell has the directions its lines leave it in, by weight; the glyph is chosen from them when the rows are read, so lines
/// that meet make the right corner, tee or cross whichever was drawn first. A cell can also hold a character of its own, which wins over the lines.
struct CellGrid {
    let columns: Int
    let rows: Int
    private(set) var light: [UInt8]
    private(set) var heavy: [UInt8]
    private(set) var double: [UInt8]
    /// A character put in the cell, or 0; the second cell of a wide character holds `continuation`.
    private(set) var glyph: [UInt32]
    private(set) var role: [UInt8]
    private var rounded: [Bool]
    private var dashed: [Bool]
    static let continuation: UInt32 = 0xFFFF_FFFF

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        let count = columns * rows
        light = [UInt8](repeating: 0, count: count)
        heavy = light
        double = light
        glyph = [UInt32](repeating: 0, count: count)
        role = [UInt8](repeating: 255, count: count)
        rounded = [Bool](repeating: false, count: count)
        dashed = rounded
    }

    private func index(_ x: Int, _ y: Int) -> Int? {
        x >= 0 && y >= 0 && x < columns && y < rows ? y * columns + x : nil
    }

    mutating func line(
        _ x: Int,
        _ y: Int,
        _ mask: Int,
        weight: CellWeight,
        role newRole: SceneRole,
        dashed isDashed: Bool = false
    ) {
        guard let i = index(x, y) else { return }
        switch weight {
            case .light: light[i] |= UInt8(mask)
            case .heavy: heavy[i] |= UInt8(mask)
            case .double: double[i] |= UInt8(mask)
        }
        role[i] = newRole.rawValue
        if isDashed { dashed[i] = true }
    }

    /// How a line is drawn into the grid: its weight, the role of the cells, whether it is dashed.
    struct LineStyle {
        var weight: CellWeight
        var role: SceneRole
        var dashed: Bool
    }

    /// A straight run of line from `start` to `end` along row `fixed` (horizontal) or column `fixed`: its two ends leave only towards the run, the cells between both ways.
    mutating func run(horizontal: Bool, along fixed: Int, from start: Int, to end: Int, style: LineStyle) {
        let (low, high) = (Swift.min(start, end), Swift.max(start, end))
        let (back, forward) = horizontal ? (8, 2) : (1, 4)
        for position in low ... high {
            let mask = (position > low ? back : 0) | (position < high ? forward : 0)
            line(
                horizontal ? position : fixed,
                horizontal ? fixed : position,
                mask,
                weight: style.weight,
                role: style.role,
                dashed: style.dashed
            )
        }
    }

    mutating func round(_ x: Int, _ y: Int) {
        if let i = index(x, y) { rounded[i] = true }
    }

    mutating func put(_ scalar: UInt32, _ x: Int, _ y: Int, role newRole: SceneRole?) {
        guard let i = index(x, y) else { return }
        glyph[i] = scalar
        if let newRole { role[i] = newRole.rawValue }
    }

    mutating func markContinuation(_ x: Int, _ y: Int) {
        if let i = index(x, y) { glyph[i] = Self.continuation }
    }

    /// The character shown in a cell, or nil for the second half of a wide one.
    func character(_ x: Int, _ y: Int, ascii: Bool) -> Character? {
        let i = y * columns + x
        if glyph[i] == Self.continuation { return nil }
        if glyph[i] != 0 { return Character(Unicode.Scalar(glyph[i]) ?? "\u{FFFD}") }
        let weight: CellWeight
        let mask: Int
        if heavy[i] != 0 {
            (weight, mask) = (.heavy, Int(heavy[i] | light[i] | double[i]))
        } else if double[i] != 0 {
            (weight, mask) = (.double, Int(double[i] | light[i]))
        } else {
            (weight, mask) = (.light, Int(light[i]))
        }
        if mask == 0 { return " " }
        if dashed[i], !ascii, weight == .light {
            if mask == 10 { return "┄" }
            if mask == 5 { return "┆" }
        }
        return CellGlyphs.glyph(mask: mask, weight: weight, rounded: rounded[i], ascii: ascii)
    }

    func roleAt(_ x: Int, _ y: Int) -> SceneRole? {
        let value = role[y * columns + x]
        return value == 255 ? nil : SceneRole(rawValue: value)
    }
}
