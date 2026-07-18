---
name: constitution:amend
description: |
  Amend project constitution with semantic versioning and changelog management.
  Use when user asks to "amend constitution", "update constitution version",
  "add principle", or "modify governance rules". Automatically regenerates checklist.
---

# Constitution Amendment Skill

You are amending a project's CONSTITUTION.md with version tracking.

## Goal

Update constitutional principles with semantic versioning, maintain changelog (newest first), and automatically regenerate the implementation checklist.

## Workflow

### 1. Find Constitution & Parse Version

Search for CONSTITUTION.md:
1. Current directory
2. Parent directories
3. Git root

Parse version from footer:
```
*Version: X.Y.Z*
```

If not found: Assume `1.0.0`

### 2. Gather Amendment Details

**Interactive prompts:**

**Prompt 1: Amendment Type**
```
What type of amendment?

1. MAJOR - Breaking change (removes/fundamentally changes core principles)
2. MINOR - Additive change (adds new principles)
3. PATCH - Clarification (typo fixes, wording improvements)

Choice [1-3]:
```

**Prompt 2: Change Description**
```
Describe the changes (2-5 sentences):
```

**Prompt 3: Migration Notes** (skip for PATCH)
```
Migration guidance for existing code (what needs to change?):
```

**Prompt 4: Rationale**
```
Why is this amendment necessary?
```

### 3. Increment Version

**Rules:**
- **MAJOR**: X+1.0.0 (e.g., 2.3.1 → 3.0.0)
  - Removes principles
  - Fundamentally changes core requirements
  - Example: "Remove TDD requirement"

- **MINOR**: X.Y+1.0 (e.g., 2.3.1 → 2.4.0)
  - Adds new principles
  - Expands requirements
  - Example: "Add security audit requirement"

- **PATCH**: X.Y.Z+1 (e.g., 2.3.1 → 2.3.2)
  - Clarifies existing principles
  - Fixes typos
  - Example: "Clarify test coverage metric"

### 4. Render Amendment Entry

Load template from:
```
${CLAUDE_PLUGIN_ROOT}/plugins/constitution/skills/amend/templates/amendment.template.md
```

Replace placeholders:
- `{{new_version}}` → Calculated version (e.g., "2.4.0")
- `{{amendment_date}}` → Today's date (YYYY-MM-DD format)
- `{{amendment_type}}` → MAJOR/MINOR/PATCH
- `{{change_description}}` → User input
- `{{migration_notes}}` → User input (or "N/A" for PATCH)
- `{{rationale}}` → User input

**Rendering:** Simple string replacement (no external dependencies)

### 5. Update Changelog

**Find or create changelog section:**

Look for:
```markdown
## Changelog
```

If not found, insert after preamble (before first `##` principle):
```markdown

## Changelog

### Version {{new_version}} - {{amendment_date}}

**Type**: {{amendment_type}}

**Changes**:
{{change_description}}

**Migration Notes**:
{{migration_notes}}

**Rationale**:
{{rationale}}

---
```

**If found:**
Insert rendered entry **immediately after** `## Changelog` header (newest first):

```markdown
## Changelog

### Version 2.4.0 - 2026-01-25
...

### Version 2.3.0 - 2026-01-20
...
```

### 6. Update Footer

Find footer (last 3 lines typically):
```markdown
---

*Last amended: YYYY-MM-DD*
*Version: X.Y.Z*
```

Update:
- `Last amended:` → Today's date
- `Version:` → New version

If no footer exists, append:
```markdown

---

*Last amended: 2026-01-25*
*Version: 2.4.0*
```

### 7. Regenerate Checklist

**Automatically invoke checklist generator:**

Output instruction:
```
Amendment complete. Now regenerating checklist to reflect updated principles...
```

Then instruct Claude:
```
Please run the constitution:checklist-generator skill to update the implementation checklist based on the amended constitution.
```

(Skills cannot directly invoke other skills, so this is an instruction for Claude to execute next)

### 8. Report Summary

Output:
```
✓ Constitution amended successfully

Version: 1.2.3 → 2.0.0
Type: MAJOR
Date: 2026-01-25

Changelog entry added (3 total entries)
Footer updated
Checklist regeneration requested

⚠️  MAJOR version change detected!
Review existing code for compliance with updated principles.

Migration notes:
[User's migration guidance]
```

## Edge Cases

**No constitution found:** Error with "Run constitution:writer first"

**Invalid version format:** Assume 1.0.0 and add warning

**Changelog placement:** If unclear structure, add section at end (before footer)

**Empty migration notes:** Use "N/A" for PATCH, require for MAJOR/MINOR

## Version Decision Tree

```
Amendment removes principles? → MAJOR
Amendment changes core requirements fundamentally? → MAJOR
Amendment adds new principles? → MINOR
Amendment expands scope? → MINOR
Amendment clarifies existing wording? → PATCH
Amendment fixes typos? → PATCH
```

**When uncertain:** Ask user to confirm type before proceeding

## Anti-Patterns

❌ **Don't:**
- Manually edit checklist (let generator handle it)
- Put oldest changelog entry first (newest on top)
- Skip migration notes for breaking changes
- Use PATCH for additive changes
- Forget to update footer

✅ **Do:**
- Always regenerate checklist after amendment
- Maintain newest-first changelog order
- Provide clear migration guidance
- Use semantic versioning correctly
- Commit constitution and checklist together
