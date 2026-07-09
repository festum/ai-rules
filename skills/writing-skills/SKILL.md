---
name: writing-skills
description: Use when creating or editing a skill and needing to verify it actually changes agent behavior — covers RED-GREEN-REFACTOR testing, description writing (CSO), and closing rationalization loopholes
---

# Writing Skills

## Overview

Writing skills IS Test-Driven Development applied to process documentation.

Write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** Understand `test-driven-development` before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle.

## Scope of this Skill

This skill covers **verifying skills actually work** — testing methodology, discovery optimization, and bulletproofing against rationalization.

For skill **structure, scaffolding, and packaging** (bundled resources layout, `init_skill.py`, `package_skill.py`, distribution zips), use `skill-creator`. Do not duplicate that content here.

Rule of thumb:
- `skill-creator` = *how to build and ship a skill*
- `writing-skills` = *how to know it does what you claim*

## When to Create a Skill

Create when:
- Technique wasn't intuitively obvious
- The pattern will be referenced across projects
- Others would benefit

Don't create for:
- One-off solutions
- Standard practices documented elsewhere
- Project-specific conventions (put in project docs)
- Mechanical constraints (if enforceable with regex/validation, automate it — save documentation for judgment calls)

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| Test case | Pressure scenario with subagent |
| Production code | Skill document (SKILL.md) |
| Test fails (RED) | Agent violates rule without skill (baseline) |
| Test passes (GREEN) | Agent complies with skill present |
| Refactor | Close loopholes while maintaining compliance |
| Write test first | Run baseline scenario BEFORE writing skill |
| Watch it fail | Document exact rationalizations agent uses |
| Minimal code | Write skill addressing those specific violations |
| Watch it pass | Verify agent now complies |
| Refactor cycle | Find new rationalizations → plug → re-verify |

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

No exceptions:
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Delete means delete

## Claude Search Optimization (CSO)

Critical: future Claude needs to FIND the skill.

### 1. Rich Description Field

**CRITICAL: Description = When to Use, NOT What the Skill Does.**

The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow.

**Why this matters:** Testing revealed that when a description summarizes workflow, Claude may follow the description instead of reading the full skill. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO. When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), Claude correctly read the flowchart.

**The trap:** Descriptions that summarize workflow create a shortcut Claude takes. The skill body becomes documentation Claude skips.

> Note: This is stricter than `skill-creator`'s guidance. When they conflict, follow this rule — it's the tested version.

```yaml
# ❌ BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ✅ GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks in the current session

# ✅ GOOD: Triggering conditions only
description: Use when implementing any feature or bugfix, before writing implementation code
```

Content requirements:
- Concrete triggers, symptoms, and situations that signal this skill applies
- Describe the *problem* (race conditions, inconsistent behavior), not *language-specific symptoms* (setTimeout, sleep)
- Keep triggers technology-agnostic unless the skill itself is technology-specific
- Third person (injected into system prompt)
- NEVER summarize workflow

```yaml
# ❌ BAD: Vague
description: For async testing

# ❌ BAD: First person
description: I can help you with async tests when they're flaky

# ❌ BAD: Mentions technology but skill isn't specific to it
description: Use when tests use setTimeout/sleep and are flaky

# ✅ GOOD: Starts with "Use when", describes problem
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

### 2. Keyword Coverage

Use words Claude would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: actual commands, library names, file types

### 3. Descriptive Naming

Use active voice, verb-first:
- ✅ `creating-skills` not `skill-creation`
- ✅ `condition-based-waiting` not `async-test-helpers`
- ✅ `root-cause-tracing` > `debugging-techniques`

Gerunds (-ing) work well for processes: `creating-skills`, `testing-skills`, `debugging-with-logs`.

### 4. Token Efficiency

Frequently-loaded skills load into EVERY conversation. Every token counts.

Target word counts:
- getting-started workflows: <150 words each
- Frequently-loaded skills: <200 words total
- Other skills: <500 words

Techniques:
- Move details to tool `--help` output
- Cross-reference other skills instead of copying content
- Compress examples to essential moves
- Don't repeat what's in cross-referenced skills

### 5. Cross-Referencing Other Skills

Use skill name only, with explicit requirement markers:
- ✅ `REQUIRED SUB-SKILL: Use test-driven-development`
- ✅ `REQUIRED BACKGROUND: You MUST understand systematic-debugging`
- ❌ `See skills/testing/test-driven-development` (unclear if required)
- ❌ `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)

