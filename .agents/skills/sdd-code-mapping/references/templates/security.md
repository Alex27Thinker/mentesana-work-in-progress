# Security

> **Purpose**: Document authentication, authorization, security controls, and vulnerability status.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Authentication

### Authentication Method

| Method | Implementation | Configuration |
|--------|----------------|---------------|
| [e.g., JWT] | [e.g., jose library] | [e.g., `src/auth/jwt.ts`] |
| [e.g., OAuth2] | [e.g., NextAuth] | [e.g., `src/auth/[...nextauth].ts`] |
| [e.g., Session] | [e.g., express-session] | [e.g., `src/middleware/session.ts`] |

### Token Configuration

| Setting | Value | Location |
|---------|-------|----------|
| Token type | [e.g., JWT] | |
| Expiration | [e.g., 1 hour] | |
| Refresh token | [e.g., 7 days] | |
| Signing algorithm | [e.g., RS256] | |

### Session Management

| Setting | Value |
|---------|-------|
| Session storage | [e.g., Redis] |
| Session duration | [e.g., 24 hours] |
| Idle timeout | [e.g., 30 minutes] |

## Authorization

### Authorization Model

| Model | Description |
|-------|-------------|
| [e.g., RBAC] | Role-based access control |
| [e.g., ABAC] | Attribute-based access control |
| [e.g., Custom] | [Description] |

### Roles & Permissions

| Role | Permissions | Scope |
|------|-------------|-------|
| admin | [e.g., all] | [e.g., system-wide] |
| user | [e.g., read, write own] | [e.g., own resources] |
| viewer | [e.g., read only] | [e.g., public resources] |

### Permission Checks

| Location | Pattern | Example |
|----------|---------|---------|
| API routes | [e.g., Middleware] | `src/middleware/authorize.ts` |
| UI | [e.g., Component wrapper] | `src/components/ProtectedRoute.tsx` |
| Service layer | [e.g., Guard functions] | `src/services/guards.ts` |

## Input Validation

### Validation Strategy

| Layer | Method | Library |
|-------|--------|---------|
| API input | [e.g., Schema validation] | [e.g., Zod] |
| Form input | [e.g., Client validation] | [e.g., React Hook Form + Zod] |
| Database | [e.g., Constraints] | [e.g., Prisma schema] |

### Sanitization

| Data Type | Sanitization | Location |
|-----------|--------------|----------|
| HTML content | [e.g., DOMPurify] | `src/utils/sanitize.ts` |
| SQL | [e.g., Parameterized queries] | ORM handles |
| URLs | [e.g., URL validation] | `src/utils/validate.ts` |

## Data Protection

### Sensitive Data Handling

| Data Type | Protection Method | Storage |
|-----------|-------------------|---------|
| Passwords | [e.g., bcrypt hash] | Database |
| API keys | [e.g., Encrypted] | Vault |
| PII | [e.g., Encrypted at rest] | Database |

### Encryption

| Type | Algorithm | Key Management |
|------|-----------|----------------|
| At rest | [e.g., AES-256] | [e.g., AWS KMS] |
| In transit | [e.g., TLS 1.3] | [e.g., Let's Encrypt] |
| Application | [e.g., libsodium] | [e.g., Environment vars] |

## Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| Content-Security-Policy | [e.g., default-src 'self'] | XSS protection |
| X-Frame-Options | [e.g., DENY] | Clickjacking protection |
| X-Content-Type-Options | [e.g., nosniff] | MIME sniffing protection |
| Strict-Transport-Security | [e.g., max-age=31536000] | HTTPS enforcement |

## CORS Configuration

| Setting | Value |
|---------|-------|
| Allowed origins | [e.g., https://app.example.com] |
| Allowed methods | [e.g., GET, POST, PUT, DELETE] |
| Allowed headers | [e.g., Authorization, Content-Type] |
| Credentials | [e.g., true] |

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| API general | [e.g., 100 req] | [e.g., 1 minute] |
| Login | [e.g., 5 attempts] | [e.g., 15 minutes] |
| Sensitive operations | [e.g., 10 req] | [e.g., 1 hour] |

## Secrets Management

### Environment Variables

| Category | Naming Convention | Example |
|----------|-------------------|---------|
| API keys | `{SERVICE}_API_KEY` | `STRIPE_API_KEY` |
| Database | `DATABASE_*` | `DATABASE_URL` |
| Secrets | `{SERVICE}_SECRET` | `JWT_SECRET` |

### Secrets Storage

| Environment | Method |
|-------------|--------|
| Development | [e.g., .env.local (gitignored)] |
| CI/CD | [e.g., GitHub Secrets] |
| Production | [e.g., AWS Secrets Manager] |

## Audit Logging

| Event | Logged Data | Retention |
|-------|-------------|-----------|
| Authentication | [e.g., user, ip, timestamp, success] | [e.g., 90 days] |
| Authorization failures | [e.g., user, resource, action] | [e.g., 90 days] |
| Data access | [e.g., user, resource, action] | [e.g., 1 year] |

---

## What Does NOT Belong Here

- Tech debt and risks → CONCERNS.md
- Testing strategy → TESTING.md
- Code conventions → CONVENTIONS.md

---

*This document defines security controls. Update when security posture changes.*
