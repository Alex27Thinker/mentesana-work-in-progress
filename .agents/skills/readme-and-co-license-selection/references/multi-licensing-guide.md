# Multi-Licensing Guide

Comprehensive guide to dual licensing, multi-licensing strategies, business models, and real-world implementation examples.

## What is Multi-Licensing?

**Multi-licensing** is the practice of offering the same software under multiple different licenses, allowing users to choose which license terms they prefer to operate under.

**Key concept:** Same codebase, multiple license options for different use cases.

## Multi-Licensing Patterns

### Pattern 1: Dual Licensing (OSS + Commercial)

**Model:**
- Free open source license (usually GPL)
- Paid commercial/proprietary license

**How it works:**
1. Release software under strong copyleft (GPL/AGPL)
2. Offer commercial license for proprietary use
3. Users choose: Free with copyleft, or paid without copyleft

**Business logic:**
- GPL users must open source derivatives
- Companies wanting proprietary use pay for commercial license
- Company retains copyright to sell both licenses

**Best for:**
- Developer tools
- Libraries
- Database systems
- Developer-facing products

**Examples:**
- MySQL (GPL + Commercial)
- Qt (LGPL + Commercial)
- MongoDB (SSPL + Commercial, though SSPL controversial)
- Sentry (before FSL switch)

---

### Pattern 2: Permissive Dual Licensing

**Model:**
- Two permissive licenses (usually MIT + Apache-2.0)
- User chooses whichever fits their needs

**How it works:**
1. Include both LICENSE-MIT and LICENSE-APACHE files
2. Users select which license to operate under
3. Both are permissive, different trade-offs

**Business logic:**
- MIT: Simple, widely accepted
- Apache: Patent protection, corporate-friendly
- User picks based on their needs

**Best for:**
- Rust ecosystem (standard practice)
- Projects wanting maximum compatibility
- Corporate-friendly open source

**Examples:**
- Rust language itself (MIT/Apache-2.0)
- Most Rust crates
- Tokio
- Serde

---

### Pattern 3: Time-Delayed Open Source (FSL Model)

**Model:**
- Proprietary/source-available now
- Automatic open source license in future (e.g., 2 years)

**How it works:**
1. Release under FSL (or similar)
2. Users can read/modify/test but not use in production
3. After time period, license automatically converts to MIT/Apache

**Business logic:**
- Company gets competitive advantage period
- Users know it will become open source
- Builds trust through commitment to eventual OSS

**Best for:**
- SaaS products
- Commercial OSS companies
- Products needing revenue runway
- "Eventual open source" strategy

**Examples:**
- Sentry (FSL-1.1-MIT, pioneered this)
- GitButler
- Codecov
- Lago

---

### Pattern 4: Open Core

**Model:**
- Core features under permissive OSS license
- Premium features under proprietary license
- Different codebases/products

**How it works:**
1. Basic/core functionality is fully open source
2. Advanced/enterprise features are proprietary
3. Users can use free tier or pay for premium

**Business logic:**
- Open source drives adoption
- Premium features drive revenue
- Not technically multi-licensing (different products)

**Best for:**
- SaaS platforms
- Enterprise software
- Developer tools

**Examples:**
- GitLab (MIT core + Proprietary enterprise)
- Elastic (Elastic License + proprietary features)
- HashiCorp products

---

### Pattern 5: Weak Copyleft + Commercial

**Model:**
- LGPL/MPL for library
- Commercial license available
- Allows proprietary use via linking

**How it works:**
1. Library released under LGPL or MPL
2. Modifications to library must be open sourced
3. Applications using library can be proprietary
4. Commercial license available for special terms

**Business logic:**
- LGPL allows wide adoption
- Library modifications stay open
- Revenue from special licensing needs

**Best for:**
- UI frameworks
- Shared libraries
- Middleware

**Examples:**
- Qt (LGPL + Commercial)
- iText (AGPL + Commercial)

---

## Business Models Enabled by Multi-Licensing

### Model 1: Dual License Revenue

**Licenses:** GPL + Commercial

**Revenue source:** Selling commercial license

**Target customers:**
- Companies that can't comply with GPL
- Proprietary software vendors
- Companies that don't want to open source

**Pricing:**
- Per developer
- Per deployment
- Enterprise contracts

