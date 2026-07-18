---
name: worktrees:finish
description: Use when completing work in a worktree. Handles PR creation or direct merge, worktree removal, and branch cleanup. Invoke with "/worktrees:finish" or when user mentions "finish worktree", "clean up worktree", "merge worktree", "done with worktree", or "complete worktree work".
argument-hint: "[--pr | --merge] [--force]"
version: 0.1.0
arguments:
  - name: --pr
    description: Create a pull request (default for peer workflow)
    required: false
  - name: --merge
    description: Direct merge to target branch (for orchestrator integration)
    required: false
  - name: --force
    description: Force cleanup even with uncommitted changes
    required: false
---

# Finish Worktree

Complete work in a worktree and clean up.

## Arguments

- `--pr` - Create a pull request (default)
- `--merge` - Direct merge to target branch
- `--force` - Force cleanup with uncommitted changes

## Pre-Completion Checklist

Before finishing, verify:

- [ ] All changes committed
- [ ] Tests passing
- [ ] Branch pushed to remote
- [ ] Work reviewed (if applicable)

```bash
# Check for uncommitted changes
git status

# Run tests
npm test  # or your test command

# Push if needed
git push -u origin $(git branch --show-current)
```

## Option 1: Create Pull Request (--pr)

For peer workflows and standard code review.

### Step 1: Ensure Up to Date

```bash
# Fetch latest changes
git fetch origin main

# Rebase to include latest main
git rebase origin/main

# Force push rebased branch
git push --force-with-lease
```

### Step 2: Create PR

```bash
gh pr create \
  --base main \
  --title "feat: <description>" \
  --body "## Summary
<What this PR accomplishes>

## Changes
- <Bullet list of changes>

## Testing
<How to test>
"
```

### Step 3: After PR Merge

```bash
# Return to main project directory
cd ../..  # Exit .worktrees/<name> to project root

# Pull merged changes
git checkout main
git pull origin main

# Remove worktree
git worktree remove .worktrees/<name>

# Delete local branch if still exists (PR merge usually deletes remote)
git branch -d feature/<name> 2>/dev/null

# Prune stale references
git worktree prune
```

## Option 2: Direct Merge (--merge)

For orchestrator integration where work merges directly.

### Step 1: Switch to Target Branch

```bash
# From main project directory (not worktree)
cd /path/to/main/project
git checkout <target-branch>
```

### Step 2: Merge Worktree Branch

```bash
git merge feature/<name> --no-ff -m "Merge <description>"
```

### Step 3: Run Tests

```bash
npm test  # Verify integration
```

### Step 4: Cleanup

```bash
# Remove worktree
git worktree remove .worktrees/<name>

# Delete local branch
git branch -d feature/<name>

# If pushed to remote, delete remote branch
git push origin --delete feature/<name>

# Prune stale references
git worktree prune
```

## Force Cleanup (--force)

When worktree has uncommitted changes and you want to discard:

```bash
# Force remove worktree (discards all uncommitted changes!)
git worktree remove --force .worktrees/<name>

# Delete branch
git branch -D feature/<name>

# Prune
git worktree prune
```

> **Warning:** `--force` discards uncommitted work permanently.

## Complete Cleanup Script

For cleaning up multiple worktrees:

```bash
#!/bin/bash
# cleanup-worktree.sh <worktree-name>

NAME=$1
BRANCH="feature/${NAME}"
WORKTREE=".worktrees/${NAME}"

# Check if worktree exists
if git worktree list | grep -q "$WORKTREE"; then
    # Remove worktree
    git worktree remove "$WORKTREE" || git worktree remove --force "$WORKTREE"
fi

# Delete local branch
git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH" 2>/dev/null

# Delete remote branch if exists
git push origin --delete "$BRANCH" 2>/dev/null

# Prune
git worktree prune

echo "Cleanup complete for $NAME"
```

## Verification

After cleanup:

```bash
# Verify worktree removed
git worktree list

# Verify branch deleted
git branch -a | grep <name>

# Should show no results for worktree or branch
```

## Troubleshooting

### Cannot Remove: Uncommitted Changes

**Error:** `fatal: cannot remove worktree with uncommitted changes`

**Solutions:**
1. Commit your changes: `git add . && git commit -m "WIP"`
2. Stash changes: `git stash`
3. Force remove (loses changes): `git worktree remove --force .worktrees/<name>`

### Cannot Remove: Worktree Locked

**Error:** `fatal: worktree is locked`

**Solution:**
```bash
git worktree unlock .worktrees/<name>
git worktree remove .worktrees/<name>
```

### Branch Cannot Be Deleted

**Error:** `error: branch is not fully merged`

**Solutions:**
1. If work is merged via PR, force delete: `git branch -D feature/<name>`
2. If work needs preserving, merge first

### Stale Worktree Entry

If worktree directory was manually deleted:

```bash
git worktree prune
```

## Quick Reference

| Task | Command |
|------|---------|
| Remove worktree | `git worktree remove .worktrees/<name>` |
| Force remove | `git worktree remove --force .worktrees/<name>` |
| Delete local branch | `git branch -d feature/<name>` |
| Force delete branch | `git branch -D feature/<name>` |
| Delete remote branch | `git push origin --delete feature/<name>` |
| Prune stale entries | `git worktree prune` |
| Create PR | `gh pr create --base main` |
| Merge PR | `gh pr merge --squash --delete-branch` |
