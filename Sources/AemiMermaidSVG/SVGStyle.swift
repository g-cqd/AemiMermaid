/// The style sheet of a diagram: the roles of the scene as classes, colours from variables with a default for light and one for dark, the system font (ADR 0006). A host that
/// draws the SVG inside a page can set the variables; one that draws it alone gets the defaults.
public enum SVGStyle {
    public static let sheet = """
        svg.mermaid { --stroke: #3c3c43; --fill: #f5f5f7; --text: #1d1d1f; --muted: #8e8e93; --accent: #0a84ff; --surface: #ffffff;
          font: 13px -apple-system, system-ui, 'SF Pro Text', sans-serif; color: var(--text); }
        @media (prefers-color-scheme: dark) {
          svg.mermaid { --stroke: #d1d1d6; --fill: #2c2c2e; --text: #f5f5f7; --muted: #8e8e93; --accent: #64d2ff; --surface: #1c1c1e; }
        }
        svg.mermaid .n { fill: var(--fill); stroke: var(--stroke); stroke-width: 1.25; }
        svg.mermaid .e { fill: none; stroke: var(--stroke); stroke-width: 1.25; stroke-linejoin: round; stroke-linecap: round; }
        svg.mermaid .e.d { stroke-dasharray: 5 4; }
        svg.mermaid .e.t { stroke-width: 2.5; }
        svg.mermaid .m { fill: var(--stroke); stroke: var(--stroke); stroke-width: 1; }
        svg.mermaid .c { fill: none; stroke: var(--muted); stroke-width: 1; stroke-dasharray: 4 3; }
        svg.mermaid .nt { fill: var(--surface); stroke: var(--muted); stroke-width: 1; }
        svg.mermaid .a { stroke: var(--accent); stroke-width: 4; fill: none; }
        svg.mermaid .u { stroke: var(--muted); stroke-width: 1; stroke-dasharray: 3 4; fill: none; }
        svg.mermaid text { fill: var(--text); stroke: none; }
        svg.mermaid text.ct { fill: var(--muted); font-weight: 600; paint-order: stroke; stroke: var(--surface); stroke-width: 5px; }
        svg.mermaid text.l { fill: var(--text); }
        svg.mermaid .s0 { fill: #0a84ff; } svg.mermaid .s1 { fill: #30d158; } svg.mermaid .s2 { fill: #ff9f0a; } svg.mermaid .s3 { fill: #ff453a; }
        svg.mermaid .s4 { fill: #bf5af2; } svg.mermaid .s5 { fill: #64d2ff; } svg.mermaid .s6 { fill: #ffd60a; } svg.mermaid .s7 { fill: #ac8e68; }
        """
}
