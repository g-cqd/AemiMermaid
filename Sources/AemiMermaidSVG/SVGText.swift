/// Text made safe for an SVG attribute or element (ADR 0006): the five characters XML reserves are escaped, and a scalar XML 1.0 does not allow, or a bidirectional control, is dropped, so no
/// label can end an element, open a tag or smuggle a control into the markup.
enum SVGText {
    static func escaped(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for scalar in text.unicodeScalars {
            switch scalar.value {
                case 0x26: result += "&amp;"
                case 0x3C: result += "&lt;"
                case 0x3E: result += "&gt;"
                case 0x22: result += "&quot;"
                case 0x27: result += "&#39;"
                case 0x09, 0x0A, 0x0D, 0x20 ... 0x7E, 0xA0 ... 0xD7FF, 0xE000 ... 0xFFFD, 0x10000 ... 0x10FFFF:
                    if (0x202A ... 0x202E).contains(scalar.value) || (0x2066 ... 0x2069).contains(scalar.value)
                        || [0x200E, 0x200F, 0x061C, 0xFEFF].contains(scalar.value)
                    {
                        continue
                    }
                    result.unicodeScalars.append(scalar)
                default: continue
            }
        }
        return result
    }

    /// A number as it is written in markup: whole numbers without a point, others with at most two decimals.
    static func number(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(rounded)
    }
}
