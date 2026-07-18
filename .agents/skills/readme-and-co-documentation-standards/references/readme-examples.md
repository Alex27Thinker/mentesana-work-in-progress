# README Examples and Patterns

Analysis of stellar README files from successful open source projects, with extracted patterns and best practices.

## Exemplary README Files

### 1. React (facebook/react)

**URL:** https://github.com/facebook/react

**What makes it great:**
- Opens with clear one-line description
- Links to comprehensive documentation site immediately
- Installation instructions are concise (npm/yarn commands only)
- Minimal README, delegates to docs site for details
- Clear contributing and license sections

**Pattern extracted:**
```markdown
# Project Name

[Badges]

One-line description

[Link to main documentation]

## Installation

[Package manager command]

## Documentation

[Link to detailed docs]

## Contributing

[Link to CONTRIBUTING.md]

## License

[License type with link]
```

**When to use:** Large frameworks with extensive documentation sites

### 2. Requests (psf/requests)

**URL:** https://github.com/psf/requests

**What makes it great:**
- Tagline is memorable: "HTTP for Humans"
- Quick start code example in README
- Feature highlights before installation
- Links to documentation, but includes usage examples
- Shows both simple and complex usage

**Pattern extracted:**
```markdown
# Project Name
> Memorable tagline

## Feature Highlights

- Feature 1
- Feature 2
- Feature 3

## Installation

[Install command]

## Quick Start

```[language]
[Minimal working example]
```

## More Examples

[2-3 additional examples]

## Documentation

[Link to full docs]
```

**When to use:** Libraries with API that benefits from code examples

### 3. Awesome Lists (sindresorhus/awesome)

**URL:** https://github.com/sindresorhus/awesome

**What makes it great:**
- Explains what "awesome lists" are upfront
- Guidelines for contributing are clear
- Uses emojis sparingly but effectively
- Table of contents for easy navigation
- Consistent formatting throughout

**Pattern extracted:**
```markdown
# Project Name

Brief explanation of concept

## Contents

- [Category 1](#category-1)
- [Category 2](#category-2)

## Category 1

- [Item](link) - Description
- [Item](link) - Description

## Contributing

Guidelines inline or linked
```

**When to use:** Curated lists, resource collections

### 4. VS Code (microsoft/vscode)

**URL:** https://github.com/microsoft/vscode

**What makes it great:**
- Screenshots show the product immediately
- Multiple installation options clearly presented
- Development setup separate from user installation
- Contribution guide is detailed
- Feature badges (build status, version)

**Pattern extracted:**
```markdown
# Project Name

[Screenshot or demo]

One-line description

## Download & Install

### Users
[Download links by platform]

### Developers
[Build from source instructions]

## Features

[Key features with visuals]

## Contributing

[Development setup and guidelines]

## Feedback

[Issue reporting and feature requests]

## License

[License info]
```

**When to use:** Desktop applications, tools with GUI

### 5. Flask (pallets/flask)

**URL:** https://github.com/pallets/flask

**What makes it great:**
- Shows a complete minimal application upfront
- Installation and quick start combined
- Links to documentation for detailed guides
- Clean, simple structure
- Includes "A Simple Example" section

**Pattern extracted:**
```markdown
# Project Name

One-line description

## A Simple Example

```[language]
[Complete minimal working code]
```

## Installing

[Install command]

For more information, see [documentation link]

## Contributing

[Link to contributing guide]

## Links

- Documentation: [link]
- Changes: [changelog link]
- PyPI: [package link]
- Source Code: [github link]
- Issue Tracker: [issues link]
```

**When to use:** Frameworks where showing working code is essential

### 6. Terraform (hashicorp/terraform)

**URL:** https://github.com/hashicorp/terraform

**What makes it great:**
- Clear introduction with use case
- Prerequisites listed upfront
- Multiple installation methods
- Getting started tutorial linked
- Community and commercial support separated

**Pattern extracted:**
```markdown
# Project Name

What it does and why you'd use it

## Installation

### Package Managers
[OS-specific install commands]

### Building from Source
[Build instructions]

## Getting Started

[Link to tutorial or minimal example]

## Documentation

[Link to comprehensive docs]

## Community Support

[Forums, chat, issues]

## Commercial Support

[Enterprise options if applicable]

## Contributing

[Link to contributing guide]

## License

[License with link]
```

