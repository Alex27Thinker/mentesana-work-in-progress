# Architecture

> **Purpose**: Document system design, patterns, component relationships, and data flow.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Architecture Overview

Brief description of the overall architecture:
- [e.g., Monolithic application with modular structure]
- [e.g., Microservices with API gateway]
- [e.g., Serverless functions with event-driven design]

## Architecture Pattern

| Pattern | Description |
|---------|-------------|
| [e.g., Layered] | [e.g., Presentation → Business → Data access layers] |
| [e.g., Hexagonal] | [e.g., Ports and adapters for external dependencies] |
| [e.g., Event-Driven] | [e.g., Pub/sub for async communication] |

## Core Components

### [Component 1 Name]

- **Purpose**: [What it does]
- **Location**: `[path/to/component/]`
- **Dependencies**: [What it depends on]
- **Dependents**: [What depends on it]

### [Component 2 Name]

- **Purpose**: [What it does]
- **Location**: `[path/to/component/]`
- **Dependencies**: [What it depends on]
- **Dependents**: [What depends on it]

## Data Flow

### Primary User Flow

```
[Entry Point] → [Component A] → [Component B] → [Output]
     ↓              ↓
[Auth Check]    [Data Store]
```

Describe the main data flow through the system:
1. [Step 1: e.g., Request enters via API route]
2. [Step 2: e.g., Middleware validates authentication]
3. [Step 3: e.g., Service layer processes business logic]
4. [Step 4: e.g., Repository layer persists data]
5. [Step 5: e.g., Response returned to client]

### Event Flow (if applicable)

```
[Event Source] → [Event Bus] → [Handler A] → [Side Effect]
                      ↓
                [Handler B] → [Side Effect]
```

## Layer Boundaries

| Layer | Responsibility | Can Access | Cannot Access |
|-------|----------------|------------|---------------|
| [e.g., API] | [e.g., HTTP handling] | [e.g., Services] | [e.g., Repositories directly] |
| [e.g., Services] | [e.g., Business logic] | [e.g., Repositories] | [e.g., HTTP context] |
| [e.g., Repositories] | [e.g., Data access] | [e.g., Database] | [e.g., Services, API] |

## Dependency Rules

Rules for what can depend on what:
- [e.g., Higher layers can depend on lower layers, not vice versa]
- [e.g., Domain layer has no external dependencies]
- [e.g., Infrastructure adapters implement domain interfaces]

## Key Interfaces & Contracts

| Interface | Purpose | Implementations |
|-----------|---------|-----------------|
| [e.g., `UserRepository`] | [e.g., User data access] | [e.g., `PostgresUserRepository`] |

## State Management

| State Type | Location | Pattern |
|------------|----------|---------|
| [e.g., Client state] | [e.g., React Context] | [e.g., Reducer pattern] |
| [e.g., Server state] | [e.g., React Query] | [e.g., Cache invalidation] |

## Cross-Cutting Concerns

| Concern | Implementation | Location |
|---------|----------------|----------|
| [e.g., Logging] | [e.g., Winston + middleware] | [e.g., `src/middleware/logger.ts`] |
| [e.g., Error handling] | [e.g., Error boundary + centralized] | [e.g., `src/errors/`] |

---

## What Does NOT Belong Here

- Directory structure details → STRUCTURE.md
- Technology versions → STACK.md
- External service configs → INTEGRATIONS.md
- Code style rules → CONVENTIONS.md

---

*This document describes HOW the system is organized. Keep focus on patterns and relationships.*
