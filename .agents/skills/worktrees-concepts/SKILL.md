---
name: worktrees:concepts
description: Comprehensive reference for git worktrees. Covers concepts, commands, conflict resolution, and best practices. Invoke with "/worktrees:concepts" or when user mentions "worktree reference", "explain worktrees", "worktree documentation", "worktree commands", "worktree concepts", or "learn about worktrees".
version: 0.1.0
---

# Git Worktrees Reference

Comprehensive reference for git worktrees in AI development workflows.

## What Are Worktrees?

Git worktrees allow checking out multiple branches simultaneously in separate directories, all sharing the same `.git` repository.

**Key characteristics:**
- Each worktree has its own working directory and index
- All worktrees share the same Git history and objects
- Branches checked out in worktrees are "locked" to prevent checkout elsewhere
- Worktrees persist across sessions until explicitly removed

## When to Use Worktrees

**Ideal for:**
- Parallel development of independent features
- Isolating experimental work from stable code
- Running tests in one branch while developing in another
- AI agent collaboration requiring workspace isolation
- Reviewing PRs without stashing current work

**Not ideal for:**
- Very small, quick fixes (overhead not worth it)
- When disk space is severely limited
- Single-file changes that don't need isolation

## Directory Organization

### Recommended Structure

```
my-project/
├── .git/                    # Shared git directory
├── .gitignore               # Must include .worktrees/
├── .worktrees/              # All worktrees live here
│   ├── feature-auth/        # Feature worktree
│   ├── feature-api/         # Another feature worktree
│   └── hotfix-urgent/       # Hotfix worktree
└── src/                     # Main working directory
```

### First-Time Setup

Before creating any worktree, ensure `.worktrees/` is gitignored:

```bash
grep -q "^\.worktrees" .gitignore 2>/dev/null || echo ".worktrees/" >> .gitignore
git add .gitignore
git commit -m "chore: add .worktrees to gitignore"
```

**Why gitignore?** Each worktree contains a complete checkout. Without gitignoring, you'd accidentally commit nested copies of your entire codebase.

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature-<name>` | `feature-auth` |
| Agent | `<agent-id>-<feature>` | `agent-42-api` |
| Instance | `inst-<id>` | `inst-alpha` |
| Hotfix | `hotfix-<issue>` | `hotfix-login` |

## Workspace Organization

### Desktop Layout

For multiple concurrent worktrees:

- **One Space/Desktop per worktree** - Quick switching with keyboard shortcuts
- **Consistent layout**: IDE on left, Claude on right
- **Separate terminal tabs** per worktree
- **tmux sessions** for persistence

### Editor Windows

- Separate window per worktree
- Clear titles: `[worktree-name] - project`
- Color-code terminals by worktree

## Environment Isolation

### Port Assignment

Avoid port conflicts when running multiple instances:

```bash
# Worktree 1
PORT=3001 npm run dev

# Worktree 2
PORT=3002 npm run dev
```

### Database Options

| Approach | When to Use |
|----------|-------------|
| SQLite per worktree | Simple apps, testing |
| PostgreSQL schemas | Shared DB, isolated data |
| Docker containers | Full isolation |
| In-memory DB | Unit tests |

```bash
# SQLite: Different files
DATABASE_URL="file:.worktrees/auth/dev.sqlite"

# PostgreSQL: Different schemas
DATABASE_URL="postgres://localhost/app?schema=worktree_auth"

# Docker: Different containers
docker-compose -p worktree-auth up -d
```

### Environment Files

Keep worktree-specific `.env` files:

```bash
# In worktree
cp ../.env.example .env
# Customize PORT, DATABASE_URL, etc.
```

## Resource Considerations

### Disk Space

Each worktree duplicates working files (not git objects):
- Small projects: ~10-50MB per worktree
- Large projects: Can be significant

```bash
# Check worktree sizes
du -sh .worktrees/*
```

### Memory

Multiple running dev servers increase memory usage:
- Monitor with `top` or `htop`
- Stop unused dev servers
- Consider using `--watch` only on active worktree

### File Watchers

Many tools use file watchers (webpack, nodemon, etc.):
- Each worktree may spawn watchers
- Can hit system limits on large projects
- Increase limits if needed: `fs.inotify.max_user_watches`

## Common Pitfalls

### Branch Already Checked Out

**Error:** `fatal: 'branch-name' is already checked out at '/path'`

**Cause:** Each branch can only exist in one worktree.

**Solutions:**
1. Use the existing worktree: `git worktree list`
2. Create a new branch for the new worktree
3. Remove the existing worktree first

### Uncommitted Changes on Removal

**Error:** `fatal: cannot remove worktree with uncommitted changes`

**Solutions:**
1. Commit changes: `git add . && git commit -m "WIP"`
2. Stash changes: `git stash`
3. Force remove (loses changes): `git worktree remove --force`

### Stale Worktree References

**Problem:** Manually deleted worktree directory leaves stale entry.

**Solution:** `git worktree prune`

### Detached HEAD in Worktree

**Problem:** Worktree ends up in detached HEAD state.

**Solution:**
```bash
cd .worktrees/<name>
git checkout <branch>
# or create new branch
git checkout -b <new-branch>
```

## Git Version Requirements

| Feature | Git Version |
|---------|-------------|
| Basic worktree | 2.5+ |
| `worktree list` | 2.7+ |
| `worktree lock/unlock` | 2.10+ |
| `worktree move` | 2.17+ |
| `worktree remove` | 2.17+ |
| `worktree repair` | 2.30+ |
| `--orphan` | 2.37+ |

Check version: `git --version`

## Quick Reference

| Task | Command |
|------|---------|
| Create (new branch) | `git worktree add -b <branch> .worktrees/<name> [base]` |
| Create (existing branch) | `git worktree add .worktrees/<name> <branch>` |
| List | `git worktree list` |
| Remove | `git worktree remove .worktrees/<name>` |
| Force remove | `git worktree remove --force .worktrees/<name>` |
| Prune stale | `git worktree prune` |
| Lock | `git worktree lock .worktrees/<name>` |
| Unlock | `git worktree unlock .worktrees/<name>` |
| Move | `git worktree move .worktrees/<old> .worktrees/<new>` |
| Repair | `git worktree repair` |

## Reference Files

For detailed information, see:

- **`references/commands-reference.md`** - Complete git worktree command reference
- **`references/conflict-resolution.md`** - Handling merge conflicts
- **`references/best-practices.md`** - Recommended patterns and tips

## Related Skills

- **`/worktrees:new`** - Create a new worktree
- **`/worktrees:status`** - Check worktree health and status
- **`/worktrees:finish`** - Complete and clean up worktree
- **`/worktrees:peer`** - Independent PR-based workflow
- **`/worktrees:orchestrator`** - Multi-subagent parallel development
