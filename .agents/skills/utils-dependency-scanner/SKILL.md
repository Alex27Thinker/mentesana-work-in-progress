---
name: utils:dependency-scanner
description: This skill should be used when the user asks to "scan for dependencies", "find plugin dependencies", "generate extends-plugin.json", "discover plugin requirements", or invokes /utils:dependency-scanner. Scans plugin files for patterns indicating dependencies on other plugins or system tools.
version: 0.1.0
---

# Dependency Scanner

Scan plugins for patterns that indicate dependencies on other plugins or system tools.

## Usage

- `/utils:dependency-scanner` - Scan all enabled plugins
- `/utils:dependency-scanner --plugin <name>` - Scan specific plugin
- `/utils:dependency-scanner --marketplace <name>` - Scan all plugins from marketplace
- `/utils:dependency-scanner --plugin-dir <path>` - Scan local plugin directory
- `/utils:dependency-scanner --marketplace-dir <path>` - Scan local marketplace directory

## Workflow

### Step 1: Generate CPR Resolver

```bash
Skill(skill="utils:find-claude-plugin-root")
```

### Step 2: Run the Scanner Script

```bash
PLUGIN_ROOT=$(python3 /tmp/cpr.py utils)
python3 "$PLUGIN_ROOT/scripts/dependency-scanner.py" [FLAGS] > /tmp/dependency-scan.json
```

### Step 3: Read and Interpret Matches

Read `/tmp/dependency-scan.json` and analyze the matches. The script returns raw pattern matches - the analysis process involves:

1. **Filter internal references**: If Skill A in plugin X references Skill B also in plugin X, that's NOT a dependency
2. **Group by source**: Combine `/foo:spam`, `/foo:ham`, `/foo:eggs` into one "foo" dependency
3. **Identify source**: For each group, determine which plugin/marketplace provides it
4. **Classify**: Determine if it's a plugin dependency or system dependency

### Step 4: Determine Dependency Sources

**For plugin dependencies:**
- Search installed plugins for matching skill/command names
- Check marketplace plugins if not found in installed
- If skill is `/foo:bar`, look for plugin named "foo"
- If skill is `/bar` (no prefix), search all available skills

**For system dependencies:**
- Run `which <command>` to check if installed
- Run `<command> --version` to get version
- Do web search for installation instructions if needed

### Step 5: Batch Confirmations with User

For EACH dependency group, use AskUserQuestion to confirm. BATCH similar findings:

```
Found 3 skills (spam, ham, eggs) from foo@bar-marketplace.
Current installed version: 1.2.3

Add to dependencies?
- Yes, require ^1.2.0 (Recommended)
- Yes, require ^1.0.0
- Yes, as optional dependency
- No, skip this
```

For system dependencies:

```
Found system command: gh (used 5 times)
Currently installed: 2.45.0

Add to systemDependencies?
- Yes, require >=2.0.0 (Recommended)
- Yes, require >=2.45.0 (exact current)
- Yes, as optional system dependency
- No, skip this
```

### Step 6: Build extends-plugin.json

After all confirmations, build the final JSON:

```json
{
  "dependencies": {
    "foo": "^1.2.0"
  },
  "optionalDependencies": {},
  "systemDependencies": {
    "gh": ">=2.0.0"
  },
  "optionalSystemDependencies": {}
}
```

### Step 7: Confirm and Write

Show the final `extends-plugin.json` to the user and ask for confirmation before writing.

Write to: `<plugin-path>/.claude-plugin/extends-plugin.json`

## Key Principles

- **Script does pattern matching only** - returns potential matches
- **LLM interprets** - groups, filters, identifies sources
- **User confirms everything** - never auto-write
- **Batch similar findings** - don't ask 3 times for same plugin
- **False positives are OK** - better than missing dependencies

## Additional Resources

### Scripts
- `$PLUGIN_ROOT/scripts/dependency-scanner.py` - Pattern matching scanner
