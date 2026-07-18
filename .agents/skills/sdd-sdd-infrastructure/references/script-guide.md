# Script Guide

Comprehensive documentation for all SDD workflow automation scripts including parameters, examples, and extension patterns.

## Script Index

1. [common.sh](#commonsh) - Shared utilities
2. [create-new-feature.sh](#create-new-featuresh) - Feature initialization
3. [setup-plan.sh](#setup-plansh) - Plan setup
4. [check-prerequisites.sh](#check-prerequisitessh) - Validation
5. [update-agent-context.sh](#update-agent-contextsh) - Agent sync

---

## common.sh

**Purpose**: Shared functions and utilities for all SDD scripts

**Usage**: Sourced by other scripts (not called directly)

### Key Functions

#### `get_repo_root()`
Returns repository root directory (git or non-git repos)

```bash
REPO_ROOT=$(get_repo_root)
```

#### `get_current_branch()`
Returns current feature branch or name

Checks in order:
1. `$SDD_FEATURE` environment variable
2. Git current branch
3. Latest feature directory (non-git repos)
4. "main" (fallback)

```bash
BRANCH=$(get_current_branch)
```

#### `get_feature_paths()`
Outputs all feature-related paths as shell variables

```bash
eval $(get_feature_paths)
# Now have: $REPO_ROOT, $CURRENT_BRANCH, $FEATURE_DIR, etc.
```

Output variables:
- `REPO_ROOT` - Repository root
- `CURRENT_BRANCH` - Current feature branch
- `HAS_GIT` - "true" or "false"
- `FEATURE_DIR` - Feature spec directory
- `FEATURE_SPEC` - Path to spec.md
- `IMPL_PLAN` - Path to plan.md
- `TASKS` - Path to tasks.md
- `RESEARCH` - Path to research.md
- `DATA_MODEL` - Path to data-model.md
- `QUICKSTART` - Path to quickstart.md
- `CONTRACTS_DIR` - Path to contracts directory

#### `check_feature_branch(branch, has_git)`
Validates feature branch naming (###-feature-name format)

```bash
check_feature_branch "$BRANCH" "$HAS_GIT" || exit 1
```

#### `has_git()`
Checks if git is available

```bash
if has_git; then
    # Git operations
fi
```

### Environment Variables

**`SDD_FEATURE`**: Override automatic feature detection

```bash
export SDD_FEATURE="001-my-feature"
./some-script.sh
```

Useful for:
- Non-git repositories
- CI/CD environments
- Testing scripts

---

## create-new-feature.sh

**Purpose**: Creates new feature branches and specification files

**Used by**: `/sdd:specify` command

### Usage

```bash
./create-new-feature.sh [OPTIONS] <feature_description>
```

### Options

```
--json                Output in JSON format
--short-name <name>   Custom short name (2-4 words) for branch
--number N            Specify branch number manually
--help, -h            Show help message
```

### Examples

**Basic usage**:
```bash
./create-new-feature.sh "Add user authentication system"
# Creates: 001-user-authentication-system
#          specs/001-user-authentication-system/spec.md
```

**Custom short name**:
```bash
./create-new-feature.sh "Implement OAuth2 integration for API" --short-name "oauth-api"
# Creates: 002-oauth-api
```

**Specific number**:
```bash
./create-new-feature.sh "Add caching layer" --number 10
# Creates: 010-caching-layer
```

**JSON output**:
```bash
./create-new-feature.sh --json "Add feature"
# {"BRANCH_NAME":"003-add-feature","SPEC_FILE":"/path/to/spec.md","FEATURE_NUM":"003"}
```

### Behavior

**Branch numbering**:
- Auto-detects highest existing number from:
  - All git branches (local and remote)
  - All specs directories
- Increments by 1
- Can be overridden with `--number`

**Branch naming**:
- Filters stop words (the, a, to, etc.)
- Keeps meaningful words (3+ chars)
- Limits to 3-4 words
- Enforces 244-byte limit (GitHub restriction)

**Non-git repos**:
- Still creates spec directory structure
- Skips git branch creation
- Shows warnings but continues

### Output

**Standard mode**:
```
BRANCH_NAME: 001-feature-name
SPEC_FILE: /path/to/specs/001-feature-name/spec.md
FEATURE_NUM: 001
SDD_FEATURE environment variable set to: 001-feature-name
```

**JSON mode**:
```json
{"BRANCH_NAME":"001-feature-name","SPEC_FILE":"/path/to/spec.md","FEATURE_NUM":"001"}
```

### Environment Variables Set

- `SDD_FEATURE` - Feature branch name (for current session)

---

## setup-plan.sh

**Purpose**: Initializes implementation plan from template

**Used by**: `/sdd:plan` command

### Usage

```bash
./setup-plan.sh [--json]
```

### Options

```
--json    Output results in JSON format
--help    Show help message
```

### Examples

**Basic usage**:
```bash
./setup-plan.sh
# Creates: specs/001-feature/plan.md from template
```

**JSON output**:
```bash
./setup-plan.sh --json
# {"FEATURE_SPEC":"/path/spec.md","IMPL_PLAN":"/path/plan.md",...}
```

### Behavior

- Must be run from feature branch (or with `SDD_FEATURE` set)
- Copies `plan-template.md` to feature directory
- Creates feature directory if missing
- Validates feature branch format (###-*)

### Output

**Standard mode**:
```
FEATURE_SPEC: /path/to/specs/001-feature/spec.md
IMPL_PLAN: /path/to/specs/001-feature/plan.md
SPECS_DIR: /path/to/specs/001-feature
BRANCH: 001-feature
HAS_GIT: true
```

**JSON mode**:
```json
{
  "FEATURE_SPEC":"/path/spec.md",
  "IMPL_PLAN":"/path/plan.md",
  "SPECS_DIR":"/path/specs/001-feature",
  "BRANCH":"001-feature",
  "HAS_GIT":"true"
}
```

---

## check-prerequisites.sh

**Purpose**: Validates feature structure and documents before workflow phases

**Used by**: `/sdd:tasks`, `/sdd:implement` commands

### Usage

```bash
./check-prerequisites.sh [OPTIONS]
```

### Options

```
--json              Output in JSON format
--require-tasks     Require tasks.md to exist (for implementation)
--include-tasks     Include tasks.md in AVAILABLE_DOCS list
--paths-only        Only output paths (no validation)
--help, -h          Show help message
```

### Examples

**Check task prerequisites** (plan.md required):
```bash
./check-prerequisites.sh --json
# Validates plan.md exists, lists available docs
```

**Check implementation prerequisites** (plan.md + tasks.md required):
```bash
./check-prerequisites.sh --json --require-tasks --include-tasks
# Validates plan.md AND tasks.md exist
```

**Get paths only** (no validation):
```bash
./check-prerequisites.sh --paths-only
# Just outputs feature paths, no file checking
```

### Behavior

**Validation checks**:
1. Feature directory exists
2. plan.md exists (always required)
3. tasks.md exists (if `--require-tasks`)

**Optional docs detected**:
- research.md
- data-model.md
- contracts/ (if has files)
- quickstart.md
- tasks.md (if `--include-tasks`)

### Output

**Standard mode**:
```
FEATURE_DIR:/path/to/specs/001-feature
AVAILABLE_DOCS:
  ✓ research.md
  ✓ data-model.md
  ✓ contracts/
  ✗ quickstart.md
```

**JSON mode**:
```json
{
  "FEATURE_DIR":"/path/to/specs/001-feature",
  "AVAILABLE_DOCS":["research.md","data-model.md","contracts/"]
}
```

**Paths-only mode**:
```
REPO_ROOT: /path/to/repo
BRANCH: 001-feature
FEATURE_DIR: /path/to/specs/001-feature
FEATURE_SPEC: /path/to/specs/001-feature/spec.md
IMPL_PLAN: /path/to/specs/001-feature/plan.md
TASKS: /path/to/specs/001-feature/tasks.md
```

---

## update-agent-context.sh

**Purpose**: Synchronizes AI agent context files with project information from plans

**Used by**: `/sdd:implement` command

### Usage

```bash
./update-agent-context.sh [agent_type]
```

### Agent Types

```
claude          Claude Code (CLAUDE.md)
gemini          Gemini CLI (GEMINI.md)
copilot         GitHub Copilot (.github/agents/copilot-instructions.md)
cursor-agent    Cursor IDE (.cursor/rules/sdd-rules.mdc)
qwen            Qwen Code (QWEN.md)
windsurf        Windsurf (.windsurf/rules/sdd-rules.md)
kilocode        Kilo Code (.kilocode/rules/sdd-rules.md)
auggie          Auggie CLI (.augment/rules/sdd-rules.md)
roo             Roo Code (.roo/rules/sdd-rules.md)
codebuddy       CodeBuddy CLI (CODEBUDDY.md)
qoder           Qoder CLI (QODER.md)
shai            SHAI (SHAI.md)
q               Amazon Q Developer CLI (AGENTS.md)

[no argument]   Update all existing agent files
```

### Examples

**Update all agent files**:
```bash
./update-agent-context.sh
# Finds and updates all existing agent files
# Creates CLAUDE.md if no agent files exist
```

**Update specific agent**:
```bash
./update-agent-context.sh claude
# Updates only CLAUDE.md
```

### Behavior

**Data extraction** from plan.md:
- Language/Version
- Primary Dependencies
- Storage
- Project Type

**File operations**:
- Creates new agent file if missing (from template)
- Updates existing file's Active Technologies section
- Updates Recent Changes (keeps last 2, adds new)
- Updates timestamp
- Preserves manual additions (between comment markers)

**New file creation**:
- Uses `agent-file-template.md`
- Substitutes project info
- Creates parent directories if needed

**Existing file update**:
- Adds new technologies if not present
- Adds recent change entry
- Maintains last 2 previous changes
- Updates "Last updated" date

### Output

```
INFO: Updating claude context file: /path/to/CLAUDE.md
INFO: Found language: Python 3.11
INFO: Found framework: FastAPI
✓ Updated existing Claude Code context file

Summary of changes:
  - Added language: Python 3.11
  - Added framework: FastAPI
```

### Environment Variables

**`SDD_FEATURE`**: Override feature detection (like other scripts)

---

## Extension Patterns

### Creating Custom Scripts

All scripts follow this pattern:

```bash
#!/usr/bin/env bash
set -e  # Exit on error

# Load common utilities
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get feature paths
eval $(get_feature_paths)

# Validate (optional)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Your logic here
...
```

### Error Handling

```bash
# Check file exists before reading
if [[ ! -f "$IMPL_PLAN" ]]; then
    echo "ERROR: plan.md not found" >&2
    exit 1
fi

# Check directory exists before writing
if [[ ! -d "$FEATURE_DIR" ]]; then
    mkdir -p "$FEATURE_DIR" || {
        echo "ERROR: Failed to create directory" >&2
        exit 1
    }
fi
```

### JSON Output Pattern

```bash
JSON_MODE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
    esac
done

# Output
if $JSON_MODE; then
    printf '{"KEY":"%s"}\n' "$VALUE"
else
    echo "KEY: $VALUE"
fi
```

### Template Usage

Scripts find templates relative to their location:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/template-name.md"

if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$TARGET"
else
    echo "Warning: Template not found" >&2
fi
```

### Non-Git Repository Support

```bash
if has_git; then
    # Git operations
    git checkout -b "$BRANCH_NAME"
else
    # Non-git fallback
    echo "Warning: Git not available, skipping branch creation" >&2
fi
```

## Troubleshooting

### Script not finding feature

**Problem**: "Unable to determine current feature"

**Solutions**:
1. Run from feature branch: `git checkout 001-feature`
2. Set environment variable: `export SDD_FEATURE="001-feature"`
3. Check specs directory exists: `ls specs/`

### Template not found

**Problem**: "Template file not found"

**Solutions**:
1. Verify script location (should be in plugin skill)
2. Check template exists: `ls ../templates/`
3. Reinstall plugin if templates missing

### Permission errors

**Problem**: "Failed to create directory"

**Solutions**:
1. Check write permissions: `ls -la .`
2. Create directories manually: `mkdir -p specs/001-feature`
3. Check repository root is writable

## Related Documentation

- **Workflow Overview**: How scripts fit into SDD workflow
- **Template Guide**: Templates used by scripts
- **Constitution Guide**: Principles enforced by scripts
