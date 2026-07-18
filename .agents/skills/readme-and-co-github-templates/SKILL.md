---
name: readme-and-co:github-templates
description: This skill should be used when creating GitHub issue templates, pull request templates, CODEOWNERS files, or when user asks to "create issue template", "add PR template", "set up CODEOWNERS", "create bug report template", "add feature request form", or discusses GitHub repository templates and automation.
version: 0.1.0
---

# GitHub Templates for Issues, PRs, and Code Ownership

## Purpose

Provide guidance for creating effective GitHub templates including issue templates (both Markdown and YAML forms), pull request templates, and CODEOWNERS files.

## When to Use This Skill

Use this skill when:
- Creating issue templates (bug reports, feature requests)
- Setting up pull request templates
- Configuring CODEOWNERS files
- Choosing between Markdown and YAML template formats
- Structuring template fields and validation
- Setting up template automation (labels, assignees)

## GitHub Template Types

### Issue Templates

GitHub supports two formats for issue templates:

**Markdown templates** (`.github/ISSUE_TEMPLATE/*.md`):
- Simple format, easy to create
- Good for basic templates
- Limited validation and structure

**YAML forms** (`.github/ISSUE_TEMPLATE/*.yml`):
- Structured forms with validation
- Rich field types (dropdowns, checkboxes, textareas)
- Better for complex templates
- Recommended for new projects

### Pull Request Templates

**Single template** (`.github/pull_request_template.md`):
- Applied to all pull requests
- Simplest setup

**Multiple templates** (`.github/PULL_REQUEST_TEMPLATE/`):
- Different templates for different PR types
- Users select which template to use

### CODEOWNERS

**File location**: `.github/CODEOWNERS` or `CODEOWNERS` (root) or `docs/CODEOWNERS`

Defines code ownership and automatic review requests.

## Issue Template Formats

### When to Use Markdown

Use Markdown templates for:
- Simple projects with straightforward needs
- Legacy templates (already in Markdown)
- Maximum flexibility in structure
- Projects where YAML might be overkill

**Example use cases:**
- Small personal projects
- Simple bug report forms
- Question templates

### When to Use YAML Forms

Use YAML forms for:
- New projects (recommended default)
- Complex templates with validation
- Dropdown selections (severity, priority, versions)
- Required fields and validation
- Better user experience

**Example use cases:**
- Bug reports with required information
- Feature requests with structured data
- Templates needing dropdowns or checkboxes

## Issue Template Patterns

### Bug Report Template

**Essential fields:**
- Description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (OS, browser, version)

**Optional but valuable:**
- Screenshots or error messages
- Severity/priority selection
- Affected version dropdown
- Additional context

**YAML structure:**
```yaml
name: Bug Report
description: Report a bug or unexpected behavior
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: Thanks for reporting! Please fill out the information below.

  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: Clear description of the bug
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      placeholder: |
        1. Go to...
        2. Click on...
        3. See error
    validations:
      required: true

  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Low
        - Medium
        - High
        - Critical
```

### Feature Request Template

**Essential fields:**
- Problem or use case
- Proposed solution
- Alternatives considered

**Optional:**
- Priority selection
- Related issues
- Willingness to contribute

**YAML structure:**
```yaml
name: Feature Request
description: Suggest a new feature or enhancement
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this solve?
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: How should this work?
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: What other solutions did you consider?
```

### Question Template

For projects using GitHub Discussions, redirect to discussions:

```yaml
name: Question
description: Ask a question (will redirect to Discussions)
body:
  - type: markdown
    attributes:
      value: |
        Questions should be posted in [GitHub Discussions](../../discussions).

        This issue tracker is for bug reports and feature requests only.
```

## Pull Request Templates

### Standard PR Template

**Essential sections:**
- Description of changes
- Type of change (bug fix, feature, refactor)
- Testing checklist
- Breaking changes note

**Template structure:**
```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing

- [ ] Tests pass locally
- [ ] Added new tests for changes
- [ ] Updated documentation

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-reviewed the code
- [ ] Commented complex code sections
- [ ] Updated relevant documentation
- [ ] No new warnings generated
- [ ] Added tests proving fix/feature works
- [ ] Dependent changes merged and published
```

### Detailed PR Template

For projects with stricter requirements:

**Additional sections:**
- Related issues/tickets
- Screenshots (for UI changes)
- Performance impact
- Security considerations
- Deployment notes
- Rollback plan

## CODEOWNERS Patterns

### Basic Structure

```
# Default owners for everything
* @organization/core-team

# Specific paths
/docs/ @organization/docs-team
/src/api/ @organization/backend-team
/src/ui/ @organization/frontend-team

# Specific files
package.json @organization/leads
*.md @organization/docs-team
```

