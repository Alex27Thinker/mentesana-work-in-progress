---
name: readme-and-co:documentation-standards
description: This skill should be used when creating README files, CONTRIBUTING guides, SUPPORT documentation, or any core repository documentation. Triggers when user asks to "create a README", "write documentation", "generate CONTRIBUTING", "add support docs", or discusses repository documentation standards and best practices.
version: 0.1.0
---

# Documentation Standards for GitHub Repositories

## Purpose

Provide comprehensive guidance for creating high-quality GitHub repository documentation following industry best practices. This skill covers README structure, contributing guidelines, support resources, and documentation organization.

## When to Use This Skill

Use this skill when:
- Creating README.md files for repositories
- Writing CONTRIBUTING.md guides
- Generating SUPPORT.md documentation
- Structuring repository documentation
- Deciding what sections to include in documentation
- Following documentation best practices

## Core Documentation Types

### README.md

The README is the entry point to any repository. Essential sections include:

**Must-have sections:**
- Project title and description (one-line summary)
- Installation instructions
- Usage examples
- License information

**Recommended sections:**
- Features list
- Prerequisites/requirements
- Contributing link
- Support/contact information
- Acknowledgments

**Optional but valuable:**
- Badges (build status, coverage, version)
- Screenshots/demos
- Tech stack overview
- Roadmap
- FAQ

**Structure pattern:**
```markdown
# Project Name

Brief description (1-2 sentences)

## Features

## Installation

## Usage

## Contributing

## License
```

### CONTRIBUTING.md

Guides contributors through the contribution process.

**Essential elements:**
- How to set up development environment
- Code style guidelines
- Testing requirements
- Pull request process
- Commit message conventions

**Structure levels:**

*Basic (for simple projects):*
- Development setup
- How to submit changes
- Code of conduct link

*Standard (recommended):*
- Development environment setup
- Running tests
- Code style (linting, formatting)
- Pull request process
- Issue reporting guidelines

*Comprehensive (for large projects):*
- All standard sections plus:
- Architecture overview
- Testing strategy
- Release process
- Contribution recognition
- Detailed workflow examples

### SUPPORT.md

Defines how users get help.

**Key sections:**
- Where to ask questions (GitHub Discussions, Stack Overflow, Discord)
- How to report bugs (link to issue templates)
- Support resources (documentation, FAQ, tutorials)
- Response time expectations (if applicable)

**Variants:**

*Basic:* Links to issue tracker and communication channels

*Detailed:* Includes troubleshooting guides, FAQ, escalation paths

## Documentation Principles

### Clarity Over Completeness

Write for the target audience:
- **End users**: Focus on installation and usage
- **Contributors**: Emphasize development setup and guidelines
- **Maintainers**: Include architecture and maintenance docs

### Progressive Disclosure

Structure documentation from basic to advanced:
1. Quick start (get running in <5 minutes)
2. Common use cases
3. Advanced features
4. API reference
5. Architecture details

### Maintain Consistency

**Across files:**
- Use consistent terminology
- Match code style in examples
- Link between documents appropriately

**Within files:**
- Consistent heading levels
- Uniform code block formatting
- Standard section ordering

### Keep Updated

Documentation rots quickly. Strategies:
- Link to canonical sources (not duplicate information)
- Use automated tools for version numbers, API references
- Include "last updated" dates for time-sensitive content
- Review documentation in PR process

## Project-Specific Customization

Adapt documentation to project characteristics:

**Language/Framework:**
- Python: Include requirements.txt/pyproject.toml, virtual env setup
- JavaScript: Include package.json scripts, npm/yarn/pnpm
- Go: Include go.mod, go install instructions
- Rust: Include Cargo.toml, cargo build/run

**Project Type:**
- Library: Emphasize API documentation, installation
- Application: Focus on usage, configuration
- CLI tool: Include command reference, examples
- Framework: Provide getting started guide, concepts

**Audience:**
- Open source: Emphasize contributing, community
- Internal tool: Focus on organization-specific setup
- Commercial: Include licensing, support channels

## README Patterns by Project Type

### Library/Package

```markdown
# Library Name

Description of what the library does

## Installation

[Package manager commands]

## Quick Start

[Minimal example]

## API Reference

[Key functions/classes]

## Examples

[Common use cases]
```

### Application/Service

```markdown
# Application Name

What the application does and why

## Features

[Key capabilities]

## Getting Started

### Prerequisites
### Installation
### Configuration

## Usage

[How to use the application]

## Deployment

[Production deployment guide]
```

### CLI Tool

```markdown
# Tool Name

One-line description

## Installation

[Install command]

## Usage

```bash
tool-name [options] <arguments>
```

## Commands

[Command reference]

## Examples

[Common workflows]
```

## Documentation Anti-Patterns

**Avoid:**
- Duplicating information that exists in code comments
- Screenshots that become outdated quickly
- Installation instructions for every OS when package managers work cross-platform
- Extensive API documentation in README (link to generated docs)
- Mixing user docs with contributor docs

**Instead:**
- Link to generated API docs
- Use badges for CI status, not screenshots
- Focus on primary installation method, link to wiki for alternatives
- Separate user docs (README) from contributor docs (CONTRIBUTING)

## Additional Resources

### Reference Files

For detailed guidance and examples:
- **`references/readme-examples.md`** - Analysis of stellar README files with patterns extracted
- **`references/contributing-patterns.md`** - Contributing guide structures from major projects
- **`references/support-structures.md`** - Support documentation examples and patterns

### Example Files

Working documentation templates in `examples/`:
- **`examples/README-minimal.md`** - Minimal README template
- **`examples/README-standard.md`** - Standard README with common sections
- **`examples/CONTRIBUTING-basic.md`** - Basic contributing guidelines

## Quick Reference

**README checklist:**
- [ ] Clear title and description
- [ ] Installation instructions
- [ ] Usage example
- [ ] License specified
- [ ] Contributing link (if accepting contributions)

**CONTRIBUTING checklist:**
- [ ] Development environment setup
- [ ] Testing instructions
- [ ] PR process explained
- [ ] Code style guidelines
- [ ] Code of conduct link

**SUPPORT checklist:**
- [ ] Where to ask questions
- [ ] How to report bugs
- [ ] Available resources
- [ ] Response expectations

Consult reference files for detailed patterns and real-world examples.
