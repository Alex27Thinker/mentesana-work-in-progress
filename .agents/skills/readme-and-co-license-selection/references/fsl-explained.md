# FSL-1.1-MIT Explained: Functional Source License

Deep dive into the Functional Source License (FSL), the time-delayed open source licensing model pioneered by Sentry.

## What is FSL?

**Functional Source License (FSL)** is a source-available license that automatically converts to a permissive open source license (typically MIT or Apache-2.0) after a specified time period (commonly 2 years).

**Key characteristics:**
- Source code is publicly available immediately
- Users can read, modify, and test the code
- Production use is restricted during the delay period
- Competing use is prohibited during delay period
- Automatically becomes MIT/Apache after time period
- Rolling window: each release has its own timeline

**Created by:** Sentry (launched 2023)

**Official site:** https://fsl.software

---

## How FSL Works

### Timeline Explained

```
Year 0: Release v1.0 under FSL-1.1-MIT
├─ Source available (read, modify, test)
├─ Production use: Pay or wait
└─ Competing use: Prohibited

Year 1: Release v2.0 under FSL-1.1-MIT
├─ v2.0: FSL restrictions apply
├─ v1.0: Still FSL (1 year in)
└─ Both available for reading/testing

Year 2: Release v3.0 under FSL-1.1-MIT
├─ v3.0: FSL restrictions apply
├─ v2.0: Still FSL (1 year in)
└─ v1.0: Automatically becomes MIT ✅

Year 3: Release v4.0 under FSL-1.1-MIT
├─ v4.0: FSL restrictions apply
├─ v3.0: Still FSL (1 year in)
├─ v2.0: Automatically becomes MIT ✅
└─ v1.0: Already MIT ✅
```

**Key insight:** Every release eventually becomes MIT, just not immediately.

---

## What You Can Do Under FSL

### Immediately Permitted

✅ **Read the source code**
- Full access to all source code
- Study how it works
- Understand the implementation

✅ **Modify the code**
- Fork the repository
- Make changes
- Experiment with features

✅ **Test and develop**
- Run in development environment
- Write tests
- Build applications using it (non-production)

✅ **Distribute source**
- Share the source code
- Create forks
- Contribute improvements

✅ **Private use**
- Use internally for development
- Testing environments
- Staging servers (non-production)

### Restricted During Delay Period

❌ **Production use (without license)**
- Cannot deploy in production
- Cannot serve real users
- Must wait or pay for license

❌ **Competing services**
- Cannot offer competing product
- Cannot host as service for others
- Specifically designed to prevent SaaS competition

❌ **Commercial exploitation**
- Cannot sell access to the software
- Cannot monetize without permission
- Must wait for MIT conversion

### After Change Date (2 years)

✅ **Everything MIT allows**
- Full production use
- Commercial use
- Any purpose
- Compete with original author
- No restrictions

---

## FSL License Variants

### FSL-1.1-MIT

**Change License:** MIT
**Change Date:** 2 years from release
**Use Case:** Most common, maximum freedom after delay

**After 2 years:**
- Becomes MIT
- Maximum permissive freedom
- Can be used anywhere
- No attribution requirement beyond copyright notice

### FSL-1.1-Apache-2.0

**Change License:** Apache-2.0
**Change Date:** 2 years from release
**Use Case:** Projects wanting patent protection after delay

**After 2 years:**
- Becomes Apache-2.0
- Includes patent grant
- Explicit patent protection
- Trademark protection

### FSL-1.1-Custom

**Change License:** Any OSI-approved license
**Change Date:** Custom (1-4 years typical)
**Use Case:** Specialized needs

**Examples:**
- FSL-1.1-GPL-3.0 (copyleft after delay)
- FSL-1.1-MIT with 1-year delay (faster open source)
- FSL-1.1-Apache with 3-year delay (longer runway)

---

## Why Companies Choose FSL

### Business Benefits

