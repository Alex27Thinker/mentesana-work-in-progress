# Contributing Guide Patterns

Analysis of contributing guides from major open source projects, with extracted patterns and best practices.

## Exemplary CONTRIBUTING Files

### 1. Atom (atom/atom)

**URL:** https://github.com/atom/atom/blob/master/CONTRIBUTING.md

**What makes it great:**
- Welcoming tone: "First off, thanks for taking the time to contribute!"
- Table of contents for easy navigation
- Separate sections for questions vs. contributions
- Clear issue reporting guidelines with templates
- Pull request process explained step-by-step
- Styleguides for Git commits, code, and documentation

**Pattern extracted:**
```markdown
# Contributing to [Project]

Thank you message and encouragement

## Table of Contents

[Navigation links]

## I Don't Want to Read This Whole Thing

[Quick links for common tasks]

## How Can I Contribute?

### Reporting Bugs
### Suggesting Enhancements
### Your First Code Contribution
### Pull Requests

## Styleguides

### Git Commit Messages
### Code Styleguide
### Documentation Styleguide
```

**When to use:** Large, active projects with many contributors

### 2. Rails (rails/rails)

**URL:** https://github.com/rails/rails/blob/main/CONTRIBUTING.md

**What makes it great:**
- Links to Code of Conduct immediately
- Explains what contributions are valued
- Issue reporting guidelines are specific
- Testing requirements clearly stated
- Includes "What to work on" section
- Warns about wasted effort on rejected PRs

**Pattern extracted:**
```markdown
# Contributing to [Project]

## Code of Conduct

[Link or inline]

## Reporting Issues

### Security Issues
### Bug Reports
### Feature Requests

## Contributing Code

### What to Work On
### Development Setup
### Running Tests
### Making Changes

## Pull Request Guidelines

- Guideline 1
- Guideline 2

## Commit Message Format

[Format specification]

## Getting Help

[Where to ask questions]
```

**When to use:** Projects with specific contribution policies

### 3. Kubernetes (kubernetes/kubernetes)

**URL:** https://github.com/kubernetes/kubernetes/blob/master/CONTRIBUTING.md

**What makes it great:**
- Multiple contribution paths (code, docs, community)
- Links to extensive developer documentation
- Mentions Special Interest Groups (SIGs)
- Contributor ladder explained
- Clear governance structure

**Pattern extracted:**
```markdown
# Contributing Guidelines

## Before You Get Started

### Code of Conduct
### Community Expectations

## Contributing

### Find Something to Work On
### File an Issue
### Submit a Pull Request

## Contributor Guide

[Link to detailed guide]

## Development Guide

[Link to setup instructions]

## Community

### Communication
### Events
### Mentorship

## Membership

[Contributor roles and path]
```

**When to use:** Large open source projects with governance structure

### 4. Jest (jestjs/jest)

**URL:** https://github.com/jestjs/jest/blob/main/CONTRIBUTING.md

**What makes it great:**
- Development workflow clearly explained
- Uses monorepo structure, explains how to work with it
- Testing strategy detailed
- Links to good first issues
- Includes debugging tips

**Pattern extracted:**
```markdown
# Contributing to [Project]

## Code of Conduct

## Development Workflow

### Prerequisites
### Setup
### Running Tests
### Debugging

## Project Structure

[Monorepo or architecture explanation]

## How to Contribute

### Good First Issues
### Reporting Bugs
### Proposing Changes

## Pull Request Checklist

- [ ] Item 1
- [ ] Item 2
```

**When to use:** Monorepos, testing-focused projects

### 5. Node.js (nodejs/node)

**URL:** https://github.com/nodejs/node/blob/main/CONTRIBUTING.md

**What makes it great:**
- Separate guides for different contribution types
- Detailed commit guidelines with examples
- Developer's Certificate of Origin explained
- CI/CD process documented
- Review process transparent

