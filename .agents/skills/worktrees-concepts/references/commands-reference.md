# Git Worktree Commands Reference

Complete reference for all git worktree commands.

## git worktree add

Create a new worktree.

### Syntax

```bash
git worktree add [-f] [--detach] [--checkout] [--lock [--reason <string>]]
                 [-b <new-branch>] [-B <new-branch>] [--orphan <new-branch>]
                 [--track [--no-track]] [-q] <path> [<commit-ish>]
```

### Common Forms

```bash
# Create worktree for existing branch
git worktree add .worktrees/<name> <branch>

# Create worktree with new branch
git worktree add -b <new-branch> .worktrees/<name>

# Create worktree with new branch from specific base
git worktree add -b <new-branch> .worktrees/<name> <base>
```

### Options

| Option | Description |
|--------|-------------|
| `-b <branch>` | Create new branch and check it out |
| `-B <branch>` | Create or reset branch (force) |
| `--detach` | Create worktree with detached HEAD |
| `-f, --force` | Override safeguards |
| `--lock` | Lock worktree immediately |
| `--reason <string>` | Reason for lock |
| `-q, --quiet` | Suppress output |
| `--track` | Set up tracking for new branch |
| `--no-track` | Don't set up tracking |
| `--orphan <branch>` | Create orphan branch |
| `--checkout` | Check out branch (default) |
| `--no-checkout` | Don't check out branch |
| `--guess-remote` | Match with remote-tracking branch |

### Examples

```bash
# Basic: existing branch
git worktree add .worktrees/feature-auth feature/authentication

# New branch from current HEAD
git worktree add -b hotfix/urgent .worktrees/hotfix

# New branch from specific base
git worktree add -b feature/new-api .worktrees/new-api main

# New branch tracking remote
git worktree add --track -b local-feature .worktrees/feature origin/feature

# Locked worktree
git worktree add --lock --reason "Critical development" -b release .worktrees/release

# Detached HEAD (testing specific commits)
git worktree add --detach .worktrees/test-commit abc1234

# Force add when branch checked out elsewhere
git worktree add -f .worktrees/forced feature/already-out

# Orphan branch (no history)
git worktree add --orphan docs .worktrees/docs
```

## git worktree list

List all worktrees.

### Syntax

```bash
git worktree list [--porcelain] [-z] [-v | --verbose]
```

### Options

| Option | Description |
|--------|-------------|
| `--porcelain` | Machine-readable output |
| `-z` | NUL-terminated lines |
| `-v, --verbose` | Show detailed information |

### Examples

```bash
# Human-readable
git worktree list
# Output:
# /path/to/main       abc1234 [main]
# /path/to/feature    def5678 [feature/auth]

# Machine-readable
git worktree list --porcelain
# Output:
# worktree /path/to/main
# HEAD abc1234...
# branch refs/heads/main
#
# worktree /path/to/feature
# HEAD def5678...
# branch refs/heads/feature/auth

# Verbose
git worktree list -v
```

### Parsing

```bash
# Get worktree paths
git worktree list --porcelain | grep "^worktree " | cut -d ' ' -f 2

# Get worktree for specific branch
git worktree list --porcelain | grep -A 2 "branch refs/heads/feature/auth" | head -1 | cut -d ' ' -f 2
```

## git worktree remove

Remove a worktree.

### Syntax

```bash
git worktree remove [-f | --force] <worktree>
```

### Options

| Option | Description |
|--------|-------------|
| `-f, --force` | Remove even with uncommitted changes |

### Examples

```bash
# Standard remove
git worktree remove .worktrees/feature-auth

# Force remove (discards changes)
git worktree remove --force .worktrees/feature-auth

# By absolute path
git worktree remove /full/path/to/worktree
```

### Error Handling

```bash
# Uncommitted changes
# Solution: commit, stash, or --force

# Worktree locked
# Solution: unlock first
git worktree unlock .worktrees/feature
git worktree remove .worktrees/feature

# Cannot remove main worktree
# Only linked worktrees can be removed
```

