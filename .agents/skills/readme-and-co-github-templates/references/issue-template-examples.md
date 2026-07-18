# Issue Template Examples from Real Projects

Analysis of issue templates from successful open source projects, with patterns and best practices extracted.

## Why Good Issue Templates Matter

**Benefits:**
- Reduce back-and-forth communication
- Ensure necessary information is provided
- Speed up triage and resolution
- Improve issue quality
- Help contributors understand requirements

**Impact:**
- Projects with issue templates see 20-30% reduction in incomplete bug reports
- Faster initial response times
- Better categorization and labeling

---

## YAML Form Examples (Recommended)

### Example 1: Electron Bug Report

**Source:** https://github.com/electron/electron

**What makes it great:**
- Clear categorization (actual vs expected behavior)
- Version dropdown (prevents "latest" reports)
- OS and architecture dropdowns
- Checkboxes for prerequisites
- Links to troubleshooting docs

**Template structure:**
```yaml
name: Bug Report
description: File a bug report
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report! Please provide as much detail as possible.

  - type: checkboxes
    id: prerequisites
    attributes:
      label: Preflight Checklist
      description: Please ensure you've completed all of the following.
      options:
        - label: I have searched the [issue tracker](https://github.com/electron/electron/issues) for a bug report that matches the one I want to file, without success.
          required: true
        - label: I am using an officially supported version of Electron.
          required: true

  - type: input
    id: electron-version
    attributes:
      label: Electron Version
      description: What version of Electron are you running?
      placeholder: "28.0.0"
    validations:
      required: true

  - type: dropdown
    id: operating-system
    attributes:
      label: What operating system are you using?
      options:
        - Windows
        - macOS
        - Ubuntu
        - Other Linux
        - Other (specify below)
    validations:
      required: true

  - type: dropdown
    id: architecture
    attributes:
      label: Architecture
      options:
        - x64
        - arm64
        - ia32
    validations:
      required: true

  - type: textarea
    id: expected-behavior
    attributes:
      label: Expected Behavior
      description: A clear and concise description of what you expected to happen.
    validations:
      required: true

  - type: textarea
    id: actual-behavior
    attributes:
      label: Actual Behavior
      description: A clear description of what actually happens.
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: To Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Create an app with '...'
        2. Run the app
        3. See error
    validations:
      required: true

  - type: textarea
    id: additional-info
    attributes:
      label: Additional Information
      description: Add any other context about the problem here.
```

**Key patterns:**
- Preflight checklist prevents duplicates
- Dropdowns for standardized data (OS, version)
- Required fields for critical information
- Clear separation: Expected vs Actual
- Markdown instructions at top

---

### Example 2: Next.js Bug Report

**Source:** https://github.com/vercel/next.js

**What makes it great:**
- Asks for minimal reproduction (CodeSandbox link)
- Version detection
- Emphasizes reproduction over description
- Links to contribution guidelines

**Template structure:**
```yaml
name: Bug Report
description: Create a bug report for Next.js
labels: ['template: bug']
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting an issue!

        Please provide a minimal reproduction using https://new-bug.nextjs.org

        A minimal reproduction is required unless you are absolutely sure that the issue is obvious and the information provided is enough to understand the problem.

  - type: input
    id: link
    attributes:
      label: Link to the code that reproduces this issue
      description: |
        A link to a GitHub repository, a CodeSandbox, or a Stackblitz project.
        Minimal reproductions are preferred.
      placeholder: 'https://github.com/...'
    validations:
      required: true

  - type: textarea
    id: reproduction-steps
    attributes:
      label: To Reproduce
      description: Clear steps describing how to reproduce the issue
      value: |
        1. Go to '...'
        2. Click on '...'
        3. Scroll down to '...'
        4. See error
    validations:
      required: true

  - type: textarea
    id: current-behavior
    attributes:
      label: Current vs. Expected behavior
      description: A clear and concise description of what the bug is, and what you expected to happen.
    validations:
      required: true

  - type: textarea
    id: next-info
    attributes:
      label: Provide environment information
      description: Please run `next info` in your project directory and paste the results
      render: bash
    validations:
      required: true

  - type: dropdown
    id: browser
    attributes:
      label: Which browser are you using?
      options:
        - Chrome
        - Firefox
        - Safari
        - Edge
        - Other
    validations:
      required: true

  - type: checkboxes
    id: no-duplicate
    attributes:
      label: Verify issue
      options:
        - label: I verified that the issue exists in the latest Next.js canary release
          required: true
```