**Pattern extracted:**
```markdown
# Contributing to [Project]

## Code of Conduct

## Ways to Contribute

- Documentation
- Code
- Bug Triaging
- Testing

## Developer's Certificate of Origin

[DCO explanation]

## Development Setup

### Prerequisites
### Building
### Testing

## Submitting Changes

### Commit Message Format
[Detailed format with examples]

### Opening a Pull Request

## Review Process

[What to expect]

## Additional Resources

- [Collaborator Guide](link)
- [Security Policy](link)
```

**When to use:** Projects requiring DCO, detailed process documentation

## Common Patterns Across Great Contributing Guides

### Pattern: Welcome Message

**Purpose:** Make contributors feel valued and encourage participation

**Example:**
```markdown
# Contributing to [Project]

First off, thank you for considering contributing to [Project]! It's people like you that make [Project] such a great tool.

Following these guidelines helps communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.
```

**Best practices:**
- Thank contributors upfront
- Set expectations about mutual respect
- Explain why guidelines exist
- Be welcoming and inclusive

### Pattern: Types of Contributions

**Purpose:** Show there are many ways to contribute beyond code

**Example:**
```markdown
## How Can I Contribute?

We love contributions in many forms:

- 📝 **Documentation** - Improve guides and API docs
- 🐛 **Bug Reports** - Help us identify issues
- ✨ **Feature Suggestions** - Share your ideas
- 💻 **Code** - Fix bugs or add features
- 🎨 **Design** - Improve UI/UX
- 🌍 **Translation** - Localize the project
- 💬 **Community Support** - Help other users
```

**Best practices:**
- List 5-8 contribution types
- Use icons/emojis for visual interest
- Include non-code contributions
- Link to specific guides for each type

### Pattern: Development Setup

**Purpose:** Get contributors running the project locally

**Example:**
```markdown
## Development Setup

### Prerequisites

- Node.js 18+
- Git
- [Other tools]

### Setup Steps

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/project.git
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Run tests to verify setup:
   ```bash
   npm test
   ```
5. Create a branch:
   ```bash
   git checkout -b feature/my-feature
   ```
```

**Best practices:**
- List prerequisites with version requirements
- Step-by-step commands
- Verification step (run tests)
- Branch naming convention

### Pattern: Commit Message Format

**Purpose:** Ensure consistent, meaningful commit history

**Example:**
```markdown
## Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type** must be one of:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(parser): add support for ES2022 syntax

Implements support for class static blocks and ergonomic
brand checks as specified in ES2022.

Closes #123
```
```

**Best practices:**
- Specify format clearly
- Provide type list
- Show good examples
- Explain each component
- Mention any automation (semantic-release, etc.)

### Pattern: Pull Request Process

**Purpose:** Set clear expectations for PR workflow

**Example:**
```markdown
## Pull Request Process

1. **Update Documentation** - If you change behavior, update the README
2. **Add Tests** - PRs without tests may not be merged
3. **Follow Code Style** - Run linter before submitting
4. **One Feature Per PR** - Keep changes focused
5. **Update Changelog** - Add entry to CHANGELOG.md
6. **Request Review** - Tag relevant maintainers
7. **Wait for CI** - All checks must pass
8. **Address Feedback** - Respond to review comments
9. **Squash Commits** - Before merge (or we'll do it)

### PR Checklist

Before submitting, ensure:

- [ ] Tests pass locally
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] Branch is up-to-date with main
```

**Best practices:**
- Numbered steps for clarity
- Checkbox list for verification
- Explain review expectations
- Mention CI/CD requirements
- State merge strategy (squash, rebase, merge)

### Pattern: Code of Conduct Link

**Purpose:** Establish community standards and safety

**Example:**
```markdown
## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [email@example.com].
```

**Best practices:**
- Link to full CoC document
- State reporting mechanism
- Place near top of document
- Use standard CoC (Contributor Covenant)

### Pattern: Testing Requirements

**Purpose:** Ensure quality and prevent regressions

**Example:**
```markdown
## Testing

All code contributions must include tests.

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.js

