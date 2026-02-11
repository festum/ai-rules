# AI Coding Rules - Superpowers Enhanced
---
# Windsurf: trigger: always_on
# Cursor: alwaysApply: true
# VS Code: workspace settings
# Aider: system prompt integration
# GitHub Copilot: instruction following
---

## Superpowers Methodology

### Core Philosophy
Superpowers is a complete software development workflow for AI agents that emphasizes:
- Discipline over convenience - Follow proven processes rigorously
- Red-Green-Refactor - The fundamental cycle of reliable development
- Skill-based approach - Use proven techniques for specific situations
- Subagent-driven development - Fresh perspectives for each focused task

### Core Workflow Principles
- RED-GREEN-REFACTOR: Write failing test → minimal code → refactor
- YAGNI: You Aren't Gonna Need It - implement only what's needed now
- DRY: Don't Repeat Yourself - extract reusable patterns
- Subagent-driven development: Use fresh agents for each focused task
- Two-stage review: Spec compliance → code quality

### The Iron Law of Development
`NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`

Violating the letter of the rules is violating the spirit of the rules.

### Mandatory Development Workflow
1. Brainstorming - Refine ideas through questions, explore alternatives, present design for validation
2. Git Worktrees - Create isolated workspace on new branch, verify clean test baseline
3. Writing Plans - Break work into 2-5 minute tasks with exact file paths and verification steps
4. Test-Driven Development - Write failing test first, watch it fail, write minimal code, watch it pass, commit
5. Code Review - Review against plan, report issues by severity, critical issues block progress
6. Branch Completion - Verify tests, present merge/PR options, cleanup worktree

### Go Pre-flight Checklist (Mandatory for every Task)
Before declaring a task "done" or providing the final solution, you MUST:

1. Dependency & Impact Analysis:
   - Scan the workspace to ensure changes do not break other packages.
   - Consider side effects on shared states or configurations.
2. Unittest Verification & Supplement:
   - Check if the modified logic has existing tests.
   - If missing or insufficient: You MUST generate high-quality unit tests.
   - For Go: Use the standard `testing` package or `testify`.
3. Static Analysis & Quality Hooks:
   - Run and pass `go fmt` and `go vet`.
   - Run the project's `pre-commit` hooks.
   - Ensure compliance with `golangci-lint` if available.

### Go Execution Workflow
1. Plan: Briefly state how the change adheres to Uber Go style and assess potential impact.
2. Code: Implement using Idiomatic Go.
3. Verify: Run `go test ./...` and `pre-commit run`.
4. Refactor: Fix any linting or test failures before finalizing.

### Skill Usage Rules

#### Mandatory Skill Invocation
If there's even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke it.

This is not negotiable. This is not optional.

#### Priority Order
1. Process skills first (brainstorming, debugging) - determine HOW to approach
2. Implementation skills second (writing-plans, executing-plans) - guide execution

#### Common Rationalizations to Avoid
| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

### Red-Green-Refactor Cycle

#### RED - Write Failing Test
- Write one minimal test showing what should happen
- Clear name, tests real behavior, one thing only
- Use real code, avoid mocks when possible
- MANDATORY: Watch it fail correctly

#### GREEN - Minimal Code
- Write simplest code to pass the test
- Don't add features, refactor other code, or "improve"
- Just enough to pass
- MANDATORY: Watch it pass with pristine output

#### REFACTOR - Clean Up
- Remove duplication, improve names, extract helpers
- Keep tests green, don't add behavior
- Only after GREEN is confirmed

### Problem-Solving Techniques

#### When Stuck
1. Collision Zone Thinking - Force unrelated concepts together for emergent insights
2. Inversion Exercise - Flip assumptions to reveal hidden constraints
3. Meta-Pattern Recognition - Spot universal principles across domains
4. Scale Game - Test at extremes to expose fundamental truths
5. Simplification Cascades - Find insights that eliminate multiple components

#### Debugging Methodology
1. Form a hypothesis - What do you think is wrong?
2. Create test - Prove or disprove hypothesis
3. Observe results - What actually happened?
4. Refine hypothesis - Based on observations
5. Repeat - Until problem is solved

### Architecture Principles

#### Preserving Productive Tensions
- Keep multiple valid approaches instead of forcing premature resolution
- Maintain competing designs when both have merit
- Use time and experience to reveal the better approach
- Avoid early optimization that locks you into one path

