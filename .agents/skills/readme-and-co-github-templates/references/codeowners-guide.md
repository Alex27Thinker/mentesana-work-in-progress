# CODEOWNERS Guide: Advanced Patterns and Strategies

Comprehensive guide to GitHub CODEOWNERS files with patterns for different organizational structures and team workflows.

## What is CODEOWNERS?

**CODEOWNERS** is a GitHub feature that automatically requests reviews from specified users or teams when PRs modify particular files or directories.

**Purpose:**
- Automate review assignment
- Enforce code ownership
- Distribute review load
- Maintain quality standards
- Document expertise areas

**How it works:**
1. PR touches file matching pattern
2. GitHub automatically requests review from owners
3. Reviews can be required for merge (via branch protection)

---

## File Location

CODEOWNERS can be placed in three locations (checked in order):

1. **`.github/CODEOWNERS`** (recommended)
2. **`CODEOWNERS`** (repository root)
3. **`docs/CODEOWNERS`**

**Recommendation:** Use `.github/CODEOWNERS` for consistency with other GitHub configuration.

---

## Basic Syntax

### Pattern Matching

**Syntax rules:**
```
# Pattern       Owner(s)
*               @org/default-team
/docs/          @org/docs-team
*.js            @org/js-developers
/src/api/       @org/backend-team @tech-lead
```

**Pattern types:**
- `*` - Matches any file in repository
- `/path/` - Matches directory and all contents
- `*.ext` - Matches all files with extension
- `**/pattern` - Matches pattern in any directory
- `path/**/file` - Matches file nested anywhere in path

### Owner Syntax

**Individual users:**
```
*.py @alice @bob
```

**Teams:**
```
*.py @org/python-team
```

**Mix:**
```
/critical/ @security-lead @org/security-team
```

**Note:** Team names must include organization: `@org-name/team-name`

---

## Pattern Matching Rules

### Specificity Wins

More specific patterns override general ones:

```
# All files owned by core team
* @org/core-team

# Except docs owned by docs team
/docs/ @org/docs-team

# Except API docs owned by API team
/docs/api/ @org/api-team
```

**Result:** `docs/api/endpoint.md` is owned by `@org/api-team`

### Last Match Wins

When patterns have same specificity, last one wins:

```
*.js @org/frontend-team
*.js @org/javascript-experts
```

**Result:** All `.js` files owned by `@org/javascript-experts`

### Directory vs File Patterns

```
# Directory (includes all nested files)
/src/ @org/dev-team

# Specific file pattern
/src/**/*.test.js @org/qa-team
```

**Result:** Test files owned by QA, everything else by dev team

---

## Organizational Patterns

### Pattern 1: Small Team (Flat Structure)

**Team size:** 2-5 developers

**Approach:** Broad ownership, everyone reviews everything

**CODEOWNERS:**
```
# Everyone reviews everything
* @alice @bob @charlie

# Except infrastructure (DevOps only)
/.github/ @alice
/docker/ @alice
/k8s/ @alice
```

**Pros:**
- Simple
- Everyone stays informed
- Cross-training

**Cons:**
- Can slow down PRs
- Not scalable

---

### Pattern 2: Medium Team (Functional Areas)

**Team size:** 10-30 developers

**Approach:** Ownership by functional area

**CODEOWNERS:**
```
# Default: core team leads
* @org/tech-leads

# Frontend
/src/ui/ @org/frontend-team
/src/components/ @org/frontend-team
*.css @org/frontend-team
*.scss @org/frontend-team

# Backend
/src/api/ @org/backend-team
/src/services/ @org/backend-team
/src/database/ @org/backend-team @dba-lead

# DevOps
/.github/ @org/devops-team
/docker/ @org/devops-team
/terraform/ @org/devops-team
/k8s/ @org/devops-team

# Documentation
/docs/ @org/docs-team
*.md @org/docs-team

# Tests
**/*.test.js @org/qa-team
**/*.spec.js @org/qa-team

# Configuration
package.json @org/tech-leads
*.config.js @org/tech-leads
```

**Pros:**
- Clear ownership
- Experts review their areas
- Scales to medium teams

**Cons:**
- Can create silos
- Cross-functional changes need multiple approvals

---

### Pattern 3: Large Team (Modular/Microservices)

**Team size:** 30+ developers

**Approach:** Ownership by service/module

