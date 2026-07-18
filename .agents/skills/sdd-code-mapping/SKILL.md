---
name: sdd:code-mapping
description: Provides templates and analysis guidance for mapping codebases into specialized documentation. Used by the sdd:code-mapper agent to generate 8 focused codebase documents.
---

# Codebase Mapping Skill

This skill provides templates and analysis guidance for generating comprehensive codebase documentation. It supports four focus areas, each producing two specialized documents.

## Focus Area Routing

When invoked, check the `focus` parameter to determine which templates and analysis guides to use:

| Focus Area | Templates to Use | Analysis Guide |
|------------|------------------|----------------|
| `tech` | stack.md, integrations.md | tech-analysis.md |
| `arch` | architecture.md, structure.md | arch-analysis.md |
| `conventions` | conventions.md, testing.md | conventions-analysis.md |
| `security` | security.md, concerns.md | security-analysis.md |

## Output Location

All documents are written to: `.sdd/codebase/`

Files use UPPERCASE naming: `STACK.md`, `INTEGRATIONS.md`, `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `SECURITY.md`, `CONCERNS.md`

## Document Quality Requirements

Each generated document MUST:

1. **Be Actionable**: Content should guide future development decisions
2. **Include File Paths**: Reference actual paths in backticks for navigation (e.g., `src/api/auth.py`)
3. **Be Current**: Reflect the actual state of the codebase at time of generation
4. **Focus on What Executes**: Capture only what runs (languages, runtime, frameworks, dependencies)
5. **Limit Dependencies**: Document 5-10 most important dependencies, not every entry
6. **Specify Versions**: Only when compatibility matters
7. **Use Prescriptive Language**: Guide future code generation with clear patterns

## Exclusions by Document

Content belongs in specific documents - avoid duplication:

| If Content Is About... | Put It In... | NOT In... |
|------------------------|--------------|-----------|
| Languages, frameworks, versions | STACK.md | ARCHITECTURE.md |
| External APIs, databases, auth services | INTEGRATIONS.md | STACK.md |
| System design, patterns, data flow | ARCHITECTURE.md | STRUCTURE.md |
| Directory layout, module boundaries | STRUCTURE.md | ARCHITECTURE.md |
| Code style, naming, error handling | CONVENTIONS.md | TESTING.md |
| Test strategy, frameworks, patterns | TESTING.md | CONVENTIONS.md |
| Auth, authorization, vulnerabilities | SECURITY.md | CONCERNS.md |
| Tech debt, risks, TODOs | CONCERNS.md | Any other doc |

## How to Use This Skill

1. **Read the focus-specific analysis guide** from `references/focus-guides/{focus}-analysis.md`
2. **Load the relevant templates** from `references/templates/`
3. **Analyze the codebase** following the analysis guide instructions
4. **Fill templates** with discovered information
5. **Write documents** directly to `.sdd/codebase/`
6. **Return confirmation only**: file paths + line counts

## Template Files

Templates are located in `references/templates/`:
- `stack.md` - Languages, frameworks, dependencies
- `integrations.md` - External services, APIs, data stores
- `architecture.md` - System design, patterns, data flow
- `structure.md` - Directory layout, module boundaries
- `conventions.md` - Code style, naming, patterns
- `testing.md` - Test strategy, frameworks, patterns
- `security.md` - Auth, authorization, vulnerabilities
- `concerns.md` - Tech debt, risks, known issues

## Focus Guides

Analysis guides are located in `references/focus-guides/`:
- `tech-analysis.md` - How to analyze tech stack and integrations
- `arch-analysis.md` - How to analyze architecture and structure
- `conventions-analysis.md` - How to analyze conventions and testing
- `security-analysis.md` - How to analyze security and concerns
