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

Reference-register documents (CVs, API docs, technical specs, legal, changelogs) sound human when they are neutral, factual, and parallel — not when they are opinionated or rhythmically varied. This skill applies the base `humanizer` skill's pattern detection but skips the personality layer and adds reference-specific overrides.

## Process

1. **Load the base humanizer skill first.** Read `~/.agents/skills/humanizer/SKILL.md` (or the equivalent path in this environment) for the pattern definitions §1-§26 (sections A-F).
2. **Apply the base patterns §1-§26** — all are tell-removal; none inject personality.
3. **Keep it neutral.** Do not add opinions, first person, mixed feelings, tangents, or deliberate rhythmic variation (base `### Voice`: reference text stays neutral and plain). The correct human voice for reference documents *is* neutral and parallel.
4. **Apply the overrides below** where they conflict with the base humanizer.
5. **Deliverable** matches the base humanizer: draft rewrite, "still-AI" audit bullets, final rewrite with 0 em/en dashes.
6. **Facts**: this skill never verifies claims. When accuracy matters, run `fact-check` before it and its claim-diff step after it.

## Overrides for reference register

### §6 Forced triads — allow factual lists
Tech stacks, feature enumerations, spec bullets, and skill lists are factual and often exceed three items. Only cut forced rhetorical triples ("innovation, inspiration, and industry insights"). Keep "Kafka, gRPC, Protobuf, Docker, Kubernetes".

### §7 Repeated sentence openings — prefer parallelism over synonym cycling
Reference documents *want* repeated verbs. All CV bullets starting with `Cut` / `Delivered` / `Reduced` is a feature, not repetition. Do not cycle synonyms just for variety.

### §11 Passive voice and missing subjects — subject-dropped bullets are convention
CV bullets like `Recruited from Taiwan as Principal Engineer` or `Shipped 15 payment-method APIs` drop the subject by convention. Do not rewrite to `I was recruited...`. Rewrite passive only when it hides the actor in a way that obscures meaning.

### §19 Bold as decoration — ATS keyword bolding is convention
Bolding technical keywords (`*Go*`, `*AWS*`, `*20%*`) in CVs is ATS-friendly, not an AI tell. Only cut bold when it is applied mechanically to every noun or every list item header (see §20).

### §10 Hyphenated pairs everywhere — attributive stays
`zero-downtime migrations`, `data-driven report`, `end-to-end tests` in CV bullets almost always sit in attributive position and should stay hyphenated. Only drop hyphens in predicate position (`the report is data driven`).

### §2 One-line closers and dramatic fragments — bullet fragments are format
Short bullets are not staccato drama. Only flag stacked short sentences within a single bullet or prose paragraph that inflate tone.

## Extra checks specific to reference register

Beyond removing AI tells, verify:

- **Parallel verb openings** — all bullets in a section start with the same tense (past for prior roles, present for current role's ongoing responsibilities).
- **Metric-first structure** — action-verb + quantified impact + technique + tech, in that order, when possible. `Cut compliance incidents by 20% by architecting KYC screening` beats `Architected KYC screening, which cut compliance incidents by 20%`.
- **Consistent capitalisation** of proper nouns and product names (`Protobuf`, not sometimes `protobuf`; `Kubernetes`, not sometimes `K8s`).
- **UK vs US English** — pick one and stick with it (`containerised` or `containerized`, not both).
- **No meta-narrative** — CVs should not explain the biographical significance of a role (`First international role.`, `The pivot that opened my career.`). The timeline speaks for itself.
- **Oxford comma consistency** — pick one and stick with it.

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

If a document sits between registers (marketing meets spec, personal-brand website), ask the user.
