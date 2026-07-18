---
name: readme-and-co:license-selection
description: This skill should be used when selecting software licenses, choosing Creative Commons licenses, discussing multi-licensing strategies, or when user asks "what license should I use", "help me choose a license", "explain FSL", "dual licensing", "MIT vs Apache", or mentions license compatibility and selection.
version: 0.1.0
---

# License Selection for Software and Content

## Purpose

Guide users through selecting appropriate licenses for code, documentation, and content. Provide decision trees, use case analysis, and multi-licensing strategies with emphasis on practical outcomes.

## When to Use This Skill

Use this skill when:
- User needs to choose a software license
- Selecting Creative Commons licenses for documentation/media
- Discussing multi-licensing or dual-licensing strategies
- Comparing license options (MIT vs Apache, GPL vs permissive)
- Understanding license compatibility
- Considering FSL-1.1-MIT or time-delayed open source
- Setting up license files in repositories

## License Hierarchy and Recommendations

### For Code Projects

**Tier 1: GitHub-Approved Licenses (Recommended First)**

Present these licenses first for code projects:

- **MIT**: Maximum adoption, simple, permissive
- **Apache-2.0**: Permissive with patent grant protection
- **GPL-3.0**: Strong copyleft, derivatives must be open source
- **AGPL-3.0**: Network copyleft, closes SaaS loophole
- **BSD-3-Clause**: Permissive with trademark protection

**Tier 2: Special Purpose**

- **FSL-1.1-MIT**: Commercial now, MIT in 2 years (Sentry model)
- **MPL-2.0**: File-level copyleft, good for libraries
- **LGPL-2.1**: Library-focused copyleft

**Tier 3: OSI-Approved (Not on GitHub List)**

Recommend only if specific requirements demand them.

### For Documentation and Media

**Tier 1: Creative Commons (Recommended First)**

Present these for non-code content:

- **CC-BY-4.0**: Attribution only, most permissive
- **CC-BY-SA-4.0**: Attribution + ShareAlike (copyleft)
- **CC0-1.0**: Public domain dedication
- **CC-BY-NC-4.0**: Attribution + NonCommercial (limits commercial use)

**Tier 2: Code Licenses**

Use only if documentation is code-adjacent (API docs in repo).

## License Decision Tree

### Quick Selection for Code

**Question 1: Do you want maximum adoption?**
- YES → **MIT License** (recommended for most projects)
- NO → Continue

**Question 2: Do you need patent protection?**
- YES → **Apache-2.0** (includes explicit patent grant)
- NO → Continue

**Question 3: Do you want copyleft (derivatives must be open source)?**
- YES → **GPL-3.0** (strong copyleft) or **AGPL-3.0** (for network services)
- NO → Continue

**Question 4: Is this a commercial SaaS that will become open source?**
- YES → **FSL-1.1-MIT** (2-year delay, then MIT)
- NO → Review detailed comparison

### Quick Selection for Documentation

**Question 1: Should others give attribution when using your work?**
- NO → **CC0-1.0** (public domain dedication)
- YES → Continue

**Question 2: Should derivative works also be open?**
- YES → **CC-BY-SA-4.0** (ShareAlike, like GPL for content)
- NO → Continue

**Question 3: Should commercial use be allowed?**
- YES → **CC-BY-4.0** (most permissive with attribution)
- NO → **CC-BY-NC-4.0** (non-commercial restriction)

## Multi-Licensing Strategies

### What is Multi-Licensing?

Offering the same software under multiple license options, allowing users to choose which license terms they prefer.

**Common patterns:**

1. **Permissive + Copyleft**: MIT + GPL (user chooses)
2. **Open Source + Commercial**: GPL + Proprietary (dual licensing)
3. **Time-Delayed**: FSL → MIT (automatic transition)

### When to Use Multi-Licensing

**Good candidates:**
- Commercial open-source projects needing revenue
- Projects wanting copyleft but not wanting to scare away permissive-only users
- SaaS products transitioning to open source

**Business models:**
- **Open Core**: Base under OSS, premium features under commercial
- **Dual Licensing**: GPL for open source, commercial for proprietary use
- **Time-Delayed**: FSL today, MIT automatically in 2 years

### FSL-1.1-MIT (Functional Source License)

**What it is:**
- Source-available now, production use restricted
- Automatic MIT license after 2 years from release
- Used by Sentry and other commercial OSS companies

**When to recommend:**
- Commercial SaaS products
- Projects wanting eventual open source with revenue period
- Companies following "open source with a business model"

**Key points:**
- Users can read, modify, test the code immediately
- Cannot use in production or competing services for 2 years
- After 2 years, becomes fully MIT licensed automatically

**Not OSI-approved but ethical and sustainable**

## License Characteristics Reference

### Permissions Comparison

