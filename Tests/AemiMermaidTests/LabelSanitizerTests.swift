import Testing

@testable import AemiMermaidSyntax

/// A label never carries a byte that could move a terminal's cursor, change its text direction, or break a layout (ADR 0003).
@Suite("Labels are cleaned before anything draws them")
struct LabelSanitizerTests {
    private func clean(_ bytes: [UInt8], maxBytes: Int = 2048) -> (String, LabelSanitizer.Outcome) {
        var output: [UInt8] = []
        let outcome = LabelSanitizer.clean(bytes[...], maxBytes: maxBytes, into: &output)
        return (String(decoding: output, as: UTF8.self), outcome)
    }

    private func clean(_ text: String, maxBytes: Int = 2048) -> (String, LabelSanitizer.Outcome) {
        clean(Array(text.utf8), maxBytes: maxBytes)
    }

    @Test func `plain text is unchanged and trimmed`() {
        #expect(clean("  hello world  ").0 == "hello world")
        #expect(clean("日本語 ünï").0 == "日本語 ünï")
    }

    @Test(arguments: [UInt8(0x00), 0x01, 0x07, 0x08, 0x1B, 0x7F])
    func `a control byte is replaced`(byte: UInt8) {
        let (text, outcome) = clean([UInt8(ascii: "a"), byte, UInt8(ascii: "b")])
        #expect(text == "a\u{FFFD}b" && outcome.contains(.replaced))
    }

    @Test func `tab and the line endings become spaces`() {
        #expect(clean("a\tb\nc\rd").0 == "a b c d")
        #expect(clean("a\u{2028}b\u{2029}c").0 == "a b c")
    }

    @Test(arguments: [
        "\u{0085}", "\u{009B}", "\u{202A}", "\u{202E}", "\u{2066}", "\u{2069}", "\u{200E}", "\u{200F}", "\u{061C}",
        "\u{FEFF}"
    ])
    func `a C1 control, a bidirectional control and a byte order mark are replaced`(scalar: String) {
        let (text, outcome) = clean("a" + scalar + "b")
        #expect(text == "a\u{FFFD}b" && outcome.contains(.replaced))
    }

    @Test func `escape sequences do not survive as escapes`() {
        let (text, _) = clean("\u{1B}[2J\u{1B}]0;title\u{7}x")
        #expect(!text.unicodeScalars.contains { $0.value < 0x20 })
    }

    @Test func `invalid UTF-8 is replaced one byte at a time`() {
        #expect(clean([0x61, 0xFF, 0x62, 0xC3, 0x28, 0xE2, 0x82]).0 == "a\u{FFFD}b\u{FFFD}(\u{FFFD}\u{FFFD}")
        #expect(clean([0xED, 0xA0, 0x80]).0.unicodeScalars.allSatisfy { $0.value == 0xFFFD }, "an encoded surrogate")
        #expect(clean([0xC0, 0x80]).0.unicodeScalars.allSatisfy { $0.value == 0xFFFD }, "an overlong NUL")
    }

    @Test func `line break tags become a line break, in any case`() {
        #expect(clean("a<br/>b<BR>c<br />d").0 == "a\nb\nc\nd")
        #expect(clean("a<brx>b").0 == "a<brx>b")
    }

    @Test func `entities are decoded, and numeric ones that are controls are replaced`() {
        #expect(clean("a &amp; b &lt;c&gt; &quot;d&quot; &#65;&#x42;").0 == "a & b <c> \"d\" AB")
        #expect(clean("x&#27;y").0 == "x\u{FFFD}y")
        #expect(clean("&unknown; &#xZZ; &#99999999;").0 == "&unknown; &#xZZ; &#99999999;")
    }

    @Test func `a label is cut at the limit on a scalar boundary`() {
        let (text, outcome) = clean(String(repeating: "é", count: 100), maxBytes: 11)
        #expect(outcome.contains(.truncated) && text.utf8.count <= 11 && text.unicodeScalars.allSatisfy { $0 == "é" })
        #expect(clean(String(repeating: "a", count: 5000)).0.utf8.count == 2048)
    }

    @Test func `every byte value alone gives text with no control`() {
        for byte in 0 ... 255 {
            let (text, _) = clean([UInt8(byte)])
            #expect(
                !text.unicodeScalars.contains {
                    $0.value < 0x20 && $0.value != 0x0A || $0.value == 0x7F || (0x80 ... 0x9F).contains($0.value)
                },
                "byte \(byte)"
            )
        }
    }
}
