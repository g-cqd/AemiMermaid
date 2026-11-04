# 0002: Limits

`MermaidLimits` (`default`, `terminal`): source 256 KiB, nodes 2000 (500 in a terminal), edges 8000 (2000), labels 2 KiB, nesting 16, messages 5000 (1000), lines 8 KiB, virtual nodes 50,000
(10,000). The figures are hypotheses to be revised by measurement on real diagrams; each has a test that passes it. A limit passed is a refusal with the figure
(`diagram too large: 201 nodes, limit 200`), never a cut diagram, except a label (cut on a scalar boundary, reported) and a line (dropped, reported). There is no fuel counter yet: the phases
are bounded by sizes the limits fix, and the growth test would show a phase that is not.
