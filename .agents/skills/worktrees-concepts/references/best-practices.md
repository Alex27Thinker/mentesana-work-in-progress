# Best Practices

Recommended patterns and tips for effective worktree usage.

## Setup Best Practices

### Always Gitignore First

Before creating any worktree:

```bash
grep -q "^\.worktrees" .gitignore 2>/dev/null || echo ".worktrees/" >> .gitignore
git add .gitignore
git commit -m "chore: add .worktrees to gitignore"
```

**Why:** Prevents accidentally committing nested repository copies.

### Use `.worktrees/` Directory

Keep all worktrees in `.worktrees/`:

```
.worktrees/
├── feature-auth/
├── feature-api/
└── hotfix-urgent/
```

**Benefits:**
- Self-contained within project
- Hidden from casual browsing (dot prefix)
- Easy to gitignore
- Clear organization

### Descriptive Naming

Use clear, consistent naming:

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature-<name>` | `feature-auth` |
| Agent work | `<agent>-<feature>` | `agent-42-api` |
| Hotfix | `hotfix-<issue>` | `hotfix-login` |
| Instance | `inst-<id>` | `inst-alpha` |

## Lifecycle Management

### Create at Task Start

Create worktrees when beginning work:

```bash
git worktree add -b feature/new-feature .worktrees/new-feature main
cd .worktrees/new-feature
```

### Remove at Task Completion

Clean up immediately after merging:

```bash
git worktree remove .worktrees/completed-feature
git branch -d feature/completed-feature
git worktree prune
```

### Regular Audits

Periodically check for stale worktrees:

```bash
git worktree list
# Remove any that are no longer needed
```

### Lock Important Worktrees

Prevent accidental removal of critical work:

```bash
git worktree lock --reason "In active use" .worktrees/important
```

## Development Workflow

### Atomic Commits

Make small, focused commits:

```bash
# Good
git add src/auth/service.ts
git commit -m "feat(auth): add login method"

git add tests/auth/service.test.ts
git commit -m "test(auth): add login method tests"

# Avoid
git add .
git commit -m "Add auth feature"  # Too broad
```

### Push Regularly

Keep remote up to date:

```bash
git push -u origin feature/branch-name
```

**Benefits:**
- Backup in case of issues
- Enables collaboration
- Shows progress

### Run Tests Frequently

Verify changes as you work:

```bash
npm test  # After significant changes
npm test src/auth/  # Just relevant tests
```

## Coordination Patterns

### Communicate Scope

In PR descriptions:

```markdown
## Affected Areas
- `src/payments/**` - New module

## Does NOT Modify
- Existing API routes
- Database schema
```

### Unique Branch Prefixes

For multi-agent work:

```
feature/subagent-1-auth
feature/subagent-2-api
feature/subagent-3-ui
```

### Merge Frequently

Keep merge scope small:

- Merge completed work promptly
- Don't let branches diverge too far
- Shorter worktree lifespans = fewer conflicts

## Resource Management

### Monitor Disk Space

Each worktree duplicates working files:

```bash
du -sh .worktrees/*
```

Clean up unused worktrees to reclaim space.

### Manage Running Processes

Don't leave dev servers running in abandoned worktrees:

```bash
# Check for running processes
lsof -i :3000-3010

# Use different ports per worktree
PORT=3001 npm run dev  # worktree 1
PORT=3002 npm run dev  # worktree 2
```

### File Watcher Limits

Many tools use file watchers:

```bash
# Check current limit
cat /proc/sys/fs/inotify/max_user_watches

# Increase if needed (Linux)
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Environment Isolation

### Separate Environment Files

Each worktree can have its own `.env`:

```bash
cd .worktrees/feature-auth
cp ../.env.example .env
# Customize PORT, DATABASE_URL, etc.
```

### Database Isolation

Options for database isolation:

```bash
# SQLite: Different files
DATABASE_URL="file:.worktrees/auth/dev.sqlite"

# PostgreSQL: Different schemas
DATABASE_URL="postgres://localhost/app?schema=worktree_auth"

# Docker: Different containers
docker-compose -p worktree-auth up -d
```

### Port Management

Assign unique ports:

| Worktree | Port |
|----------|------|
| Main | 3000 |
| worktree-1 | 3001 |
| worktree-2 | 3002 |

## Error Prevention

### Verify Before Removing

Check worktree status before removal:

```bash
cd .worktrees/<name>
git status  # Any uncommitted changes?
git log --oneline -3  # Recent commits?
cd ..
git worktree remove .worktrees/<name>
```

### Use `--force-with-lease`

When force pushing after rebase:

```bash
git push --force-with-lease  # Safer than --force
```

**Why:** Fails if remote has unexpected commits, preventing accidental overwrites.

### Test After Merges

Always verify integration:

```bash
git merge feature/branch --no-ff
npm test  # Verify nothing broke
```

## Documentation Patterns

### Track Worktree Assignments

For orchestrator workflows:

```markdown
## Active Worktrees

| Worktree | Branch | Assignee | Status |
|----------|--------|----------|--------|
| .worktrees/auth | feature/user-auth | Subagent 1 | In Progress |
| .worktrees/api | feature/user-api | Subagent 2 | Complete |
```

### PR Context

Include instance context in PRs:

```markdown
## Instance Context
- Instance: Alpha
- Worktree: .worktrees/inst-alpha
- Independent feature, no coordination needed
```

## Quick Checklist

### Before Creating Worktree
- [ ] `.worktrees/` is gitignored
- [ ] Clear naming convention chosen
- [ ] Base branch is up to date

### During Development
- [ ] Working in correct worktree
- [ ] Making atomic commits
- [ ] Pushing regularly
- [ ] Running tests

### Before Finishing
- [ ] All changes committed
- [ ] Tests passing
- [ ] Branch pushed
- [ ] Ready for PR/merge

### After Finishing
- [ ] PR merged (or direct merge complete)
- [ ] Worktree removed
- [ ] Branch deleted
- [ ] `git worktree prune` run