### Advanced Patterns

**Multiple owners (all must approve):**
```
/critical-path/ @org/security-team @org/lead-engineer
```

**Individual and team ownership:**
```
/infrastructure/ @devops-lead @org/devops-team
```

**Wildcards and exclusions:**
```
# All TypeScript files
**/*.ts @org/typescript-experts

# Except test files
**/*.test.ts @org/qa-team
```

### Best Practices for CODEOWNERS

**Keep focused:**
- Don't assign too many reviewers (slows down PRs)
- Use teams instead of individuals when possible
- Balance coverage with PR velocity

**Organize logically:**
- Start with broad rules, refine with specific rules
- Group related paths together
- Comment sections for clarity

**Maintain actively:**
- Update as team structure changes
- Remove departed team members promptly
- Review quarterly for accuracy

## Template Configuration

### Template Discovery

GitHub automatically discovers templates in:
- `.github/ISSUE_TEMPLATE/` - Issue templates
- `.github/PULL_REQUEST_TEMPLATE/` - PR templates (directory for multiple)
- `.github/pull_request_template.md` - Single PR template
- `.github/CODEOWNERS` - Code ownership

### Template Metadata (YAML)

**Issue template frontmatter:**
```yaml
name: Template Name
description: Brief description
title: "[PREFIX] Default title"
labels: ["label1", "label2"]
assignees:
  - username1
  - username2
```

**Available fields:**
- `name`: Template name shown in issue creation
- `description`: Detailed description
- `title`: Default issue title (can include placeholders)
- `labels`: Auto-applied labels
- `assignees`: Auto-assigned users

### Config File

Create `.github/ISSUE_TEMPLATE/config.yml` to customize issue creation:

```yaml
blank_issues_enabled: false
contact_links:
  - name: GitHub Discussions
    url: https://github.com/org/repo/discussions
    about: Please ask questions in Discussions
  - name: Security Issues
    url: https://github.com/org/repo/security
    about: Report security vulnerabilities privately
```

## Field Types Reference (YAML Forms)

### textarea

Multi-line text input:
```yaml
- type: textarea
  id: description
  attributes:
    label: Description
    description: Detailed description
    placeholder: Enter text here
    value: Default text
  validations:
    required: true
```

### input

Single-line text input:
```yaml
- type: input
  id: version
  attributes:
    label: Version
    description: Which version are you using?
    placeholder: "1.0.0"
  validations:
    required: false
```

### dropdown

Select from options:
```yaml
- type: dropdown
  id: browser
  attributes:
    label: Browser
    description: Which browser?
    options:
      - Chrome
      - Firefox
      - Safari
      - Edge
    multiple: false
  validations:
    required: true
```

### checkboxes

Multiple selections:
```yaml
- type: checkboxes
  id: terms
  attributes:
    label: Acknowledgments
    options:
      - label: I have searched existing issues
        required: true
      - label: I have read the documentation
        required: true
```

### markdown

Static text/instructions:
```yaml
- type: markdown
  attributes:
    value: |
      ## Instructions

      Please provide detailed information below.
```

## Additional Resources

### Reference Files

For detailed patterns and examples:
- **`references/issue-template-examples.md`** - Real-world issue templates from Appium, Ionic, RethinkDb
- **`references/pr-template-patterns.md`** - PR template variations and best practices
- **`references/codeowners-guide.md`** - Advanced CODEOWNERS patterns and organizational strategies

### GitHub Templates

Complete GitHub templates available in plugin:
- **`../../templates/ISSUE_TEMPLATES/full/bug_report.yml.template`** - YAML bug report form
- **`../../templates/ISSUE_TEMPLATES/full/feature_request.yml.template`** - YAML feature request form
- **`../../templates/PR_TEMPLATES/full/PULL_REQUEST_TEMPLATE.md.template`** - Standard PR template
- **`../../templates/CODEOWNERS`** - CODEOWNERS with common patterns

Use the `render_template.py` script to render templates with project-specific variables

## Quick Reference

**Issue templates:**
- Use **YAML forms** for new projects (better validation, UX)
- Use **Markdown** for simple cases or legacy support

**PR templates:**
- Single template for most projects (`.github/pull_request_template.md`)
- Multiple templates if different PR types have different requirements

**CODEOWNERS:**
- Place in `.github/CODEOWNERS`
- Use teams for easier maintenance
- Start broad, refine specific paths
- Balance coverage with PR velocity

**Template checklist:**
- [ ] Issue templates in `.github/ISSUE_TEMPLATE/`
- [ ] PR template created
- [ ] CODEOWNERS configured (if needed)
- [ ] Config file for issue creation customization (optional)
- [ ] Labels and assignees configured in templates

Consult reference files for complete examples and advanced patterns.
