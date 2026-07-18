# Constitution Guide

Comprehensive guide to creating and maintaining project constitutions that effectively guide development decisions through enforceable principles.

## What is a Constitution?

A project constitution is a living document that:
- Defines **core principles** that guide all development decisions
- Establishes **quality gates** and review processes
- Codifies **architectural constraints** and technology choices
- Provides **governance rules** for amendments and exceptions

Constitutions are **loaded into AI agent memory** so every development decision can be checked against project principles automatically.

## Why Constitutions Matter

### Without a Constitution
```
Developer: "Should I add another microservice?"
→ Inconsistent decisions
→ Architecture drift
→ Technical debt accumulation
```

### With a Constitution
```
Developer: "Should I add another microservice?"
Constitution: "Principle II: Maximum 3 microservices (currently at 3)"
→ Must justify violation or find alternative
→ Consistent architecture
→ Intentional complexity
```

## Constitution Structure

### Essential Sections

```markdown
# [PROJECT_NAME] Constitution

## Core Principles
[3-7 specific, enforceable principles]

## Governance
[Amendment process, exception handling]

**Version**: X.Y.Z | **Ratified**: DATE | **Last Amended**: DATE
```

### Optional Sections

- Additional Constraints
- Security Requirements
- Performance Standards
- Compliance Requirements
- Review Process
- Deployment Policy

## Core Principles: The Catalog

### Development Practices

#### Test-First / TDD
```markdown
### I. Test-First (NON-NEGOTIABLE)

Tests must be written and approved before implementation begins.

**Why**: Prevents implementation-driven design, ensures testability

**Enforcement**:
- PR reviews block code without tests
- Tests must fail before implementation
- Tests written by implementer or peer

**Applies to**: All new features, bug fixes requiring new scenarios
```

**When to use**: Projects requiring high reliability

#### Code Review
```markdown
### II. Mandatory Code Review

All code changes require review by at least one other developer.

**Why**: Knowledge sharing, bug prevention, maintains standards

**Enforcement**:
- GitHub branch protection rules
- No self-merging allowed
- Reviews must be from someone who didn't write the code

**Exceptions**: Documentation-only changes, emergency hotfixes (must be reviewed post-deployment)
```

**When to use**: Teams of 2+ developers

#### Pair Programming
```markdown
### III. Complex Features Require Pairing

Features marked "complex" in planning must use pair programming.

**Why**: Knowledge distribution, real-time review, reduced bugs

**Enforcement**:
- Plan phase marks complexity
- Task assignment includes pair
- Retros capture pairing sessions

**Defines complex as**: >5 files, new architecture patterns, external integrations
```

**When to use**: Teams valuing knowledge sharing

---

### Architecture Constraints

#### Microservices Limit
```markdown
### IV. Maximum 3 Microservices

System may have at most 3 independent microservices.

**Why**: Avoid operational complexity, enable team velocity

**Current count**: 2 (Auth Service, Payment Service)

**To add 4th**: Document simpler alternatives attempted, performance/isolation requirements
```

**When to use**: Small teams, early-stage products

#### Library-First
```markdown
### V. Library-First Development

Features must be extractable as standalone libraries.

**Why**: Modularity, testability, reusability

**Enforcement**:
- Each feature has clear import/export
- Library can be used independently
- Documented public API

**Exceptions**: Infrastructure code, deployment scripts
```

**When to use**: Polyglot environments, reuse emphasis

#### Monorepo vs Multirepo
```markdown
### VI. Monorepo Structure

All code lives in single repository.

**Why**: Atomic commits, simplified dependencies, unified tooling

**Enforcement**:
- New projects start in monorepo
- No external git dependencies
- Shared CI/CD configuration
```

**When to use**: Single team, related services

---

### Technology Choices

#### Language Standardization
```markdown
### VII. Primary Language: Python 3.11+

All backend services written in Python 3.11 or later.

**Why**: Team expertise, tooling consistency, hiring

**Enforcement**:
- New services use Python
- Dependencies managed with Poetry
- Type hints required (mypy strict)

**Exceptions**: Performance-critical components (Rust allowed), existing services (no rewrites)
```

**When to use**: Team has primary language

#### Framework Decisions
```markdown
### VIII. Web Framework: FastAPI

All REST APIs built with FastAPI.

**Why**: Performance, type safety, documentation generation

**Enforcement**:
- API templates use FastAPI
- No Flask/Django for new APIs
- Shared middleware library

**Exceptions**: GraphQL APIs (use Strawberry), admin panels (Django allowed)
```

**When to use**: Multiple services, API consistency needed

