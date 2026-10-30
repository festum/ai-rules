---
name: humanizer-ref
version: 1.0.1
description: |
  Humanize reference-register documents — CVs / résumés, API docs, technical
  specs, changelogs, legal text, product requirements, READMEs. Applies the
  base humanizer's patterns without personality injection (which
  belongs to personal register), and adds overrides for CV/reference conventions
  like ATS keyword bolding, parallel-verb bullets, and subject-dropped bullets.
  Use when editing a CV or any document whose correct human voice is neutral,
  factual, and parallel — not opinionated.
license: MIT
compatibility: any-agent
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Humanizer for Reference Register

Reference-register documents (CVs, API docs, technical specs, legal, changelogs) sound human when neutral, factual, parallel; not when opinionated or rhythmically varied. Skill applies base `humanizer` skill's pattern detection, skips personality layer, adds reference-specific overrides.

## Process

1. **Load base humanizer skill first.** Read `~/.agents/skills/humanizer/SKILL.md` (or equivalent path in this environment) for pattern definitions §1-§26 (sections A-F).
2. **Apply base patterns §1-§26**: all tell-removal; none inject personality.
3. **Keep it neutral.** No opinions, first person, mixed feelings, tangents, or deliberate rhythmic variation (base `### Voice`: reference text stays neutral and plain). Correct human voice for reference documents *is* neutral and parallel.
4. **Apply overrides below** where they conflict with base humanizer.
5. **Deliverable** matches base humanizer: draft rewrite, "still-AI" audit bullets, final rewrite with 0 em/en dashes.
6. **Facts**: skill never verifies claims. Accuracy matters → run `fact-check` before it and its claim-diff step after it.

## Overrides for reference register

### §6 Forced triads — allow factual lists
Tech stacks, feature enumerations, spec bullets, skill lists: factual, often > three items. Cut only forced rhetorical triples ("innovation, inspiration, and industry insights"). Keep "Kafka, gRPC, Protobuf, Docker, Kubernetes".

### §7 Repeated sentence openings — prefer parallelism over synonym cycling
Reference documents *want* repeated verbs. All CV bullets starting with `Cut` / `Delivered` / `Reduced` = feature, not repetition. Never cycle synonyms just for variety.

### §11 Passive voice and missing subjects — subject-dropped bullets are convention
CV bullets like `Recruited from Taiwan as Principal Engineer` or `Shipped 15 payment-method APIs` drop subject by convention. Don't rewrite to `I was recruited...`. Rewrite passive only when it hides the actor in a way that obscures meaning.

### §19 Bold as decoration — ATS keyword bolding is convention
Bolding technical keywords (`*Go*`, `*AWS*`, `*20%*`) in CVs = ATS-friendly, not AI tell. Cut bold only when applied mechanically to every noun or every list item header (see §20).

### §10 Hyphenated pairs everywhere — attributive stays
`zero-downtime migrations`, `data-driven report`, `end-to-end tests` in CV bullets: almost always attributive; stay hyphenated. Drop hyphens only in predicate position (`the report is data driven`).

### §2 One-line closers and dramatic fragments — bullet fragments are format
Short bullets ≠ staccato drama. Flag only stacked short sentences within single bullet or prose paragraph that inflate tone.

## Extra checks specific to reference register

Beyond removing AI tells, verify:

- **Parallel verb openings**: all bullets in a section start with same tense (past for prior roles, present for current role's ongoing responsibilities).
- **Metric-first structure**: action-verb + quantified impact + technique + tech, in that order, when possible. `Cut compliance incidents by 20% by architecting KYC screening` beats `Architected KYC screening, which cut compliance incidents by 20%`.
- **Consistent capitalisation** of proper nouns and product names (`Protobuf`, not sometimes `protobuf`; `Kubernetes`, not sometimes `K8s`).
- **UK vs US English**: pick one, stick with it (`containerised` or `containerized`, not both).
- **No meta-narrative**: CVs should not explain biographical significance of a role (`First international role.`, `The pivot that opened my career.`). Timeline speaks for itself.
- **Oxford comma consistency**: pick one, stick with it.

## When to use this skill vs base humanizer

| Document | Skill |
|---|---|
| CV / résumé | humanizer-ref |
| Cover letter | humanizer (personal register, first person expected) |
| LinkedIn About | humanizer (personal register with mild professional restraint) |
| LinkedIn post | humanizer |
| Blog post / essay | humanizer |
| API documentation | humanizer-ref |
| README | humanizer-ref (usually), humanizer if it's a personal-project narrative |
| Changelog / release notes | humanizer-ref |
| Legal / contract | humanizer-ref |
| Product spec / PRD | humanizer-ref |
| Technical design doc | humanizer-ref |
| Marketing copy | humanizer (voice-heavy) |
| Fiction | humanizer |

Document between registers (marketing meets spec, personal-brand website) → ask user.
