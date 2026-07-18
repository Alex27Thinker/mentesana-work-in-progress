# Pull Request Template Patterns

Comprehensive guide to PR templates with examples from successful projects and best practices for different workflows.

## Why PR Templates Matter

**Benefits:**
- Ensure consistent PR quality
- Remind contributors of requirements
- Speed up review process
- Catch common issues before review
- Document changes effectively

**Impact:**
- Projects with PR templates see 30-40% reduction in review cycles
- Faster merge times
- Better git history
- Fewer broken builds

---

## Basic PR Template Structure

### Minimal Template (Small Projects)

**Use when:** Small projects, solo developers, simple contributions

**Template:**
```markdown
## What does this PR do?

Brief description of changes

## How can this be tested?

Steps to verify the changes work

## Checklist

- [ ] Tests pass
- [ ] Documentation updated (if needed)
```

**Strengths:**
- Quick to fill out
- Low barrier to contribution
- Covers essentials

**Weaknesses:**
- May miss important details
- No categorization
- Minimal guidance

---

### Standard Template (Most Projects)

**Use when:** Most open source projects, teams of 3-10 developers

**Template:**
```markdown
## Description

Brief description of what this PR does and why.

Fixes #(issue)

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Test update

## How Has This Been Tested?

Describe the tests you ran to verify your changes.

- [ ] Test A
- [ ] Test B

## Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published
```

**Strengths:**
- Comprehensive checklist
- Type categorization
- Testing section
- Self-review reminder

**Weaknesses:**
- Can feel long
- Some items may not apply to all PRs

---

### Comprehensive Template (Large Projects)

**Use when:** Large projects, enterprise environments, strict requirements

**Template:**
```markdown
## Description

### Summary
Brief description of changes (1-2 sentences).

### Motivation and Context
Why is this change required? What problem does it solve?

Related issue: Fixes #(issue)

### What kind of change does this PR introduce?
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Build/CI
- [ ] Other (please describe):

## Changes Made

Detailed list of changes:
- Change 1
- Change 2
- Change 3

## Screenshots (if appropriate)

Before | After
--- | ---
[before screenshot] | [after screenshot]

## How Has This Been Tested?

### Test Configuration
- OS:
- Browser (if applicable):
- Node version:

### Test Cases
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Manual testing

**Manual test steps:**
1. Step 1
2. Step 2
3. Expected outcome

## Performance Impact

- [ ] No performance impact
- [ ] Performance improvement (describe)
- [ ] Potential performance regression (describe and justify)

**Benchmarks:**
```
[paste benchmark results if relevant]
```

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes (describe below)

**If breaking changes, describe migration path:**

## Security Considerations

- [ ] No security implications
- [ ] Security improvement
- [ ] Requires security review

**Security notes:**

## Documentation

- [ ] Documentation updated
- [ ] No documentation needed
- [ ] Documentation to be added in follow-up

## Deployment Notes

**Database migrations:**
- [ ] No migrations
- [ ] Migrations included (describe)

**Configuration changes:**
- [ ] No config changes
- [ ] Config changes needed (describe)

**Rollback plan:**

## Dependencies

- [ ] No new dependencies
- [ ] New dependencies added (list below)

**New dependencies:**
- dependency-name: reason for adding

## Checklist

### Code Quality
- [ ] Code follows project style guide
- [ ] Self-reviewed my code
- [ ] Commented hard-to-understand areas
- [ ] No new warnings or errors
- [ ] Code is DRY (Don't Repeat Yourself)

### Testing
- [ ] Added/updated unit tests
- [ ] Added/updated integration tests
- [ ] All tests pass locally
- [ ] Test coverage maintained/improved

### Documentation
- [ ] Updated README (if needed)
- [ ] Updated API documentation
- [ ] Updated inline code comments
- [ ] Updated CHANGELOG

### Review
- [ ] Ready for review
- [ ] Reviewers assigned
- [ ] CI/CD checks passing
```

**Strengths:**
- Extremely thorough
- Covers all edge cases
- Great for enterprise/compliance
- Documents everything

**Weaknesses:**
- Very long
- Can discourage small contributions
- May be overkill for simple changes

---

## PR Template Patterns by Project Type

### Pattern 1: Open Source Library

**Focus:** API changes, backward compatibility, versioning

**Template sections:**
```markdown
## What's Changed
- API additions/changes
- Deprecations

## Breaking Changes
- [ ] Yes / [ ] No
- Migration guide if yes

## Backward Compatibility
- [ ] Fully backward compatible
- [ ] Requires migration

## Version Bump
- [ ] Patch (bug fix)
- [ ] Minor (new feature)
- [ ] Major (breaking change)

## Documentation
- [ ] API docs updated
- [ ] Examples updated
- [ ] Migration guide (if breaking)

## Tests
- [ ] Unit tests
- [ ] Integration tests
- [ ] Examples still work
```

---

### Pattern 2: Web Application (Frontend)

**Focus:** UI changes, UX, accessibility, browser compatibility