**Pros:**
- Predictable revenue
- Forces contribution or payment
- Protects competitive advantage

**Cons:**
- Requires copyright ownership of all code
- Must reject external contributions (or get copyright assignment)
- Can reduce community contribution

**Example: MySQL**
```
Free Tier: GPL-2.0
- Must open source derivative work
- Free for FOSS projects

Commercial: Custom terms
- $2,000/server/year
- Proprietary use allowed
- Support included
```

---

### Model 2: Support & Services

**Licenses:** Permissive OSS (MIT/Apache)

**Revenue source:** Support, consulting, hosting, training

**How it works:**
1. Fully open source software
2. Charge for support, hosting, professional services
3. Build ecosystem around free product

**Pros:**
- Maximum adoption
- Community contributions welcome
- No licensing complexity

**Cons:**
- Harder to monetize
- Can be undercut by competitors
- Services don't scale like product

**Examples:**
- Red Hat (support for Linux)
- Automattic (WordPress hosting)
- Databricks (managed Spark)

---

### Model 3: Open Core SaaS

**Licenses:** Permissive core + Proprietary features

**Revenue source:** Hosted version, premium features

**How it works:**
1. Self-hosted version is open source
2. Cloud-hosted version has premium features
3. Enterprise features are proprietary

**Pros:**
- OSS drives adoption
- Clear value differentiation
- Can scale product revenue

**Cons:**
- Community may fork and add "premium" features
- Balancing free vs. paid is tricky
- Harder to enforce boundaries

**Examples:**
- GitLab (CE vs EE)
- Mattermost
- Sentry (before FSL)

---

### Model 4: FSL Revenue Window

**Licenses:** FSL-1.1-MIT (or similar)

**Revenue source:** Production use during restriction period

**How it works:**
1. Free for development/testing
2. Pay for production use
3. Becomes MIT/Apache after 2 years

**Pros:**
- Commitment to open source builds trust
- Revenue runway for initial versions
- Eventually fully open source

**Cons:**
- Not "true" open source initially
- Complex for users to understand
- May hurt adoption

**Examples:**
- Sentry (now FSL)
- Codecov
- GitButler

---

## Implementing Multi-Licensing

### Legal Requirements

**Copyright ownership:**
- You must own copyright to all code
- OR get copyright assignment from contributors
- OR get dual-licensing agreement from contributors

**Contributor License Agreement (CLA):**
```markdown
By contributing, you agree:
1. You own the copyright to your contribution
2. You grant [Company] perpetual license to use under any terms
3. You grant [Company] ability to relicense your contribution
```

**Alternative: Copyright Assignment:**
```markdown
Contributors assign copyright to [Company]
[Company] can license under any terms
Original contributor retains right to use their contribution
```

---

### File Structure: Dual Licensing

**Recommended structure:**
```
repository/
├── LICENSE (primary license, e.g., GPL-3.0)
├── LICENSE.commercial (commercial terms or link)
├── README.md (explains licensing options)
└── CONTRIBUTING.md (mentions CLA requirement)
```

**Alternative structure:**
```
repository/
├── LICENSE-GPL.txt
├── LICENSE-COMMERCIAL.txt
└── README.md (choose your license)
```

---

### File Structure: Permissive Dual

**Rust-style structure:**
```
repository/
├── LICENSE-MIT
├── LICENSE-APACHE
├── README.md (dual licensed MIT/Apache-2.0)
└── CONTRIBUTING.md
```

**All source files header:**
```rust
// Licensed under either of
//  * Apache License, Version 2.0 (LICENSE-APACHE or http://www.apache.org/licenses/LICENSE-2.0)
//  * MIT license (LICENSE-MIT or http://opensource.org/licenses/MIT)
// at your option.
```

---

### README License Section

**Dual License Example (GPL + Commercial):**
```markdown
## License

This project is dual-licensed:

### Open Source License: GPL-3.0

For open source projects, this software is licensed under the GNU General Public License v3.0.

- ✅ Free to use in open source projects
- ✅ Modify and distribute
- ⚠️ Derivatives must also be open source under GPL-3.0
- ⚠️ Must disclose source code

### Commercial License

For proprietary/closed-source projects, we offer a commercial license.

- ✅ Use in proprietary software
- ✅ No open source requirements
- ✅ Priority support included
- 💰 Contact sales@example.com for pricing

**Which license should you choose?**
- Building an open source project? → Use GPL-3.0 (free)
- Building proprietary software? → Purchase commercial license

See [LICENSE](LICENSE) and [LICENSE.commercial](LICENSE.commercial) for full terms.
```