**CODEOWNERS:**
```
# Default: architecture team
* @org/architects

# Services (microservices architecture)
/services/auth/ @org/auth-team
/services/billing/ @org/billing-team
/services/analytics/ @org/analytics-team
/services/notifications/ @org/notifications-team

# Shared libraries
/libs/common/ @org/platform-team
/libs/utils/ @org/platform-team

# Frontend monorepo
/apps/web/ @org/web-team
/apps/mobile/ @org/mobile-team
/apps/admin/ @org/admin-team

# Shared components
/packages/ui/ @org/design-system-team
/packages/icons/ @org/design-system-team

# Infrastructure
/infrastructure/ @org/platform-team @org/sre-team

# CI/CD
/.github/workflows/ @org/platform-team
/.github/actions/ @org/platform-team

# Documentation
/docs/architecture/ @org/architects
/docs/api/ @org/api-team
/docs/user/ @org/docs-team

# Security-sensitive
/services/auth/security/ @org/security-team @security-lead
/services/billing/payments/ @org/security-team @org/billing-team
*.security.js @org/security-team

# Database migrations
**/migrations/ @org/dba-team @service-owner
```

**Pros:**
- Scales well
- Clear module ownership
- Independent teams

**Cons:**
- More complex
- Cross-cutting changes harder
- Needs good documentation

---

### Pattern 4: Open Source Project

**Team size:** Varies (external contributors)

**Approach:** Maintainer ownership with subsystem delegation

**CODEOWNERS:**
```
# Default: all maintainers
* @org/maintainers

# Core maintainers for critical paths
/src/core/ @org/core-maintainers
/src/runtime/ @org/core-maintainers

# Subsystem maintainers
/src/parser/ @parser-maintainer
/src/compiler/ @compiler-maintainer
/src/stdlib/ @stdlib-maintainer

# Documentation (more permissive)
/docs/ @org/docs-maintainers @community-docs

# Examples (community-driven)
/examples/ @org/maintainers @community-contributors

# Tests (anyone can review)
**/*.test.js @org/maintainers

# Build and CI
/build/ @org/build-team
/.github/ @org/core-maintainers
```

**Pros:**
- Distributes review load
- Empowers subsystem owners
- Clear escalation path

**Cons:**
- Need active maintainers
- External contributors may not have access

---

## Advanced Patterns

### Pattern 1: Escalation Chain

**Use case:** Junior/senior review progression

**Approach:**
```
# All code reviewed by team
/src/ @org/developers

# Critical paths need senior review too
/src/auth/ @org/developers @senior-engineer
/src/payments/ @org/developers @senior-engineer @security-lead
/src/core/ @org/developers @architect @tech-lead
```

**How it works:**
- Junior changes: team reviews
- Critical changes: team + senior reviews
- Core changes: team + senior + architect reviews

---

### Pattern 2: Pair Ownership

**Use case:** Ensure knowledge transfer

**Approach:**
```
# Every area has two owners
/services/auth/ @alice @bob
/services/billing/ @charlie @diana
/services/api/ @eve @frank
```

**Benefits:**
- No single point of failure
- Built-in code review
- Knowledge sharing
- Vacation coverage

---

### Pattern 3: Security Gates

**Use case:** Security-sensitive code requires security team

**Approach:**
```
# Security-sensitive patterns require security team
**/auth*.js @org/developers @org/security-team
**/crypto*.js @org/developers @org/security-team
**/secrets*.js @org/developers @org/security-team
**/*security*.js @org/developers @org/security-team

# Payment-related
**/payment*.js @org/developers @org/security-team @org/compliance

# User data
**/models/user*.js @org/developers @org/privacy-team
**/pii*.js @org/developers @org/privacy-team
```

**Result:** Any PR touching these files requires security/privacy review

---

### Pattern 4: Tech Lead Oversight

**Use case:** Tech leads review all significant changes

**Approach:**
```
# Regular code
/src/ @org/developers

# Configuration and dependencies need lead approval
package.json @org/developers @tech-lead
package-lock.json @org/developers @tech-lead
*.config.js @org/developers @tech-lead
.env.example @org/developers @tech-lead

# Database changes
**/migrations/ @org/developers @tech-lead @dba
**/schema/ @org/developers @tech-lead @dba

# CI/CD changes
/.github/workflows/ @org/developers @tech-lead
/Dockerfile @org/developers @tech-lead
```

---

### Pattern 5: Wildcard Expertise