### Research Approach

#### Tracing Knowledge Lineages
- Understand how ideas evolved over time
- Learn from historical context and previous attempts
- Build on existing knowledge rather than repeating mistakes
- Respect the evolution of technical concepts

## Superpowers Skills Integration

### Available Skills (Invoke When Matching)

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

### Skill Invocation Priority
1. Process skills first - Determine HOW to approach (brainstorming, debugging)
2. Implementation skills second - Guide execution (writing-plans, executing-plans)

## Coding Standards

### Language-Agnostic Rules
- Single responsibility principle - Each function/class does one thing well
- Descriptive naming - Variables, functions, and classes reveal intent
- Small functions - Maximum 20 lines, ideally 5-10
- No magic numbers - Extract to named constants
- Error handling - Handle errors at appropriate levels, never swallow silently

### TypeScript/JavaScript Specific
- Strict mode always - `use strict` and TypeScript strict mode enabled
- Async/await preferred - Over promises or callbacks
- Type safety - No `any` types, explicit return types
- Interface over type - For object shapes that might be extended
- Prefer const - Use `let` only when reassignment is necessary

### Python Specific
- PEP 8 compliance - Follow Python style guide strictly
- Type hints required - All functions and variables
- Docstrings - Google or NumPy style for all public functions
- List comprehensions - Over map/filter where readable

### Go Specific
- KSS + Idiomatic Go: Prioritize clarity. "Clear is better than clever."
- Uber Go Style Guide: Strictly follow the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
  - Use `Pointers to Interfaces` only when necessary (rarely).
  - Be explicit about `Slices` and `Maps` initialization.
  - Follow Uber's rules for `Errors` (wrapping and types).
  - Function grouping and ordering (Exported first).
- Composition over Inheritance: Use struct embedding. No deep hierarchies.
- CSP Concurrency: Use channels/goroutines. Proverb: "Don't communicate by sharing memory; share memory by communicating."
- Interface Design: "Accept interfaces, return structs". Keep interfaces tiny (1-2 methods).

## Code Organization

### Naming Conventions
- Files: kebab-case (`user-service.ts`, `payment-handler.go`)
- Components: PascalCase (`UserProfile.tsx`, `PaymentService`)
- Functions: camelCase (`getUserData()`, `processPayment()`)
- Constants: UPPER_SNAKE_CASE (`API_BASE_URL`, `MAX_RETRIES`)
- Variables: camelCase (`userName`, `totalAmount`)

