# Architecture Analysis Guide

This guide describes how to analyze a codebase to populate ARCHITECTURE.md and STRUCTURE.md.

## Documents to Generate

1. **ARCHITECTURE.md** - System design, patterns, data flow
2. **STRUCTURE.md** - Directory layout, module boundaries

## Analysis Strategy

### Step 1: Map Directory Structure

Start with the top-level directory layout:

```bash
# Get directory structure (depth 2-3)
find . -type d -maxdepth 3 | grep -v node_modules | grep -v .git
```

Identify the organizational pattern:
- **Layered**: `controllers/`, `services/`, `repositories/`
- **Feature-based**: `features/auth/`, `features/users/`
- **Domain-driven**: `domain/`, `application/`, `infrastructure/`
- **Next.js App Router**: `app/`, `components/`, `lib/`
- **Monorepo**: `packages/`, `apps/`

### Step 2: Identify Entry Points

Find where the application starts:

| Framework | Entry Point |
|-----------|-------------|
| Next.js App Router | `app/layout.tsx`, `app/page.tsx` |
| Next.js Pages | `pages/_app.tsx`, `pages/index.tsx` |
| Express/Fastify | `src/server.ts`, `src/index.ts` |
| FastAPI | `main.py`, `app/main.py` |
| Rust CLI | `src/main.rs` |
| Rust Library | `src/lib.rs` |

### Step 3: Trace Data Flow

Follow the request/response flow:

1. **Entry**: Where requests come in (API routes, CLI args)
2. **Middleware**: What processing happens first (auth, logging)
3. **Business Logic**: Where decisions are made (services)
4. **Data Access**: Where data is stored/retrieved (repositories)
5. **Response**: How results are returned

Document this as a flow diagram in ARCHITECTURE.md.

### Step 4: Identify Layer Boundaries

For each directory, determine:
- **What it can access**: Dependencies it imports
- **What it cannot access**: What should never be imported
- **Its responsibility**: Single purpose

Example layer rules:
- API layer → Services ✓, Database ✗
- Services → Repositories ✓, API ✗
- Repositories → Database ✓, Services ✗

### Step 5: Find Common Patterns

Look for recurring patterns:

**Dependency Injection:**
- Constructor injection
- Factory functions
- Context/Provider patterns

**Error Handling:**
- Custom error classes
- Error boundaries
- Result types (Rust)

**State Management:**
- Global state (Redux, Zustand)
- Server state (React Query, SWR)
- Local state (useState, Context)

### Step 6: Analyze Component Relationships

For each major component:
- What does it depend on?
- What depends on it?
- Can it be deployed independently?

Create a dependency map for ARCHITECTURE.md.

### Step 7: Document Module Boundaries

For STRUCTURE.md, identify:
- Where to add new API endpoints
- Where to add new components
- Where to add new services
- Where to add shared utilities

## Patterns to Identify

### Monorepo Patterns

- **Packages**: Shared libraries
- **Apps**: Deployable applications
- **Tools**: Build/dev tooling
- **Configs**: Shared configurations

### API Patterns

- **REST**: Resource-based routes
- **GraphQL**: Schema-first or code-first
- **RPC**: Procedure-based calls
- **Event-driven**: Pub/sub, webhooks

### UI Patterns

- **Container/Presenter**: Smart/dumb components
- **Compound Components**: Composable UI
- **Render Props**: Flexible composition
- **Hooks**: Reusable logic

## Output Guidelines

### For ARCHITECTURE.md

- **Document the WHY**: Why this pattern was chosen
- **Show relationships**: How components interact
- **Include diagrams**: Flow diagrams, dependency graphs
- **Define boundaries**: What can/cannot access what

### For STRUCTURE.md

- **Be prescriptive**: Tell developers WHERE to add code
- **Include examples**: Path patterns with examples
- **Document conventions**: Naming, organization rules
- **List generated files**: What's auto-generated

## Analysis Commands

### Find imports/dependencies

```bash
# TypeScript/JavaScript
grep -r "from '" src/ | grep -v node_modules

# Python
grep -r "^from\|^import" src/

# Rust
grep -r "^use\|^mod" src/
```

### Find public APIs

```bash
# Exported functions/classes
grep -r "export " src/

# Python public modules
ls -la src/*/__init__.py
```

### Find entry points

```bash
# Main files
find . -name "main.*" -o -name "index.*" -o -name "server.*"

# Route definitions
grep -r "router\|app\." src/ | grep -E "(get|post|put|delete|use)\("
```

## What to Exclude

**From ARCHITECTURE.md:**
- Directory structure details (→ STRUCTURE.md)
- Specific file contents
- Configuration values

**From STRUCTURE.md:**
- System design decisions (→ ARCHITECTURE.md)
- Technology choices (→ STACK.md)
- Code conventions (→ CONVENTIONS.md)
