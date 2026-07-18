# Support Documentation Patterns

Analysis of support documentation from successful open source projects, with patterns for helping users get assistance effectively.

## Purpose of SUPPORT.md

The SUPPORT.md file serves as a central hub for:
- Directing users to appropriate help resources
- Setting expectations for response times
- Preventing issue tracker spam with support questions
- Building community around the project

**Key principle:** Keep issues for bugs/features, route questions elsewhere.

## Exemplary SUPPORT Files

### 1. Electron (electron/electron)

**URL:** https://github.com/electron/electron/blob/main/.github/SUPPORT.md

**What makes it great:**
- Opens with what NOT to file issues for
- Lists question resources with descriptions
- Clear escalation path (community → paid support)
- Links to security reporting
- Includes response time expectations

**Pattern extracted:**
```markdown
# Getting Help

If you have a question about using [Project], please use one of the following resources:

## Questions and General Help

- **[Community Forum](link)** - For general questions and discussions
- **[Stack Overflow](link)** - For specific coding questions (use tag: [project-name])
- **[Discord/Slack](link)** - For real-time chat and quick questions

## Bugs and Feature Requests

- **[Issue Tracker](link)** - For confirmed bugs and feature proposals

## Security Issues

- **[Security Policy](link)** - For reporting vulnerabilities

## Commercial Support

- **[Vendor Link](link)** - For enterprise support options

Please DO NOT file issues for questions. The issue tracker is for bugs and feature requests only.
```

**When to use:** Projects with active community and commercial support options

### 2. Gatsby (gatsbyjs/gatsby)

**URL:** https://github.com/gatsbyjs/gatsby/blob/master/.github/SUPPORT.md

**What makes it great:**
- Friendly, welcoming tone
- Multiple support tiers clearly explained
- Response time expectations set
- Free vs. paid support differentiated
- Links to learning resources

**Pattern extracted:**
```markdown
# Support

Looking for help with [Project]? Here are your options:

## Free Community Support

### Documentation
- [Official Docs](link) - Start here!
- [Tutorials](link) - Step-by-step guides
- [FAQ](link) - Common questions

### Community Channels
- [GitHub Discussions](link) - Best for questions
- [Discord](link) - Real-time chat
- [Twitter](link) - Updates and tips

**Response time:** Community-driven, typically 24-48 hours

## Professional Support

Need guaranteed response times or custom solutions?
- [Enterprise Support](link) - SLA-backed support
- [Consulting](link) - Custom development

## Reporting Issues

Found a bug? Please check if it's already reported, then:
1. Read [issue guidelines](link)
2. Open an issue with [bug template](link)

## What NOT to File Issues For

❌ Questions about how to use [Project]
❌ Troubleshooting your specific project
✅ Reproducible bugs in [Project] itself
✅ Feature proposals with clear use cases
```

**When to use:** Projects with both free and paid support tiers

### 3. Next.js (vercel/next.js)

**URL:** https://github.com/vercel/next.js/blob/canary/.github/SUPPORT.md

**What makes it great:**
- Emphasizes documentation first
- Clear troubleshooting path
- Examples repository linked
- Discussions vs. issues clearly differentiated
- Template language is friendly but firm

**Pattern extracted:**
```markdown
# Support

## Before Asking for Help

1. **Check the [Documentation](link)** - Most questions are answered there
2. **Search [Existing Issues](link)** - Your question may already be answered
3. **Review [Examples](link)** - See working implementations

## Getting Help

### Questions
Use [GitHub Discussions](link) for:
- How do I...?
- Why does...?
- Can I...?

### Issues
Use [GitHub Issues](link) ONLY for:
- Bug reports (with reproduction)
- Feature requests (with use case)

### Real-Time Help
- [Discord](link) - Community chat
- [Reddit](link) - Discussions and tips

## Creating a Good Question

- ✅ Provide context and what you've tried
- ✅ Include relevant code snippets
- ✅ Share error messages
- ❌ Just paste your entire project
- ❌ Ask to ask ("Can someone help me?")
```

**When to use:** Developer tools with extensive documentation

### 4. TensorFlow (tensorflow/tensorflow)

**URL:** https://github.com/tensorflow/tensorflow/blob/master/SUPPORT.md

**What makes it great:**
- Academic and enterprise audiences addressed
- Links to learning paths
- Stack Overflow emphasized for technical questions
- Multiple language support mentioned
- Research collaborations welcomed

**Pattern extracted:**
```markdown
# Support

## Getting Started

New to [Project]? Start here:
- [Beginner Tutorial](link)
- [Getting Started Guide](link)
- [Core Concepts](link)

## Technical Questions

**[Stack Overflow](link)** is the best place for technical questions.
- Tag your question with `[project-tag]`
- Search before asking
- Provide minimal reproducible example

## Community

- [Forum](link) - General discussions
- [Mailing List](link) - Announcements
- [Social Media](link) - Updates

## Research Collaboration

Interested in research partnerships? See [Research page](link)

## Enterprise Solutions

For production support and SLAs: [Contact sales](link)

## Issue Reporting

See [CONTRIBUTING.md](link) for bug reporting guidelines.
```

