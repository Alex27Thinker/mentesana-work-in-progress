# Project Structure

> **Purpose**: Document directory layout, module boundaries, and where to add new code.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Directory Layout

```
project-root/
├── src/                    # [Purpose description]
│   ├── api/                # [Purpose description]
│   ├── components/         # [Purpose description]
│   ├── services/           # [Purpose description]
│   └── utils/              # [Purpose description]
├── tests/                  # [Purpose description]
├── config/                 # [Purpose description]
└── scripts/                # [Purpose description]
```

## Key Directories

### `src/` - Source Code

| Directory | Purpose | Naming Convention |
|-----------|---------|-------------------|
| `api/` | [e.g., API routes and handlers] | [e.g., `{resource}.ts`] |
| `components/` | [e.g., React components] | [e.g., `PascalCase.tsx`] |
| `services/` | [e.g., Business logic] | [e.g., `{domain}Service.ts`] |
| `models/` | [e.g., Data models/entities] | [e.g., `{Entity}.ts`] |
| `utils/` | [e.g., Shared utilities] | [e.g., `{function}.ts`] |

### `tests/` - Test Files

| Directory | Purpose | Naming Convention |
|-----------|---------|-------------------|
| `unit/` | [e.g., Unit tests] | [e.g., `{module}.test.ts`] |
| `integration/` | [e.g., Integration tests] | [e.g., `{feature}.spec.ts`] |
| `e2e/` | [e.g., End-to-end tests] | [e.g., `{flow}.e2e.ts`] |

### `config/` - Configuration

| File/Directory | Purpose |
|----------------|---------|
| `database.ts` | [e.g., Database configuration] |
| `env.ts` | [e.g., Environment variable validation] |

## Module Boundaries

### Feature Modules

Each feature should be self-contained:

```
src/features/{feature}/
├── components/     # Feature-specific UI
├── hooks/          # Feature-specific hooks
├── api/            # Feature API routes
├── services/       # Feature business logic
├── types/          # Feature type definitions
└── index.ts        # Public exports
```

### Shared Modules

Shared code that crosses feature boundaries:

```
src/shared/
├── components/     # Reusable UI components
├── hooks/          # Reusable hooks
├── utils/          # Utility functions
└── types/          # Shared type definitions
```

## Where to Add New Code

| If you're adding... | Put it in... | Example |
|---------------------|--------------|---------|
| New API endpoint | `src/api/{resource}/` | `src/api/users/create.ts` |
| New React component | `src/components/{domain}/` | `src/components/auth/LoginForm.tsx` |
| New service | `src/services/` | `src/services/emailService.ts` |
| New utility | `src/utils/` | `src/utils/formatDate.ts` |
| New type definition | `src/types/` | `src/types/user.ts` |
| Configuration | `config/` | `config/stripe.ts` |
| Database migration | `migrations/` | `migrations/001_create_users.sql` |

## Import Paths

| Path Alias | Maps To | Usage |
|------------|---------|-------|
| `@/` | `src/` | `import { User } from '@/types/user'` |
| `@components/` | `src/components/` | `import { Button } from '@components/ui'` |
| `@lib/` | `src/lib/` | `import { db } from '@lib/database'` |

## Entry Points

| File | Purpose |
|------|---------|
| `src/index.ts` | [e.g., Main application entry] |
| `src/server.ts` | [e.g., Server bootstrap] |
| `src/app/layout.tsx` | [e.g., Next.js root layout] |

## Generated Files

Files that are auto-generated and should not be manually edited:

| Location | Generator | Regenerate Command |
|----------|-----------|-------------------|
| `src/generated/` | [e.g., OpenAPI codegen] | `npm run generate` |
| `prisma/client/` | [e.g., Prisma] | `npx prisma generate` |

---

## What Does NOT Belong Here

- Architecture patterns → ARCHITECTURE.md
- Technology choices → STACK.md
- Code style rules → CONVENTIONS.md
- Test patterns → TESTING.md

---

*This document shows WHERE code lives. Update when directory structure changes.*