**When to use:** Enterprise tools, infrastructure projects

## Common Patterns Across Great READMEs

### Pattern: Badge Row

**Purpose:** Show project health and metadata at a glance

**Example:**
```markdown
[![Build Status](badge-url)](link)
[![Coverage](badge-url)](link)
[![Version](badge-url)](link)
[![License](badge-url)](link)
```

**Best practices:**
- Limit to 4-6 badges (avoid clutter)
- Use shields.io for consistency
- Link badges to relevant pages (build logs, coverage reports)
- Order: CI/CD status, coverage, version, license

### Pattern: Quick Start Section

**Purpose:** Get users running code in under 5 minutes

**Example:**
```markdown
## Quick Start

```bash
# Install
npm install package-name

# Use
import { feature } from 'package-name';
feature.doSomething();
```
```

**Best practices:**
- Complete working example
- Copy-paste ready code
- Minimal explanation (details in docs)
- Show most common use case

### Pattern: Feature Showcase

**Purpose:** Highlight key capabilities

**Example:**
```markdown
## Features

- ✨ **Feature 1** - Benefit explanation
- 🚀 **Feature 2** - Why it matters
- 🔒 **Feature 3** - Value proposition
```

**Best practices:**
- 3-7 features (most important)
- Lead with benefit, not technical detail
- Use icons/emojis sparingly
- Link to detailed docs for each

### Pattern: Progressive Disclosure

**Purpose:** Layer information from basic to advanced

**Example:**
```markdown
## Installation
[Simple install command]

## Quick Start
[Minimal example]

## Usage
[Common scenarios]

## Advanced Features
[Link to docs]

## API Reference
[Link to API docs]
```

**Best practices:**
- Start simple, get complex
- Link to external docs for details
- Keep README focused on getting started
- Use "Learn more" links liberally

### Pattern: Visual First

**Purpose:** Show, don't just tell

**Example:**
```markdown
# Project Name

![Demo](demo.gif)

One-line description
```

**Best practices:**
- Use animated GIFs for CLI tools
- Screenshots for GUI applications
- Keep image file sizes small (<1MB)
- Host images in repo or reliable CDN

## Anti-Patterns to Avoid

### ❌ Wall of Text

**Problem:** No visual breaks, intimidating blocks of text

**Solution:** Use headings, lists, code blocks to break up content

### ❌ Installation Novel

**Problem:** Pages of OS-specific installation instructions

**Solution:** Link to detailed installation guide, show primary method only

### ❌ Duplicate Documentation

**Problem:** README contains full API docs

**Solution:** Link to generated docs, keep README high-level

### ❌ Stale Screenshots

**Problem:** Images show outdated UI

**Solution:** Use text examples, or automate screenshot generation

### ❌ Assume Context

**Problem:** Doesn't explain what the project does

**Solution:** Always start with clear one-line description

### ❌ Missing License

**Problem:** No license information

**Solution:** Always include license section with SPDX identifier

## README Length Guidelines

**Minimal (50-100 lines):**
- Simple libraries
- Single-purpose tools
- Well-established projects with extensive docs

**Standard (100-300 lines):**
- Most projects
- Applications
- Frameworks

**Comprehensive (300-500 lines):**
- Complex tools
- Multi-component systems
- Projects without external docs

**Too Long (500+ lines):**
- Consider splitting into multiple docs
- Move API reference to separate file
- Link to wiki or documentation site

## Testing Your README

**Checklist:**
- [ ] Can a new user install and run in <5 minutes?
- [ ] Is the project's purpose clear in first paragraph?
- [ ] Are code examples copy-paste ready?
- [ ] Are links working and up-to-date?
- [ ] Is the license clearly stated?
- [ ] Does it render correctly on GitHub?

**Tools:**
- [readme-score](https://github.com/clayallsopp/readme-score) - README quality checker
- [standard-readme](https://github.com/RichardLitt/standard-readme) - README specification
- [awesome-readme](https://github.com/matiassingers/awesome-readme) - More examples

## Summary

Great READMEs share common traits:
1. **Clear purpose** - Understand what it does in 10 seconds
2. **Quick start** - Running code in 5 minutes
3. **Progressive depth** - Basic to advanced
4. **Link heavy** - Delegate details to docs
5. **Maintained** - Updated with project changes

Choose patterns based on your project type, but always prioritize clarity and quick user success.
