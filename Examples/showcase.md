# Mermaid showcase

Every diagram type AemiMermaid draws, with the variations that exercise the layout. Open this file in MarkdownLook, or print one diagram with `aemi-mermaid`.

## Flowcharts

### Every node shape

```mermaid
flowchart LR
  A[Rectangle] --> B(Rounded) --> C([Stadium]) --> D[[Subroutine]]
  D --> E[(Database)] --> F((Circle)) --> G{Decision}
  G --> H{{Hexagon}} --> I[/Parallelogram/] --> J[\Alt/] --> K[/Trapezoid\]
```

### Every link style

```mermaid
flowchart TD
  A --> B
  A --- C
  A -.-> D
  A ==> E
  A --o F
  A --x G
  A <--> H
  A -->|labelled| I
```

### Decisions and loops

```mermaid
flowchart TD
  Start([Start]) --> Input[/Read input/]
  Input --> Valid{Valid?}
  Valid -->|yes| Process[Process]
  Valid -->|no| Error[Show error]
  Error --> Input
  Process --> More{More items?}
  More -->|yes| Input
  More -->|no| Done([Done])
```

### Subgraphs

```mermaid
flowchart LR
  subgraph Client
    UI[App] --> Cache[(Cache)]
  end
  subgraph Server
    API[API] --> DB[(Database)]
    API --> Queue[[Queue]]
  end
  UI -->|HTTPS| API
  Queue -.-> Worker([Worker])
```

### Nested subgraphs

```mermaid
flowchart TD
  subgraph Cloud
    subgraph Region A
      A1[Node 1] --> A2[Node 2]
    end
    subgraph Region B
      B1[Node 3] --> B2[Node 4]
    end
  end
  A2 --> B1
  User([User]) --> A1
```

### Fan out and fan in

```mermaid
flowchart LR
  S[Source] --> A & B & C & D
  A --> T[Target]
  B --> T
  C --> T
  D --> T
```

### Bottom up and right to left

```mermaid
flowchart BT
  A[Foundation] --> B[Middle] --> C[Top]
```

```mermaid
flowchart RL
  A[Answer] --> B[Question]
```

### A node that points at itself

```mermaid
flowchart TD
  Retry[Retry] --> Retry
  Retry --> Done([Done])
```

### Long labels

```mermaid
flowchart TD
  A[A rather long label that has to wrap onto several lines to stay readable] --> B[Another label with<br/>an explicit line break]
  B -->|an edge label that is also fairly long| C[End]
```

## Sequence diagrams

### A conversation

```mermaid
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hello Bob
  B-->>A: Hi Alice
  A->>+B: Can you help?
  B-->>-A: Of course
```

### Activations, notes and self calls

```mermaid
sequenceDiagram
  participant C as Client
  participant S as Server
  participant D as Database
  C->>+S: Request
  S->>+D: Query
  Note right of D: Index lookup
  D-->>-S: Rows
  S->>S: Render
  S-->>-C: Response
  Note over C,S: Done
```

### Blocks

```mermaid
sequenceDiagram
  participant U as User
  participant A as App
  U->>A: Log in
  alt valid credentials
    A-->>U: Welcome
  else wrong password
    A-->>U: Try again
  end
  loop every minute
    A->>A: Refresh token
  end
  opt remember me
    A->>U: Save session
  end
```

## State diagrams

### A lifecycle

```mermaid
stateDiagram-v2
  [*] --> Proposed: PR Review
  Proposed --> Implemented: Implementation
  Implemented --> Obsoleted: Superseded by new RFCs
  Proposed --> Obsoleted: Outdated
  Obsoleted --> [*]
```

### A machine that loops back

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Running: start
  Running --> Paused: pause
  Paused --> Running: resume
  Running --> Idle: stop
  Running --> Failed: error
  Failed --> Idle: reset
  Failed --> [*]
```

### Composite states

```mermaid
stateDiagram-v2
  [*] --> Active
  state Active {
    [*] --> Reading
    Reading --> Writing: write
    Writing --> Reading: done
  }
  Active --> [*]: close
```

## Class diagrams

### Inheritance

```mermaid
classDiagram
  Animal <|-- Dog
  Animal <|-- Cat
  Animal : +String name
  Animal : +eat()
  Dog : +bark()
  Cat : +purr()
```

### Relationships

```mermaid
classDiagram
  Order "1" --> "*" LineItem : contains
  Order --> Customer
  LineItem --> Product
  Customer : +String name
  Order : +total()
  Product : +Decimal price
```

## Entity relationship diagrams

### A shop

```mermaid
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ LINE_ITEM : contains
  PRODUCT ||--o{ LINE_ITEM : "appears in"
  CUSTOMER {
    string name
    string email
  }
```

## Pie charts

### Few slices

```mermaid
pie title Pets
  "Dogs" : 5
  "Cats" : 3
  "Fish" : 2
```

### With values

```mermaid
pie showData title Time spent
  "Reading" : 40
  "Writing" : 25
  "Reviewing" : 15
  "Meetings" : 10
  "Other" : 10
```

### One dominant slice

```mermaid
pie title Coverage
  "Covered" : 92
  "Missed" : 8
```

## Refused or unsupported

These stay as code instead of a broken picture.

```mermaid
gantt
  title Not drawn yet
  section A
  Task : 2026-01-01, 3d
```

```mermaid
this is not a diagram
```
