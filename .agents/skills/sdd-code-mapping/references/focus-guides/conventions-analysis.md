# Conventions Analysis Guide

This guide describes how to analyze a codebase to populate CONVENTIONS.md and TESTING.md.

## Documents to Generate

1. **CONVENTIONS.md** - Code style, naming, error handling, patterns
2. **TESTING.md** - Test strategy, frameworks, patterns

## Analysis Strategy

### Step 1: Identify Tooling Configuration

Scan for configuration files:

**Linting:**
- `.eslintrc*`, `eslint.config.js` → ESLint
- `biome.json` → Biome
- `clippy.toml`, `.clippy.toml` → Clippy (Rust)
- `ruff.toml`, `pyproject.toml [tool.ruff]` → Ruff (Python)

**Formatting:**
- `.prettierrc*` → Prettier
- `biome.json` → Biome
- `rustfmt.toml` → rustfmt (Rust)
- `pyproject.toml [tool.black/ruff]` → Black/Ruff (Python)

**Type Checking:**
- `tsconfig.json` → TypeScript
- `mypy.ini`, `pyproject.toml [tool.mypy]` → mypy (Python)
- `pyrightconfig.json` → Pyright (Python)

### Step 2: Infer Naming Conventions

Analyze existing code to identify patterns:

**File naming:**
```bash
# Check component naming
ls -la src/components/

# Check utility naming
ls -la src/utils/
```

**Code element naming:**
- Functions: camelCase, snake_case, PascalCase
- Constants: SCREAMING_SNAKE_CASE
- Classes/Types: PascalCase
- Interfaces: with/without I prefix

### Step 3: Analyze Error Handling

Find error handling patterns:

```bash
# Find custom error classes
grep -r "class.*Error" src/

# Find try/catch patterns
grep -r "try {" src/

# Find Result/Option usage (Rust)
grep -r "Result<\|Option<" src/
```

Document:
- How errors are created
- How errors are propagated
- How errors are logged
- Standard error response format

### Step 4: Identify Common Patterns

Look for recurring code patterns:

**API handlers:**
```bash
# Express/Fastify
grep -r "async.*req.*res" src/

# Next.js API routes
cat src/app/api/*/route.ts
```

**Service methods:**
```bash
grep -r "class.*Service" src/
```

**Repository methods:**
```bash
grep -r "class.*Repository" src/
```

### Step 5: Analyze Git Conventions

Check commit history and configuration:

```bash
# Check commit message format
git log --oneline -20

# Check for conventional commits
grep -i "feat\|fix\|docs\|style\|refactor\|test\|chore" <(git log --oneline -50)

# Check for commitlint config
cat commitlint.config.js 2>/dev/null
```

### Step 6: Identify Testing Framework

Scan for test configuration:

| Config File | Framework |
|-------------|-----------|
| `vitest.config.ts` | Vitest |
| `jest.config.js/ts` | Jest |
| `pytest.ini`, `pyproject.toml [tool.pytest]` | pytest |
| `Cargo.toml [dev-dependencies]` | Rust built-in |
| `playwright.config.ts` | Playwright (E2E) |
| `cypress.config.ts` | Cypress (E2E) |

### Step 7: Analyze Test Organization

Find how tests are organized:

```bash
# Co-located tests
find src -name "*.test.*" -o -name "*.spec.*"

# Separate test directory
ls tests/ 2>/dev/null
```

Determine:
- Unit test location
- Integration test location
- E2E test location
- Fixture/mock location

### Step 8: Analyze Test Patterns

Look at existing tests for patterns:

```bash
# Find test structure
head -50 $(find . -name "*.test.ts" | head -1)

# Find mock patterns
grep -r "mock\|vi.fn\|jest.fn" tests/
```

### Step 9: Check Coverage Configuration

Find coverage settings:

```bash
# Vitest/Jest coverage
grep -A 10 "coverage" vitest.config.ts jest.config.js 2>/dev/null

# pytest coverage
grep coverage pyproject.toml pytest.ini 2>/dev/null
```

## Patterns to Document

### Code Style Patterns

- Import ordering (external, internal, relative)
- Comment conventions (JSDoc, docstrings)
- Function length limits
- File organization within modules

### Testing Patterns

- Arrange/Act/Assert structure
- Given/When/Then (BDD)
- Test data factories
- Mock strategies
- Snapshot testing usage

### Error Patterns

- Custom error hierarchies
- Error codes/types
- Logging standards
- Retry logic

## Output Guidelines

### For CONVENTIONS.md

- **Be specific**: Include actual examples from codebase
- **Reference configs**: Point to config files
- **Include commands**: How to run lint/format
- **Document exceptions**: When rules are broken

### For TESTING.md

- **List all test types**: Unit, integration, E2E
- **Include commands**: How to run each type
- **Document mocking**: What's mocked and how
- **Set expectations**: Coverage targets

## Analysis Commands

### Style Analysis

```bash
# Find longest files (complexity indicator)
find src -name "*.ts" -exec wc -l {} + | sort -n | tail -10

# Find most-used patterns
grep -rho "async function\|const.*=.*=>" src/ | sort | uniq -c | sort -n
```

### Test Analysis

```bash
# Count tests
find . -name "*.test.*" -exec grep -l "it\|test\|describe" {} \; | wc -l

# Find test utilities
find . -name "testUtils*" -o -name "helpers*" | grep -i test
```

## What to Exclude

**From CONVENTIONS.md:**
- Test strategies (→ TESTING.md)
- Architecture decisions (→ ARCHITECTURE.md)
- Security practices (→ SECURITY.md)

**From TESTING.md:**
- Code style rules (→ CONVENTIONS.md)
- Security testing details (→ SECURITY.md)
- CI/CD pipeline details (brief mention OK)
