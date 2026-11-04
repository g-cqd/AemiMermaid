import AemiTestKit
import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

/// Every corpus diagram with bytes overwritten, flipped, cut and extended: it is read, laid out and drawn without a crash, within the geometric rules, and with
/// nothing a terminal could act on. Seeded, so a failure repeats.
@Suite("Mutated diagrams are read, laid out and drawn safely")
struct FuzzTests {
    private func run(_ bytes: [UInt8]) -> (problems: [String], text: [String]) {
        let parse = MermaidParse.parse(bytes, limits: .terminal)
        var scene = DiagramScene()
        var problems: [String] = []
        switch parse.result {
            case .flowchart(let diagram): _ = FlowLayout.lay(diagram, maxWidth: 100, into: &scene)
            case .sequence(let diagram): _ = SequenceLayout.lay(diagram, maxWidth: 100, into: &scene)
            case .refused: return ([], [])
        }
        problems = SceneLinter.problems(scene, checkEdges: false)
        return (problems, TextRenderer().text(scene) ?? [])
    }

    @Test(arguments: [UInt64(1), 2, 3, 4])
    func `mutations of the corpus`(seed: UInt64) {
        var random = SeededRNG(seed: seed)
        let mutator = ByteMutator()
        for source in DiagramCorpus.all {
            for _ in 0 ..< 60 {
                var bytes = Array(source.utf8)
                mutator.apply(Int.random(in: 1 ... 6, using: &random), to: &bytes, using: &random)
                let (problems, text) = run(bytes)
                #expect(problems.isEmpty, "\(problems) for \(String(decoding: bytes, as: UTF8.self).debugDescription)")
                for line in text {
                    #expect(
                        line.unicodeScalars.allSatisfy {
                            $0.value >= 0x20 && $0.value != 0x7F && !(0x80 ... 0x9F).contains($0.value)
                                && !(0x202A ... 0x202E).contains($0.value)
                        }
                    )
                }
            }
        }
    }

    @Test func `the whole corpus on a stack of 512 KiB`() {
        let sources = DiagramCorpus.all
        let rows = runOnConstrainedStack { sources.map { run(Array($0.utf8)).text.count } }
        #expect(rows.allSatisfy { $0 > 0 })
    }
}