# Run tests in watch mode
npm run test:watch
```

### Writing Tests

- Place tests next to the code they test: `feature.test.js`
- Use descriptive test names: `it('should handle invalid input gracefully')`
- Aim for 80%+ coverage
- Test edge cases, not just happy paths

### Test Structure

```javascript
describe('FeatureName', () => {
  describe('methodName', () => {
    it('should do expected thing', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```
```

**Best practices:**
- Show how to run tests
- Explain where tests go
- Provide test templates
- State coverage requirements
- Include testing philosophy

## Structure Levels by Project Size

### Basic (Small Projects)

**200-400 lines**

Sections:
- Welcome message
- Code of Conduct link
- Development setup
- How to submit changes
- Contact information

**Example structure:**
```markdown
# Contributing

## Welcome

## Code of Conduct

## Development Setup

## Submitting Changes

## Getting Help
```

### Standard (Medium Projects)

**400-800 lines**

Sections:
- Welcome message
- Table of contents
- Code of Conduct
- Ways to contribute
- Development setup
- Testing
- Commit guidelines
- PR process
- Style guides

**Example structure:**
```markdown
# Contributing

## Table of Contents

## Welcome

## Code of Conduct

## Ways to Contribute

## Development Setup

## Testing

## Commit Guidelines

## Pull Request Process

## Code Style

## Getting Help
```

### Comprehensive (Large Projects)

**800-1500 lines**

Sections:
- All standard sections plus:
- Architecture overview
- Governance structure
- Contributor ladder
- Release process
- Security policy
- Detailed workflows
- Troubleshooting

**Example structure:**
```markdown
# Contributing

## Table of Contents

## Welcome

## Code of Conduct

## Project Governance

## Ways to Contribute

## Development Setup

## Architecture Overview

## Testing Strategy

## Commit Guidelines

## Pull Request Process

## Review Process

## Code Style

## Documentation Style

## Contributor Ladder

## Release Process

## Security Policy

## Troubleshooting

## Getting Help
```

## Anti-Patterns to Avoid

### ❌ No Development Setup

**Problem:** Assumes contributors know how to set up the project

**Solution:** Always include step-by-step setup instructions

### ❌ Vague Guidelines

**Problem:** "Follow good coding practices"

**Solution:** Be specific about style guides, testing requirements, commit format

### ❌ Gatekeeping Tone

**Problem:** "Only submit PRs if you're an expert"

**Solution:** Welcome all skill levels, provide mentorship resources

### ❌ Hidden Requirements

**Problem:** PR rejected for reasons not in CONTRIBUTING.md

**Solution:** Document all requirements, expectations, and policies

### ❌ Outdated Instructions

**Problem:** Setup steps don't work anymore

**Solution:** Test setup process regularly, keep docs current

### ❌ No Response Expectations

**Problem:** Contributors don't know when to expect feedback

**Solution:** State typical review times, triage process

## Tone and Language Guidelines

**Do:**
- Use welcoming, inclusive language
- Say "we" and "our" (community)
- Assume good intentions
- Provide examples
- Thank contributors

**Don't:**
- Use jargon without explanation
- Assume prior knowledge
- Be condescending
- Create unnecessary barriers
- Forget to say thanks

## Testing Your Contributing Guide

**Checklist:**
- [ ] Can a new contributor set up the project following these instructions?
- [ ] Are all requirements clearly stated?
- [ ] Is the tone welcoming?
- [ ] Are contribution types beyond code mentioned?
- [ ] Is the PR process explained step-by-step?
- [ ] Are links working and up-to-date?
- [ ] Is the Code of Conduct linked?

**Get Feedback:**
- Ask new contributors to follow the guide
- Track where people get stuck
- Update based on common questions
- Review annually or after major changes

## Summary

Great contributing guides share common traits:
1. **Welcoming** - Thank contributors, be inclusive
2. **Clear** - Step-by-step instructions, no assumptions
3. **Complete** - Cover setup, testing, PRs, style
4. **Current** - Keep updated with project changes
5. **Accessible** - Multiple contribution paths, not just code

Choose patterns based on your project size and community, but always prioritize clarity and encouragement.