**Use case:** Specific expertise regardless of location

**Approach:**
```
# Default ownership
* @org/developers

# Anyone touching TypeScript gets TS expert review
**/*.ts @org/developers @typescript-expert
**/*.tsx @org/developers @typescript-expert

# Anyone touching SQL gets DBA review
**/*.sql @org/developers @dba-team

# Anyone touching GraphQL gets API expert review
**/*.graphql @org/developers @graphql-expert
**/schema.* @org/developers @graphql-expert

# Performance-critical code
**/performance/ @org/developers @performance-team
**/*.perf.js @org/developers @performance-team
```

---

## Common Patterns by File Type

### Configuration Files

```
# Package management
package.json @tech-lead @security-team
package-lock.json @tech-lead
yarn.lock @tech-lead
Gemfile @tech-lead
requirements.txt @tech-lead @security-team
Cargo.toml @tech-lead

# Build configuration
webpack.config.js @frontend-lead
tsconfig.json @typescript-lead
babel.config.js @frontend-lead
rollup.config.js @frontend-lead

# CI/CD
.github/workflows/ @devops-team
.gitlab-ci.yml @devops-team
.travis.yml @devops-team
Jenkinsfile @devops-team

# Docker
Dockerfile @devops-team
docker-compose.yml @devops-team
.dockerignore @devops-team

# Infrastructure as Code
*.tf @devops-team @infra-lead
*.tfvars @devops-team @infra-lead
*.yaml @devops-team
*.yml @devops-team
```

### Documentation Files

```
# All documentation
*.md @docs-team

# Except technical docs
/docs/api/ @api-team
/docs/architecture/ @architects

# README (important for first impressions)
README.md @tech-lead @docs-team

# Contributing guide
CONTRIBUTING.md @tech-lead @community-lead

# Security policy
SECURITY.md @security-team @tech-lead
```

### Test Files

```
# Unit tests reviewed by developers
**/*.test.js @developers
**/*.spec.js @developers

# E2E tests reviewed by QA
**/*.e2e.js @qa-team
**/*.integration.js @qa-team

# Performance tests
**/*.perf.js @performance-team
**/*.benchmark.js @performance-team
```

---

## Best Practices

### 1. Start Broad, Refine Specific

**Good:**
```
# Start with default
* @org/team

# Refine for specific areas
/docs/ @org/docs-team
/src/api/ @org/api-team
```

**Bad:**
```
# Too specific from the start (hard to maintain)
/src/api/users/controller.js @alice
/src/api/users/service.js @bob
/src/api/users/model.js @charlie
```

### 2. Use Teams, Not Individuals

**Good:**
```
/src/ @org/backend-team
```

**Bad:**
```
/src/ @alice @bob @charlie @diana @eve
```

**Why:**
- Team membership changes
- Easier to manage in GitHub
- Distributes reviews automatically within team

### 3. Balance Coverage with Velocity

**Too few owners:**
```
# One person reviews everything (bottleneck)
* @tech-lead
```

**Too many owners:**
```
# Everyone reviews everything (slow PRs)
* @alice @bob @charlie @diana @eve @frank @grace @henry
```

**Just right:**
```
# Team reviews, with escalation for critical
* @org/developers
/critical/ @org/developers @tech-lead
```

### 4. Document Your Patterns

Add comments to CODEOWNERS:

```
# =============================================================================
# CODEOWNERS File
# =============================================================================
#
# This file defines ownership for automatic review requests.
#
# Syntax: <pattern> <owner1> <owner2>
# More specific patterns override general ones.
# Last matching pattern wins for same specificity.
#
# For questions, contact @tech-lead
# =============================================================================

# Default ownership
* @org/developers

# Frontend Code
# Owned by frontend team, complex components need senior review
/src/ui/ @org/frontend-team
/src/ui/complex-chart/ @org/frontend-team @senior-frontend

# Backend Code
# API changes require API team review
/src/api/ @org/backend-team
```

### 5. Avoid Over-Specification

**Too specific (maintenance nightmare):**
```
/src/api/users/controller.js @alice
/src/api/users/service.js @alice
/src/api/users/model.js @alice
/src/api/users/validator.js @alice
```

**Better (same effect, easier to maintain):**
```
/src/api/users/ @alice
```

### 6. Review Regularly