**Why no `@` links:** `@` syntax force-loads files immediately, consuming context before you need it.

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run pressure scenario with a subagent WITHOUT the skill. Document exact behavior:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

You must see what agents naturally do before writing the skill.

### GREEN: Write Minimal Skill

Write a skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

## Testing by Skill Type

Different skill types need different test approaches.

### Discipline-Enforcing Skills (rules/requirements)

Examples: TDD, verification-before-completion, designing-before-coding

Test with:
- Academic questions: do they understand the rules?
- Pressure scenarios: do they comply under stress?
- Multiple pressures combined: time + sunk cost + exhaustion
- Identify rationalizations and add explicit counters

**Success criteria:** Agent follows rule under maximum pressure.

### Technique Skills (how-to guides)

Examples: condition-based-waiting, root-cause-tracing

Test with:
- Application scenarios: can they apply the technique correctly?
- Variation scenarios: do they handle edge cases?
- Missing information tests: do instructions have gaps?

**Success criteria:** Agent successfully applies technique to a new scenario.

### Pattern Skills (mental models)

Examples: reducing-complexity, information-hiding

Test with:
- Recognition scenarios: do they recognize when the pattern applies?
- Application scenarios: can they use the mental model?
- Counter-examples: do they know when NOT to apply?

**Success criteria:** Agent correctly identifies when/how to apply pattern.

### Reference Skills (documentation/APIs)

Examples: API documentation, command references

Test with:
- Retrieval scenarios: can they find the right information?
- Application scenarios: can they use what they found correctly?
- Gap testing: are common use cases covered?

**Success criteria:** Agent finds and correctly applies reference information.

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging a bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

All of these mean: **test before deploying. No exceptions.**

## Bulletproofing Skills Against Rationalization

Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes under pressure.

### Close Every Loophole Explicitly

Don't just state the rule — forbid specific workarounds.

❌ Weak:
```markdown
Write code before test? Delete it.
```

✅ Strong:
```markdown
Write code before test? Delete it. Start over.

No exceptions:
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

### Address "Spirit vs Letter" Arguments

Add a foundational principle early:

```markdown
Violating the letter of the rules is violating the spirit of the rules.
```

This cuts off an entire class of "I'm following the spirit" rationalizations.

### Build a Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make goes in the table:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
```

### Create a Red Flags List

Make it easy for agents to self-check when rationalizing:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

All of these mean: Delete code. Start over with TDD.
```

### Update CSO for Violation Symptoms

Add to description: symptoms of when the agent is ABOUT to violate the rule.

```yaml
description: Use when implementing any feature or bugfix, before writing implementation code
```

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
Why bad: too specific, not reusable.

### ❌ Multi-Language Dilution
`example-js.js`, `example-py.py`, `example-go.go`
Why bad: mediocre quality across all, maintenance burden. One excellent example beats many mediocre ones.

### ❌ Workflow Summary in Description
See CSO section — Claude will follow the summary instead of reading the skill.

### ❌ Untested "Just a Small Edit"
Editing a skill without re-running pressure scenarios is the same violation as writing one without tests.

## STOP: Before Moving to Next Skill

After writing ANY skill, STOP and complete the deployment process.

Do NOT:
- Create multiple skills in batch without testing each
- Move to the next skill before the current one is verified
- Skip testing because "batching is more efficient"

Deploying untested skills = deploying untested code.

## Skill Creation Checklist (TDD Adapted)

**RED Phase — Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill — document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase — Write Minimal Skill:**
- [ ] Scaffold with `skill-creator` (`init_skill.py`) — structure/packaging belongs there
- [ ] Description starts with "Use when..." and includes specific triggers/symptoms (NO workflow summary)
- [ ] Description written in third person
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Address specific baseline failures identified in RED
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill — verify agents now comply

**REFACTOR Phase — Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Deployment:**
- [ ] Package via `skill-creator`'s `package_skill.py` if distributing
- [ ] Commit skill to git

## The Bottom Line

Creating skills IS TDD for process documentation.

- Same Iron Law: no skill without a failing test first.
- Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
- Same benefits: better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.
