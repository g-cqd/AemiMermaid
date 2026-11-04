/// The style sheet of a diagram: the roles of the scene as classes, colours from variables with a default for light and one for dark, the system font (ADR 0006). A host that
/// draws the SVG inside a page can set the variables; one that draws it alone gets the defaults. Quiet by design: hairline strokes in grey, no fill to speak of, and colour only
/// where it carries meaning (the slices of a pie, in muted tones).
public enum SVGStyle {
    public static let sheet = """
        svg.mermaid { --stroke: #6e6e73; --fill: #fafafa; --text: #1d1d1f; --muted: #8e8e93; --surface: Canvas;
          --s0: #6b7f99; --s1: #8fae9f; --s2: #cdb98f; --s3: #bf8f86; --s4: #a395bd; --s5: #86adbf; --s6: #d8cba6; --s7: #a89f93;
          font: 13px -apple-system, system-ui, 'SF Pro Text', sans-serif; color: var(--text); }
        @media (prefers-color-scheme: dark) {
          svg.mermaid { --stroke: #98989d; --fill: #2a2a2c; --text: #ececf0; --muted: #8e8e93;
            --s0: #8199b5; --s1: #9fbfae; --s2: #d9c79b; --s3: #cf9f96; --s4: #b3a7cc; --s5: #98c0d1; --s6: #e0d4b0; --s7: #b9b0a4; }
        }
        svg.mermaid .n { fill: var(--fill); stroke: var(--stroke); stroke-width: 1; }
        svg.mermaid .e { fill: none; stroke: var(--stroke); stroke-width: 1; stroke-linejoin: round; stroke-linecap: round; }
        svg.mermaid .e.d { stroke-dasharray: 5 4; }
        svg.mermaid .e.t { stroke-width: 2; }
        svg.mermaid .m { fill: var(--stroke); stroke: var(--stroke); stroke-width: 1; stroke-linejoin: round; }
        svg.mermaid .c { fill: none; stroke: var(--muted); stroke-width: 1; stroke-dasharray: 4 3; opacity: 0.8; }
        svg.mermaid .nt { fill: var(--surface); stroke: var(--muted); stroke-width: 1; }
        svg.mermaid .a { stroke: var(--stroke); stroke-width: 5; fill: none; opacity: 0.45; }
        svg.mermaid .u { stroke: var(--muted); stroke-width: 1; stroke-dasharray: 2 4; fill: none; opacity: 0.8; }
        svg.mermaid text { fill: var(--text); stroke: none; }
        svg.mermaid text.ct { fill: var(--muted); font-weight: 500; paint-order: stroke; stroke: var(--surface); stroke-width: 6px; stroke-linejoin: round; }
        svg.mermaid text.l { fill: var(--text); }
        svg.mermaid text.el { fill: var(--muted); font-size: 0.92em; paint-order: stroke; stroke: var(--surface); stroke-width: 5px; stroke-linejoin: round; }
        svg.mermaid .s0 { fill: var(--s0); } svg.mermaid .s1 { fill: var(--s1); } svg.mermaid .s2 { fill: var(--s2); } svg.mermaid .s3 { fill: var(--s3); }
        svg.mermaid .s4 { fill: var(--s4); } svg.mermaid .s5 { fill: var(--s5); } svg.mermaid .s6 { fill: var(--s6); } svg.mermaid .s7 { fill: var(--s7); }
        """
}