#### Database Standardization
```markdown
### IX. Primary Database: PostgreSQL

PostgreSQL for all relational data needs.

**Why**: Feature richness, team expertise, operational simplicity

**Allowed alternatives**:
- Redis: Caching, sessions, pub/sub
- S3: File storage
- Elasticsearch: Full-text search (justify first)

**Enforcement**: New schemas use PostgreSQL unless approved exception
```

**When to use**: Reduce operational complexity

---

### Performance Standards

#### Latency Requirements
```markdown
### X. API Latency: p95 < 200ms

95th percentile API response time under 200ms.

**Why**: User experience, service SLAs

**Measurement**: CloudWatch metrics, weekly review

**Violation handling**:
- p95 > 200ms triggers investigation
- 2 consecutive weeks: mandatory optimization sprint
- Document architectural trade-offs

**Excludes**: Batch endpoints, file uploads, external API proxies
```

**When to use**: User-facing APIs, real-time systems

#### Resource Limits
```markdown
### XI. Container Memory: < 512MB

Services must operate within 512MB memory limit.

**Why**: Cost control, forces efficiency

**Enforcement**:
- Kubernetes resource limits set to 512MB
- Load tests verify compliance
- OOM kills investigated

**Exceptions**: ML models, batch processors (justify and document)
```

**When to use**: Resource-constrained environments

---

### Security Requirements

#### Authentication Standard
```markdown
### XII. Authentication: OAuth2 + JWT

All user-facing services use OAuth2 with JWT tokens.

**Why**: Industry standard, token-based auth, stateless

**Implementation**:
- Auth service issues JWT
- 15-minute access tokens
- Refresh tokens stored in httpOnly cookies
- No custom auth schemes

**Enforcement**: Security review blocks alternatives
```

**When to use**: Multi-service authentication

#### Secrets Management
```markdown
### XIII. Secrets via AWS Secrets Manager

All secrets stored in AWS Secrets Manager, never in code or env files.

**Why**: Security, auditability, rotation support

**Enforcement**:
- Pre-commit hooks block committed secrets
- CI/CD fetches from Secrets Manager
- .env.example only (never .env)

**Exceptions**: Local development (Docker secrets), test fixtures (non-sensitive)
```

**When to use**: Cloud deployments, regulated industries

---

### Quality Gates

#### Test Coverage
```markdown
### XIV. Minimum 80% Test Coverage

Unit + integration tests must cover at least 80% of code.

**Why**: Confidence in changes, regression prevention

**Measurement**: pytest-cov, coverage.py

**Enforcement**:
- CI fails if coverage drops below 80%
- PRs show coverage change
- Focus on critical paths over 100% coverage

**Excludes**: Generated code, type stubs, config files
```

**When to use**: Mature projects, frequent changes

#### Static Analysis
```markdown
### XV. Zero Linter Warnings

Code must pass strict linting (ruff, mypy) with no warnings.

**Why**: Code quality, catch bugs early

**Tools**:
- ruff: Style, common errors
- mypy: Type checking (strict mode)
- bandit: Security issues

**Enforcement**:
- CI blocks on warnings
- Pre-commit hooks auto-fix style
- Weekly: Raise strictness if team ready
```

**When to use**: Type-safe languages, quality emphasis

---

## Principles Best Practices

### Characteristics of Good Principles

✅ **Specific**
```markdown
❌ "Write good code"
✅ "All public functions must have type hints and docstrings"
```

✅ **Enforceable**
```markdown
❌ "Try to write tests"
✅ "CI blocks merges if coverage < 80%"
```

✅ **Justified**
```markdown
❌ "Use PostgreSQL"
✅ "Use PostgreSQL (team expertise, feature richness, reduces operational complexity)"
```

✅ **Measurable**
```markdown
❌ "Be fast"
✅ "p95 API latency < 200ms, measured via CloudWatch"
```

### How Many Principles?

**3-7 principles is optimal**

- **Too few (1-2)**: Not comprehensive enough
- **Just right (3-7)**: Memorable, actionable, comprehensive
- **Too many (10+)**: Hard to remember, likely overlap, becomes checklist

### Prioritizing Principles

Use **tiers** to indicate importance:

```markdown
### I. Test-First (NON-NEGOTIABLE)
[Never violate without executive approval]

### II. Library-First
[Strong preference, violations need good justification]

### III. Preferred: Functional Style
[Guideline, not requirement]
```

## Constitution Lifecycle

### 1. Initial Creation

**When**: Project start or major architectural decision point

**Process**:
1. Team discusses pain points and values
2. Draft 3-5 core principles
3. Review and refine
4. Ratify (team sign-off)

**Template**:
```bash
# Copy template to your repo
PLUGIN_ROOT=$(python3 /tmp/cpr.py sdd)
cp "$PLUGIN_ROOT"/skills/sdd-infrastructure/assets/constitution/constitution-template.md .sdd/memory/constitution.md

# Edit and ratify
vim .sdd/memory/constitution.md
```