**When to use:** Academic/research projects with enterprise applications

### 5. Ruby on Rails (rails/rails)

**URL:** https://github.com/rails/rails/blob/main/.github/SUPPORT.md

**What makes it great:**
- Very concise and to the point
- Directs to official channels immediately
- No fluff or over-explanation
- Issue policy is clear

**Pattern extracted:**
```markdown
# Support

## Questions and Help

Please use these resources for questions:

- [Stack Overflow](link) with tag `rails`
- [Rails Forum](link)
- [Ruby on Rails Discord](link)

## Bug Reports

See [CONTRIBUTING.md](link) for how to report bugs.

Issues asking questions will be closed. Please use the resources above instead.
```

**When to use:** Mature projects with established communities

## Common Patterns

### Pattern: Resource Hierarchy

**Purpose:** Guide users from self-service to direct support

**Example:**
```markdown
## Getting Help

### 1. Self-Service (Fastest)
- [Documentation](link)
- [FAQ](link)
- [Troubleshooting Guide](link)

### 2. Community Support (24-48 hours)
- [GitHub Discussions](link)
- [Stack Overflow](link)

### 3. Real-Time Chat (If available)
- [Discord/Slack](link)

### 4. Issue Tracker (Bugs only)
- [GitHub Issues](link)

### 5. Commercial Support (SLA)
- [Enterprise Support](link)
```

**Best practices:**
- Order by speed and self-service first
- Set response time expectations
- Make it easy to escalate if needed
- Keep issue tracker sacred for actual bugs

### Pattern: What Qualifies as a Support Question

**Purpose:** Prevent issue tracker pollution

**Example:**
```markdown
## Support Questions vs. Bug Reports

### Support Questions (Use Discussions/Forum)
- "How do I configure X?"
- "Why is my code not working?"
- "What's the best way to Y?"
- "Can I use this for Z?"

### Bug Reports (Use Issue Tracker)
- Reproducible bugs in the library
- Documentation errors
- Build/install failures in supported environments
- Performance regressions

**Rule of thumb:** If it works for others but not you, it's a support question. If it's broken for everyone, it's a bug.
```

**Best practices:**
- Provide clear examples of each
- Explain the distinction
- Give rule of thumb
- Be respectful but firm

### Pattern: Response Time Expectations

**Purpose:** Set realistic expectations

**Example:**
```markdown
## Response Times

We aim to respond within these timeframes:

| Channel | Response Time | Best For |
|---------|--------------|----------|
| Documentation | Instant | Most questions |
| Stack Overflow | 2-24 hours | Technical issues |
| GitHub Discussions | 24-72 hours | General questions |
| Discord | Varies | Real-time chat |
| GitHub Issues | 1-7 days | Bugs and features |
| Enterprise Support | 4-8 hours | Critical production issues |

**Note:** These are community best-effort times, not guarantees. For guaranteed SLA, see [Enterprise Support](link).
```

**Best practices:**
- Be realistic, not optimistic
- Differentiate free vs. paid
- State these are goals, not promises
- Update based on actual performance

### Pattern: How to Ask Good Questions

**Purpose:** Improve question quality and response rate

**Example:**
```markdown
## How to Ask for Help

Good questions get faster, better answers. Please include:

1. **What you're trying to do** - Your goal, not just the error
2. **What you've tried** - Show your research effort
3. **Minimal reproducible example** - Simplest code that shows the problem
4. **Environment** - Versions, OS, relevant config
5. **Error messages** - Full, unedited error output

### Example Good Question

> I'm trying to implement authentication using JWT tokens. I've followed the [tutorial](link) but get "Invalid signature" error.
>
> **Environment:**
> - Project v2.3.0
> - Node 18.x
> - Ubuntu 22.04
>
> **Code:**
> ```javascript
> [minimal example]
> ```
>
> **Error:**
> ```
> [full error]
> ```
>
> I've tried [X, Y, Z] based on [links to what I read].

### Example Bad Question

> "It doesn't work. Help?"
```

**Best practices:**
- Show by example
- Make it easy to help
- Reward good questions with fast answers
- Link to "How to Ask" guides

### Pattern: Security Issue Handling

**Purpose:** Provide safe channel for vulnerability reports

**Example:**
```markdown
## Security Issues

**DO NOT file public issues for security vulnerabilities.**

To report a security vulnerability:
1. Email security@project.org
2. Include description and reproduction steps
3. Allow 90 days for patching before disclosure

See [SECURITY.md](link) for full security policy.

We appreciate responsible disclosure and will credit reporters.
```

