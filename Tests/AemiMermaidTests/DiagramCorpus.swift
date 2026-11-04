/// Diagrams the tests lay out, draw and mutate: the shapes and links of the accepted subset, and the cases that are hard to lay out.
enum DiagramCorpus {
    static let flowcharts: [String] = [
        "flowchart TD\n  A[Start] --> B{Is it?}\n  B -->|Yes| C[OK]\n  C --> D[Rethink]\n  D --> B\n  B ---->|No| E[End]",
        "graph LR\n  A((one)) --> B(two) --> C([three])\n  A --> C",
        "flowchart TD\n  subgraph one [Group]\n    A --> B\n  end\n  B --> C\n  C -.-> A",
        "flowchart BT\n  A --> B & C\n  B --> D\n  C --> D\n  D --> D",
        "flowchart RL\n  A[[sub]] ==> B[(db)] --o C{{hex}} --x D[/par/]\n  D <--> E[\\alt\\] -- text --> F>flag]",
        "flowchart TD\n  A --> B\n  A --> C\n  A --> D\n  B --> E\n  C --> E\n  D --> E\n  E --> F\n  A --> F",
        "flowchart LR\n  a1 --> a2 --> a3 --> a4 --> a5 --> a6 --> a7 --> a8",
        "flowchart TD\n  A[\"Quoted (label) with [brackets]\"] --> B[Line one<br/>line two]\n  B --> C[A very long label that has to wrap onto several lines to fit the node]",
        "flowchart TD\n  X --> Y\n  Z --> W\n  Q",
        "flowchart TD\n  subgraph outer\n    subgraph inner\n      A --> B\n    end\n    C --> A\n  end\n  D --> C",
        "flowchart LR\n  A -.-> B\n  B ==> C\n  C ~~~ D\n  D --- A"
    ]

    static let sequences: [String] = [
        "sequenceDiagram\n  autonumber\n  participant A as Alice\n  actor B as Bob\n  A->>B: Hello Bob, how are you?\n  B-->>A: Great!\n  A->>+B: more\n  B->>B: think\n  Note over A,B: a note\n  loop every day\n    A-)B: ping\n  end\n  deactivate B",
        "sequenceDiagram\n  A->>B: one\n  alt ok\n    B->>C: two\n  else bad\n    B-xA: three\n  end\n  Note left of A: left\n  Note right of C: right",
        "sequenceDiagram\n  title Order\n  Customer->>Shop: order\n  Shop-->>Customer: receipt"
    ]

    static var all: [String] { flowcharts + sequences }
}