**Template sections:**
```markdown
## What's Changed
Brief description

## Screenshots/GIFs
Before | After
--- | ---
[image] | [image]

## Browser Testing
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge
- [ ] Mobile (iOS/Android)

## Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader tested
- [ ] ARIA labels added/updated
- [ ] Color contrast verified

## Performance
- [ ] Lighthouse score: [score]
- [ ] Bundle size impact: [size]

## Responsive Design
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)
```

---

### Pattern 3: Backend Service/API

**Focus:** API changes, performance, database, security

**Template sections:**
```markdown
## What's Changed
Brief description

## API Changes
- [ ] No API changes
- [ ] New endpoints (list below)
- [ ] Modified endpoints (list below)
- [ ] Deprecated endpoints

### New/Modified Endpoints
```
POST /api/v1/resource
GET /api/v1/resource/:id
```

## Database Changes
- [ ] No migrations
- [ ] Migrations included
- [ ] Rollback tested

### Migration Details
```sql
[paste migration SQL or describe]
```

## Performance Impact
- [ ] Response time: [before] → [after]
- [ ] Query performance tested
- [ ] N+1 queries avoided
- [ ] Caching strategy (if applicable)

## Security
- [ ] Input validation
- [ ] Authentication/authorization
- [ ] No sensitive data leaked
- [ ] SQL injection prevented
- [ ] XSS prevented

## Load Testing
- [ ] Tested under load
- [ ] Results: [summary or link]
```

---

### Pattern 4: Infrastructure/DevOps

**Focus:** Deployment, rollback, monitoring, incidents

**Template sections:**
```markdown
## What's Changed
Infrastructure change description

## Impact
- [ ] No downtime required
- [ ] Scheduled downtime needed
- [ ] Rolling deployment possible

## Deployment Steps
1. Step 1
2. Step 2
3. Step 3

## Rollback Plan
1. Rollback step 1
2. Rollback step 2

## Monitoring
- [ ] Alerts configured
- [ ] Dashboards updated
- [ ] SLIs/SLOs defined

## Testing
- [ ] Tested in staging
- [ ] Load tested
- [ ] Disaster recovery tested

## Dependencies
- [ ] No external dependencies
- [ ] Requires [system/service]

## Documentation
- [ ] Runbook updated
- [ ] Architecture diagrams updated
```

---

### Pattern 5: Documentation Only

**Focus:** Clarity, accuracy, examples

**Template sections:**
```markdown
## What's Changed
Documentation changes summary

## Type of Documentation
- [ ] README
- [ ] API docs
- [ ] Tutorial/guide
- [ ] Code comments
- [ ] Architecture docs
- [ ] Contributing guide

## Changes Made
- Change 1
- Change 2

## Checklist
- [ ] No broken links
- [ ] Code examples tested
- [ ] Screenshots up to date
- [ ] Spelling/grammar checked
- [ ] Follows docs style guide

## Preview
[Link to preview if available]
```

---

## Advanced PR Template Techniques

### Technique 1: Multiple Templates

**Use case:** Different PR types need different information

**Structure:**
```
.github/
└── PULL_REQUEST_TEMPLATE/
    ├── bugfix.md
    ├── feature.md
    ├── docs.md
    └── infrastructure.md
```

**How it works:**
User selects template when creating PR.

**Example URL parameter:**
```
https://github.com/org/repo/compare/main...feature?template=feature.md
```

---

### Technique 2: Conditional Sections with Comments

**Use case:** Optional sections for specific scenarios

**Template:**
```markdown
## Screenshots
<!-- Delete this section if not applicable -->

Before | After
--- | ---
[image] | [image]

<!--
## Breaking Changes
Uncomment and fill out if this PR introduces breaking changes:

- Breaking change 1
- Migration path:
-->
```

---

### Technique 3: Auto-Linking Issues

**Use case:** Ensure PRs are linked to issues

**Template:**
```markdown
## Related Issues

Closes #
Fixes #
Resolves #
Related to #

<!-- Use keywords above to auto-link and close issues -->
```

**Keywords that close issues:**
- close, closes, closed
- fix, fixes, fixed
- resolve, resolves, resolved

---

### Technique 4: Size/Complexity Indicator

**Use case:** Help reviewers gauge effort

**Template:**
```markdown
## PR Size
- [ ] Small (<100 lines)
- [ ] Medium (100-500 lines)
- [ ] Large (500-1000 lines)
- [ ] Extra Large (>1000 lines)

## Complexity
- [ ] Trivial (typo fix, small tweak)
- [ ] Simple (straightforward change)
- [ ] Moderate (requires some thought)
- [ ] Complex (requires deep review)
```

---

### Technique 5: Visual Indicators

**Use case:** Make PR description scannable

**Template:**
```markdown
## Summary

🐛 **Bug Fix** | 🎉 **New Feature** | 📝 **Documentation** | ⚡ **Performance**

Brief description here.

## 📸 Screenshots
[images]

## ✅ Checklist
[checklist]

## ⚠️ Breaking Changes
[if applicable]
```

---

## PR Template Best Practices

### 1. Keep It Scannable

