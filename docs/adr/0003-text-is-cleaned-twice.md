# 0003: Text is cleaned twice

Layer one, `LabelSanitizer`, runs when a label is read: invalid UTF-8, controls, C1 controls, bidirectional controls (U+061C, U+200E/F, U+202A to U+202E, U+2066 to U+2069), byte order marks
and the line and paragraph separators are replaced (U+FFFD, or a space for white space); `<br/>` becomes a line break, a few named and all numeric entities are decoded; the text is trimmed and cut at the label limit.
Layer two is the cell writer, which accepts only scalars whose width the metrics know, replaces what layer one would have, and in ASCII mode puts `?` for anything above U+007E. A scene
that did not come from the layout is therefore as safe to draw as one that did (`TextRendererTests`).