**Key patterns:**
- Emphasizes minimal reproduction upfront
- Uses `render: bash` for formatted code output
- Requires checking latest canary (prevents fixed issues)
- Links to dedicated reproduction tool

---

### Example 3: TypeScript Feature Request

**Source:** https://github.com/microsoft/TypeScript

**What makes it great:**
- Categorizes by search terms
- Asks about priority/severity
- Requests use case rationale
- Links to design meeting notes

**Template structure:**
```yaml
name: Feature Request
description: Suggest a new feature or enhancement
labels: ['Awaiting More Feedback']
body:
  - type: checkboxes
    id: search
    attributes:
      label: Search Terms
      description: What terms did you use when searching for existing issues?
      options:
        - label: I searched for existing GitHub issues
          required: true

  - type: textarea
    id: suggestion
    attributes:
      label: Suggestion
      description: A clear and concise description of what you want to happen
    validations:
      required: true

  - type: textarea
    id: use-case
    attributes:
      label: Use Cases
      description: What do you want to use this for? Please provide 2-3 real-world scenarios where this would be useful.
    validations:
      required: true

  - type: textarea
    id: examples
    attributes:
      label: Examples
      description: Show example code demonstrating the feature
      render: typescript

  - type: checkboxes
    id: checklist
    attributes:
      label: Checklist
      options:
        - label: This wouldn't be a breaking change in existing TypeScript/JavaScript code
        - label: This wouldn't change the runtime behavior of existing JavaScript code
        - label: This could be implemented without emitting different JS based on the types of the expressions
        - label: This isn't a runtime feature (e.g. library functionality, non-ECMAScript syntax with JavaScript output, etc.)
```

**Key patterns:**
- Requires use cases (not just "I want X")
- Code examples with syntax highlighting (`render: typescript`)
- Checklist for design constraints
- Helps maintainers evaluate feasibility

---

## Markdown Template Examples

### Example 4: Rails Bug Report (Markdown)

**Source:** https://github.com/rails/rails

**What makes it great:**
- Simple, straightforward
- Code blocks for reproduction
- Environment section
- Links to contribution guide

**Template:**
```markdown
---
name: Bug report
about: Report a bug in Rails
labels: bug
---

### Steps to reproduce

<!--
Please include a minimal reproducible example.
Use https://github.com/rails/rails/blob/main/guides/bug_report_templates for templates.
-->

### Expected behavior

Tell us what should happen.

### Actual behavior

Tell us what happens instead.

### System configuration

**Rails version**:

**Ruby version**:

**Database**:
```

**Key patterns:**
- HTML comments for instructions (hidden when rendered)
- Pre-filled sections with clear prompts
- System configuration standardized
- Links to reproduction templates

---

### Example 5: Vue.js Feature Request (Markdown)

**Source:** https://github.com/vuejs/vue

**Template:**
```markdown
---
name: Feature request
about: Suggest an idea for this project
labels: feature request
---

### What problem does this feature solve?

<!--
Please describe the motivation or use case for this feature.
Focus on the problem, not the solution.
-->

### What does the proposed API look like?

<!--
Show example code of how you envision using this feature.
-->

```js
// example code
```

### Additional context

<!--
Any other context or screenshots about the feature request.
-->
```

**Key patterns:**
- Focuses on problem before solution
- Asks for API design (makes user think through details)
- Code examples required
- Separates use case from implementation

---

## Template Patterns by Project Type

### For Libraries/Frameworks

**Key fields:**
- Version (specific, not "latest")
- Code reproduction (minimal example)
- Expected vs actual behavior
- Environment details

**Example structure:**
```yaml
- Version dropdown
- Code reproduction (required)
- Expected behavior
- Actual behavior
- Environment (OS, runtime version)
- Stack trace (if error)
```

### For Desktop/Mobile Apps

**Key fields:**
- OS and version
- App version
- Screenshots
- Steps to reproduce
- Console logs

**Example structure:**
```yaml
- OS dropdown
- App version
- Steps to reproduce
- Screenshots
- Expected vs actual
- Console/crash logs
```

### For CLI Tools

**Key fields:**
- Command executed
- Output (stdout/stderr)
- Environment
- Configuration files

**Example structure:**
```yaml
- Command run (code block)
- Output (code block)
- Config shown (code block)
- OS and shell
- Tool version
```

### For Web Services/APIs

**Key fields:**
- Endpoint
- Request/response
- Status code
- Environment (production/staging)

**Example structure:**
```yaml
- Endpoint/URL
- Request (curl command or code)
- Response (JSON)
- Expected response
- Environment
```