**Good:**
```markdown
## Summary
One-line description

## Changes
- Bullet point 1
- Bullet point 2

## Testing
- [x] Unit tests pass
- [x] Integration tests pass
```

**Bad:**
```markdown
This PR implements a new feature that allows users to do XYZ. I've made changes to the following files: file1.js, file2.js, file3.js. The changes include refactoring the ABC component, adding new functions DEF and GHI, updating tests, and modifying documentation. Testing was done by running the test suite and manually testing in Chrome and Firefox...

[long paragraph continues]
```

### 2. Make Checkboxes Actionable

**Good:**
```markdown
- [ ] Tests added
- [ ] Documentation updated
- [ ] Reviewed my own code
```

**Bad:**
```markdown
- [ ] Code is good
- [ ] Everything works
- [ ] Ready to merge
```

### 3. Include Context for Reviewers

**Good:**
```markdown
## Context
This fixes the issue where users couldn't upload files >10MB.

## Approach
Changed from synchronous to streaming upload using multipart form.

## Trade-offs
Slightly more complex code, but handles large files without timeout.
```

**Bad:**
```markdown
## What I Did
Fixed the upload thing
```

### 4. Use Templates, Not Scripts

**Good:** Markdown template (filled by human)

**Bad:** Auto-generated PR descriptions from commits
- Loses context
- Reviewer gets no summary
- Just repeats commit log

### 5. Tailor to Your Team

**Consider:**
- Team size (larger teams need more structure)
- Project complexity
- Compliance requirements
- Contribution frequency

**Avoid:**
- Copying templates without customization
- Too many required fields
- Irrelevant sections

---

## Common Mistakes

### ❌ Mistake 1: Template Too Long

**Problem:** Contributors skip sections or abandon PR

**Solution:** Keep to essentials. Make advanced sections optional.

### ❌ Mistake 2: No Description

**Problem:** Reviewers don't know what PR does

**Solution:** Require summary/description field. Make it clear and mandatory.

### ❌ Mistake 3: Checklist Items Ignored

**Problem:** Checklist items are never checked

**Solution:** Only include items you actually enforce. Remove noise.

### ❌ Mistake 4: Not Updated

**Problem:** Template references outdated tools or processes

**Solution:** Review template quarterly. Update as workflows change.

### ❌ Mistake 5: One Size Fits All

**Problem:** Same template for bugs, features, docs

**Solution:** Use multiple templates or make sections conditional.

---

## Integration with CI/CD

### PR Title Conventions

Some teams enforce PR title format:

**Convention:**
```
type(scope): description

Examples:
feat(auth): add OAuth2 support
fix(api): handle null responses
docs(readme): update installation steps
```

**Enforce with GitHub Actions:**
```yaml
name: PR Title Check
on:
  pull_request:
    types: [opened, edited]

jobs:
  check-title:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
```

### Required Checks in Template

Link template to CI checks:

```markdown
## CI Checks
- [ ] Build passes
- [ ] Tests pass (see status above)
- [ ] Linter passes
- [ ] Coverage threshold met
```

---

## Real-World Examples

### Example 1: React (Meta)

**Focus:** Simplicity, automated checks

**Template highlights:**
- Summary (required)
- Test plan (how to verify)
- Related issues
- Minimal checklist

**Why it works:**
- Fast to fill out
- Automated checks do heavy lifting
- Focus on description, not checklist

---

### Example 2: Kubernetes

**Focus:** Thorough review for critical infra

**Template highlights:**
- Release note block (required)
- Docs consideration
- Size estimation
- Multiple reviewers

**Why it works:**
- Critical software needs thoroughness
- Release notes help changelog
- Size helps reviewer planning

---

### Example 3: VS Code

**Focus:** User impact, testing

**Template highlights:**
- What's changed for users
- Testing instructions
- Complexity estimate
- GIF/screenshot for UI

**Why it works:**
- User-facing changes clearly documented
- Reviewers know testing priority
- Visual changes shown with images

---

## Template Maintenance

### Review Schedule

**Quarterly:**
- Check if sections are being filled
- Remove unused sections
- Add sections for common review comments

**After Process Changes:**
- Update CI/CD requirements
- Reflect new testing requirements
- Update links to documentation

### Metrics to Track

- PR review time (before/after template)
- Number of review rounds
- Incomplete PR rate
- Contributor feedback

### Getting Feedback

Ask contributors:
- Which sections are unclear?
- Which sections feel redundant?
- What's missing?

---

## Resources

- [GitHub PR Template Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Awesome PR Templates](https://github.com/stevemao/github-issue-templates)

---

## Summary

**Key takeaways:**
1. **Start simple** - use standard template, customize over time
2. **Make scanning easy** - bullets, checkboxes, sections
3. **Require only essentials** - description, testing, checklist
4. **Tailor to project type** - frontend, backend, infra need different info
5. **Review regularly** - update template as workflows evolve
6. **Multiple templates OK** - different PR types, different templates

**Golden rule:** PR template should help reviewers review faster, not create busywork for contributors.
