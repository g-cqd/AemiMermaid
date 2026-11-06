public import AemiFrontMatter
public import AemiHMMMLCore
public import AemiYAML

/// A diagram's front matter (Mermaid's `---` head): its title and its configuration, read as YAML by AemiHMMML. Mermaid reads
/// `title`, `displayMode` and `config` from it; the rest is kept for a caller that wants it.
public struct MermaidHead: Sendable {
    /// Where the head is in the source.
    public let frontMatter: FrontMatter
    /// The whole head, as YAML; nil only if it could not be read at all.
    public let document: YAMLDocument?
    /// What was broken in the head. It is read recovering, as the diagram is: a broken head never refuses the diagram.
    public let diagnostics: Diagnostics

    /// `title:`, as text.
    public var title: String? { document?.root["title"]?.text }
    /// `config:`, Mermaid's configuration as written, for a renderer to apply what it supports.
    public var config: YAMLValue? { document?.root["config"] }

    /// The head of `source` at `frontMatter`, read.
    init(_ frontMatter: FrontMatter, in source: [UInt8]) {
        self.frontMatter = frontMatter
        // Recovering never throws.
        let reading = try? frontMatter.read(from: source, policy: .recovering)
        document = reading?.value?.yaml
        diagnostics = reading?.diagnostics ?? Diagnostics(policy: .recovering)
    }
}
