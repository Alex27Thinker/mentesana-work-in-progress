# Conflict Resolution

Strategies for handling merge conflicts in worktree workflows.

## Conflict Prevention

### Task Decomposition

The best conflict is one that never happens. When decomposing tasks:

**Good decomposition:**
- Each task modifies distinct files/directories
- Minimal dependencies between tasks
- Clear interfaces between components
- Testable in isolation

**Red flags:**
- Multiple tasks touching same config files
- Shared base classes being extended
- Overlapping directory scopes
- Interdependent database migrations

### Scope Communication

Use PR descriptions to communicate scope:

```markdown
## Affected Areas
- `src/payments/**` - New payment module
- `src/config/payments.ts` - Payment configuration

## Does NOT Modify
- User authentication
- API routing (new routes only)
- Existing database tables
```

### Area Ownership

Track who's working where:

| Area | Active Instance/Subagent |
|------|--------------------------|
| src/payments/ | Instance Alpha |
| src/dashboard/ | Instance Beta |
| src/api/users/ | Subagent 3 |

## Detecting Conflicts Early

### Before Creating PR

```bash
git fetch origin main
git rebase origin/main

# If conflicts appear, you'll see them now
```

### Dry-Run Merge

```bash
# Attempt merge without committing
git merge --no-commit --no-ff feature/branch-name

# Check for conflicts
git status

# Abort the dry run
git merge --abort
```

### Merge-Tree Preview

```bash
# Preview merge conflicts without touching working directory
git merge-tree $(git merge-base HEAD feature/branch-name) HEAD feature/branch-name
```

## Resolving Conflicts

### Basic Resolution Workflow

```bash
# Attempt merge
git merge feature/branch-name
# CONFLICT (content): Merge conflict in src/config.ts

# See conflicting files
git status

# Edit files to resolve conflicts
# Look for <<<<<<< ======= >>>>>>> markers

# Mark as resolved
git add src/config.ts

# Complete merge
git commit -m "Merge feature/branch-name, resolve config conflict"
```

### Conflict Markers

```
<<<<<<< HEAD
// Current branch code
const config = { port: 3000 };
=======
// Incoming branch code
const config = { port: 3001 };
>>>>>>> feature/branch-name
```

**Resolution:** Remove markers, keep correct code:
```javascript
const config = { port: process.env.PORT || 3000 };
```

## Common Conflict Patterns

### Shared Configuration Files

**Problem:** Multiple subagents modify the same config file.

**Prevention:**
- Have orchestrator handle shared configs
- Assign config changes to single subagent
- Use config sections (one per subagent)

**Resolution:** Carefully combine all necessary changes:
```javascript
// Combine auth config (from subagent 1)
// with API config (from subagent 2)
export const config = {
  auth: { ... },  // From subagent 1
  api: { ... },   // From subagent 2
};
```

### Import Statements

**Problem:** Multiple modules add imports to the same index file.

**Prevention:**
- Use separate export files per module
- Have orchestrator manage index files

**Resolution:** Combine imports in logical order:
```typescript
// index.ts - combine imports
export * from './auth';    // From subagent 1
export * from './users';   // From subagent 2
export * from './payments'; // From subagent 3
```

### Type Definitions

**Problem:** Multiple subagents extend shared interfaces.

**Prevention:**
- Define interfaces up front
- Assign extension to specific subagent
- Use interface composition

**Resolution:** Merge type definitions:
```typescript
interface User {
  id: string;
  name: string;
  // From subagent 1
  authToken?: string;
  // From subagent 2
  preferences?: UserPreferences;
}
```

### Package Dependencies

**Problem:** Multiple branches add different dependencies.

**Prevention:**
- Coordinate dependency additions
- Run `npm install` after each merge

**Resolution:**
```bash
# After resolving package.json conflicts
rm -rf node_modules package-lock.json
npm install
git add package.json package-lock.json
```

## Orchestrator Conflict Resolution

### Sequential Merge Strategy

Merge branches one at a time, resolving conflicts immediately:

```bash
git checkout feature/main-branch

# Merge in dependency order
git merge feature/db-migrations --no-ff
# Resolve any conflicts
npm test  # Verify

git merge feature/auth --no-ff
# Resolve any conflicts
npm test  # Verify

git merge feature/api --no-ff
# Resolve any conflicts
npm test  # Verify
```

### Requesting Subagent Help

If conflict involves subagent's domain knowledge:

```markdown
## Conflict Resolution Request

**Conflicting Files:** src/api/index.ts
**Your Branch:** feature/user-api
**Conflicting Branch:** feature/auth-api

The API route definitions conflict. Please advise on correct resolution:
- Your routes: /api/users/*
- Auth routes: /api/auth/*

How should these be combined in the router setup?
```

### Staged Integration Testing

Test after each merge stage:

```bash
# Stage 1: Foundation
git merge feature/db-migrations
npm test  # Verify DB layer

# Stage 2: Auth
git merge feature/auth
npm test  # Verify auth integration

# Stage 3: API
git merge feature/api
npm test  # Verify API integration

# Stage 4: UI
git merge feature/ui
npm test  # Full integration
```

## Peer Workflow Conflicts

### Rebase-Based Resolution

For peer workflows, rebase before PR:

```bash
git fetch origin main
git rebase origin/main

# For each conflict:
# 1. Edit file to resolve
# 2. git add <file>
# 3. git rebase --continue

# Force push rebased branch
git push --force-with-lease
```

### Post-Merge Conflicts

When another PR merged first:

```bash
git fetch origin main
git log --oneline HEAD..origin/main  # See what merged

git rebase origin/main
# Resolve conflicts
git add .
git rebase --continue

# Update PR
git push --force-with-lease
```

## Recovery Strategies

### Abort Merge

If merge is going badly:

```bash
git merge --abort
# Working directory restored to pre-merge state
```

### Reset After Partial Integration

If integration fails midway:

```bash
git reflog  # Find pre-integration commit
git reset --hard <commit-hash>
# Re-attempt with different strategy
```

### Cherry-Pick Specific Commits

When full merge is problematic:

```bash
# Pick specific commits instead of full merge
git cherry-pick abc1234
git cherry-pick def5678
```

## Conflict Resolution Checklist

- [ ] Understand both versions before resolving
- [ ] Preserve functionality from both branches
- [ ] Remove all conflict markers
- [ ] Run tests after resolution
- [ ] Review resolved code for correctness
- [ ] Commit with clear message describing resolution
