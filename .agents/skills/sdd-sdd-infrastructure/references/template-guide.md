# Template Guide

Comprehensive documentation for all SDD templates including purpose, structure, customization options, and best practices.

## Template Index

1. [Spec Template](#spec-template) - Feature specifications
2. [Plan Template](#plan-template) - Implementation plans
3. [Tasks Template](#tasks-template) - Task lists
4. [Checklist Template](#checklist-template) - Quality checklists
5. [Agent File Template](#agent-file-template) - Agent context
6. [Constitution Template](#constitution-template) - Project governance

---

## Spec Template

**File**: `templates/spec-template.md`
**Used by**: `/sdd:specify` command
**Output**: `specs/###-feature-name/spec.md`

### Purpose

Defines WHAT needs to be built from the user's perspective. Focuses on user value, not technical implementation.

### Key Sections

#### 1. User Scenarios & Testing (Mandatory)

Prioritized user stories that are independently testable:

```markdown
### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Value explanation]

**Independent Test**: [How to verify independently]

**Acceptance Scenarios**:
1. **Given** [state], **When** [action], **Then** [outcome]
```

**Best practices**:
- P1 = MVP, must be independently valuable
- Each story should be deployable on its own
- Write from user's perspective, not developer's
- 3-5 stories typical, more for complex features

#### 2. Requirements (Mandatory)

Specific, measurable functional requirements:

```markdown
- **FR-001**: System MUST [specific capability]
- **FR-002**: Users MUST be able to [key interaction]
```

**Best practices**:
- Use "MUST" for requirements, "SHOULD" for preferences
- Mark unclear items: `[NEEDS CLARIFICATION: ...]`
- Technology-agnostic (no "use React" here)
- Testable and verifiable

#### 3. Success Criteria (Mandatory)

Measurable outcomes that define success:

```markdown
- **SC-001**: Users can complete [task] in under [time]
- **SC-002**: System handles [load] without degradation
```

**Best practices**:
- Quantifiable metrics only
- User-focused, not technical metrics
- Aligned with business goals

### Customization

**Add sections for**:
- Security requirements (for auth/data features)
- Performance requirements (for high-scale features)
- Compliance requirements (for regulated domains)
- Accessibility requirements

**Remove sections**:
- Key Entities (if feature has no data model)

**Override**: Create `.sdd/templates/spec-template.md` in your repo

---

## Plan Template

**File**: `templates/plan-template.md`
**Used by**: `/sdd:plan` command
**Output**: `specs/###-feature-name/plan.md`

### Purpose

Bridges specification (WHAT) to implementation (HOW). Defines technical approach and architecture.

### Key Sections

#### 1. Technical Context

Technology stack and constraints:

```markdown
**Language/Version**: Python 3.11
**Primary Dependencies**: FastAPI
**Storage**: PostgreSQL
**Testing**: pytest
**Project Type**: web (determines structure)
```

**Best practices**:
- Use "NEEDS CLARIFICATION" if unknown
- Be specific (Python 3.11, not just Python)
- Align with constitution if one exists

#### 2. Constitution Check

Validates against project principles:

```markdown
## Constitution Check

*GATE: Must pass before Phase 0 research.*

- ✓ Test-First: Will write tests before implementation
- ✓ Library-First: Auth will be standalone library
- ⚠ Complexity: Requires 4th microservice [needs justification]
```

**Best practices**:
- Reference constitution principles by name
- Document any violations with justification
- Use Complexity Tracking table for violations

#### 3. Project Structure

Concrete directory layout:

```markdown
### Source Code

\```text
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/
\```
```

**Best practices**:
- Use actual paths, not placeholders
- Delete unused structure options
- Match existing codebase conventions

### Customization

**Add sections for**:
- Architecture diagrams (links to external tools)
- Migration strategy (for database changes)
- Deployment plan (for infrastructure changes)
- Performance benchmarks (for optimization work)

**Remove sections**:
- Complexity Tracking (if no constitution violations)
- Constitution Check (if project has no constitution)

**Override**: Create `.sdd/templates/plan-template.md` in your repo

---

## Tasks Template

**File**: `templates/tasks-template.md`
**Used by**: `/sdd:tasks` command
**Output**: `specs/###-feature-name/tasks.md`

### Purpose

Organizes work into independent, parallel-executable tasks grouped by user story.

### Key Sections

#### 1. Format Convention

```markdown
## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: User story (US1, US2, etc.)
- Include exact file paths
```

#### 2. Phase Structure

**Phase 1: Setup** - Project initialization

**Phase 2: Foundational** - BLOCKS all user stories
- Database schema
- Authentication framework
- Base models

**Phase 3+: User Stories** - Independent implementation
- Organized by priority (P1, P2, P3)
- Each story fully functional when complete

**Final Phase: Polish** - Cross-cutting concerns

#### 3. Task Format

```markdown
- [ ] T012 [P] [US1] Create Entity1 model in src/models/entity1.py
- [ ] T013 [P] [US1] Create Entity2 model in src/models/entity2.py
```

**Best practices**:
- Exact file paths (helps with parallel work)
- [P] only if different files and no dependencies
- [Story] tag for traceability
- Tests before implementation (if tests requested)

### Customization

**Add phases for**:
- Data migration (for schema changes)
- Feature flags (for gradual rollout)
- Documentation (for public APIs)

**Adjust parallelization**:
- Remove [P] in monorepo with shared code
- Add more [P] in microservices

**Override**: Create `.sdd/templates/tasks-template.md` in your repo

---

## Checklist Template

**File**: `templates/checklist-template.md`
**Used by**: `/sdd:checklist` command
**Output**: Various (custom per request)

### Purpose

Most flexible template - generates quality validation checklists for any purpose.

### Structure

```markdown
# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [What this checklist covers]

## [Category 1]

- [ ] CHK001 First item with clear action
- [ ] CHK002 Second item
```

### Common Checklist Types

#### Requirements Analysis
```markdown
## Completeness
- [ ] CHK001 All user stories have acceptance criteria
- [ ] CHK002 Edge cases documented

## Clarity
- [ ] CHK003 No ambiguous requirements
- [ ] CHK004 All "NEEDS CLARIFICATION" resolved
```

#### Architecture Review
```markdown
## Constitution Compliance
- [ ] CHK001 Adheres to Test-First principle
- [ ] CHK002 No unnecessary complexity

## Scalability
- [ ] CHK003 Handles expected load
```

#### Security Audit
```markdown
## Authentication
- [ ] CHK001 Passwords hashed, not stored plain
- [ ] CHK002 Session management secure

## Input Validation
- [ ] CHK003 All user inputs validated
```

### Customization

**Highly customizable** - command generates based on:
- User's specific request
- Feature context (from spec/plan)
- Relevant principles (from constitution)

**No override needed** - always dynamically generated

---

## Agent File Template

**File**: `templates/agent-file-template.md`
**Used by**: `/sdd:implement` via `update-agent-context.sh`
**Output**: `CLAUDE.md`, `GEMINI.md`, etc.

### Purpose

Auto-generates AI agent context from all feature plans. Keeps agents synchronized with current tech stack and structure.

### Structure

```markdown
# [PROJECT NAME] Development Guidelines

Auto-generated from all feature plans. Last updated: [DATE]

## Active Technologies

[EXTRACTED FROM ALL PLAN.MD FILES]

## Project Structure

[ACTUAL STRUCTURE FROM PLANS]

## Commands

[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES]

## Code Style

[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE]

## Recent Changes

[LAST 3 FEATURES AND WHAT THEY ADDED]

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
```

### Best Practices

- **Don't edit directly** - regenerated from plans
- **Manual additions** - Use marked section for custom rules
- **Multiple agents** - Same content for all agent types
- **Keep current** - Run update-agent-context.sh after plan changes

### Customization

**Manual additions preserved**:
```markdown
<!-- MANUAL ADDITIONS START -->
## Custom Project Rules

- Always use factory pattern for models
- Prefer composition over inheritance
<!-- MANUAL ADDITIONS END -->
```

**Override**: Not recommended - template is intentionally generic

---

## Constitution Template

**File**: `assets/constitution/constitution-template.md`
**Used by**: `/sdd:constitution` command
**Output**: `.sdd/memory/constitution.md`

### Purpose

Defines project-specific principles and governance that guide all development decisions.

### Structure

```markdown
# [PROJECT_NAME] Constitution

## Core Principles

### [PRINCIPLE_1_NAME]
[PRINCIPLE_1_DESCRIPTION]

### [PRINCIPLE_2_NAME]
[PRINCIPLE_2_DESCRIPTION]

...

## Governance

[GOVERNANCE_RULES]
```

### Effective Principles

**Good principles are**:
- Specific and actionable
- Testable (can verify compliance)
- Valuable (prevent real problems)
- Documented with rationale

**Examples**:

```markdown
### I. Test-First (NON-NEGOTIABLE)

Tests must be written and approved before implementation.

**Why**: Prevents implementation-driven design, ensures testability

**Enforcement**: PR reviews block if tests missing
```

```markdown
### II. Library-First

Features must be extractable standalone libraries.

**Why**: Encourages modularity, enables reuse

**Compliance**: Each feature can be imported and used independently
```

### Customization

**Principle categories**:
- Development practices (TDD, code review)
- Architecture constraints (microservices limit, no singletons)
- Technology choices (approved languages, frameworks)
- Performance standards (latency, throughput)
- Security requirements (auth, encryption)

**See**: `constitution-guide.md` for principles catalog

---

## Template Relationships

```
Constitution
    ↓ (informs)
Spec ← (user input)
    ↓ (technical planning)
Plan → (checks) → Constitution
    ↓ (generates)
Tasks → (organized by) → Spec User Stories
    ↓ (execution)
Agent File ← (extracts from) ← Plan
```

## Local Template Overrides

All templates can be overridden:

1. Create `.sdd/templates/` in your repo
2. Copy template: `cp $PLUGIN_ROOT/skills/sdd-infrastructure/templates/spec-template.md .sdd/templates/`
3. Customize as needed
4. Commands will use local version if it exists

**When to override**:
- Domain-specific sections needed
- Company style requirements
- Custom workflow phases

**Override priority**:
1. `.sdd/templates/[template-name]` (highest)
2. `$PLUGIN_ROOT/skills/sdd-infrastructure/templates/[template-name]`

## Related Documentation

- **Workflow Overview**: How templates fit into SDD phases
- **Script Guide**: How scripts use templates
- **Constitution Guide**: Creating effective constitutions
