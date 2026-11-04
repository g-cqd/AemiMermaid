public import AemiMermaidScene
public import AemiMermaidSyntax
internal import Foundation

/// Lays a pie chart out in cells as bars: a row for each slice with its label, a bar as long as its share of the largest, and its share of the whole (and its value, with
/// `showData`). The bars are drawn with block characters; a vector backend draws sectors from the same slices.
public enum PieLayout {
    public static func lay(
        _ diagram: PieDiagram,
        metrics: MermaidMetrics,
        maxWidth: Int?,
        into scene: inout DiagramScene
    ) -> MermaidLayoutOutcome {
        guard !diagram.slices.isEmpty else { return .source(.empty) }
        scene.reset()
        let total = diagram.slices.reduce(0) { $0 + $1.value }
        let largest = diagram.slices.map(\.value).max() ?? 1
        let labels = diagram.slices.map {
            String(decoding: diagram.labels.slice($0.label), as: UTF8.self).replacingOccurrences(of: "\n", with: " ")
        }
        let labelWidth = labels.map { metrics.width(of: ArraySlice($0.utf8)) }.max() ?? 0
        let tails = zip(diagram.slices, labels)
            .map { slice, _ in
                let tenths = Int((slice.value / total * 1000).rounded())
                let share = "\(tenths / 10).\(tenths % 10)%"
                return diagram.showData ? share + " (" + trimmed(slice.value) + ")" : share
            }
        let tailWidth = tails.map(\.count).max() ?? 0
        let available = (maxWidth ?? Int.max) - labelWidth - tailWidth - 2
        let barWidth = Swift.min(30, available)
        guard barWidth >= 4 else {
            return .source(.tooWide(needed: labelWidth + tailWidth + 2 + 4, available: maxWidth ?? 0))
        }
        var rows: [String] = []
        if let title = diagram.title, !title.isEmpty {
            rows.append(String(decoding: diagram.labels.slice(title), as: UTF8.self))
            rows.append("")
        }
        for (index, slice) in diagram.slices.enumerated() {
            let eighths = Int((slice.value / largest * Double(barWidth * 8)).rounded())
            let bar = String(repeating: "█", count: eighths / 8) + ["", "▏", "▎", "▍", "▌", "▋", "▊", "▉"][eighths % 8]
            let pad = String(repeating: " ", count: labelWidth - metrics.width(of: ArraySlice(labels[index].utf8)))
            rows.append(
                labels[index] + pad + " " + bar
                    + String(repeating: " ", count: barWidth - metrics.width(of: ArraySlice(bar.utf8))) + " "
                    + tails[index]
            )
        }
        let width = rows.map { metrics.width(of: ArraySlice($0.utf8)) }.max() ?? 0
        scene.width = Int32(width)
        scene.height = Int32(rows.count)
        for (y, row) in rows.enumerated() where !row.isEmpty {
            let role: SceneRole = diagram.title != nil && y == 0 ? .clusterTitle : .label
            scene.texts.append(
                SceneText(x: 0, y: Int32(y), anchor: .leading, role: role, text: scene.addLabel(ArraySlice(row.utf8)))
            )
        }
        return .drawn(width: width, height: rows.count)
    }

    private static func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}
