---
name: utils:dependency-checker
description: This skill should be used when the user asks to "check dependencies", "verify plugin requirements", "what plugins am I missing", "validate plugin dependencies", or invokes /utils:dependency-checker. Validates declared dependencies in extends-plugin.json files against installed and enabled plugins.
version: 0.1.0
---

# Dependency Checker

Validate dependencies declared in `extends-plugin.json` files against installed and enabled plugins.

## Usage

- `/utils:dependency-checker` - Check all enabled plugins
- `/utils:dependency-checker --installed` - Check all installed plugins
- `/utils:dependency-checker --all` - Check all plugins in all marketplaces
- `/utils:dependency-checker --plugin <name>` - Check specific plugin

## Workflow

### Step 1: Determine Flags

Parse the user's request to determine appropriate flags:
- Default (no args): Check enabled plugins only
- "check installed": Use `--installed`
- "check all": Use `--all`
- "check <plugin-name>": Use `--plugin <name>`

### Step 2: Generate CPR Resolver

First, generate the Claude Plugin Root resolver:

```bash
# Invoke the find-claude-plugin-root skill to create /tmp/cpr.py
Skill(skill="utils:find-claude-plugin-root")
```

### Step 3: Execute Scripts

```bash
# Get plugin root
PLUGIN_ROOT=$(python3 /tmp/cpr.py utils)

# Run dependency checker
python3 "$PLUGIN_ROOT/scripts/dependency-checker.py" [FLAGS] > /tmp/dependency-check.json

# Render tables
python3 "$PLUGIN_ROOT/scripts/table-renderer.py" /tmp/dependency-check.json

# Show resolution steps
python3 "$PLUGIN_ROOT/scripts/resolution-steps.py" /tmp/dependency-check.json
```

### Step 4: Interpret Results

After displaying tables and resolution steps, provide a summary including:
- Total dependencies checked
- Satisfied vs unsatisfied count
- Priority order for fixes (required before optional)
- Additional context from the JSON data

### Error Handling

If scripts fail:
1. Verify Python 3 is available
2. Confirm plugin paths exist
3. Check extends-plugin.json for valid JSON syntax

## Additional Resources

### Scripts
- `$PLUGIN_ROOT/scripts/dependency-checker.py` - Core validation logic
- `$PLUGIN_ROOT/scripts/table-renderer.py` - ASCII table formatting
- `$PLUGIN_ROOT/scripts/resolution-steps.py` - Resolution guidance
