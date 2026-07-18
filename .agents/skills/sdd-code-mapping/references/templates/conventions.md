# Coding Conventions

> **Purpose**: Document code style, naming conventions, error handling, and common patterns.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Code Style

### Formatting Tools

| Tool | Configuration | Command |
|------|---------------|---------|
| [e.g., Prettier] | [e.g., `.prettierrc`] | `npm run format` |
| [e.g., ESLint] | [e.g., `eslint.config.js`] | `npm run lint` |

### Style Rules

| Rule | Convention | Example |
|------|------------|---------|
| Indentation | [e.g., 2 spaces] | |
| Quotes | [e.g., Single quotes] | `'string'` |
| Semicolons | [e.g., No semicolons] | `const x = 1` |
| Line length | [e.g., 100 chars max] | |
| Trailing commas | [e.g., Always in multi-line] | |

## Naming Conventions

### Files & Directories

| Type | Convention | Example |
|------|------------|---------|
| Components | [e.g., PascalCase] | `UserProfile.tsx` |
| Hooks | [e.g., camelCase with use prefix] | `useAuth.ts` |
| Utilities | [e.g., camelCase] | `formatDate.ts` |
| Constants | [e.g., SCREAMING_SNAKE_CASE file] | `API_CONSTANTS.ts` |
| Test files | [e.g., Same as source + .test] | `UserProfile.test.tsx` |

### Code Elements

| Type | Convention | Example |
|------|------------|---------|
| Variables | [e.g., camelCase] | `userName` |
| Constants | [e.g., SCREAMING_SNAKE_CASE] | `MAX_RETRIES` |
| Functions | [e.g., camelCase, verb prefix] | `getUserById` |
| Classes | [e.g., PascalCase] | `UserService` |
| Interfaces | [e.g., PascalCase, no I prefix] | `User` |
| Types | [e.g., PascalCase] | `UserResponse` |
| Enums | [e.g., PascalCase, singular] | `Status.Active` |

## Error Handling

### Error Patterns

| Scenario | Pattern | Example Location |
|----------|---------|------------------|
| API errors | [e.g., Custom error classes] | `src/errors/ApiError.ts` |
| Validation | [e.g., Zod schemas with parse] | `src/schemas/` |
| Async operations | [e.g., try/catch with typed errors] | |

### Error Response Format

```typescript
// Standard error response structure
{
  error: {
    code: 'ERROR_CODE',
    message: 'Human readable message',
    details?: object
  }
}
```

### Logging Conventions

| Level | When to Use | Example |
|-------|-------------|---------|
| error | Unrecoverable failures | `logger.error('Payment failed', { orderId })` |
| warn | Recoverable issues | `logger.warn('Retry attempted', { attempt })` |
| info | Important events | `logger.info('User created', { userId })` |
| debug | Development details | `logger.debug('Query result', { rows })` |

## Common Patterns

### API Handlers

```typescript
// Pattern for API route handlers
export async function handler(req, res) {
  // 1. Validate input
  // 2. Call service
  // 3. Return response
}
```

### Service Layer

```typescript
// Pattern for service methods
export class UserService {
  // 1. Validate business rules
  // 2. Call repository
  // 3. Transform result
}
```

### Repository Layer

```typescript
// Pattern for data access
export class UserRepository {
  // 1. Build query
  // 2. Execute query
  // 3. Map to domain entity
}
```

## Import Ordering

Standard import order:

1. External packages (react, next, etc.)
2. Internal packages (@/components, etc.)
3. Relative imports (./utils, ../types)
4. Type imports

## Comments & Documentation

| Type | When to Use | Format |
|------|-------------|--------|
| JSDoc | Public APIs | `/** ... */` |
| Inline | Complex logic | `// Explanation` |
| TODO | Planned work | `// TODO: description` |
| FIXME | Known issues | `// FIXME: description` |

## Git Conventions

### Commit Messages

Format: `type(scope): description`

| Type | Usage |
|------|-------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| style | Formatting |
| refactor | Code restructure |
| test | Adding tests |
| chore | Maintenance |

### Branch Naming

Format: `{type}/{ticket}-{description}`

Example: `feat/123-user-authentication`

---

## What Does NOT Belong Here

- Test strategies → TESTING.md
- Security practices → SECURITY.md
- Architecture patterns → ARCHITECTURE.md
- Technology choices → STACK.md

---

*This document defines HOW to write code. Update when conventions change.*