**1. Revenue runway**
- 2-year window to monetize before competition
- Build sustainable business model
- Charge for production use

**2. Commitment to open source**
- Shows long-term OSS commitment
- Builds trust with community
- Differentiates from proprietary alternatives

**3. Transparent development**
- All development happens in public
- Community can contribute
- Users can audit code for security

**4. Competitive protection**
- Prevents cloud providers from competing immediately
- Gives time to establish market position
- Automatic license change prevents indefinite restriction

### Community Benefits

**1. Source availability**
- Can read and learn from code immediately
- Security audits possible
- Understand implementation

**2. Guaranteed open source**
- Will become MIT, no ifs or buts
- Not dependent on company goodwill
- Automatic conversion protects users

**3. Contribution opportunity**
- Can submit improvements
- Bug fixes welcome
- Community can shape development

**4. Future freedom**
- Old versions always available
- No lock-in long-term
- Can fork after Change Date

---

## Companies Using FSL

### Sentry

**Product:** Error tracking and performance monitoring
**License:** FSL-1.1-MIT (2 year delay)
**Timeline:** Switched from BSL to FSL in 2023

**Why FSL:**
- Cloud providers were hosting Sentry
- Needed revenue for sustainable development
- Commitment to eventual open source

**Business model:**
- Cloud hosting (sentry.io) - no restrictions
- Self-hosted (free tier) - FSL restrictions
- Enterprise - on-prem license available

**Results:**
- Sustainable revenue
- Continued community contributions
- Trust maintained through OSS commitment

**Quote from Sentry:**
> "We believe software is better when it's open. FSL lets us build sustainably while committing to open source."

### GitButler

**Product:** Git client and workflow tool
**License:** FSL-1.1-MIT/Apache-2.0
**Timeline:** FSL from launch

**Why FSL:**
- New product needing runway
- Want eventual open source
- Transparent development from day one

**Approach:**
- Dual FSL-MIT/Apache (user chooses future license)
- 2-year delay
- Public development

### Codecov

**Product:** Code coverage analysis
**License:** BSL transitioning to FSL-like model
**Why:** Similar to Sentry - prevent cloud competition while committing to OSS

### Lago

**Product:** Open source billing
**License:** AGPL with FSL consideration
**Why:** Exploring FSL for commercial sustainability

---

## FSL vs Other Licenses

### FSL vs Proprietary

| Aspect | FSL | Proprietary |
|--------|-----|-------------|
| Source availability | ✅ Immediate | ❌ Never |
| Audit for security | ✅ Yes | ❌ No |
| Contributions | ✅ Welcome | ❌ Not possible |
| Future freedom | ✅ Guaranteed (MIT) | ❌ Never |
| Production use | ⏱️ After 2 years | ⏱️ With license |

**Verdict:** FSL much more open than proprietary

### FSL vs Open Source (MIT/Apache)

| Aspect | FSL | MIT/Apache |
|--------|-----|------------|
| Immediate freedom | ❌ Restricted | ✅ Full freedom |
| OSI approved | ❌ No | ✅ Yes |
| Revenue protection | ✅ 2-year window | ❌ None |
| Eventual freedom | ✅ Guaranteed | ✅ Immediate |
| Community trust | ⚠️ Moderate | ✅ High |

**Verdict:** MIT/Apache more free, but FSL offers revenue window

### FSL vs AGPL

| Aspect | FSL | AGPL |
|--------|-----|------|
| Copyleft | ⏱️ Temporary | ✅ Permanent |
| Source disclosure | ✅ Required | ✅ Required (network use) |
| Commercial use | ⏱️ After delay | ✅ Allowed (with copyleft) |
| OSI approved | ❌ No | ✅ Yes |
| Corporate acceptance | ⚠️ Moderate | ❌ Often banned |

**Verdict:** AGPL protects freedom permanently, FSL protects revenue temporarily

### FSL vs BSL (Business Source License)

