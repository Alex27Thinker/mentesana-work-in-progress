---
name: readme-and-co:using-local-config
version: "1.0"
description: Configure readme-and-co plugin with project-specific defaults using .claude/readme-and-co.local.md
---

# Using Local Configuration

The readme-and-co plugin supports project-specific configuration through a local config file. This allows you to set default values that apply to your project without repeating them in every command.

## Setup

First, ensure plugin path resolution works:
```
Skill(skill="utils:find-claude-plugin-root")
```

## Quick Start

1. **Copy the example config**:
   ```bash
   mkdir -p .claude
   PLUGIN_ROOT=$(python3 /tmp/cpr.py readme-and-co)
   cp "$PLUGIN_ROOT/examples/readme-and-co.local.md" .claude/readme-and-co.local.md
   ```

2. **Edit the config** to match your project:
   ```yaml
   ---
   defaults:
     project_name: my-awesome-app
     author_name: Your Name
     license: MIT
   badges:
     enabled: true
     style: flat-square
   ---
   ```

3. **Use the plugin** - defaults are automatically loaded:
   ```bash
   # project_name and license come from config
   python scripts/render_template.py --template templates/README/full/README-MINIMAL.template.md --vars '{"description":"Cool app"}' --output README.md
   ```

## Configuration File Format

The config file must be located at `.claude/readme-and-co.local.md` and use YAML frontmatter:

```yaml
---
defaults:
  project_name: value
  key: value
badges:
  enabled: true
---
# Optional markdown content below
```

## Configuration Priority

Values are merged with the following priority (highest to lowest):

1. **CLI arguments** (`--vars` flag) - Always wins
2. **Local config** (`.claude/readme-and-co.local.md`)
3. **Auto-detected** (from git, package.json, etc.)
4. **Built-in defaults**

### Example

Config file:
```yaml
---
defaults:
  author_name: Jane Doe
  license: MIT
---
```

Command:
```bash
python scripts/render_template.py --vars '{"license":"Apache-2.0"}' ...
```

Result: `license=Apache-2.0` (CLI overrides config), `author_name=Jane Doe` (from config)

## Available Configuration Options

### `defaults` - Template Variables

Default values for template variables:

```yaml
defaults:
  # Project metadata
  project_name: my-project
  description: Short description

  # Author info
  author_name: Your Name
  author_email: you@example.com

  # License
  license: MIT

  # Repository
  repo_url: https://github.com/user/repo
```

### `badges` - Badge Generation

Control badge auto-generation:

```yaml
badges:
  enabled: true
  style: flat-square  # flat, flat-square, plastic, for-the-badge
  include:
    - license
    - ci-status
    - language-version
    - npm-version
    - coverage
```

### `templates` - Template Preferences

Control which template variants to use:

```yaml
templates:
  readme_variant: standard  # minimal, standard, comprehensive
```

### `hooks` - Documentation Hooks

Control when to suggest documentation updates:

```yaml
hooks:
  doc_updates:
    enabled: true  # Set to false to disable suggestions
```

## Use Cases

### Single Developer Projects

```yaml
---
defaults:
  author_name: Jane Developer
  author_email: jane@dev.com
  license: MIT
badges:
  enabled: true
  style: flat-square
---
```

### Team Projects

```yaml
---
defaults:
  # Don't set author_name - will be auto-detected from git
  license: Apache-2.0
  project_name: team-project
badges:
  enabled: true
  include:
    - license
    - build-status
    - coverage
templates:
  readme_variant: comprehensive
---
```

### Open Source Projects

```yaml
---
defaults:
  license: MIT
badges:
  enabled: true
  style: for-the-badge
  include:
    - license
    - ci-status
    - npm-version
    - downloads
    - contributors
templates:
  readme_variant: comprehensive
hooks:
  doc_updates:
    enabled: true
---
```

## Tips

1. **Version control**: Commit `.claude/readme-and-co.local.md` so your team shares the same defaults
2. **Privacy**: The config file is for defaults, not secrets. Don't include API keys or passwords
3. **Override when needed**: Use CLI args to override config for one-off changes
4. **Validation**: The plugin validates the config file format and shows warnings for invalid YAML

## Troubleshooting

### Config not loading

Check:
- File is at `.claude/readme-and-co.local.md` (relative to current directory)
- YAML frontmatter starts and ends with `---` on their own lines
- YAML syntax is valid (proper indentation, no tabs)

### Values not being used

Check priority:
- CLI arguments override config
- Use `--vars '{}'` to ensure config defaults are used
- Check stderr output for "Loaded N default(s)" message

### Invalid YAML

The plugin uses a simple YAML parser. If you have complex YAML:
- Avoid advanced features (anchors, multi-line strings)
- Use simple key: value pairs
- For lists, use `- item` syntax with proper indentation

## Example Workflow

1. **Setup** (once per project):
   ```bash
   mkdir -p .claude
   PLUGIN_ROOT=$(python3 /tmp/cpr.py readme-and-co)
   cp "$PLUGIN_ROOT/examples/readme-and-co.local.md" .claude/readme-and-co.local.md
   # Edit .claude/readme-and-co.local.md
   git add .claude/readme-and-co.local.md
   git commit -m "Add readme-and-co config"
   ```

2. **Use** (ongoing):
   ```bash
   # Defaults from config, only specify what changes
   python scripts/render_template.py \
     --template templates/README/full/README-STANDARD.template.md \
     --vars '{"description":"New feature added"}' \
     --output README.md
   ```

3. **Override** (when needed):
   ```bash
   # Different license for this one file
   python scripts/populate_license.py \
     --license Apache-2.0 \
     --output LICENSE-APACHE
   ```
