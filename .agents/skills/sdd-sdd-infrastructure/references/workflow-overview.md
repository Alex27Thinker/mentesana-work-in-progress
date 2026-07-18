# SDD Workflow Overview

This document provides a comprehensive overview of the Specification-Driven Development (SDD) workflow, from constitution to implementation.

## The SDD Workflow Phases

```
Constitution → Specify → Clarify → Plan → Map → Tasks → Analyze → Implement
     |            |          |        |      |       |        |          |
  Governance   Requirements  Q&A  Technical  Docs  Task List Review  Execute
```

## Phase Breakdown

### 1. Constitution (`/sdd:constitution`)

**Purpose**: Establish project governance and core principles

**What it does**:
- Defines project-specific development principles
- Sets constraints (testing, architecture, performance)
- Establishes quality gates and review processes
- Loaded into AI agent memory for all subsequent work

**Outputs**:
- `.sdd/memory/constitution.md` - Project constitution

**When to use**:
- At project start (before any features)
- When principles need updating or clarification
- When onboarding new team members

**Templates used**: `constitution-template.md`

---

### 2. Specify (`/sdd:specify`)

**Purpose**: Create feature specification with prioritized user stories

**What it does**:
- Creates feature branch (if using git)
- Generates spec from user description
- Defines user stories with priorities (P1, P2, P3)
- Captures requirements and success criteria

**Outputs**:
- `specs/###-feature-name/spec.md` - Feature specification

**When to use**:
- When starting any new feature
- Before writing any code

**Templates used**: `spec-template.md`
**Scripts used**: `create-new-feature.sh`

---

### 3. Clarify (`/sdd:clarify`)

**Purpose**: Identify and resolve ambiguities in requirements

**What it does**:
- Analyzes spec for unclear or missing requirements
- Uses parallel explore agents for thorough analysis
- Generates clarifying questions
- Updates spec with answers

**Outputs**:
- Updated `spec.md` with clarifications
- Questions for stakeholders

**When to use**:
- After initial spec creation
- When spec has "NEEDS CLARIFICATION" markers
- Before creating plan

**Templates used**: None (dynamic analysis)

---

### 4. Plan (`/sdd:plan`)

**Purpose**: Create technical implementation plan

**What it does**:
- Defines technical context (language, frameworks, etc.)
- Maps out project structure
- Checks constitution compliance
- Identifies research needs

**Outputs**:
- `specs/###-feature-name/plan.md` - Implementation plan
- `research.md` - Technical research (if needed)
- `data-model.md` - Data/entity definitions (if needed)
- `contracts/` - API contracts (if needed)

**When to use**:
- After spec is clarified
- Before implementation begins

**Templates used**: `plan-template.md`
**Scripts used**: `setup-plan.sh`

---

### 5. Map (`/sdd:map`)

**Purpose**: Generate codebase documentation for context

**What it does**:
- Creates 8 codebase documentation files
- Uses parallel agents for speed
- Provides context for implementation

**Outputs** (in `.sdd/codebase/`):
- `STACK.md` - Technology stack and dependencies
- `ARCHITECTURE.md` - System architecture
- `STRUCTURE.md` - Directory structure
- `CONVENTIONS.md` - Code style and patterns
- `TESTING.md` - Testing approach
- `SECURITY.md` - Security measures
- `INTEGRATIONS.md` - External integrations
- `CONCERNS.md` - Cross-cutting concerns

**When to use**:
- Before implementation in large/unfamiliar codebases
- When new team members join
- After significant architectural changes

**Templates used**: 8 codebase documentation templates (in code-mapping skill)

---

### 6. Tasks (`/sdd:tasks`)

**Purpose**: Generate implementable task list

**What it does**:
- Breaks plan into independent, testable tasks
- Organizes by user story priority
- Identifies parallelization opportunities
- Creates clear acceptance criteria

**Outputs**:
- `specs/###-feature-name/tasks.md` - Task list

**When to use**:
- After plan is complete
- Before implementation begins

**Templates used**: `tasks-template.md`

---

### 7. Analyze (`/sdd:checklist`)

**Purpose**: Quality validation checklists

**What it does**:
- Generates custom checklists for validation
- Can check requirements, implementation, security, etc.
- Customized to feature and phase

**Outputs**:
- Custom checklist files (various locations)

**When to use**:
- For requirements analysis
- Pre-implementation review
- Code review
- Security audits

