# Tech Stack Analysis Guide

This guide describes how to analyze a codebase to populate STACK.md and INTEGRATIONS.md.

## Documents to Generate

1. **STACK.md** - Languages, frameworks, dependencies, versions
2. **INTEGRATIONS.md** - External services, APIs, data stores

## Analysis Strategy

### Step 1: Identify Package Manifests

Scan for these files in the project root:

| File | Language/Ecosystem |
|------|-------------------|
| `package.json` | JavaScript/TypeScript/Node.js |
| `Cargo.toml` | Rust |
| `pyproject.toml` | Python (modern) |
| `requirements.txt` | Python (legacy) |
| `go.mod` | Go |
| `Gemfile` | Ruby |
| `pom.xml` | Java (Maven) |
| `build.gradle` | Java/Kotlin (Gradle) |

### Step 2: Extract Core Technologies

From package manifests, identify:

1. **Language version** (if specified)
2. **Framework** (the primary application framework)
3. **Critical dependencies** (packages used throughout the codebase)

**Priority for STACK.md:**
- List frameworks first (Next.js, FastAPI, Actix, etc.)
- Then critical libraries used across the codebase
- Limit to 5-10 dependencies - don't list everything

### Step 3: Identify Configuration Files

Scan for config files that indicate technologies:

| Config File | Technology |
|-------------|------------|
| `next.config.js/ts` | Next.js |
| `vite.config.ts` | Vite |
| `tailwind.config.js/ts` | Tailwind CSS |
| `tsconfig.json` | TypeScript |
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.ts` | Drizzle ORM |
| `.eslintrc*`, `eslint.config.js` | ESLint |
| `biome.json` | Biome |
| `.prettierrc*` | Prettier |
| `docker-compose.yml` | Docker Compose |

### Step 4: Detect Integrations

Scan for patterns indicating external services:

**Database indicators:**
- Prisma schema files → PostgreSQL, MySQL, SQLite
- Environment variables: `DATABASE_URL`, `POSTGRES_*`, `MYSQL_*`
- Import statements: `pg`, `mysql2`, `better-sqlite3`

**Authentication providers:**
- NextAuth config → OAuth providers
- Auth0 SDK imports
- JWT library imports

**External APIs:**
- SDK imports (stripe, twilio, sendgrid)
- API client files in `src/clients/` or `src/api/`
- Environment variables with `*_API_KEY`, `*_SECRET`

**Message queues:**
- Redis, RabbitMQ, Kafka imports
- `REDIS_URL`, `RABBITMQ_URL` env vars

**Storage:**
- S3/GCS SDK imports
- Upload handling code

### Step 5: Analyze Import Patterns

Search for import statements to understand:
- Which packages are actually used (not just installed)
- How external services are integrated
- Which internal modules depend on which packages

```bash
# Example search patterns
grep -r "from 'stripe'" src/
grep -r "import.*prisma" src/
grep -r "createClient.*supabase" src/
```

### Step 6: Check Environment Configuration

Analyze environment variable usage:

1. Check `.env.example` or `.env.template` for required vars
2. Look for env validation (Zod schema, envalid)
3. Map env vars to their purposes

## Output Guidelines

### For STACK.md

- **Be concise**: Only list what actually runs
- **Specify versions**: Only when compatibility matters
- **Focus on frameworks**: They define the architecture
- **Limit dependencies**: 5-10 most important, not all

### For INTEGRATIONS.md

- **Include connection details**: Where config lives
- **Document auth flow**: How authentication works
- **List environment vars**: What's needed to run
- **Note failure modes**: What happens when services are down

## Common Patterns by Stack

### Next.js + TypeScript

Check for:
- App Router vs Pages Router (presence of `app/` vs `pages/`)
- Data fetching patterns (Server Components, getServerSideProps)
- State management (Zustand, Jotai, Redux)
- Styling (Tailwind, CSS Modules, styled-components)

### Python + FastAPI

Check for:
- Async patterns (async def, await)
- ORM (SQLAlchemy, Tortoise, raw SQL)
- Dependency injection patterns
- Pydantic for validation

### Rust + Actix/Axum

Check for:
- Async runtime (Tokio, async-std)
- Database (sqlx, diesel, sea-orm)
- Error handling (thiserror, anyhow)
- Serialization (serde)

## What to Exclude

**From STACK.md:**
- Dev-only dependencies (unless critical like TypeScript)
- Testing frameworks (→ TESTING.md)
- Linting/formatting tools (→ CONVENTIONS.md)

**From INTEGRATIONS.md:**
- Internal module communication
- Architecture patterns (→ ARCHITECTURE.md)
- Code organization (→ STRUCTURE.md)