**Permissive Dual Example (MIT/Apache):**
```markdown
## License

Licensed under either of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
```

**FSL Example:**
```markdown
## License

This software is licensed under the Functional Source License, Version 1.1, MIT Future License.

### What this means:

**Today:**
- ✅ Free to use for development and testing
- ✅ Read and modify the source code
- ⚠️ Cannot use in production for 2 years
- ⚠️ Cannot use in competing products

**After 2 years from each release:**
- ✅ Automatically becomes MIT licensed
- ✅ Full open source permissions
- ✅ Use in production freely

**Why FSL?**
We're committed to open source, but need a runway to build a sustainable business. Every release becomes MIT licensed after 2 years, ensuring this software will be fully open source.

See [LICENSE.md](LICENSE.md) for full terms.
```

---

## Real-World Examples Analyzed

### Example 1: MySQL (Dual GPL/Commercial)

**Strategy:** Dual licensing GPL + Commercial

**How it works:**
- MySQL server is GPL-2.0
- Oracle sells commercial licenses
- GPL users must open source applications
- Commercial license removes GPL obligations

**Pricing model:**
- ~$2,000-5,000 per server per year
- Enterprise support included
- Consulting available

**Revenue:**
- Billions in revenue (now owned by Oracle)
- Large enterprise customers pay
- Small/OSS projects use GPL version

**Considerations:**
- Oracle owns all MySQL code
- Community contributions require copyright assignment
- Forks exist (MariaDB) to avoid Oracle control

---

### Example 2: Qt (LGPL/Commercial)

**Strategy:** LGPL + Commercial dual licensing

**How it works:**
- Qt framework is LGPL
- Applications can be proprietary (via linking)
- Modifications to Qt must be open sourced
- Commercial license for special needs

**Pricing model:**
- Free: LGPL (for most uses)
- Commercial: $459/month per developer
- Commercial includes:
  - No LGPL obligations
  - Early access to new features
  - Support

**Why buy commercial?**
- Static linking (LGPL requires dynamic)
- iOS/Android where LGPL is problematic
- Don't want to provide Qt source changes
- Enterprise support

**Revenue:**
- Sustainable business model
- Widely used (KDE, many commercial apps)
- Community contributions accepted

---

### Example 3: Sentry (FSL-1.1-MIT)

**Strategy:** Time-delayed open source via FSL

**Timeline:**
- Pre-2019: BSD-3-Clause (fully open source)
- 2019-2023: BSL (Business Source License, 3 years)
- 2023+: FSL-1.1-MIT (2 years)

**How FSL works for Sentry:**
- New releases are FSL (source-available)
- Cannot use in production without license
- Cannot run competing error tracking SaaS
- After 2 years, release becomes MIT
- Old versions are all MIT now

**Pricing model:**
- Free tier: Self-hosted (FSL restrictions)
- Paid: Cloud hosting (no restrictions)
- Enterprise: On-prem license

**Why they switched:**
- Competitors were hosting Sentry as a service
- Needed revenue to sustain development
- Commitment to eventual open source maintains trust

**Community reaction:**
- Mixed: Some unhappy about "not real OSS"
- Understanding: Most appreciate honesty about sustainability
- Forks: Some created before FSL (remain BSD)

---

### Example 4: GitLab (Open Core)

**Strategy:** Open Core (CE vs EE)

**How it works:**
- GitLab CE (Community Edition): MIT licensed
- GitLab EE (Enterprise Edition): Proprietary
- Different codebases (CE is subset)

**Feature split:**
- CE: Core Git, CI/CD, basic features
- EE: Security scanning, advanced CI, compliance, etc.

**Pricing model:**
- Free: CE self-hosted
- SaaS: Freemium → paid tiers
- Enterprise: EE license + support

**Revenue:**
- Public company (NASDAQ: GTLB)
- Most revenue from SaaS and EE
- CE drives adoption