## git worktree move

Move a worktree.

### Syntax

```bash
git worktree move <worktree> <new-path>
```

### Examples

```bash
# Rename within .worktrees/
git worktree move .worktrees/feature-auth .worktrees/auth-dev

# Move to different location
git worktree move .worktrees/feature /other/location/feature
```

### Notes

- Cannot move main worktree
- Cannot move locked worktree
- New path must not exist
- Git metadata updated automatically

## git worktree lock

Lock a worktree to prevent accidental removal.

### Syntax

```bash
git worktree lock [--reason <string>] <worktree>
```

### Examples

```bash
# Basic lock
git worktree lock .worktrees/feature-auth

# Lock with reason
git worktree lock --reason "Active development" .worktrees/feature-auth

# Detailed reason
git worktree lock --reason "Release candidate testing by QA" .worktrees/release
```

### Use Cases

- Prevent accidental removal during long-running work
- Mark worktrees used by automated systems
- Protect shared worktrees

## git worktree unlock

Unlock a locked worktree.

### Syntax

```bash
git worktree unlock <worktree>
```

### Example

```bash
git worktree unlock .worktrees/feature-auth
```

## git worktree prune

Clean up stale worktree entries.

### Syntax

```bash
git worktree prune [-n | --dry-run] [-v | --verbose] [--expire <time>]
```

### Options

| Option | Description |
|--------|-------------|
| `-n, --dry-run` | Show what would be removed |
| `-v, --verbose` | Report all removals |
| `--expire <time>` | Only prune entries older than time |

### Examples

```bash
# Prune stale entries
git worktree prune

# Preview what would be pruned
git worktree prune --dry-run

# Verbose
git worktree prune -v

# Prune entries older than 30 days
git worktree prune --expire 30.days.ago
```

### When to Prune

- After manually deleting worktree directories
- After moving worktree directories manually
- Periodically as maintenance
- After system crashes

## git worktree repair

Repair worktree administrative files.

### Syntax

```bash
git worktree repair [<path>...]
```

### Examples

```bash
# Repair all worktrees
git worktree repair

# Repair specific worktree
git worktree repair .worktrees/feature-auth

# Repair multiple
git worktree repair .worktrees/feature-1 .worktrees/feature-2
```

### Use Cases

- After moving main repository
- After manually moving worktree directories
- When worktree/repository links break
- Recovery from backup

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GIT_WORK_TREE` | Override working tree location |
| `GIT_DIR` | Override git directory location |
| `GIT_COMMON_DIR` | Override common directory for linked worktrees |

## Administrative Files

```
.git/worktrees/
├── <worktree-name>/
│   ├── HEAD              # Current checkout
│   ├── commondir         # Path to common git dir
│   ├── gitdir            # Path to worktree's .git file
│   ├── index             # Staging area
│   ├── locked            # Present if locked
│   └── ORIG_HEAD         # Previous HEAD

<worktree>/
├── .git                  # File pointing to .git/worktrees/<name>
└── ... (working files)
```

## Utility Patterns

### List Worktree Paths Only

```bash
git worktree list --porcelain | grep "^worktree " | sed 's/worktree //'
```

### Find Worktree for Branch

```bash
git worktree list | grep "\[feature/auth\]" | awk '{print $1}'
```

### Check if Branch Has Worktree

```bash
git worktree list | grep -q "\[feature/auth\]" && echo "Has worktree" || echo "No worktree"
```

### Remove All Feature Worktrees

```bash
git worktree list --porcelain | grep "^worktree " | sed 's/worktree //' | \
  grep -v "$(git rev-parse --show-toplevel)" | \
  xargs -I {} git worktree remove {}
```

### Audit Worktree Status

```bash
for wt in $(git worktree list --porcelain | grep "^worktree " | sed 's/worktree //'); do
  echo "=== $wt ==="
  (cd "$wt" && git status --short)
done
```