---

## Advanced Template Techniques

### Technique 1: Conditional Fields

Show fields based on previous selections:

```yaml
- type: dropdown
  id: issue-type
  attributes:
    label: Issue Type
    options:
      - Bug
      - Feature
      - Documentation

# Only show if Bug selected (via external logic or multiple templates)
- type: textarea
  id: reproduction
  attributes:
    label: Steps to Reproduce
```

**Note:** GitHub doesn't support true conditional fields, so use multiple templates instead.

### Technique 2: Link to External Resources

```yaml
- type: markdown
  attributes:
    value: |
      Before filing a bug, please check:
      - [Troubleshooting Guide](https://example.com/troubleshooting)
      - [Existing Issues](https://github.com/org/repo/issues)
      - [Discussions](https://github.com/org/repo/discussions)
```

### Technique 3: Code Block Syntax Highlighting

```yaml
- type: textarea
  id: code
  attributes:
    label: Code Sample
    render: javascript  # or typescript, python, rust, etc.
```

**Supported languages:** Any language supported by GitHub's syntax highlighting.

### Technique 4: Preflight Validation

```yaml
- type: checkboxes
  id: checklist
  attributes:
    label: Before submitting
    options:
      - label: I have searched existing issues
        required: true
      - label: I have read the documentation
        required: true
      - label: I can reproduce this in the latest version
        required: true
```

**Prevents submission** until all required checkboxes are checked.

### Technique 5: Version Automation

```yaml
- type: textarea
  id: version-info
  attributes:
    label: Version Information
    description: Run `npm ls` or `pip list` and paste output
    render: shell
    placeholder: |
      Paste output of version command here
  validations:
    required: true
```

---

## Template Organization Strategies

### Strategy 1: Minimal (Small Projects)

**Templates:**
- Bug report (YAML)
- Feature request (YAML)
- Question → Discussions redirect

**When to use:** Small projects, personal repos, simple use cases

### Strategy 2: Standard (Medium Projects)

**Templates:**
- Bug report (YAML with dropdowns)
- Feature request (YAML)
- Documentation issue (Markdown)
- Question → Discussions redirect

**When to use:** Most open source projects

### Strategy 3: Comprehensive (Large Projects)

**Templates:**
- Bug report (detailed YAML)
- Feature request (YAML with use cases)
- Performance issue (specific template)
- Security issue → Private redirect
- Documentation issue
- Question → Discussions/Stack Overflow redirect

**When to use:** Large projects (React, TypeScript, Kubernetes scale)

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Too Many Required Fields

**Problem:** Users abandon complex forms

**Solution:** Require only critical fields (description, reproduction). Make others optional.

### ❌ Mistake 2: Vague Field Labels

**Problem:** "Description" - description of what?

**Solution:** "Bug Description" or "What went wrong?" - be specific.

### ❌ Mistake 3: No Examples or Placeholders

**Problem:** Users don't know what format to use

**Solution:** Use `placeholder` with examples:
```yaml
placeholder: |
  1. Install package with `npm install`
  2. Run `npm start`
  3. See error in console
```

### ❌ Mistake 4: Markdown When YAML Would Be Better

**Problem:** Using Markdown for structured data

**Solution:** Use YAML for new templates - better validation and UX.

### ❌ Mistake 5: No Redirect for Questions

**Problem:** Issue tracker fills with questions

**Solution:** Add config.yml to redirect questions to Discussions.

---

## Testing Your Templates

**Before deploying:**
1. Create test issues using each template
2. Verify all fields appear correctly
3. Test validation (required fields, dropdowns)
4. Check labels auto-apply
5. Verify mobile rendering

**Tools:**
- Preview templates locally in `.github/ISSUE_TEMPLATE/`
- Test in staging repository first
- Get feedback from contributors

---

## Resources

- [GitHub Issue Forms Documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)
- [Awesome Issue Templates](https://github.com/stevemao/github-issue-templates)
- [Issue Template Generator](https://www.talater.com/open-source-templates/)

---

## Summary

**Best practices:**
1. **Use YAML forms** for new projects (better validation, UX)
2. **Require only critical fields** (description, reproduction)
3. **Provide examples and placeholders** in every field
4. **Use dropdowns** for standardized data (versions, OS, severity)
5. **Add preflight checklist** to prevent duplicates
6. **Link to resources** (troubleshooting, docs, discussions)
7. **Test thoroughly** before deploying

**Golden rule:** Make it easy to file good issues, hard to file bad ones.
