// Draws a Mermaid diagram in the terminal: `aemi-mermaid [--ascii] [--width N] [file]`, or the diagram on standard input.
import AemiMermaidLayout
import AemiMermaidScene
import AemiMermaidSyntax
import AemiMermaidText
import Foundation

var arguments = Array(CommandLine.arguments.dropFirst())
let ascii = arguments.contains("--ascii")
arguments.removeAll { $0 == "--ascii" }
var width: Int?
if let index = arguments.firstIndex(of: "--width"), index + 1 < arguments.count {
    width = Int(arguments[index + 1])
    arguments.removeSubrange(index ... (index + 1))
}
let input =
    arguments.first.flatMap { FileManager.default.contents(atPath: $0) }
    ?? FileHandle.standardInput.readDataToEndOfFile()
let parse = MermaidParse.parse(Array(input), limits: .terminal)
var scene = DiagramScene()
if case .refused(let reason) = parse.result {
    FileHandle.standardError.write(Data("not drawn: \(reason)\n".utf8))
    exit(1)
}
let outcome = MermaidLayout.lay(parse.result, maxWidth: width, into: &scene)
guard case .drawn = outcome, let lines = TextRenderer(ascii: ascii).text(scene) else {
    FileHandle.standardError.write(Data("not drawn: \(outcome)\n".utf8))
    exit(1)
}
for diagnostic in parse.diagnostics.entries {
    FileHandle.standardError.write(Data("line \(diagnostic.line): \(diagnostic.kind)\n".utf8))
}
print(lines.joined(separator: "\n"))