| Aspect | FSL | BSL |
|--------|-----|-----|
| Change date | ✅ Fixed timeline | ✅ Fixed timeline |
| Change license | ✅ Specified upfront | ✅ Specified upfront |
| Use restrictions | Competing use | Custom (varies) |
| Standardization | ✅ fsl.software | ⚠️ Each company differs |
| Clarity | ✅ Clear rules | ⚠️ Custom per project |

**Verdict:** FSL is standardized version of BSL concept

---

## Criticisms and Responses

### Criticism 1: "Not Real Open Source"

**Criticism:**
- OSI doesn't recognize FSL as open source
- Fails Open Source Definition (OSD)
- Immediate use is restricted

**Response:**
- FSL acknowledges it's source-available, not open source (yet)
- Commits to becoming OSI-approved OSS (MIT)
- Transparent about restrictions
- Better than proprietary alternatives

**FSL position:**
"We're source-available now, open source later. That's the honest deal."

### Criticism 2: "Hurts Adoption"

**Criticism:**
- Users avoid non-OSI licenses
- Corporate legal departments block FSL
- Reduces community contributions

**Response:**
- Some reduction in adoption, but sustainable business enables better software
- Corporate users can wait 2 years or pay
- Many companies support sustainable open source
- Community contributions still possible

**Counter-argument:**
Dead projects help no one. Sustainable funding enables development.

### Criticism 3: "Creates Two-Tier System"

**Criticism:**
- Paying customers get immediate use
- Free users must wait
- Divides community

**Response:**
- Similar to dual licensing (GPL + commercial)
- Paying customers fund development
- Free users get it eventually, guaranteed
- Transparent about the trade-off

**Alternative view:**
FSF and OSI purists object, but many developers support sustainable OSS.

### Criticism 4: "Could Change Terms Later"

**Criticism:**
- Company could change license in future versions
- No guarantee FSL will continue

**Response:**
- Each version has its own FSL terms
- Change date is locked in per version
- Even if company goes proprietary, old versions become MIT
- Better guarantee than proprietary software

**Legal protection:**
FSL license is irrevocable for that version.

---

## When to Use FSL

### ✅ Good Fit For:

**SaaS products**
- You're building a cloud service
- Want to prevent AWS/GCP from competing
- Need revenue runway
- Committed to eventual open source

**Commercial OSS**
- Building a business around open source
- Need funding for development
- Want community involvement
- Don't want to go fully proprietary

**Developer tools**
- Complex products needing investment
- Want transparency and trust
- Sustainable development required
- Users can wait 2 years for free version

**Infrastructure software**
- Databases, queues, orchestration
- High development costs
- Enterprise customers willing to pay
- Community can contribute

### ❌ Poor Fit For:

**Libraries**
- Immediate adoption critical
- Developers won't wait 2 years
- MIT/Apache better for libraries

**Non-commercial projects**
- No revenue needs
- Just use MIT/Apache
- FSL adds unnecessary complexity

**Hobby/side projects**
- Overkill for small projects
- MIT/Apache simpler
- No business model needed

**Need OSI approval**
- Some organizations require OSI-approved
- Government/academic restrictions
- Use MIT/Apache instead

---

## Implementing FSL

### License File Structure

**Single file approach:**
```
LICENSE.md

# Functional Source License, Version 1.1, MIT Future License

## Abbreviation
FSL-1.1-MIT

## Notice
Copyright [year] [author]

## Terms
Licensed under the Functional Source License, Version 1.1, MIT Future License

[Full FSL text from https://fsl.software]

## Additional Use Grant
[Any additional permissions you want to grant]

## Change Date
2 years from the date this version was released

## Change License
MIT License
```

### README Explanation