**Quarterly review checklist:**
- [ ] Remove departed team members
- [ ] Update team assignments
- [ ] Check if patterns still match team structure
- [ ] Identify unused patterns (simplify)
- [ ] Add patterns for new areas

---

## Integration with Branch Protection

### Require Code Owner Review

In branch protection settings:

```yaml
Settings > Branches > Branch Protection Rules

☑ Require pull request reviews before merging
  ☑ Require review from Code Owners
  ☑ Dismiss stale pull request approvals when new commits are pushed
```

**Effect:** PRs cannot merge until code owners approve

### Combining with Required Reviews

```yaml
☑ Require pull request reviews before merging
  Required approving reviews: 2
  ☑ Require review from Code Owners
```

**Effect:** Needs 2 approvals, AND one must be from code owner

---

## Common Challenges and Solutions

### Challenge 1: Too Many Required Reviewers

**Problem:** PR touches 5 areas, needs 5 approvals, never merges

**Solution 1 - Broad ownership:**
```
# Instead of multiple specific teams
/area1/ @team1
/area2/ @team2
/area3/ @team3

# Use umbrella team
/area1/ @org/platform
/area2/ @org/platform
/area3/ @org/platform
```

**Solution 2 - Make some reviews optional:**
Use branch protection for critical areas only, CODEOWNERS for nice-to-have

### Challenge 2: External Contributors Can't Be Owners

**Problem:** Open source project, external contributors can't review

**Solution:** Owners are maintainers, but welcome external reviews
```
# Maintainers are owners
* @org/maintainers

# But external contributors can still review (manually added)
```

### Challenge 3: Reorganization Pain

**Problem:** Team restructure means updating entire CODEOWNERS

**Solution:** Use teams (update team membership, not CODEOWNERS)
```
# Resilient to team changes
/frontend/ @org/frontend-team

# Fragile (individual names)
/frontend/ @alice @bob @charlie
```

### Challenge 4: Cross-Cutting Changes

**Problem:** Refactoring touches 20 files across 5 teams

**Solution:** Create an "architects" or "tech-leads" team for broad reviews
```
# Specific ownership
/service-a/ @team-a
/service-b/ @team-b

# But architects can approve anything
* @org/architects
```

---

## Testing Your CODEOWNERS

### Manual Testing

1. Create test PR touching each pattern
2. Verify correct owners requested
3. Check for unexpected requests

### CODEOWNERS Validator

GitHub Action to validate CODEOWNERS syntax:

```yaml
name: Validate CODEOWNERS
on: pull_request

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: mszostok/codeowners-validator@v0.7.4
```

### Local Testing

Use `gh` CLI to check who owns a file:

```bash
gh api repos/OWNER/REPO/codeowners/errors
```

---

## Examples by Project Type

### Monorepo (Multiple Apps)

```
# Root ownership
* @org/platform-team

# Apps
/apps/web/ @org/web-team
/apps/mobile/ @org/mobile-team
/apps/admin/ @org/admin-team

# Packages
/packages/ui/ @org/design-team
/packages/utils/ @org/platform-team

# Shared config
/package.json @org/platform-team
/turbo.json @org/platform-team
```

### Microservices

```
# Default
* @org/architects

# Each service
/services/auth/ @org/auth-team
/services/orders/ @org/orders-team
/services/catalog/ @org/catalog-team

# Shared
/libs/ @org/platform-team
/proto/ @org/api-team
```

### Library/Framework

```
# Core (conservative)
/src/core/ @org/core-maintainers
/src/runtime/ @org/core-maintainers

# Features (more open)
/src/features/ @org/maintainers

# Docs (community-friendly)
/docs/ @org/maintainers
/examples/ @org/maintainers
```

---

## Resources

- [GitHub CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [CODEOWNERS Validator](https://github.com/mszostok/codeowners-validator)
- [GitHub Teams](https://docs.github.com/en/organizations/organizing-members-into-teams)

---

## Summary

**Key principles:**
1. **Start simple** - broad ownership, refine over time
2. **Use teams** - easier to maintain than individual names
3. **Balance coverage** - enough oversight, not too slow
4. **Document patterns** - explain why ownership is structured this way
5. **Review regularly** - keep aligned with team structure

**Common patterns:**
- `*` for default ownership
- `/path/` for directory ownership
- `**/*.ext` for file type expertise
- Multiple owners for critical paths
- Teams over individuals

**Golden rule:** CODEOWNERS should improve code quality without slowing down development.
