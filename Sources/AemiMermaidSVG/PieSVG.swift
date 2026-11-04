public import AemiMermaidSyntax
internal import Foundation

/// A pie chart as SVG sectors with a legend (ADR 0006): the same slices the cell layout draws as bars, here as the circle they describe.
public struct PieSVG: Sendable {
    public var radius = 90.0
    public var embedsStyle = true

    public init() {}

    public func svg(_ diagram: PieDiagram) -> String {
        guard !diagram.slices.isEmpty else { return "" }
        let total = diagram.slices.reduce(0) { $0 + $1.value }
        let labels = diagram.slices.map { String(decoding: diagram.labels.slice($0.label), as: UTF8.self) }
        let legendWidth = Double((labels.map(\.count).max() ?? 0) * 8 + 90)
        let width = radius * 2 + 40 + legendWidth
        let top = diagram.title == nil ? 20.0 : 44.0
        let height = Swift.max(radius * 2 + top + 20, Double(diagram.slices.count) * 20 + top + 20)
        var out =
            "<svg class=\"mermaid\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(SVGText.number(width)) \(SVGText.number(height))\""
        out +=
            " width=\"\(SVGText.number(width))\" height=\"\(SVGText.number(height))\" role=\"img\" aria-label=\"Pie chart\">"
        if embedsStyle { out += "<style>" + SVGStyle.sheet + "</style>" }
        if let title = diagram.title {
            let text = SVGText.escaped(String(decoding: diagram.labels.slice(title), as: UTF8.self))
            out +=
                "<text class=\"ct\" x=\"\(SVGText.number(width / 2))\" y=\"24\" text-anchor=\"middle\">\(text)</text>"
        }
        let (centerX, centerY) = (radius + 20, top + radius)
        var angle = -Double.pi / 2
        for (index, slice) in diagram.slices.enumerated() {
            let sweep = slice.value / total * 2 * Double.pi
            let class_ = "s\(index % 8)"
            if diagram.slices.count == 1 {
                out +=
                    "<circle class=\"\(class_)\" cx=\"\(SVGText.number(centerX))\" cy=\"\(SVGText.number(centerY))\" r=\"\(SVGText.number(radius))\"/>"
            } else {
                let (x0, y0) = (centerX + radius * cos(angle), centerY + radius * sin(angle))
                let (x1, y1) = (centerX + radius * cos(angle + sweep), centerY + radius * sin(angle + sweep))
                let large = sweep > Double.pi ? 1 : 0
                out +=
                    "<path class=\"\(class_)\" stroke=\"var(--surface)\" stroke-width=\"1.5\" d=\"M\(SVGText.number(centerX)) \(SVGText.number(centerY))L\(SVGText.number(x0)) \(SVGText.number(y0))A\(SVGText.number(radius)) \(SVGText.number(radius)) 0 \(large) 1 \(SVGText.number(x1)) \(SVGText.number(y1))Z\"/>"
            }
            angle += sweep
            let share = Int((slice.value / total * 1000).rounded())
            let legendY = top + 4 + Double(index) * 20
            let legendX = radius * 2 + 40
            out +=
                "<rect class=\"\(class_)\" x=\"\(SVGText.number(legendX))\" y=\"\(SVGText.number(legendY))\" width=\"12\" height=\"12\" rx=\"2\"/>"
            var caption = labels[index] + "  \(share / 10).\(share % 10)%"
            if diagram.showData { caption += " (\(SVGText.number(slice.value)))" }
            out +=
                "<text class=\"l\" x=\"\(SVGText.number(legendX + 18))\" y=\"\(SVGText.number(legendY + 10.5))\">\(SVGText.escaped(caption))</text>"
        }
        return out + "</svg>"
    }
}
