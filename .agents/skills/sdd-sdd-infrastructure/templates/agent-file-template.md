<!--
==============================================================================
AGENT FILE TEMPLATE
==============================================================================

PURPOSE:
  Auto-generates development guidelines for AI agents based on all active
  feature plans. Keeps agent context synchronized with current tech stack
  and project structure.

WHEN USED:
  - By /sdd:implement command's update-agent-context.sh script
  - Automatically regenerated when plan.md files change
  - Ensures agents have current project context

CUSTOMIZATION:
  - This template is largely auto-generated from plan.md files
  - Manual additions can be preserved in marked sections
  - Add project-specific agent guidance sections
  - Override by creating .sdd/templates/agent-file-template.md in your repo

LEARN MORE:
  See plugins/sdd/skills/sdd-infrastructure/references/template-guide.md
  for detailed documentation and examples.

==============================================================================
-->

# [PROJECT NAME] Development Guidelines

Auto-generated from all feature plans. Last updated: [DATE]

## Active Technologies

[EXTRACTED FROM ALL PLAN.MD FILES]

## Project Structure

```text
[ACTUAL STRUCTURE FROM PLANS]
```

## Commands

[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES]

## Code Style

[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE]

## Recent Changes

[LAST 3 FEATURES AND WHAT THEY ADDED]

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
