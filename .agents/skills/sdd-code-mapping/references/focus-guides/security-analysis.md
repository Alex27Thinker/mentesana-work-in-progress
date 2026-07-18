# Security Analysis Guide

This guide describes how to analyze a codebase to populate SECURITY.md and CONCERNS.md.

## Documents to Generate

1. **SECURITY.md** - Auth, authorization, vulnerabilities, controls
2. **CONCERNS.md** - Tech debt, risks, known issues

## Analysis Strategy

### Step 1: Identify Authentication Mechanism

Scan for auth-related code:

```bash
# Find auth-related files
find . -name "*auth*" -o -name "*login*" -o -name "*session*"

# Find JWT usage
grep -r "jwt\|jsonwebtoken\|jose" src/

# Find OAuth/OIDC
grep -r "oauth\|oidc\|nextauth\|passport" src/

# Find session handling
grep -r "session\|cookie" src/
```

Document:
- Authentication method (JWT, sessions, OAuth)
- Token storage (cookies, localStorage)
- Token refresh strategy
- Session duration

### Step 2: Analyze Authorization

Find permission-related code:

```bash
# Find role/permission checks
grep -r "role\|permission\|authorize\|can\|ability" src/

# Find middleware
grep -r "middleware" src/

# Find guards/decorators
grep -r "@.*Guard\|@.*Auth\|@.*Permission" src/
```

Document:
- Authorization model (RBAC, ABAC, ACL)
- Roles defined
- Permission enforcement points

### Step 3: Check Input Validation

Find validation patterns:

```bash
# Find Zod schemas
grep -r "z\.\|zod" src/

# Find Pydantic models
grep -r "BaseModel\|pydantic" src/

# Find manual validation
grep -r "validate\|sanitize" src/
```

Document:
- Validation library used
- Where validation happens (API layer, service layer)
- Sanitization approach

### Step 4: Identify Sensitive Data Handling

Search for sensitive data patterns:

```bash
# Find password handling
grep -r "password\|bcrypt\|argon\|hash" src/

# Find encryption
grep -r "encrypt\|decrypt\|crypto\|cipher" src/

# Find PII fields
grep -r "email\|phone\|ssn\|address" src/models/
```

Document:
- Password hashing algorithm
- Encryption at rest
- PII handling approach

### Step 5: Check Security Headers

Find header configuration:

```bash
# Find security headers
grep -r "helmet\|csp\|x-frame\|hsts" src/

# Find CORS config
grep -r "cors\|origin" src/
```

Document:
- Security headers configured
- CORS policy
- Content-Security-Policy

### Step 6: Analyze Secrets Management

Find environment variable usage:

```bash
# Find env var access
grep -r "process\.env\|os\.environ\|env::" src/

# Find secret patterns
grep -r "SECRET\|KEY\|TOKEN\|PASSWORD" .env.example

# Check for hardcoded secrets (SECURITY ISSUE!)
grep -r "password.*=.*['\"]" src/
```

Document:
- Environment variables required
- Secrets storage method
- Any hardcoded credentials (as CONCERNS)

### Step 7: Identify Rate Limiting

Find rate limiting implementation:

```bash
# Find rate limiting
grep -r "rate.*limit\|throttle\|rateLimit" src/
```

Document:
- Rate limiting library
- Limits by endpoint/user
- Rate limit storage (Redis, memory)

### Step 8: Find Security Concerns

Look for potential issues:

```bash
# Find TODO/FIXME with security implications
grep -r "TODO.*secur\|FIXME.*secur\|TODO.*auth\|FIXME.*auth" src/

# Find deprecated code
grep -r "@deprecated\|DEPRECATED" src/

# Find eval/exec (code injection risk)
grep -r "eval\|exec\|Function\(" src/

# Find SQL concatenation (injection risk)
grep -r "SELECT.*+\|INSERT.*+" src/
```

### Step 9: Check Dependencies for Vulnerabilities

```bash
# npm audit
npm audit 2>/dev/null

# Python safety check
pip-audit 2>/dev/null || safety check 2>/dev/null

# Rust cargo audit
cargo audit 2>/dev/null
```

### Step 10: Identify Technical Debt

Find debt indicators:

```bash
# Find TODO comments
grep -rn "TODO\|FIXME\|HACK\|XXX" src/

# Find commented code (potential dead code)
grep -rn "^[[:space:]]*//.*function\|^[[:space:]]*#.*def" src/

# Find complexity (long functions)
# Manual review of files > 300 lines

# Find duplicated code patterns
# Requires tooling like jscpd, PMD
```

### Step 11: Identify Known Issues

```bash
# Find bug markers
grep -rn "BUG\|KNOWN.*ISSUE\|WORKAROUND" src/

# Find temporary solutions
grep -rn "temporary\|hack\|workaround" src/

# Check for disabled tests
grep -r "skip\|xit\|xdescribe\|@pytest.mark.skip" tests/
```

## Security Patterns to Document

### Authentication Patterns

- Token-based (JWT, API keys)
- Session-based
- OAuth2 flows
- Multi-factor authentication

### Authorization Patterns

- Role-based access control (RBAC)
- Attribute-based access control (ABAC)
- Resource-based permissions
- Ownership checks

### Common Vulnerabilities to Check

- [ ] SQL Injection (parameterized queries?)
- [ ] XSS (output encoding?)
- [ ] CSRF (tokens used?)
- [ ] SSRF (URL validation?)
- [ ] Path traversal (path sanitization?)
- [ ] Insecure deserialization
- [ ] Sensitive data exposure
- [ ] Broken access control

## Output Guidelines

### For SECURITY.md

- **Document controls**: What's in place
- **Be specific**: Algorithms, libraries, versions
- **Include config locations**: Where settings live
- **Note gaps**: What's missing (link to CONCERNS.md)

### For CONCERNS.md

- **Prioritize**: Critical > High > Medium > Low
- **Be actionable**: What needs to be done
- **Include location**: Where the issue is
- **Estimate effort**: Low/Medium/High

## Concern Categories

### Technical Debt

- Missing tests
- Poor code quality
- Outdated patterns
- Performance issues

### Security Risks

- Vulnerability exposure
- Missing controls
- Insecure practices
- Dependency risks

### Known Bugs

- Documented issues
- Workarounds in place
- Disabled features

### Fragile Areas

- Complex code without tests
- Critical paths with single points of failure
- Areas with frequent bugs

## What to Exclude

**From SECURITY.md:**
- General tech debt (→ CONCERNS.md)
- Testing strategy (→ TESTING.md)
- Code conventions (→ CONVENTIONS.md)

**From CONCERNS.md:**
- Security controls (→ SECURITY.md)
- Normal implementation work
- Feature requests
