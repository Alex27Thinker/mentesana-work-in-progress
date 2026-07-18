# Software License Comparison Guide

Detailed side-by-side comparison of popular open source licenses with practical use cases and recommendations.

## Overview Table

| License | Type | Complexity | Adoption | Patent Protection | Copyleft | Best For |
|---------|------|------------|----------|-------------------|----------|----------|
| MIT | Permissive | Very Simple | Very High | No | No | Maximum adoption |
| Apache-2.0 | Permissive | Moderate | High | Yes | No | Patent concerns |
| BSD-3-Clause | Permissive | Simple | High | No | No | Academic/Research |
| GPL-3.0 | Copyleft | Complex | Moderate | Yes | Strong | Prevent proprietary forks |
| AGPL-3.0 | Network Copyleft | Complex | Low | Yes | Strongest | SaaS/Network services |
| LGPL-2.1 | Weak Copyleft | Complex | Low | No | Library-only | Libraries with copyleft |
| MPL-2.0 | Weak Copyleft | Moderate | Low | Yes | File-level | Hybrid projects |
| FSL-1.1-MIT | Time-Delayed | Moderate | Emerging | No | Temporary | Commercial → OSS |

## Detailed Comparisons

### MIT License

**Full name:** MIT License

**Key characteristics:**
- Maximum simplicity (171 words)
- Requires attribution and license notice
- No patent grant (common law applies)
- No copyleft requirements
- Most popular permissive license

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

**Conditions:**
- ⚠️ Include license and copyright notice

**Limitations:**
- ❌ No liability protection
- ❌ No warranty
- ❌ No trademark protection
- ❌ No explicit patent grant

**Best for:**
- Projects wanting maximum adoption
- JavaScript libraries (npm ecosystem standard)
- Educational projects
- Tools and utilities
- Open source advocacy projects

**Not ideal for:**
- Projects with patent concerns
- When you want to prevent proprietary forks
- Projects requiring contributor patent grants

**Real-world examples:**
- React (Facebook)
- Node.js
- jQuery
- Rails
- Babel

