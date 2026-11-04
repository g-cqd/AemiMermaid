/// Cleans a label's bytes (ADR 0003, layer one): what comes out holds only text a terminal or a layout can show.
///
/// - Invalid UTF-8 and every scalar that is a control (below U+0020 but tab, U+007F, U+0080 to U+009F), a bidirectional control (U+061C, U+200E, U+200F, U+202A to
///   U+202E, U+2066 to U+2069), a byte order mark or a line or paragraph separator becomes U+FFFD, or a space for the white space among them.
/// - `<br/>`, `<br>` and `<br />` (any case) become a line break; the entities `&amp; &lt; &gt; &quot; &apos; &nbsp;` and numeric ones are decoded.
/// - The text is trimmed, and cut at `maxBytes` on a scalar boundary.
public enum LabelSanitizer {
    public struct Outcome: OptionSet, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        /// Something was replaced.
        public static let replaced = Outcome(rawValue: 1 << 0)
        /// The label was cut.
        public static let truncated = Outcome(rawValue: 1 << 1)
    }

    /// Appends the cleaned `raw` to `output`.
    public static func clean(_ raw: ArraySlice<UInt8>, maxBytes: Int, into output: inout [UInt8]) -> Outcome {
        var outcome: Outcome = []
        let start = output.count
        var index = raw.startIndex
        let end = raw.endIndex
        while index < end {
            if output.count - start >= maxBytes {
                outcome.insert(.truncated)
                break
            }
            let byte = raw[index]
            if byte == UInt8(ascii: "<"), let length = lineBreakTag(raw, index) {
                output.append(0x0A)
                index += length
                continue
            }
            if byte == UInt8(ascii: "&"), let (scalar, length) = entity(raw, index) {
                append(scalar, to: &output, outcome: &outcome)
                index += length
                continue
            }
            if byte < 0x80 {
                append(UInt32(byte), to: &output, outcome: &outcome)
                index += 1
                continue
            }
            let (scalar, length) = decode(raw, index)
            append(scalar, to: &output, outcome: &outcome)
            index += length
        }
        trim(&output, from: start)
        if output.count - start > maxBytes { cut(&output, from: start, to: maxBytes, outcome: &outcome) }
        return outcome
    }

    /// The length of a `<br>` tag at `index`, or nil.
    private static func lineBreakTag(_ raw: ArraySlice<UInt8>, _ index: Int) -> Int? {
        var cursor = index + 1
        guard cursor + 1 < raw.endIndex, raw[cursor] | 0x20 == UInt8(ascii: "b"),
            raw[cursor + 1] | 0x20 == UInt8(ascii: "r")
        else { return nil }
        cursor += 2
        while cursor < raw.endIndex, raw[cursor] == 0x20 { cursor += 1 }
        if cursor < raw.endIndex, raw[cursor] == UInt8(ascii: "/") { cursor += 1 }
        guard cursor < raw.endIndex, raw[cursor] == UInt8(ascii: ">") else { return nil }
        return cursor + 1 - index
    }

    /// The scalar and length of an entity at `index`, or nil.
    private static func entity(_ raw: ArraySlice<UInt8>, _ index: Int) -> (UInt32, Int)? {
        var cursor = index + 1
        let limit = Swift.min(raw.endIndex, index + 12)
        while cursor < limit, raw[cursor] != UInt8(ascii: ";") { cursor += 1 }
        guard cursor < limit else { return nil }
        let name = raw[(index + 1) ..< cursor]
        let length = cursor + 1 - index
        switch String(decoding: name, as: UTF8.self) {
            case "amp": return (0x26, length)
            case "lt": return (0x3C, length)
            case "gt": return (0x3E, length)
            case "quot": return (0x22, length)
            case "apos": return (0x27, length)
            case "nbsp": return (0x20, length)
            default: break
        }
        guard name.first == UInt8(ascii: "#"), name.count > 1 else { return nil }
        var value: UInt32 = 0
        let hex = name.count > 2 && (name[name.startIndex + 1] | 0x20) == UInt8(ascii: "x")
        for digit in name.dropFirst(hex ? 2 : 1) {
            let number: UInt32
            switch digit {
                case UInt8(ascii: "0") ... UInt8(ascii: "9"): number = UInt32(digit - UInt8(ascii: "0"))
                case UInt8(ascii: "a") ... UInt8(ascii: "f") where hex: number = UInt32(digit - UInt8(ascii: "a")) + 10
                case UInt8(ascii: "A") ... UInt8(ascii: "F") where hex: number = UInt32(digit - UInt8(ascii: "A")) + 10
                default: return nil
            }
            value = value &* (hex ? 16 : 10) &+ number
            if value > 0x10FFFF { return nil }
        }
        return (value, length)
    }

    /// Decodes the scalar at `index`; an invalid sequence is U+FFFD, one byte long.
    private static func decode(_ raw: ArraySlice<UInt8>, _ index: Int) -> (UInt32, Int) {
        let lead = raw[index]
        let count: Int
        var value: UInt32
        let minimum: UInt32
        switch lead {
            case 0xC2 ... 0xDF: (count, value, minimum) = (2, UInt32(lead & 0x1F), 0x80)
            case 0xE0 ... 0xEF: (count, value, minimum) = (3, UInt32(lead & 0x0F), 0x800)
            case 0xF0 ... 0xF4: (count, value, minimum) = (4, UInt32(lead & 0x07), 0x10000)
            default: return (0xFFFD, 1)
        }
        guard index + count <= raw.endIndex else { return (0xFFFD, 1) }
        for offset in 1 ..< count {
            let next = raw[index + offset]
            guard next & 0xC0 == 0x80 else { return (0xFFFD, 1) }
            value = value << 6 | UInt32(next & 0x3F)
        }
        guard value >= minimum, value <= 0x10FFFF, !(0xD800 ... 0xDFFF).contains(value) else { return (0xFFFD, 1) }
        return (value, count)
    }

    private static func append(_ scalar: UInt32, to output: inout [UInt8], outcome: inout Outcome) {
        var value = scalar
        switch scalar {
            case 0x09, 0x0A, 0x0D, 0x2028, 0x2029: value = 0x20
            case 0 ..< 0x20, 0x7F, 0x80 ... 0x9F, 0x061C, 0x200E, 0x200F, 0x202A ... 0x202E, 0x2066 ... 0x2069, 0xFEFF:
                value = 0xFFFD
                outcome.insert(.replaced)
            case 0xFFFD: outcome.insert(.replaced)
            default: break
        }
        switch value {
            case 0 ..< 0x80: output.append(UInt8(value))
            case 0x80 ..< 0x800: output.append(contentsOf: [UInt8(0xC0 | value >> 6), UInt8(0x80 | value & 0x3F)])
            case 0x800 ..< 0x10000:
                output.append(contentsOf: [
                    UInt8(0xE0 | value >> 12), UInt8(0x80 | value >> 6 & 0x3F), UInt8(0x80 | value & 0x3F)
                ])
            default:
                output.append(contentsOf: [
                    UInt8(0xF0 | value >> 18), UInt8(0x80 | value >> 12 & 0x3F), UInt8(0x80 | value >> 6 & 0x3F),
                    UInt8(0x80 | value & 0x3F)
                ])
        }
    }

    private static func trim(_ output: inout [UInt8], from start: Int) {
        while output.count > start, output[output.count - 1] == 0x20 || output[output.count - 1] == 0x0A {
            output.removeLast()
        }
        var lead = start
        while lead < output.count, output[lead] == 0x20 || output[lead] == 0x0A { lead += 1 }
        if lead > start { output.removeSubrange(start ..< lead) }
    }

    private static func cut(_ output: inout [UInt8], from start: Int, to maxBytes: Int, outcome: inout Outcome) {
        var end = start + maxBytes
        while end > start, output[end] & 0xC0 == 0x80 { end -= 1 }
        output.removeSubrange(end...)
        outcome.insert(.truncated)
    }
}
