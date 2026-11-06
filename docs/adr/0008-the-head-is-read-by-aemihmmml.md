# 0008: A diagram's head is located and read by AemiHMMML

**Status:** accepted (2026-11-06).

## Context

Mermaid lets a diagram start with front matter: YAML between `---` fences, holding `title`, `displayMode` and `config`
(`diagram-api/frontmatter.ts`). `MermaidHeader.find` used to skip it by flipping a flag at each `---` line, without reading it.
That accepted `---` blocks anywhere before the header and threw the title and the configuration away. The family now has one
front matter locator, AemiHMMML's `AemiFrontMatter` (its ADR-0009 and ADR-0015), whose rules come from Mermaid's own regular
expression among others.

## Decision

- `MermaidHeader.find` locates the head with `AemiFrontMatter`, YAML only. It allows leading blank lines (as before), and
  indented fences closed at the same indent (Mermaid's `^([^\S\n\r]*)-{3}…\1-{3}`). It then skips blank lines and `%%` comments
  to the header, counting lines from the top of the source as before.
- `MermaidParse.head` reads the head with AemiHMMML's YAML reader in recovering mode (`MermaidHead`: `title`, `config`, the whole
  document, diagnostics). A broken head is reported and never refuses the diagram.
- A `---` block after a comment, or anywhere but the top, is no longer a head. mermaid.js anchors its expression at the start of
  the text, so it does not read one there either.

## Consequences

Renderers can now draw the title and apply what they support of `config`. They do not do either yet.