**Challenges:**
- Community occasionally forks to add "premium" features
- Balancing free vs. paid is constant challenge
- Competitors can build on CE

---

## Choosing Your Multi-Licensing Strategy

### Decision Tree

**Question 1: Do you need revenue from the software itself?**
- NO → Use permissive OSS (MIT/Apache), monetize services
- YES → Continue

**Question 2: Are you building a SaaS/cloud service?**
- YES → Consider FSL-1.1-MIT or Open Core
- NO → Continue

**Question 3: Can you maintain copyright ownership?**
- NO → Use single permissive license (can't dual license without copyright)
- YES → Continue

**Question 4: Are you willing to manage two licenses?**
- NO → Use AGPL to prevent competing services, or FSL
- YES → Dual licensing GPL + Commercial

### Strategy Comparison

| Strategy | Revenue Potential | Adoption | Complexity | Community Friendly |
|----------|------------------|----------|------------|-------------------|
| Single Permissive | Low (services) | Highest | Lowest | Highest |
| Dual GPL/Commercial | High | Low-Medium | High | Medium |
| Dual MIT/Apache | Low-Medium | Highest | Low | Highest |
| Open Core | High | Medium-High | Medium | Medium |
| FSL Time-Delayed | Medium-High | Medium | Medium | Medium-High |
| AGPL Only | Low-Medium | Low | Low | Medium |

## Common Mistakes to Avoid

### Mistake 1: No CLA with Dual Licensing

**Problem:** You don't own copyright to all code

**Result:** Can't sell commercial licenses for contributed code

**Solution:** Require CLA before accepting contributions

---

### Mistake 2: Unclear License Terms

**Problem:** README doesn't explain which license applies when

**Result:** Users confused, may avoid your project

**Solution:** Clear, prominent license explanation in README

---

### Mistake 3: Changing Licenses on Existing Code

**Problem:** Switching GPL to MIT without contributor permission

**Result:** Legal issues, community backlash

**Solution:** Only change license with all contributors' permission, or for new versions only

---

### Mistake 4: FSL Without Commitment

**Problem:** FSL but might not actually open source later

**Result:** Loss of trust, community backlash

**Solution:** Only use FSL if truly committed to eventual OSS

---

### Mistake 5: Open Core Feature Split

**Problem:** Moving popular features from CE to EE

**Result:** Community feels betrayed, forks

**Solution:** Establish clear principle for feature split upfront

---

## Legal Considerations

### Copyright Ownership

For dual licensing, you need:
1. Copyright assignment from all contributors
2. OR Contributor License Agreement (CLA)
3. OR reject external contributions (solo development)

### CLA Template

```markdown
# Contributor License Agreement

By contributing to [Project], you agree to:

1. **Grant of Copyright License**: You grant [Company] a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare derivative works of, publicly display, publicly perform, sublicense, and distribute your contributions and such derivative works.

2. **Grant of Patent License**: You grant [Company] a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer your contributions.

3. **Right to Relicense**: You grant [Company] the right to license your contributions under any license terms [Company] chooses, including proprietary licenses.

4. **Representations**: You represent that you are legally entitled to grant the above licenses and that your contributions are your original creation.
```

### Licensing Your Company Holds

If you're a company multi-licensing:
- Company owns copyright
- Employees assign copyright to company
- Contributors sign CLA
- Company can license under any terms

## Resources

- [Dual Licensing Guide (FOSSA)](https://fossa.com/blog/dual-licensing-models/)
- [FSL Official Site](https://fsl.software)
- [Qt Licensing](https://www.qt.io/licensing/)
- [Open Core Ventures](https://opencoreventures.com/blog/open-core/)
- [Contributor License Agreements](https://contributoragreements.org/)

## Summary

**Multi-licensing enables:**
- Revenue from open source software
- Flexibility for different user needs
- Protection while encouraging adoption

**Choose based on:**
- Business model needs
- Community vs. revenue priority
- Ability to manage copyright
- Long-term open source commitment

**Most common patterns:**
1. Dual GPL/Commercial (revenue from proprietary users)
2. Dual MIT/Apache (compatibility and adoption)
3. FSL → MIT (time-delayed OSS with revenue runway)
4. Open Core (free base, paid premium)

The right choice depends on your project goals, revenue needs, and commitment to open source principles.