### Project Structure Guidelines
- Go: Follow [golang-standards/project-layout](https://github.com/golang-standards/project-layout)
  - `cmd/` for main applications, `internal/` for private code, `pkg/` for public libraries
- TypeScript/JavaScript: Group by feature or layer
  - `components/`, `services/`, `utils/`, `types/`, `tests/`

## Testing Strategy

### TDD Requirements
- RED phase: Write failing test first, watch it fail
- GREEN phase: Write minimal code to pass
- REFACTOR phase: Improve without changing behavior
- Coverage: Minimum 80% line coverage, 100% for critical paths

### Test Types
- Unit tests - Single function/class in isolation
- Integration tests - Multiple components working together
- End-to-end tests - Full user workflows
- Property tests - Verify invariants with random inputs

## Editor Integration

### Universal Principles (All Editors)
All AI coding assistants must:
- Follow Superpowers methodology automatically
- Apply TDD discipline (RED-GREEN-REFACTOR)
- Generate tests before implementation
- Use two-stage code review (spec → quality)
- Maintain project conventions consistently
- Suggest improvements following YAGNI and DRY

### Editor-Specific Features

| Feature | Windsurf | Cursor | VSCode | Copilot | Aider |
|---------|----------|--------|--------|---------|-------|
| Workflow Integration | Cascade agent + Skills | Context-aware completion | Extension-based | Inline suggestions | CLI-driven |
| TDD Support | Brainstorming skill | Auto test generation | Test runner integration | Test snippet generation | Git worktree automation |
| Branch Management | Git worktree skills | Built-in branching | Manual via extensions | N/A | Native worktree support |
| Code Review | Subagent-driven review | Dual review stages | Manual review tools | Comment-based review | Automated review mode |
| Context Handling | Memory + Rules system | Max mode (200k tokens) | Workspace settings | File-level context | Full repo context |

### Activation
- Windsurf: Rules auto-apply with `trigger: always_on`, invoke skills explicitly
- Cursor: Use `alwaysApply: true` in `.cursorrules`, enable Composer for complex tasks
- VSCode: Configure in `.vscode/settings.json`, install Superpowers extension
- Copilot: Follows instructions in comments and workspace context
- Aider: Pass rules via `--message-file` or system prompt integration

## Best Practices

### Development Process
- Never write code without failing test first
- Delete code written before tests
- Commit after each GREEN phase
- Use feature flags for incomplete features
- Document decisions, not obvious code

### Code Quality
- Readability over cleverness
- Explicit over implicit
- Consistent style across project
- Meaningful comments for why, not what
- Regular refactoring sessions

### Performance
- Profile before optimizing
- Consider algorithmic complexity first
- Cache strategically
- Measure real-world usage
- Avoid premature optimization

## Security Guidelines

### General Principles
- Principle of least privilege
- Validate all inputs
- Use parameterized queries
- Implement proper authentication
- Keep dependencies updated

### Specific Practices
- Never trust client data
- Use HTTPS everywhere
- Implement rate limiting
- Log security events
- Regular security audits

## Git Workflow

### Branch Strategy
- main - Production-ready code
- dev - Integration branch
- feature/* - New features
- bugfix/* - Bug fixes
- hotfix/* - Critical production fixes

### Commit Standards
- Conventional commits - `type(scope): description`
- Atomic commits - One logical change per commit
- Clear messages - Explain what and why
- Sign commits - For accountability

## Documentation Standards

### Code Documentation
- API docs - Auto-generated from type definitions
- README - Project overview and setup
- ARCHITECTURE - System design decisions
- CONTRIBUTING - Development guidelines

### Comments
- Explain why, not what
- Document complex algorithms
- Mark TODOs with dates
- Link to external resources
- Keep comments up-to-date

## Go Maintenance & Cleanup
- Remove unnecessary annotations, unused imports, and redundant helper functions
- Maintain consistent file structure and naming conventions
- Run `gofmt` and `goimports` before committing
- Ensure all exported functions have documentation comments

## SWE-1.5 Specific Safeguards

### Context Integrity Checks (Always On)
Purpose: Compensate for SWE-1.5's context retention issues in multi-file operations

Before marking any task complete, you MUST verify:

1. Variable Completeness Check
   - List all variables/parameters mentioned in the plan or conversation
   - Confirm each one is declared, initialized, and used correctly
   - For Go: Check receiver variables, function parameters, struct fields
   - Red flag: Plan mentions variable X but code doesn't define it

2. Cross-File Dependency Verification
   - If modifying multiple files, explicitly list changed files
   - Verify imports/exports are bidirectionally consistent
   - Check function signatures match at call sites
   - Red flag: Modified function signature but didn't update callers

3. Scope Preservation
   - Before any edit, state the exact change requested
   - After editing, confirm ONLY requested changes were made
   - List any unintended formatting/style changes
   - Red flag: Reformatted arrays, changed quotes, modified unrelated files

### Implementation Protocol for SWE-1.5

#### Stage 1: Pre-Implementation Checklist
- [ ] Read complete conversation history for context
- [ ] Extract ALL entities mentioned (variables, functions, types)
- [ ] Note file boundaries and dependencies
- [ ] Identify potential context loss points (>200 lines, multiple files)

#### Stage 2: During Implementation
- [ ] For each file edit: Re-read full file if >200 lines
- [ ] Before adding code: Verify all referenced entities exist
- [ ] After adding code: Check no unmentioned changes occurred
- [ ] For multi-file changes: Update one file, verify, then next

#### Stage 3: Post-Implementation Verification
- [ ] Run static analysis (go vet, golangci-lint)
- [ ] Verify all planned entities are present in code
- [ ] Check git diff for unintended changes
- [ ] Confirm tests cover new/modified code paths

### Explicit Rejection Criteria
Stop and report immediately if:
- Cannot locate a variable mentioned in conversation context
- Modified >3 files without explicit per-file verification
- Suggested formatting changes not requested by user
- Unable to see full context of files being edited

### Compensation Strategies
When working with SWE-1.5:
- Long files (>200 lines): Request file split or explicit context window
- Complex refactoring: Break into single-file subtasks
- Multi-file changes: Use checklist-driven sequential updates
- Ambiguous context: Ask clarifying questions before code generation