**License text:** [Full MIT text at https://opensource.org/licenses/MIT]

---

### Apache License 2.0

**Full name:** Apache License, Version 2.0

**Key characteristics:**
- Explicit patent grant from contributors
- Patent retaliation clause (defensive)
- Requires NOTICE file for attributions
- Longer than MIT (9,000+ words)
- Second most popular permissive license

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use
- ✅ Patent use (explicit grant)

**Conditions:**
- ⚠️ Include license and copyright notice
- ⚠️ State significant changes
- ⚠️ Include NOTICE file if present

**Limitations:**
- ❌ Trademark use
- ❌ No liability
- ❌ No warranty

**Best for:**
- Projects where patent protection matters
- Corporate/enterprise projects
- Projects with potential patent trolling risks
- Android/mobile applications
- Projects with many contributors

**Not ideal for:**
- Simple utilities (MIT simpler)
- GPL compatibility needed (Apache → GPL allowed, but complex)
- When brevity matters

**Real-world examples:**
- Kubernetes
- Android
- Apache HTTP Server
- TensorFlow
- Swift

**Patent protection explained:**
Any contributor granting a license to their contribution also grants a patent license. If they later sue for patent infringement related to the code, they lose all patent rights to the project.

**License text:** [Full Apache 2.0 text at https://www.apache.org/licenses/LICENSE-2.0]

---

### BSD 3-Clause License

**Full name:** BSD 3-Clause "New" or "Revised" License

**Key characteristics:**
- Similar to MIT but with trademark protection
- Three clauses vs. two in BSD-2-Clause
- University of California origin
- Popular in academic/research communities

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

**Conditions:**
- ⚠️ Include license and copyright notice

**Limitations:**
- ❌ Trademark use (explicit prohibition)
- ❌ No liability
- ❌ No warranty
- ❌ Cannot use contributors' names for endorsement

**Best for:**
- Academic and research projects
- Projects concerned about name misuse
- When you want permissive but trademark protection
- University projects

**Not ideal for:**
- When MIT's simplicity is preferred
- Projects needing patent grants
- Corporate projects (Apache better)

**Real-world examples:**
- OpenBSD
- nginx
- D3.js

**BSD-2 vs BSD-3:**
- BSD-2: Simpler, no trademark clause
- BSD-3: Adds "no endorsement" clause

**License text:** [Full BSD-3 text at https://opensource.org/licenses/BSD-3-Clause]

---

### GNU General Public License v3.0 (GPL-3.0)

**Full name:** GNU General Public License, Version 3.0

**Key characteristics:**
- Strong copyleft (viral)
- Derivatives must use same license
- Patent grant included
- Anti-Tivoization provisions
- Long and complex (5,000+ words)

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Patent use
- ✅ Private use

**Conditions:**
- ⚠️ Disclose source code
- ⚠️ Include license and copyright notice
- ⚠️ State significant changes
- ⚠️ Same license for derivatives (copyleft)

**Limitations:**
- ❌ No liability
- ❌ No warranty

**Best for:**
- Projects wanting to ensure freedom (derivatives stay open)
- Preventing proprietary forks
- Free software philosophy projects
- Desktop applications
- Developer tools

**Not ideal for:**
- Libraries (use LGPL instead)
- When you want maximum adoption (copyleft scares some companies)
- Network services (use AGPL instead)
- Corporate-friendly projects

**Real-world examples:**
- Linux kernel (GPL-2.0, but similar)
- Git
- Bash
- GIMP
- WordPress (GPL-2.0)

**Copyleft explained:**
If you distribute modified GPL code, you must also license your modifications under GPL and provide source code. This "viral" nature ensures derivatives remain free/open.

**GPL-2.0 vs GPL-3.0:**
- GPL-3.0 adds patent protection
- GPL-3.0 includes anti-Tivoization (hardware restrictions)
- GPL-2.0 more compatible with some projects
- GPL-3.0 more explicit about distribution methods

**License text:** [Full GPL-3.0 text at https://www.gnu.org/licenses/gpl-3.0.txt]

---

### GNU Affero General Public License v3.0 (AGPL-3.0)

**Full name:** GNU Affero General Public License, Version 3.0

**Key characteristics:**
- Network copyleft (strongest copyleft)
- Triggers on network use, not just distribution
- Closes SaaS loophole in GPL
- Based on GPL-3.0 with network clause

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Patent use
- ✅ Private use

**Conditions:**
- ⚠️ Disclose source code
- ⚠️ Network use = distribution (must provide source)
- ⚠️ Include license and copyright notice
- ⚠️ State significant changes
- ⚠️ Same license for derivatives

**Limitations:**
- ❌ No liability
- ❌ No warranty

**Best for:**
- SaaS applications
- Network services and APIs
- Web applications
- Cloud services
- Preventing proprietary hosted services

**Not ideal for:**
- Libraries (too restrictive)
- When you want broad adoption
- Mobile apps (problematic on app stores)
- Corporate environments (often blacklisted)

**Real-world examples:**
- MongoDB (switched to SSPL, similar concept)
- Mastodon
- NextCloud
- GhostBSD

**The SaaS loophole:**
GPL requires source distribution when you "distribute" software. With SaaS, you run software on your server and users access via network - no distribution occurs, no source requirement. AGPL closes this by treating network access as distribution.

**Corporate adoption:**
Many companies ban AGPL usage because network use triggers copyleft. Google reportedly prohibits AGPL code on servers.

**License text:** [Full AGPL-3.0 text at https://www.gnu.org/licenses/agpl-3.0.txt]

---

### GNU Lesser General Public License v2.1 (LGPL-2.1)

**Full name:** GNU Lesser General Public License, Version 2.1

**Key characteristics:**
- Weak copyleft (library-focused)
- Linking doesn't trigger copyleft
- Modifications to library must be LGPL
- Applications using library can be proprietary

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

**Conditions:**
- ⚠️ Disclose source of library modifications
- ⚠️ Include license and copyright notice
- ⚠️ State changes to library
- ⚠️ Library modifications must be LGPL
- ⚠️ Applications can be proprietary

**Limitations:**
- ❌ No liability
- ❌ No warranty

**Best for:**
- Shared libraries
- When you want copyleft but not to scare away proprietary users
- Alternative to permissive for libraries
- Standard libraries (glibc model)

**Not ideal for:**
- Applications (use GPL)
- When MIT/Apache simplicity preferred
- Modern languages where "linking" is ambiguous

**Real-world examples:**
- GTK+
- Qt (dual-licensed LGPL/Commercial)
- glibc
- OpenOffice.org libraries

**How it works:**
If you modify the LGPL library itself, you must release those modifications as LGPL. But applications that merely use/link to the library can be proprietary.

**License text:** [Full LGPL-2.1 text at https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt]

---

### Mozilla Public License 2.0 (MPL-2.0)

**Full name:** Mozilla Public License, Version 2.0

**Key characteristics:**
- File-level copyleft
- Modifications to MPL files must stay MPL
- Can combine with proprietary files in same project
- Patent grant included
- Designed for mixed-license codebases

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Patent use
- ✅ Private use
- ✅ Sublicensing (for non-MPL portions)

**Conditions:**
- ⚠️ Disclose source of MPL-licensed files
- ⚠️ Include license in MPL files
- ⚠️ State changes to MPL files
- ⚠️ MPL files stay MPL (file-level copyleft)

**Limitations:**
- ❌ Trademark use
- ❌ No liability
- ❌ No warranty

**Best for:**
- Projects mixing open and proprietary code
- Libraries that may be used in proprietary products
- When you want copyleft benefits without full GPL restriction
- Corporate-friendly copyleft

**Not ideal for:**
- Simple projects (MIT simpler)
- Strong copyleft needs (use GPL)
- When file boundaries are unclear

**Real-world examples:**
- Firefox
- Thunderbird
- LibreOffice

**File-level copyleft explained:**
Only the actual MPL-licensed files must remain MPL. You can combine them with proprietary files in the same program. Contrast with GPL where the entire combined work becomes GPL.

**License text:** [Full MPL-2.0 text at https://www.mozilla.org/en-US/MPL/2.0/]

---

### Functional Source License 1.1, MIT Future (FSL-1.1-MIT)

**Full name:** Functional Source License, version 1.1, with MIT Future License

**Key characteristics:**
- Source-available now, open source later
- Production use restricted for 2 years
- Automatically becomes MIT after 2 years
- Non-compete clause during restricted period
- Not OSI-approved (source-available, not open source)

**Permissions (immediate):**
- ✅ Read the source code
- ✅ Modification (for testing/development)
- ✅ Distribution of source
- ✅ Private use (non-production)

**Permissions (after 2 years):**
- ✅ Everything MIT allows (full open source)

**Conditions:**
- ⚠️ Cannot use in production for 2 years
- ⚠️ Cannot use in competing products for 2 years
- ⚠️ Include license notice
- ⚠️ After 2 years, automatic MIT license applies

**Limitations (during restriction):**
- ❌ No production use
- ❌ No competing services
- ❌ Not OSI-approved open source

**Best for:**
- Commercial SaaS companies
- Products needing revenue runway before open sourcing
- "Eventual open source" strategy
- Building trust while protecting business
- Companies following Sentry's model

**Not ideal for:**
- Traditional open source projects
- When you need OSI-approved license
- Projects wanting immediate open source adoption
- Non-commercial projects (just use MIT)

**Real-world examples:**
- Sentry (pioneered this model)
- Codecov
- GitButler
- Other commercial OSS companies

**How it works:**
1. Company releases code under FSL-1.1-MIT
2. Users can read, modify, test the code
3. Users cannot use in production or competing services
4. After 2 years from release date, license automatically becomes MIT
5. Old versions become fully open source on rolling 2-year schedule

**Business model:**
Gives companies a 2-year competitive advantage while building trust by committing to eventual open source. Users know the software will become truly open source, just not immediately.

**Criticism:**
- Not considered true "open source" by OSI/FSF
- Two-tier access (paying customers vs. free users)
- Complex for users to understand restrictions

**License text:** [Full FSL-1.1-MIT text at https://fsl.software]

---

## License Selection Matrix

### By Project Type

| Project Type | First Choice | Alternative | Notes |
|--------------|--------------|-------------|-------|
| JavaScript library | MIT | Apache-2.0 | npm ecosystem standard is MIT |
| Python library | MIT | Apache-2.0 | PyPI convention favors permissive |
| Rust library | MIT/Apache-2.0 dual | MPL-2.0 | Dual licensing common in Rust |
| CLI tool | MIT | GPL-3.0 | Permissive for adoption, GPL to prevent proprietary versions |
| Desktop app | GPL-3.0 | MIT | GPL prevents proprietary forks |
| Web service | AGPL-3.0 | FSL-1.1-MIT | AGPL prevents proprietary hosting, FSL for commercial |
| SaaS product | FSL-1.1-MIT | AGPL-3.0 | FSL for commercial with eventual OSS |
| Mobile app | MIT | Apache-2.0 | App stores problematic with copyleft |
| Embedded/IoT | MIT | GPL-3.0 | Permissive for hardware integration |
| Framework | MIT | Apache-2.0 | Frameworks need wide adoption |

### By Business Model

| Business Model | Recommended License | Why |
|----------------|---------------------|-----|
| No monetization | MIT | Maximum adoption and contribution |
| Open core | Apache-2.0 (core) + Commercial (premium) | Core permissive, premium proprietary |
| Dual licensing | GPL-3.0 + Commercial | Free for OSS, paid for proprietary use |
| SaaS with OSS plans | AGPL-3.0 or FSL-1.1-MIT | Prevent competition from hosting your code |
| Consulting/services | MIT or Apache-2.0 | Permissive to drive adoption, monetize services |
| Hosted only | Proprietary or AGPL-3.0 | Don't need open source, or prevent competitors |

### By User Goal

| Goal | License | Tradeoff |
|------|---------|----------|
| Maximum adoption | MIT | No copyleft protection |
| Patent protection | Apache-2.0 | More complex than MIT |
| Prevent proprietary forks | GPL-3.0 | Reduces corporate adoption |
| Prevent SaaS competition | AGPL-3.0 | Very restrictive, often blacklisted |
| Revenue + eventual OSS | FSL-1.1-MIT | Not true open source initially |
| Corporate-friendly copyleft | MPL-2.0 | File-level granularity can be confusing |

## License Compatibility

### Permissive License Compatibility

| From ↓ To → | MIT | Apache-2.0 | BSD-3 | GPL-3.0 | AGPL-3.0 |
|-------------|-----|------------|-------|---------|----------|
| **MIT** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Apache-2.0** | ❌ | ✅ | ❌ | ⚠️ | ⚠️ |
| **BSD-3** | ❌ | ❌ | ✅ | ✅ | ✅ |

✅ = Can relicense to
❌ = Cannot relicense to
⚠️ = Compatible but complex

### Copyleft License Compatibility

| From ↓ To → | GPL-2.0 | GPL-3.0 | AGPL-3.0 | LGPL-2.1 | MPL-2.0 |
|-------------|---------|---------|----------|----------|---------|
| **GPL-2.0** | ✅ | ⚠️ | ❌ | ❌ | ❌ |
| **GPL-3.0** | ❌ | ✅ | ✅ | ❌ | ⚠️ |
| **AGPL-3.0** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **LGPL-2.1** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **MPL-2.0** | ✅ | ✅ | ✅ | ❌ | ✅ |

⚠️ GPL-2 to GPL-3 migration requires "GPL-2.0-or-later" clause

### Combining Licenses in One Project

**Allowed combinations:**
- MIT + Apache-2.0 (both permissive)
- LGPL + GPL (LGPL allows)
- MPL-2.0 + Proprietary (file-level separation)
- MIT/Apache/BSD + GPL (permissive can become GPL)

**Problematic combinations:**
- GPL + Apache-2.0 (patent clause conflict)
- GPL-2.0 + GPL-3.0 (version incompatibility)
- AGPL + Proprietary (network use triggers)

## Common Questions

**Q: MIT vs Apache-2.0 - which should I choose?**
A: MIT for simplicity and maximum adoption. Apache-2.0 if you or contributors have patents or patent concerns.

**Q: GPL vs AGPL - what's the difference?**
A: GPL triggers on distribution. AGPL triggers on network use. Use AGPL for web services to prevent proprietary hosted versions.

**Q: Can I change my license later?**
A: Only if you own all copyright or get permission from all contributors. Very difficult for established projects.

**Q: What if I use libraries with different licenses?**
A: Depends on compatibility. Permissive licenses are usually fine. Copyleft licenses require careful analysis.

**Q: Is FSL "real" open source?**
A: No, not by OSI definition. It's source-available with delayed open source. But it's ethical and sustainable.

**Q: How do I dual license?**
A: Include two LICENSE files, explain in README which scenarios use which license.

## Resources

- [Choose a License](https://choosealicense.com) - GitHub's license picker
- [TLDRLegal](https://tldrlegal.com) - Plain English license summaries
- [OSI License List](https://opensource.org/licenses) - Official open source licenses
- [SPDX License List](https://spdx.org/licenses/) - Standard license identifiers
- [Functional Source License](https://fsl.software) - FSL official site
- [GNU Licenses](https://www.gnu.org/licenses/) - GPL/LGPL/AGPL resources