**Templates used**: `checklist-template.md`

---

### 8. Implement (`/sdd:implement`)

**Purpose**: Execute tasks with context and tracking

**What it does**:
- Loads all context (spec, plan, tasks, codebase docs)
- Tracks progress through tasks
- Maintains agent context
- Captures retrospective learnings

**Outputs**:
- Implemented code
- Updated agent context files
- Retrospective notes

**When to use**:
- When ready to write code
- After all planning phases complete

**Templates used**: `agent-file-template.md`
**Scripts used**: `update-agent-context.sh`, `check-prerequisites.sh`

---

## Decision Tree: Which Command Should I Use?

```
START
  │
  ├─ Need to define project principles?
  │    └─> /sdd:constitution
  │
  ├─ Starting a new feature?
  │    └─> /sdd:specify
  │
  ├─ Have spec but requirements unclear?
  │    └─> /sdd:clarify
  │
  ├─ Need to plan implementation?
  │    └─> /sdd:plan
  │
  ├─ Large/unfamiliar codebase?
  │    └─> /sdd:map
  │
  ├─ Need to break down work?
  │    └─> /sdd:tasks
  │
  ├─ Need quality checklist?
  │    └─> /sdd:checklist
  │
  └─ Ready to implement?
       └─> /sdd:implement
```

## Typical Workflow Sequences

### New Project Setup
```
1. /sdd:constitution  - Define project principles
2. /sdd:map          - Document existing code (if any)
```

### New Feature (Standard Flow)
```
1. /sdd:specify      - Create spec
2. /sdd:clarify      - Resolve ambiguities
3. /sdd:plan         - Technical planning
4. /sdd:tasks        - Break into tasks
5. /sdd:implement    - Execute
```

### New Feature (Complex/Unfamiliar Codebase)
```
1. /sdd:specify      - Create spec
2. /sdd:map          - Document codebase
3. /sdd:clarify      - Resolve ambiguities
4. /sdd:plan         - Technical planning
5. /sdd:tasks        - Break into tasks
6. /sdd:implement    - Execute
```

### Feature with Quality Gates
```
1. /sdd:specify      - Create spec
2. /sdd:checklist    - Requirements analysis checklist
3. /sdd:clarify      - Resolve issues from checklist
4. /sdd:plan         - Technical planning
5. /sdd:checklist    - Architecture review checklist
6. /sdd:tasks        - Break into tasks
7. /sdd:implement    - Execute
```

## Component Usage by Phase

| Phase | Commands | Templates | Scripts |
|-------|----------|-----------|---------|
| **Constitution** | constitution | constitution-template | - |
| **Specify** | specify | spec-template | create-new-feature.sh |
| **Clarify** | clarify | - | - |
| **Plan** | plan | plan-template | setup-plan.sh |
| **Map** | map | 8 codebase templates* | - |
| **Tasks** | tasks | tasks-template | - |
| **Analyze** | checklist | checklist-template | check-prerequisites.sh |
| **Implement** | implement | agent-file-template | update-agent-context.sh |

\* Codebase templates are in the `code-mapping` skill

## Best Practices

### Start Simple
- Use constitution for new projects or when principles unclear
- Skip map for small/familiar codebases
- Skip checklist unless quality gates required

### Iterate
- Clarify can be run multiple times
- Plan can be updated as understanding improves
- Tasks can be regenerated

### Stay Organized
- One feature = one branch (if using git)
- Keep spec updated as requirements change
- Document decisions in plan

### Use the Tools
- Scripts automate repetitive tasks
- Templates ensure consistency
- Checklists catch issues early

## File Structure Reference

```
.sdd/                          # Runtime (gitignored)
├── .gitignore
├── codebase/                  # From /map
│   ├── STACK.md
│   └── ...
├── memory/
│   └── constitution.md        # From /constitution
└── templates/                 # Optional local overrides

specs/###-feature-name/        # Feature artifacts (committed)
├── spec.md                    # From /specify
├── plan.md                    # From /plan
├── tasks.md                   # From /tasks
├── research.md                # From /plan (optional)
├── data-model.md              # From /plan (optional)
├── quickstart.md              # From /plan (optional)
└── contracts/                 # From /plan (optional)
```

## Next Steps

- **Template Guide**: Detailed documentation for each template
- **Script Guide**: Parameters and examples for each script
- **Constitution Guide**: Creating effective constitutions
