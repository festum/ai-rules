# AI Coding Rules - Superpowers Enhanced
---
# Windsurf: trigger: always_on
# Cursor: alwaysApply: true
# Aider: system prompt integration
# GitHub Copilot: instruction following
# OpenCode: AGENTS.md always included
---

## Iron Laws

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
NEVER add parameters unless test fails without them
ABSOLUTELY PROHIBIT any, interface{}, object types unless test demands it
NEVER introduce ctx, logger, metrics, tracing, options={}, metadata={} unless explicitly required by failing test or conversation
ABSOLUTELY FORBID hard-coded magic numbers, strings, paths - extract to named constants
NEVER swallow errors silently - always propagate or handle explicitly
PROHIBIT overengineering, future-proofing, optional parameters
ABSOLUTELY NEVER rewrite complete files unless explicitly specified
PROHIBIT modifying unrelated code, files, or adding unrequested formatting changes
NEVER use console.log, print in production code
PROHIBIT untested code submission
ABSOLUTELY FORBID unused imports, variables, dependencies
Violations BLOCK ALL PROGRESS
```

Violating the letter of the rules is violating the spirit of the rules.

## Mandatory Development Workflow

1. Brainstorming - Refine ideas through questions, explore alternatives, present design for validation
2. Git Worktrees - Create isolated workspace on new branch, verify clean test baseline
3. Writing Plans - Break work into 2-5 minute tasks with exact file paths and verification steps
4. Test-Driven Development - Write failing test first, watch it fail, write minimal code, watch it pass, commit
5. Code Review - Review against plan, report issues by severity, critical issues block progress
6. Branch Completion - Verify tests, present merge/PR options, cleanup worktree

## Extreme Minimalism (ALL LANGUAGES - MANDATORY)

NEVER add parameters, fields, or dependencies unless DIRECTLY required by:
1. Existing APIs/functions you call
2. Test case that fails without it
3. Conversation explicitly mentions it

### Language-Specific Forbidden Patterns

| Language | ❌ Bad | ✅ Minimal |
|----------|---------|---------|
| Go | `func(ctx, amount, userID, logger, metrics)` | `func(amount int, userID string) error` |
| TypeScript | `async function(ctx: Context, data: Data, logger?: Logger)` | `async function(data: Data): Promise<Data>` |
| Python | `def process(ctx, amount, user_id, logger=None, metrics=None)` | `def process(amount: int, user_id: str) -> Order` |
| JavaScript | `async function(ctx, amount, userId, logger, options = {})` | `async function(amount, userId)` |

### YAGNI Enforcement
- Future-proofing: FORBIDDEN
- Optional params: DELETE
- Logging/metrics: DELETE unless explicitly requested
- Context/tracing: DELETE unless timeout/deadline mentioned
- ❌ `ctx`, `logger`, `metrics`, `tracing`, `options={}`, `metadata={}`
- ❌ `interface{}`, `any`, `object` unless test demands it
- ❌ Default values unless test fails without them
- ❌ Hard-coded values, magic numbers
- ❌ Unused code, imports
- ❌ Unrelated modifications

Violation report format:
```
VIOLATION: func(X) has param Y
Reason: Not in conversation / Not required by tests / Not required by called APIs
PROHIBITION: Added ctx/logger - DELETE IMMEDIATELY
```

## Universal Pre-flight Checklist (MANDATORY - EVERY TASK)

Before declaring a task "done" you MUST complete:

1. Dependency Analysis
   - List affected files/APIs
   - Verify signature compatibility at call sites

2. Parameter Audit
   ```
   Proposed: func(X, Y, Z)
   Required by tests/conversation: X, Y
   DELETE: Z
   PROHIBITED: ctx, logger, any, magic numbers
   ```

3. Test Coverage
   - Existing tests cover modified logic? → supplement minimally if not
   - Go: `testing` / `testify` | TS: Vitest | Python: pytest

4. Minimalism Verification
   ```
   Params match requirements: [YES/NO]
   Lines vs functionality: [<50 preferred, justify if more]
   Imports: [100% used]
   No prohibited patterns: [YES/NO]
   ```

5. Linting
   - Go: `go fmt`, `go vet`, `go test ./...`, `golangci-lint`
   - TS/JS: `eslint`, `prettier`
   - Python: `black`, `flake8`, `mypy`

### Go Execution (Append to step 5)
1. Plan: State how change adheres to Uber Go style + impact
2. Code: Implement Idiomatic Go
3. Verify: `go test ./...` and `pre-commit run`
4. Refactor: Fix lint/test failures before finalizing

## Red-Green-Refactor Cycle

### RED - Write Failing Test
- One minimal test, one thing only, real behavior
- Use real code, avoid mocks when possible
- MANDATORY: Watch it fail correctly

### GREEN - Minimal Code
- Simplest code to pass the test — no extra features
- MANDATORY: Watch it pass with pristine output
- PROHIBIT any prohibited patterns

### REFACTOR - Clean Up
- Remove duplication, improve names, extract helpers
- Keep tests green, no new behavior
- Only after GREEN is confirmed

## Superpowers Skills

### Available Skills

| Skill | Trigger Condition | Purpose |
|-------|------------------|---------|
| using-superpowers | Any task starting | Mandatory skill invocation rules |
| brainstorming | Before coding new feature | Design refinement through questions |
| writing-plans | Complex multi-step work | Break into 2-5 min tasks with TDD cycles |
| test-driven-development | Adding/modifying logic | RED-GREEN-REFACTOR methodology |
| using-git-worktrees | Feature development | Isolated development environments |
| executing-plans | Plan exists | Batch execution with checkpoints |
| subagent-driven-development | Context reset needed | Fresh agent per focused task |
| requesting-code-review | Code complete | Two-stage review (spec → quality) |
| finishing-a-development-branch | Feature done | Branch completion workflow |

### Invocation Rules
- ALWAYS invoke using-superpowers first on any task
- If there's even a 1% chance a skill applies, you ABSOLUTELY MUST invoke it via @skill-name
- Process skills first (brainstorming, debugging) — determine HOW to approach
- Implementation skills second (writing-plans, executing-plans) — guide execution
- Windsurf: @skill-name manual invocation if auto-miss
- Cursor: Skills via Composer mode activation

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Invoke using-superpowers. |
| "I need more context first" | Skill check BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW. Invoke first. |
| "This doesn't need a formal skill" | If skill exists, invoke. |
| "I remember this skill" | Read current rules. Invoke. |
| "The skill is overkill" | Use always. |

## Coding Standards

### Language-Agnostic
- Single responsibility - Each function does one thing well
- Descriptive naming - Variables, functions, classes reveal intent
- Small functions - Maximum 20 lines, ideally 5-10
- No magic numbers - Extract to named constants
- Error handling - Never swallow silently
- PROHIBIT console.log/print in prod

### TypeScript/JavaScript
- `use strict` and TypeScript strict mode always enabled
- Async/await over promises or callbacks
- No `any` types, explicit return types
- Interface over type for extensible shapes
- Prefer `const`; use `let` only when reassignment needed
- MINIMALISM: No ctx, logger, options={} unless test fails

### Python
- PEP 8 compliance
- Type hints on all functions and variables
- Google or NumPy docstrings for all public functions
- List comprehensions over map/filter where readable
- MINIMALISM: No ctx, logger=None, metrics=None unless required

### Go
- Idiomatic Go: "Clear is better than clever"
- Strictly follow Uber Go Style Guide
  - Pointers to Interfaces only when necessary (rarely)
  - Explicit Slices and Maps initialization
  - Uber error wrapping and types
  - Exported functions grouped first
- Composition over inheritance: struct embedding, no deep hierarchies
- CSP concurrency: channels/goroutines — share memory by communicating
- Interface design: "Accept interfaces, return structs", keep interfaces tiny (1-2 methods)
- Before committing: `gofmt`, `goimports`, remove unused imports/annotations
- All exported functions must have documentation comments

## Code Organization

### Naming Conventions
- Files: kebab-case (`user-service.ts`, `payment-handler.go`)
- Components: PascalCase (`UserProfile.tsx`, `PaymentService`)
- Functions: camelCase (`getUserData()`, `processPayment()`)
- Constants: UPPER_SNAKE_CASE (`API_BASE_URL`, `MAX_RETRIES`)
- Variables: camelCase (`userName`, `totalAmount`)

### Project Structure
- Go: golang-standards/project-layout — `cmd/`, `internal/`, `pkg/`
- TS/JS: Feature or layer grouping — `components/`, `services/`, `utils/`, `types/`, `tests/`

## Testing Strategy

### Requirements
- RED: Write failing test first, watch it fail
- GREEN: Write minimal code to pass
- REFACTOR: Improve without changing behavior
- Coverage: Minimum 80% line, 100% for critical paths

### Test Types
- Unit — Single function/class in isolation
- Integration — Multiple components working together
- End-to-end — Full user workflows
- Property — Verify invariants with random inputs

## Git Workflow

### Branch Strategy
- `main` — Production-ready
- `dev` — Integration
- `feature/*`, `bugfix/*`, `hotfix/*`


### Commit Standards
- Conventional commits: `type(scope): description`
- Atomic commits — one logical change per commit
- Sign commits for accountability

## Editor Integration

| Feature | Windsurf | Cursor | VSCode | Copilot | Aider | OpenCode |
|---------|----------|--------|--------|---------|-------|----------|
| Workflow | Cascade agent + Skills always_on | Context-aware completion alwaysApply:true | Extension-based | Inline suggestions | CLI-driven | AGENTS.md root |
| TDD | Brainstorming skill | Auto test generation | Test runner integration | Test snippet generation | Git worktree automation | AGENTS.md enforced |
| Branching | Git worktree skills | Built-in branching | Manual via extensions | N/A | Native worktree support | Manual |
| Review | Subagent-driven | Dual review stages | Manual tools | Comment-based | Automated mode | AGENTS.md review |
| Context | Memory + .windsurfrules | Max mode (200k tokens) + .cursorrules | Workspace settings | File-level | Full repo | AGENTS.md + CLAUDE.md |

### Activation
- Windsurf: `trigger: always_on`, invoke skills explicitly @skill-name
- Cursor: `alwaysApply: true`, enable Composer for complex tasks
- VSCode: `.vscode/settings.json`, install Superpowers extension
- Copilot: Instructions via comments and workspace context
- Aider: `--message-file` or system prompt integration
- OpenCode: AGENTS.md in project root, priority local > global

## Security Guidelines

- Principle of least privilege
- Validate all inputs; use parameterized queries
- Never trust client data
- Use HTTPS everywhere; implement rate limiting
- Log security events; keep dependencies updated

## Problem-Solving (When Stuck)

1. Collision Zone Thinking — Force unrelated concepts together for emergent insights
2. Inversion Exercise — Flip assumptions to reveal hidden constraints
3. Meta-Pattern Recognition — Spot universal principles across domains
4. Scale Game — Test at extremes to expose fundamental truths
5. Simplification Cascades — Find insights that eliminate multiple components

Debugging:
1. Form hypothesis → 2. Create test → 3. Observe results → 4. Refine hypothesis → 5. Repeat

## SWE-1.5 Specific Safeguards

### Context Integrity Checks (Always On)

Before marking any task complete, MUST verify:

1. Variable Completeness — List all vars/params from plan/conversation; confirm each is declared, initialized, used. Red flag: plan mentions X but code doesn't define it
2. Cross-File Dependencies — List changed files; verify imports/exports bidirectionally consistent; check signatures match at call sites. Red flag: modified signature without updating callers
3. Scope Preservation — State exact change before edit; confirm ONLY requested changes after. Red flag: reformatted arrays, changed quotes, modified unrelated files
4. Prohibition Compliance — Scan for ctx/logger/any/magic numbers/unused code

### Implementation Protocol

Stage 1 — Pre-Implementation:
- [ ] Read complete conversation for context
- [ ] Extract ALL entities mentioned (variables, functions, types)
- [ ] Note file boundaries and dependencies
- [ ] Identify context loss points (>200 lines, multiple files)

Stage 2 — During:
- [ ] Re-read full file if >200 lines
- [ ] Verify all referenced entities exist before adding code
- [ ] Update one file at a time; verify before next
- [ ] Check no prohibited patterns introduced

Stage 3 — Post-Implementation:
- [ ] Run static analysis (go vet, golangci-lint)
- [ ] Verify all planned entities present in code
- [ ] Check git diff for unintended changes
- [ ] Confirm tests cover new/modified paths

### Rejection Criteria
Stop and report immediately if:
- Cannot locate a variable mentioned in conversation
- Modified >3 files without per-file verification
- Suggested unrequested formatting changes
- Detected prohibited patterns (ctx, any, magic numbers, etc.)


### Compensation Strategies
- Long files (>200 lines): Request file split or explicit context window
- Complex refactoring: Break into single-file subtasks
- Multi-file changes: Checklist-driven sequential updates
- Ambiguous context: Ask clarifying questions before generating code
