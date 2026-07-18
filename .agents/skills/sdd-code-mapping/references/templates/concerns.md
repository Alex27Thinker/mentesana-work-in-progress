# Known Concerns

> **Purpose**: Document technical debt, known risks, bugs, fragile areas, and improvement opportunities.
> **Generated**: [DATE]
> **Last Updated**: [DATE]

## Technical Debt

### High Priority

Items that should be addressed soon:

| ID | Area | Description | Impact | Effort |
|----|------|-------------|--------|--------|
| TD-001 | [e.g., `src/api/`] | [e.g., No input validation on legacy endpoints] | [e.g., Security risk] | [e.g., Medium] |

### Medium Priority

Items to address when working in the area:

| ID | Area | Description | Impact | Effort |
|----|------|-------------|--------|--------|
| TD-010 | [e.g., `src/utils/`] | [e.g., Inconsistent error handling] | [e.g., Debugging difficulty] | [e.g., Low] |

### Low Priority

Nice to have improvements:

| ID | Area | Description | Impact | Effort |
|----|------|-------------|--------|--------|
| TD-020 | [e.g., `src/components/`] | [e.g., Some components lack TypeScript strict types] | [e.g., Type safety] | [e.g., Medium] |

## Known Bugs

Active bugs that haven't been fixed:

| ID | Description | Workaround | Severity |
|----|-------------|------------|----------|
| BUG-001 | [e.g., Race condition in concurrent updates] | [e.g., Retry on conflict] | [e.g., Medium] |

## Security Concerns

Security-related issues requiring attention:

| ID | Area | Description | Risk Level | Mitigation |
|----|------|-------------|------------|------------|
| SEC-001 | [e.g., Dependencies] | [e.g., Outdated package with CVE] | [e.g., High] | [e.g., Upgrade planned] |

## Performance Concerns

Known performance issues:

| ID | Area | Description | Impact | Mitigation |
|----|------|-------------|--------|------------|
| PERF-001 | [e.g., Database queries] | [e.g., N+1 query on user list] | [e.g., Slow page load] | [e.g., Add eager loading] |

## Fragile Areas

Code areas that are brittle or risky to modify:

| Area | Why Fragile | Precautions |
|------|-------------|-------------|
| [e.g., `src/legacy/payments.ts`] | [e.g., No tests, complex logic] | [e.g., Add tests before modifying] |
| [e.g., `src/migrations/`] | [e.g., Order-dependent] | [e.g., Never modify existing migrations] |

## Deprecated Code

Code marked for removal:

| Area | Deprecation Reason | Removal Target | Replacement |
|------|-------------------|----------------|-------------|
| [e.g., `src/api/v1/`] | [e.g., V2 API available] | [e.g., Q2 2024] | [e.g., `src/api/v2/`] |

## TODO Items

Active TODO comments in codebase:

| Location | TODO | Priority |
|----------|------|----------|
| [e.g., `src/auth/login.ts:45`] | [e.g., Add rate limiting] | [e.g., High] |
| [e.g., `src/utils/format.ts:12`] | [e.g., Handle edge cases] | [e.g., Low] |

## External Dependencies at Risk

Dependencies that may need attention:

| Package | Concern | Action Needed |
|---------|---------|---------------|
| [e.g., `old-library`] | [e.g., Unmaintained, no updates in 2 years] | [e.g., Find alternative] |
| [e.g., `major-update`] | [e.g., Breaking changes in next major] | [e.g., Plan migration] |

## Improvement Opportunities

Areas that could benefit from refactoring:

| Area | Current State | Desired State | Benefit |
|------|---------------|---------------|---------|
| [e.g., Error handling] | [e.g., Inconsistent] | [e.g., Centralized error types] | [e.g., Better debugging] |
| [e.g., API responses] | [e.g., Various formats] | [e.g., Standardized format] | [e.g., Client consistency] |

## Monitoring Gaps

Areas lacking proper observability:

| Area | Missing | Impact |
|------|---------|--------|
| [e.g., Background jobs] | [e.g., No metrics] | [e.g., Can't detect failures] |
| [e.g., External API calls] | [e.g., No tracing] | [e.g., Hard to debug latency] |

---

## Concern Severity Guide

| Level | Definition | Response Time |
|-------|------------|---------------|
| Critical | Production impact, security breach | Immediate |
| High | Degraded functionality, security risk | This sprint |
| Medium | Developer experience, minor issues | Next sprint |
| Low | Nice to have, cosmetic | Backlog |

---

## What Does NOT Belong Here

- Active implementation tasks → Project board/issues
- Security controls (what we do right) → SECURITY.md
- Architecture decisions → ARCHITECTURE.md
- Code conventions → CONVENTIONS.md

---

*This document tracks what needs attention. Update when concerns are resolved or discovered.*