```markdown
## License

This project is licensed under FSL-1.1-MIT (Functional Source License).

### What does this mean?

**Right now:**
- ✅ **Free** to read, fork, and modify the source code
- ✅ **Free** for development, testing, and learning
- ⚠️ **Cannot** use in production without a license
- ⚠️ **Cannot** offer as a competing service

**In 2 years (from each release):**
- ✅ Automatically becomes MIT licensed
- ✅ Use in production freely
- ✅ Commercial use allowed
- ✅ No restrictions

### Why FSL?

We're committed to open source, but we need a runway to build a sustainable business. FSL lets us:
- Develop transparently with community input
- Generate revenue to fund development
- Guarantee eventual open source (not just a promise)

Every version becomes MIT licensed after 2 years. There's no catch.

### Production Use Today

Want to use in production now?
- **Option 1:** Wait for MIT conversion (2 years)
- **Option 2:** Purchase a production license: [pricing](https://example.com/pricing)

### Contributing

Contributions are welcome! By contributing, you agree to license your contributions under the same FSL-1.1-MIT terms.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.
```

### FAQ for Users

```markdown
## FSL FAQ

**Q: Is this open source?**
A: Not by OSI definition (yet). It's source-available now, and becomes MIT (OSI-approved open source) after 2 years.

**Q: Can I use this in my project?**
A: Yes for development/testing. For production use, either wait 2 years or purchase a license.

**Q: Can I fork this?**
A: Yes! Fork freely. The FSL license stays with the fork.

**Q: Can I contribute?**
A: Absolutely. We welcome contributions and will credit you.

**Q: What if your company shuts down?**
A: The FSL license is irrevocable. Each version will still become MIT after 2 years, guaranteed.

**Q: Can I use version 1.0 now?**
A: Check the Change Date for v1.0. If it was released more than 2 years ago, it's MIT now. If not, wait or get a license.

**Q: Why not just use MIT from the start?**
A: We need revenue to fund development. This gives us a runway while committing to eventual open source.
```

---

## Future of FSL

### Adoption Trends

**Growing acceptance:**
- More companies exploring FSL
- Alternative to proprietary models
- Balances sustainability and openness

**Challenges:**
- OSI purists object
- Some corporate legal departments block
- Education needed

### Potential Evolution

**FSL 2.0 possibilities:**
- Shorter delay periods (1 year?)
- More flexible use grants
- Additional change licenses (e.g., AGPL)
- Better integration with dual licensing

### Industry Impact

**Changing conversation:**
- Sustainability in open source
- Alternative to VC-funded proprietary
- Honest licensing vs. bait-and-switch

**Quote from industry:**
> "FSL represents a middle path between proprietary and open source. It's not perfect, but it's honest and sustainable." - Open source developer

---

## Resources

### Official Resources
- [FSL Official Site](https://fsl.software)
- [FSL License Text](https://fsl.software/FSL-1.1-MIT.template.md)
- [FSL FAQ](https://fsl.software/faq)

### Company Examples
- [Sentry Blog: Why FSL](https://blog.sentry.io/introducing-the-functional-source-license)
- [GitButler: FSL Choice](https://gitbutler.com)

### Discussions
- [HackerNews: Sentry FSL Discussion](https://news.ycombinator.com/item?id=35137211)
- [Reddit: FSL vs AGPL](https://www.reddit.com/r/opensource)

### Comparisons
- [FSL vs BSL](https://writing.kemitchell.com/2019/03/09/Deprecation-Notice.html)
- [OSI: Why FSL Isn't OSS](https://opensource.org/osd)

---

## Summary

**FSL in one sentence:**
Source code is public now, with production restrictions that automatically expire in 2 years, converting to MIT.

**Best use case:**
Commercial SaaS products that want community trust, need revenue runway, and commit to eventual open source.

**Trade-offs:**
- ✅ Sustainable funding for development
- ✅ Guaranteed eventual open source
- ✅ Transparent, public development
- ❌ Not "true" open source initially
- ❌ May reduce adoption vs. MIT
- ⚠️ Requires user education

**Final verdict:**
FSL is a pragmatic middle ground between proprietary and open source. It's not for everyone, but it's an honest, sustainable model for commercial open source software.