| License | Commercial Use | Modifications | Distribution | Patent Grant | Private Use |
|---------|---------------|---------------|--------------|-------------|-------------|
| MIT | ✓ | ✓ | ✓ | — | ✓ |
| Apache-2.0 | ✓ | ✓ | ✓ | ✓ | ✓ |
| GPL-3.0 | ✓ | ✓ | ✓ | ✓ | ✓ |
| AGPL-3.0 | ✓ | ✓ | ✓ | ✓ | ✓ |
| FSL-1.1-MIT | Limited* | ✓ | ✓ | — | ✓ |

*FSL: No production/competing use for 2 years, then becomes MIT

### Conditions Comparison

| License | Disclose Source | License Notice | State Changes | Same License |
|---------|----------------|----------------|---------------|------------|
| MIT | — | ✓ | — | — |
| Apache-2.0 | — | ✓ | ✓ | — |
| GPL-3.0 | ✓ | ✓ | ✓ | ✓ (copyleft) |
| AGPL-3.0 | ✓ | ✓ | ✓ | ✓ (network) |
| FSL-1.1-MIT | ✓ | ✓ | — | — |

## Practical License Recommendations

### By Project Type

**Open Source Library:**
- **First choice**: MIT (widest adoption)
- **If patent concerns**: Apache-2.0
- **If want copyleft**: LGPL-2.1 (library-specific)

**Open Source Application:**
- **First choice**: MIT or GPL-3.0 (user preference)
- **If network service**: AGPL-3.0 (prevents proprietary SaaS)
- **If eventual open source**: FSL-1.1-MIT

**Documentation/Tutorials:**
- **First choice**: CC-BY-4.0 (attribution required)
- **If want ShareAlike**: CC-BY-SA-4.0
- **If public domain**: CC0-1.0

**Commercial SaaS:**
- **First choice**: FSL-1.1-MIT (delayed open source)
- **Alternative**: Dual GPL + Commercial
- **Open core**: Apache-2.0 for base, commercial for premium

### By User Goal

**Goal: Maximum adoption and contributions**
→ **MIT** (most permissive, well-known, widely accepted)

**Goal: Prevent proprietary forks**
→ **GPL-3.0** (strong copyleft, derivatives must be open source)

**Goal: Prevent proprietary SaaS**
→ **AGPL-3.0** (network copyleft, closes SaaS loophole)

**Goal: Patent protection**
→ **Apache-2.0** (explicit patent grant and retaliation clause)

**Goal: Business model + open source**
→ **FSL-1.1-MIT** (revenue window, then open source) or **Dual GPL + Commercial**

## Multi-Licensing Implementation

### File Structure for Dual Licensing

```
repository/
├── LICENSE (primary license, e.g., GPL-3.0)
├── LICENSE.commercial (commercial terms, or link to purchase)
└── README.md (explains licensing options)
```

### README Section Template

```markdown
## License

This project is dual-licensed:

- **Open Source**: GNU General Public License v3.0 (GPL-3.0)
  - Free for open source projects
  - Derivatives must also be open source

- **Commercial**: Proprietary commercial license
  - For use in proprietary/closed-source projects
  - Contact: sales@example.com

Choose the license that best fits your use case.
```

### FSL Multi-License Pattern

```
repository/
├── LICENSE.md (FSL-1.1-MIT with both licenses)
└── README.md (explains time-delayed transition)
```

## Additional Resources

### Reference Files

For detailed analysis and comparisons:
- **`references/license-comparison.md`** - Side-by-side detailed license comparisons
- **`references/multi-licensing-guide.md`** - Dual licensing models, business patterns, real-world examples from FOSSA
- **`references/fsl-explained.md`** - FSL-1.1-MIT deep dive, use cases, companies using it
- **`references/creative-commons-guide.md`** - Complete CC license guide for content creators

### License Templates

Complete license templates available in plugin:
- **`../../templates/LICENSE/github/`** - 21 GitHub-approved licenses (MIT, Apache-2.0, GPL-3.0, etc.)
- **`../../templates/LICENSE/creative-commons/`** - Creative Commons licenses (CC0, CC-BY-4.0, CC-BY-SA-4.0, etc.)
- **`../../templates/LICENSE/fsl/`** - FSL-1.1-MIT and variants

Use the `populate_license.py` script to render templates with project-specific variables (copyright holder, year, etc.)

## Quick Reference

**For most code projects:** MIT (permissive, popular)

**Need patent protection:** Apache-2.0

**Want copyleft:** GPL-3.0 (code) or AGPL-3.0 (network services)

**For documentation:** CC-BY-4.0 (attribution) or CC-BY-SA-4.0 (copyleft)

**Commercial SaaS:** FSL-1.1-MIT (delayed open source)

**Multi-licensing:** GPL + Commercial (dual) or FSL → MIT (time-delayed)

Consult reference files for detailed comparisons and multi-licensing strategies.
