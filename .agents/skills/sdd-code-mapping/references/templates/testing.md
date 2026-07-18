# Testing Strategy

> **Purpose**: Document test frameworks, patterns, organization, and coverage requirements.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Test Framework

| Type | Framework | Configuration |
|------|-----------|---------------|
| Unit | [e.g., Vitest] | [e.g., `vitest.config.ts`] |
| Integration | [e.g., Vitest] | [e.g., `vitest.config.ts`] |
| E2E | [e.g., Playwright] | [e.g., `playwright.config.ts`] |

### Running Tests

| Command | Purpose |
|---------|---------|
| `npm test` | Run all unit tests |
| `npm run test:integration` | Run integration tests |
| `npm run test:e2e` | Run E2E tests |
| `npm run test:coverage` | Run with coverage report |

## Test Organization

### Directory Structure

```
tests/
├── unit/                   # Unit tests (isolated, fast)
│   ├── services/
│   └── utils/
├── integration/            # Integration tests (with dependencies)
│   ├── api/
│   └── db/
└── e2e/                    # End-to-end tests (full system)
    ├── flows/
    └── fixtures/
```

### Test File Location

| Strategy | Convention |
|----------|------------|
| [e.g., Co-located] | `src/utils/format.ts` → `src/utils/format.test.ts` |
| [e.g., Separate dir] | `src/utils/format.ts` → `tests/unit/utils/format.test.ts` |

## Test Patterns

### Unit Tests

```typescript
// Pattern for unit tests
describe('FunctionName', () => {
  it('should do something when given input', () => {
    // Arrange
    // Act
    // Assert
  });
});
```

### Integration Tests

```typescript
// Pattern for integration tests
describe('FeatureName Integration', () => {
  beforeAll(async () => {
    // Setup: database, services
  });

  afterAll(async () => {
    // Teardown
  });

  it('should complete full flow', async () => {
    // Test with real dependencies
  });
});
```

### E2E Tests

```typescript
// Pattern for E2E tests
test.describe('User Flow', () => {
  test('should complete registration', async ({ page }) => {
    // Navigate, interact, assert
  });
});
```

## Mocking Strategy

### What to Mock

| Layer | Mock Strategy |
|-------|---------------|
| External APIs | [e.g., MSW handlers] |
| Database | [e.g., In-memory SQLite / Test containers] |
| Time | [e.g., `vi.useFakeTimers()`] |
| Environment | [e.g., Test env file] |

### Mock Locations

| Mock Type | Location |
|-----------|----------|
| API mocks | `tests/mocks/handlers.ts` |
| Fixtures | `tests/fixtures/` |
| Factories | `tests/factories/` |

## Test Data

### Fixtures

```typescript
// Pattern for test fixtures
export const testUser = {
  id: 'test-user-id',
  email: 'test@example.com',
  name: 'Test User',
};
```

### Factories

```typescript
// Pattern for test factories
export function createUser(overrides = {}) {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    ...overrides,
  };
}
```

## Coverage Requirements

| Metric | Target | Current |
|--------|--------|---------|
| Line coverage | [e.g., 80%] | [X%] |
| Branch coverage | [e.g., 75%] | [X%] |
| Function coverage | [e.g., 80%] | [X%] |

### Coverage Exclusions

Files/patterns excluded from coverage:

- `src/generated/` - Auto-generated code
- `*.config.ts` - Configuration files
- `src/types/` - Type definitions only

## Test Categories

### Smoke Tests

Critical path tests that must pass before deploy:

| Test | Purpose |
|------|---------|
| `smoke/health.test.ts` | API health check |
| `smoke/auth.test.ts` | Authentication flow |

### Regression Tests

Tests for previously fixed bugs:

| Test | Issue | Description |
|------|-------|-------------|
| `regression/issue-123.test.ts` | #123 | [Description] |

## CI Integration

### Test Pipeline

```yaml
# Test stage configuration
- Unit tests (parallel)
- Integration tests (with services)
- E2E tests (full environment)
- Coverage report
```

### Required Checks

| Check | Blocking |
|-------|----------|
| Unit tests pass | Yes |
| Integration tests pass | Yes |
| Coverage threshold met | Yes |
| E2E tests pass | Yes (for deploy) |

---

## What Does NOT Belong Here

- Code style rules → CONVENTIONS.md
- Security testing → SECURITY.md
- Architecture patterns → ARCHITECTURE.md

---

*This document describes HOW to test. Update when testing strategy changes.*
