public import AemiMermaidScene

/// Draws a ``DiagramScene`` as SVG (ADR 0006): the scene's cells become a grid of `cell` units, lines run through the middle of their cells, text is the system font, and every
/// role is a class of the style sheet, so a theme or an appearance change restyles the picture without laying it out again. Vector all the way: it zooms without loss.
public struct SVGRenderer: Sendable {
    /// The size of a cell in SVG units: a character cell of a 13-point system font, 9 wide and 18 high.
    public var cellWidth = 9.0
    public var cellHeight = 18.0
    /// Whether the style sheet is inside the SVG. A page that carries it once (several diagrams in one document) turns this off.
    public var embedsStyle = true

    public init() {}

    func x(_ cells: Int32) -> Double { Double(cells) * cellWidth }
    func y(_ cells: Int32) -> Double { Double(cells) * cellHeight }
    /// The middle of a cell.
    func cx(_ cells: Int32) -> Double { (Double(cells) + 0.5) * cellWidth }
    func cy(_ cells: Int32) -> Double { (Double(cells) + 0.5) * cellHeight }

    /// The SVG element for `scene`; an empty scene is an empty string.
    public func svg(_ scene: DiagramScene, label: String = "Diagram") -> String {
        guard scene.width > 0, scene.height > 0 else { return "" }
        let width = SVGText.number(x(scene.width))
        let height = SVGText.number(y(scene.height))
        var out =
            "<svg class=\"mermaid\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(width) \(height)\" width=\"\(width)\" height=\"\(height)\""
        out += " role=\"img\" aria-label=\"\(SVGText.escaped(label))\">"
        if embedsStyle { out += "<style>" + SVGStyle.sheet + "</style>" }
        for shape in scene.shapes { out += shapeMarkup(shape, scene) }
        for path in scene.paths { out += pathMarkup(path, scene) }
        for text in scene.texts { out += textMarkup(text, scene) }
        return out + "</svg>"
    }

    func textMarkup(_ text: SceneText, _ scene: DiagramScene) -> String {
        let anchor =
            switch text.anchor {
                case .leading: "start"
                case .center: "middle"
                case .trailing: "end"
            }
        let px = text.anchor == .leading ? x(Int32(text.x)) : cx(Int32(text.x))
        let role = text.role == .clusterTitle ? "ct" : "l"
        return line(scene.string(text.text), x: px, baseline: cy(text.y) + 4.5, anchor: anchor, class: role)
    }

    /// One line of text, its baseline at `baseline`.
    func line(_ string: String, x: Double, baseline: Double, anchor: String, class name: String) -> String {
        guard !string.isEmpty else { return "" }
        return
            "<text class=\"\(name)\" x=\"\(SVGText.number(x))\" y=\"\(SVGText.number(baseline))\" text-anchor=\"\(anchor)\" xml:space=\"preserve\">\(SVGText.escaped(string))</text>"
    }
}
