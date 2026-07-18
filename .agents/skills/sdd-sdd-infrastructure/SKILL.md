---
name: sdd:sdd-infrastructure
description: Core infrastructure for Specification-Driven Development workflow. Contains templates for specs/plans/tasks, bash scripts for feature management, and constitution framework for project governance. This skill powers the /sdd commands with reusable, versioned templates and automation.
---

# SDD Infrastructure

This skill provides the complete infrastructure for the Specification-Driven Development (SDD) workflow, including templates, scripts, and documentation that power all `/sdd:*` commands.

## Quick Reference

| Workflow Phase | Component | Location | Used By |
|----------------|-----------|----------|---------|
| **Constitution** | Constitution template | `assets/constitution/constitution-template.md` | `/sdd:constitution` |
| **Specify** | Spec template | `templates/spec-template.md` | `/sdd:specify` |
| **Specify** | Feature creation script | `scripts/create-new-feature.sh` | `/sdd:specify` |
| **Plan** | Plan template | `templates/plan-template.md` | `/sdd:plan` |
| **Plan** | Setup script | `scripts/setup-plan.sh` | `/sdd:plan` |
| **Tasks** | Tasks template | `templates/tasks-template.md` | `/sdd:tasks` |
| **Analyze** | Checklist template | `templates/checklist-template.md` | `/sdd:checklist` |
| **Implement** | Agent file template | `templates/agent-file-template.md` | `/sdd:implement` |
| **All phases** | Common utilities | `scripts/common.sh` | All scripts |
| **All phases** | Prerequisites check | `scripts/check-prerequisites.sh` | Multiple commands |
| **All phases** | Agent context sync | `scripts/update-agent-context.sh` | Multiple commands |

## Component Types

### Templates (5 files)

Templates define the structure for SDD artifacts. Each template includes:
- Purpose and usage context
- Required sections and fields
- Customization guidelines
- Examples

**Available templates:**
- `spec-template.md` - Feature specifications with user stories
- `plan-template.md` - Technical implementation plans
- `tasks-template.md` - Independent, testable user stories
- `checklist-template.md` - Quality validation checklists
- `agent-file-template.md` - AI agent context and guidelines

📖 See [Template Guide](references/template-guide.md) for detailed documentation.

### Scripts (5 files)

Bash scripts automate common SDD workflow tasks:
- `common.sh` - Shared utilities (feature paths, validation)
- `create-new-feature.sh` - Initialize new feature with branch and spec
- `setup-plan.sh` - Create plan from template
- `check-prerequisites.sh` - Validate feature readiness
- `update-agent-context.sh` - Sync AI agent configuration

**Scripts use `.sdd/` directory for runtime content:**
- `.sdd/codebase/` - Auto-generated codebase documentation
- `.sdd/memory/` - Project constitution and principles
- `.sdd/features/<name>/` - Feature-specific artifacts

📖 See [Script Guide](references/script-guide.md) for parameters and examples.

### Constitution Framework

The constitution defines project-specific principles and constraints:
- `assets/constitution/constitution-template.md` - Template for project constitution

Commands copy this to `.sdd/memory/constitution.md` and load it into Claude's memory for context-aware development.

📖 See [Constitution Guide](references/constitution-guide.md) for principles catalog.

## Architecture

**Plugin-managed (versioned):**
```
plugins/sdd/skills/sdd-infrastructure/
├── SKILL.md                           # This file
├── templates/                         # Reusable templates
├── scripts/                           # Automation scripts
├── assets/constitution/               # Constitution template
└── references/                        # Extended documentation
```

**User repository (runtime, gitignored):**
```
.sdd/
├── .gitignore                         # Ignore runtime content
├── codebase/                          # Auto-generated docs (from /map)
│   ├── STACK.md
│   ├── ARCHITECTURE.md
│   └── ...
├── memory/
│   └── constitution.md                # Project principles
└── features/<name>/                   # Feature artifacts
    ├── spec.md
    ├── plan.md
    └── tasks.md
```

## Usage Patterns

### From Commands

Commands invoke this skill's resources using `${CLAUDE_PLUGIN_ROOT}`:

```bash
# Resolve plugin root (once per command)
PLUGIN_ROOT=$(python3 /tmp/cpr.py sdd)

# Use templates
cat "$PLUGIN_ROOT"/skills/sdd-infrastructure/templates/spec-template.md

# Execute scripts
"$PLUGIN_ROOT"/skills/sdd-infrastructure/scripts/create-new-feature.sh --json "$ARGS"
```

### Local Overrides

Users can override templates by creating `.sdd/templates/<template-name>.md`. Commands check for local overrides before using plugin templates.

### Script Integration

Scripts source `common.sh` for shared utilities:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Now use shared functions
get_feature_paths "$FEATURE_NAME"
```

## Learn More

- **[Workflow Overview](references/workflow-overview.md)** - Complete SDD process from constitution to implementation
- **[Template Guide](references/template-guide.md)** - Deep dive on each template with customization examples
- **[Script Guide](references/script-guide.md)** - Script parameters, examples, and extension patterns
- **[Constitution Guide](references/constitution-guide.md)** - Creating and maintaining project constitutions

## Related Skills

- **sdd:code-mapping** - Generates codebase documentation (uses this skill's scripts)

## Version

This skill is part of SDD plugin v1.0.0 (migrated from `.specify` to `.sdd` architecture).
