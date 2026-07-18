# External Integrations

> **Purpose**: Document all external services, APIs, databases, and third-party integrations.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Databases & Data Stores

| Service | Type | Purpose | Configuration Location |
|---------|------|---------|------------------------|
| [e.g., PostgreSQL] | [e.g., Relational DB] | [e.g., Primary data store] | [e.g., `src/db/config.ts`] |

### Connection Patterns

Describe how the application connects to data stores:
- Connection pooling: [yes/no, details]
- ORM/Query builder: [e.g., Prisma, Drizzle, raw SQL]
- Migration approach: [e.g., Prisma migrations, custom scripts]

## Authentication & Authorization

| Provider | Purpose | Configuration Location |
|----------|---------|------------------------|
| [e.g., Auth0] | [e.g., User authentication] | [e.g., `src/auth/config.ts`] |

### Auth Flow

Brief description of the authentication flow:
- [e.g., OAuth2 with JWT tokens]
- [e.g., Session-based with Redis store]

## External APIs

### First-Party APIs (Our Services)

| Service | Purpose | Base URL Config | Client Location |
|---------|---------|-----------------|-----------------|
| [e.g., User Service] | [e.g., User management] | [e.g., `USER_API_URL`] | [e.g., `src/clients/user.ts`] |

### Third-Party APIs

| Provider | Purpose | SDK/Client | Rate Limits |
|----------|---------|------------|-------------|
| [e.g., Stripe] | [e.g., Payment processing] | [e.g., stripe-node] | [e.g., 100 req/sec] |

## Message Queues & Event Systems

| Service | Purpose | Configuration Location |
|---------|---------|------------------------|
| [e.g., Redis Pub/Sub] | [e.g., Real-time events] | [e.g., `src/events/config.ts`] |

## Caching

| Service | Purpose | TTL Defaults | Configuration |
|---------|---------|--------------|---------------|
| [e.g., Redis] | [e.g., Session cache] | [e.g., 1 hour] | [e.g., `src/cache/redis.ts`] |

## Monitoring & Observability

| Service | Purpose | Configuration |
|---------|---------|---------------|
| [e.g., Datadog] | [e.g., APM, logging] | [e.g., `datadog.yaml`] |

## File Storage

| Service | Purpose | Configuration |
|---------|---------|---------------|
| [e.g., S3] | [e.g., User uploads] | [e.g., `src/storage/s3.ts`] |

## Email & Notifications

| Service | Purpose | Configuration |
|---------|---------|---------------|
| [e.g., SendGrid] | [e.g., Transactional email] | [e.g., `src/email/sendgrid.ts`] |

---

## Environment Variables

List critical environment variables for integrations:

| Variable | Required | Purpose | Example |
|----------|----------|---------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection | `postgresql://...` |

---

## What Does NOT Belong Here

- Internal code architecture → ARCHITECTURE.md
- Testing infrastructure → TESTING.md
- Security policies → SECURITY.md
- Dependency versions → STACK.md

---

*This document maps external service dependencies. Update when adding new integrations.*