**Best practices:**
- Emphasize private reporting
- Provide dedicated email
- Link to full security policy
- Mention responsible disclosure timeline
- Offer credit/recognition

## Structure Levels by Project Size

### Minimal (100-200 lines)

**For:** Small projects, solo maintainers

**Sections:**
- Where to ask questions
- Issue reporting link
- Response expectation

**Example:**
```markdown
# Support

## Questions

Please ask questions on [Stack Overflow](link) with tag `project-name`.

## Bugs

See [CONTRIBUTING.md](link) for bug reporting.

## Response Time

Community support is best-effort. Typical response: 24-48 hours.
```

### Standard (200-400 lines)

**For:** Most open source projects

**Sections:**
- Multiple support channels
- What qualifies as support vs. bug
- How to ask good questions
- Response time expectations
- Security reporting

**Example:**
```markdown
# Support

## Before Asking

[Self-service resources]

## Where to Ask

[Community channels with descriptions]

## Bug Reports

[Link to contributing guide]

## How to Ask

[Tips for good questions]

## Response Times

[Expectations table]

## Security

[Responsible disclosure]
```

### Comprehensive (400-600 lines)

**For:** Large projects, enterprise tools

**Sections:**
- All standard sections plus:
- Troubleshooting guides inline
- Learning paths
- Commercial support tiers
- Community programs
- Contribution pathways

**Example:**
```markdown
# Support

## Getting Started

[Learning resources]

## Common Issues

[Troubleshooting section]

## Support Channels

[Detailed channel descriptions]

## Support Tiers

[Free vs. paid comparison]

## How to Ask

[Detailed guidance]

## Contributing

[Link to contributor support]

## Security

[Full policy inline]
```

## Anti-Patterns to Avoid

### ❌ "Email the Maintainer"

**Problem:** Creates bottleneck, not scalable

**Solution:** Use public channels so answers help many

### ❌ No Expectations

**Problem:** Users don't know when to expect help

**Solution:** Set realistic response time expectations

### ❌ Only Issue Tracker

**Problem:** Issues fill with support questions

**Solution:** Provide dedicated Q&A channels

### ❌ Unclear Channels

**Problem:** Users post in wrong place

**Solution:** Clearly differentiate when to use each channel

### ❌ Hostile Tone

**Problem:** "Don't file issues for stupid questions"

**Solution:** Be helpful and redirect kindly

## Integration with GitHub Features

### GitHub Discussions

Enable and configure:
- Q&A category for questions
- General category for discussions
- Announcements category for updates

Link in SUPPORT.md:
```markdown
Visit [GitHub Discussions](link) for questions and community chat.
```

### Issue Templates

Create `.github/ISSUE_TEMPLATE/config.yml`:
```yaml
blank_issues_enabled: false
contact_links:
  - name: Question or General Help
    url: https://github.com/username/repo/discussions
    about: Please use Discussions for questions
  - name: Stack Overflow
    url: https://stackoverflow.com/questions/tagged/project-name
    about: Ask technical questions here
```

### Custom Issue Form

Add link to support resources in issue templates:
```yaml
- type: markdown
  attributes:
    value: |
      Before filing an issue, please check:
      - [Documentation](link)
      - [Support Resources](link)
      - [Existing Issues](link)
```

## Tools and Automation

### Auto-Reply Bot

For issues with keywords like "how do I", auto-reply:
```markdown
👋 Thanks for your interest! This looks like a usage question.

Please post this in [GitHub Discussions](link) where the community can help. Issues are for confirmed bugs only.

See [SUPPORT.md](link) for all help resources.
```

### Issue Close Reason

GitHub now allows close reasons. Use:
- "Not planned" for questions redirected to discussions
- "Completed" for resolved issues
- "Duplicate" with link to original

### Saved Replies

Create GitHub saved replies for common redirects:
- "Please use Discussions for questions"
- "See SUPPORT.md for help resources"
- "Can you provide a minimal reproduction?"

## Testing Your Support Documentation

**Checklist:**
- [ ] Are all support channels clearly listed?
- [ ] Is there a channel for questions (not just issues)?
- [ ] Are response time expectations set?
- [ ] Is the distinction between support/bugs clear?
- [ ] Is security reporting addressed?
- [ ] Are links working and up-to-date?
- [ ] Is the tone helpful and welcoming?

**User Test:**
- Give to someone unfamiliar with project
- Ask: "Where would you go for help with X?"
- Update based on confusion points

## Summary

Great support documentation:
1. **Directs** - Clear routing to appropriate channels
2. **Sets expectations** - Response times and availability
3. **Protects** - Keeps issue tracker for actual issues
4. **Scales** - Community can help community
5. **Welcomes** - Friendly tone, no gatekeeping

The goal is to help users get answers quickly while maintaining project health and maintainer sanity.
