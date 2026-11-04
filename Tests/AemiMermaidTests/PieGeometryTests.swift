import Foundation
import Testing

@testable import AemiMermaidSVG
@testable import AemiMermaidSyntax

/// A pie chart's wedges all meet at its centre, lie on one circle, and follow one another round it with no gap and no overlap.
@Suite("Pie geometry")
struct PieGeometryTests {
    private struct Wedge {
        var centre: (Double, Double)
        var from: (Double, Double)
        var to: (Double, Double)
        var radius: Double
        var large: Bool
    }

    /// The numbers of every `d="M…L…A…Z"` of the markup.
    private func wedges(_ markup: String) -> [Wedge] {
        let pattern = /d="M([-\d.]+) ([-\d.]+)L([-\d.]+) ([-\d.]+)A([-\d.]+) ([-\d.]+) 0 ([01]) 1 ([-\d.]+) ([-\d.]+)Z"/
        return markup.matches(of: pattern)
            .compactMap { match in
                guard let cx = Double(match.1), let cy = Double(match.2), let x0 = Double(match.3),
                    let y0 = Double(match.4), let r = Double(match.5),
                    let x1 = Double(match.8), let y1 = Double(match.9)
                else { return nil }
                return Wedge(centre: (cx, cy), from: (x0, y0), to: (x1, y1), radius: r, large: match.7 == "1")
            }
    }

    private func pie(_ source: String) -> String {
        guard case .pie(let diagram) = MermaidParse.parse(Array(source.utf8), limits: .default).result else {
            return ""
        }
        return PieSVG().svg(diagram)
    }

    private func distance(_ a: (Double, Double), _ b: (Double, Double)) -> Double { hypot(a.0 - b.0, a.1 - b.1) }

    @Test(arguments: [
        "pie\n  \"a\" : 1\n  \"b\" : 1\n  \"c\" : 1",
        "pie\n  \"a\" : 40\n  \"b\" : 25\n  \"c\" : 15\n  \"d\" : 10\n  \"e\" : 6\n  \"f\" : 4",
        "pie\n  \"most\" : 90\n  \"rest\" : 10",
        "pie\n  \"a\" : 0.001\n  \"b\" : 1000\n  \"c\" : 3",
        "pie\n  \"a\" : 1\n  \"b\" : 1"
    ])
    func `every wedge starts at the centre, ends on the circle, and follows the one before`(source: String) throws {
        let found = wedges(pie(source))
        try #require(found.count >= 2)
        let centre = found[0].centre
        var sweep = 0.0
        for (index, wedge) in found.enumerated() {
            #expect(distance(wedge.centre, centre) < 0.01, "wedge \(index) does not start at the centre")
            #expect(abs(distance(wedge.from, centre) - wedge.radius) < 0.02, "wedge \(index) starts off the circle")
            #expect(abs(distance(wedge.to, centre) - wedge.radius) < 0.02, "wedge \(index) ends off the circle")
            #expect(abs(wedge.radius - found[0].radius) < 0.001)
            if index > 0 {
                #expect(distance(wedge.from, found[index - 1].to) < 0.02, "wedge \(index) does not follow \(index - 1)")
            }
            var angle =
                atan2(wedge.to.1 - centre.1, wedge.to.0 - centre.0)
                - atan2(wedge.from.1 - centre.1, wedge.from.0 - centre.0)
            while angle < 0 { angle += 2 * Double.pi }
            sweep += angle
            #expect(
                wedge.large == (angle > Double.pi + 1e-6) || abs(angle - Double.pi) < 1e-3,
                "the large-arc flag of wedge \(index)"
            )
        }
        #expect(distance(found[found.count - 1].to, found[0].from) < 0.02, "the last wedge does not close the circle")
        #expect(abs(sweep - 2 * Double.pi) < 0.01, "the wedges add up to \(sweep)")
    }

    @Test func `a single slice is a whole circle`() {
        let markup = pie("pie\n  \"only\" : 5")
        #expect(markup.contains("<circle") && wedges(markup).isEmpty)
    }
}