### 2. Amendment Process

**Triggers for amendment**:
- Principle repeatedly violated (sign of poor fit)
- Technology landscape changes
- Team size changes
- New regulatory requirements

**Process**:
```markdown
## Governance

### Amendments

1. Propose change with rationale
2. Document alternatives considered
3. Team discussion and vote
4. Update version number
5. Migration plan (if needed)
6. Update Last Amended date
```

### 3. Versioning

Use **semantic versioning** for constitutions:

- **MAJOR** (X.0.0): Breaking change (removes/conflicts with principle)
- **MINOR** (1.X.0): Add new principle, clarify existing
- **PATCH** (1.0.X): Fix typos, improve wording

Example:
```
Version 1.0.0 - Initial ratification
Version 1.1.0 - Added Security Principle VI
Version 1.1.1 - Clarified Test-First exceptions
Version 2.0.0 - Removed Library-First (monolith pivot)
```

### 4. Enforcement

**Automated**:
- CI/CD checks (linting, coverage, tests)
- Pre-commit hooks (secrets, formatting)
- Monitoring alerts (latency, errors)

**Manual**:
- Code review checklists
- Architecture review meetings
- Retrospective constitution compliance review

**Example checklist**:
```markdown
## PR Review Checklist

- [ ] Tests written before implementation (Principle I)
- [ ] Coverage ≥ 80% (Principle XIV)
- [ ] Type hints on public functions (Principle XV)
- [ ] Latency benchmarks if API change (Principle X)
```

### 5. Exception Handling

Constitutions should allow exceptions with process:

```markdown
## Governance

### Requesting Exceptions

1. Document why principle doesn't apply
2. Explain simpler alternatives attempted
3. Quantify impact (time, cost, complexity)
4. Get architect approval
5. Record in Complexity Tracking table
```

Example:
```markdown
| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 4th microservice | Payment provider requires isolation | Shared service: PCI compliance risk |
| Skip tests | Emergency security patch | Writing tests: Delays 2-hour fix to 8 hours |
```

## Constitution Examples

### Startup (Speed Focus)
```markdown
### I. Ship Fast
Features deployed within 1 week of approval.
Principle: Iteration over perfection

### II. Measure Everything
Every feature has success metrics defined upfront.
Principle: Data-driven decisions

### III. PostgreSQL Only
One database, one language (Python).
Principle: Reduce operational complexity
```

### Enterprise (Compliance Focus)
```markdown
### I. SOC 2 Compliance
All code changes pass security review.
Principle: Audit trail, least privilege

### II. Test Coverage ≥ 90%
Regression prevention for regulated features.
Principle: Quality over speed

### III. No Production Access
Developers read-only in production.
Principle: Separation of duties
```

### Open Source (Community Focus)
```markdown
### I. Public by Default
All code Apache 2.0 unless specific reason.
Principle: Community collaboration

### II. Comprehensive Docs
Every feature has docs, examples, and quickstart.
Principle: Contributor experience

### III. Backwards Compatibility
Breaking changes require major version bump.
Principle: User trust, stable API
```

## Common Pitfalls

### ❌ Too Vague
```markdown
"Write clean code"
```

### ✅ Specific and Measurable
```markdown
"Functions > 50 lines require refactoring justification in PR description"
```

---

### ❌ Unenforced
```markdown
"Tests are important"
```

### ✅ Enforcement Mechanism
```markdown
"CI blocks PRs if coverage drops below 80%"
```

---

### ❌ Too Many Principles
```markdown
25 principles covering every possible scenario
```

### ✅ Core Focus
```markdown
5 principles covering the most important decisions
```

---

### ❌ No Rationale
```markdown
"Use microservices"
```

### ✅ Justified
```markdown
"Maximum 3 microservices - small team can't operate more; forces thoughtful decomposition"
```

## Using Constitutions in SDD

### Plan Phase
```markdown
## Constitution Check

*GATE: Must pass before implementation.*

- ✓ Test-First: Will write tests first
- ✓ Library-First: Extractable as standalone library
- ⚠ Adds 4th microservice: Justified in Complexity Tracking
```

### Implementation Phase
```markdown
Before every significant decision:
1. Load constitution from .sdd/memory/constitution.md
2. Check relevant principles
3. Document compliance or exception
```

### Review Phase
```markdown
Constitution-based review questions:
- Does this follow Test-First?
- Does this respect our microservices limit?
- Is latency requirement met?
```

## Related Documentation

- **Workflow Overview**: How constitution fits into SDD workflow
- **Template Guide**: Using constitution template
- **Script Guide**: Scripts that check constitution compliance
