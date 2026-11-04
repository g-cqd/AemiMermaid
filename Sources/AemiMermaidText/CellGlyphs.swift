/// The glyph for the directions a cell's lines leave it in (north 1, east 2, south 4, west 8), by weight, and the ASCII stand-ins.
enum CellGlyphs {
    static let light = Array(" ╵╶└╷│┌├╴┘─┴┐┤┬┼")
    static let heavy = Array(" ╹╺┗╻┃┏┣╸┛━┻┓┫┳╋")
    static let double = Array(" ║═╚║║╔╠═╝═╩╗╣╦╬")

    static func glyph(mask: Int, weight: CellWeight, rounded: Bool, ascii: Bool) -> Character {
        if ascii {
            switch mask {
                case 0: return " "
                case 5, 1, 4: return "|"
                case 10, 2, 8: return "-"
                default: return "+"
            }
        }
        if rounded, weight == .light {
            switch mask {
                case 3: return "╰"
                case 6: return "╭"
                case 9: return "╯"
                case 12: return "╮"
                default: break
            }
        }
        switch weight {
            case .light: return light[mask]
            case .heavy: return heavy[mask]
            case .double: return double[mask]
        }
    }

    /// The arrowhead for a path that ends going `direction` (north 1, east 2, south 4, west 8).
    static func arrow(direction: Int, ascii: Bool) -> Character {
        switch direction {
            case 1: ascii ? "^" : "▲"
            case 2: ascii ? ">" : "▶"
            case 4: ascii ? "v" : "▼"
            default: ascii ? "<" : "◀"
        }
    }
}
