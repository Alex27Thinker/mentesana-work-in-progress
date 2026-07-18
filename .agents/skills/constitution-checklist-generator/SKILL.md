---
name: constitution:checklist-generator
description: |
  Distill CONSTITUTION.md into 6-12 actionable checklist items with semantic deduplication.
  Use when user asks to "generate checklist", "create action items from constitution",
  or after amendments to regenerate verification tasks.
---

# Constitution Checklist Generator

You are generating an **Implementation Checklist** from a project's CONSTITUTION.md file.

## Goal

Distill constitutional principles into 6-12 actionable, verifiable checkbox items that engineers can use to validate their work complies with project governance.

## Workflow

### 1. Locate Constitution

Search for CONSTITUTION.md:
1. Current directory
2. Parent directories (walk up tree)
3. Git root if available

If not found: Error with "No CONSTITUTION.md found. Run constitution:writer first."

### 2. Extract Principles

Parse CONSTITUTION.md:
- Identify `##` sections (principles)
- Extract core requirements from each section
- Ignore preamble, changelog, footer

### 3. Distill to Checkboxes

**Target:** 6-12 items total (fewer is better)

**Guidelines:**
- Combine related sub-rules into single checkbox
- Make specific and verifiable (not "Write good code")
- Prioritize NON-NEGOTIABLE items first
- Use active voice ("Ensure X", "Verify Y", "Document Z")

**Example Transformations:**
- Principle: "Single Responsibility - Each function does one thing"
  → Checkbox: `[ ] Functions have single, clear purpose (check for multi-responsibility)`

- Principle: "No Silent Failures - Always log errors, never empty catch"
  → Checkbox: `[ ] Error handlers log context (no empty catch/except blocks)`

- Principle: "Test Coverage - 80% minimum, integration tests for APIs"
  → Checkbox: `[ ] Test coverage ≥80% with integration tests for all API endpoints`

### 4. Semantic Deduplication (If Existing Checklist)

When `## Implementation Checklist` section exists:

**Algorithm:**
1. Parse existing checklist items (strip `[ ]` prefixes)
2. Parse newly generated items
3. For each existing item:
   - Find semantic match in new items (keyword similarity)
   - If match found: **KEEP existing wording** (preserve customization)
   - If no match: **REMOVE** (outdated principle)
4. For each new item:
   - If not covered by kept items: **ADD**
   - If similar to kept item: Compare specificity
     - Keep more specific version
     - Log decision: "Kept existing item (more specific)"

**Similarity Scoring:**
- Extract keywords (lowercase, remove common words)
- Count shared keywords
- Threshold: ≥50% shared keywords = similar

**Specificity Comparison:**
- Count specific technical terms (e.g., ">=80%", "API endpoints", "conventional format")
- More specific terms = higher specificity
- Tie: Keep existing (preserves user customization)

**Example:**
```
Existing: "Use conventional commits"
New:      "All commits follow conventional format"
→ KEEP existing (semantic match, similar specificity)

Existing: "Tests required for new features"
New:      "Test coverage ≥80% with integration tests for all API endpoints"
→ REPLACE with new (new is more specific)
```

### 5. Append or Update Checklist

**If no existing checklist:**
Append to end of CONSTITUTION.md:

```markdown

---

## Implementation Checklist

Before considering work complete, verify:

- [ ] [Item 1]
- [ ] [Item 2]
- [ ] [Item 3]
- [ ] [Item 4]
- [ ] [Item 5]
- [ ] [Item 6]
```

**If existing checklist:**
Replace entire `## Implementation Checklist` section with deduplicated version.

**Preserve:**
- Checkbox format: `- [ ]` (unchecked)
- Ordering: Most critical first
- Section header: `## Implementation Checklist`

### 6. Report

Output summary:
```
✓ Generated checklist from CONSTITUTION.md
  - [N] items total
  - [K] kept from existing checklist
  - [R] removed (outdated)
  - [A] added (new principles)

Merge decisions:
  - "Use conventional commits" KEPT (matches "All commits follow...")
  - "Tests required" REPLACED (new version more specific)
  - "Document public APIs" ADDED (new principle)
```

## Edge Cases

**No principles found:** Error with "CONSTITUTION.md has no ## sections"

**Constitution too short:** If <3 principles, generate 3-5 items (don't pad artificially)

**Uncertain similarity:** When in doubt, KEEP both items (err on side of completeness)

**User customization:** Always preserve existing wording when semantically equivalent

## Anti-Patterns

❌ **Don't:**
- Generate vague items like "Write quality code"
- Create >15 items (checkbox fatigue)
- Remove existing items without semantic analysis
- Duplicate items with slightly different wording
- Change existing wording when semantic match found

✅ **Do:**
- Make items specific and verifiable
- Combine related sub-rules
- Preserve user customizations
- Log merge decisions clearly
- Keep count between 6-12 items
