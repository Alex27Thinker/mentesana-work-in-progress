---
name: worktrees:status
description: Display comprehensive worktree status including active worktrees, stale references, and uncommitted changes. Invoke with "/worktrees:status" or when user mentions "worktree status", "list worktrees", "check worktrees", "worktree health", or "audit worktrees".
version: 0.1.0
---

# Worktree Status

Display comprehensive status of all worktrees.

## Procedure

Run these commands to gather worktree status:

### 1. List Active Worktrees

```bash
echo "=== Active Worktrees ===" && git worktree list
```

### 2. Check for Stale References

```bash
echo "=== Stale References ===" && git worktree prune --dry-run 2>&1 || echo "None found"
```

### 3. Check Uncommitted Changes Across Worktrees

```bash
echo "=== Uncommitted Changes ===" && for wt in $(git worktree list --porcelain | grep "^worktree " | cut -d ' ' -f 2); do
  changes=$(cd "$wt" && git status --porcelain 2>/dev/null | head -5)
  if [ -n "$changes" ]; then
    echo ""
    echo "📁 $wt:"
    echo "$changes"
    count=$(cd "$wt" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 5 ]; then
      echo "   ... and $((count - 5)) more files"
    fi
  fi
done
echo ""
echo "Worktrees with no changes not shown."
```

### 4. Check for Locked Worktrees

```bash
echo "=== Locked Worktrees ===" && for wt in $(git worktree list --porcelain | grep "^worktree " | cut -d ' ' -f 2); do
  if [ -f "$wt/../.git/worktrees/$(basename $wt)/locked" ] 2>/dev/null || git worktree list --porcelain | grep -A5 "^worktree $wt$" | grep -q "^locked"; then
    echo "🔒 $wt"
  fi
done || echo "None"
```

## Output Interpretation

### Active Worktrees

```
/path/to/project              abc1234 [main]
/path/to/project/.worktrees/feature  def5678 [feature/auth]
```

- First column: worktree path
- Second column: HEAD commit
- Third column: branch name

### Stale References

If `git worktree prune --dry-run` shows output, you have stale entries:

```
Removing worktrees/old-feature: gitdir file points to non-existent location
```

**Fix:** Run `git worktree prune` to clean up.

### Uncommitted Changes

Shows files with uncommitted changes in each worktree:

```
📁 /path/to/project/.worktrees/feature:
 M src/auth/service.ts
?? src/auth/new-file.ts
```

Status codes:
- `M` - Modified
- `A` - Added (staged)
- `D` - Deleted
- `??` - Untracked
- `UU` - Merge conflict

## Quick Health Check

Run all checks in one command:

```bash
echo "=== WORKTREE STATUS ===" && \
echo "" && \
echo "📋 Active Worktrees:" && \
git worktree list && \
echo "" && \
echo "🧹 Stale References:" && \
(git worktree prune --dry-run 2>&1 | grep -v "^$" || echo "  None") && \
echo "" && \
echo "📝 Uncommitted Changes:" && \
for wt in $(git worktree list --porcelain | grep "^worktree " | cut -d ' ' -f 2); do
  changes=$(cd "$wt" && git status --porcelain 2>/dev/null)
  if [ -n "$changes" ]; then
    echo "  $wt: $(echo "$changes" | wc -l | tr -d ' ') files"
  fi
done && \
echo "" && \
echo "Done."
```

## Recommended Actions

Based on status output:

| Finding | Action |
|---------|--------|
| Stale references | Run `git worktree prune` |
| Uncommitted changes | Commit, stash, or discard |
| Old worktrees | Use `/worktrees:finish` to clean up |
| Locked worktrees | Unlock with `git worktree unlock <path>` if no longer needed |

## Related Skills

- `/worktrees:new` - Create a new worktree
- `/worktrees:finish` - Clean up completed worktree
- `/worktrees:concepts` - Reference documentation
