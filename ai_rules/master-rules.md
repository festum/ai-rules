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
**Superpowers is a complete software development workflow for AI agents that emphasizes:**
- **Discipline over convenience** - Follow proven processes rigorously
- **Red-Green-Refactor** - The fundamental cycle of reliable development
- **Skill-based approach** - Use proven techniques for specific situations
- **Subagent-driven development** - Fresh perspectives for each focused task

### Core Workflow Principles
- **RED-GREEN-REFACTOR**: Write failing test → minimal code → refactor
- **YAGNI**: You Aren't Gonna Need It - implement only what's needed now
- **DRY**: Don't Repeat Yourself - extract reusable patterns
- **Subagent-driven development**: Use fresh agents for each focused task
- **Two-stage review**: Spec compliance → code quality

### The Iron Law of Development
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

**Violating the letter of the rules is violating the spirit of the rules.**

### Mandatory Development Workflow
1. **Brainstorming** - Refine ideas through questions, explore alternatives, present design for validation
2. **Git Worktrees** - Create isolated workspace on new branch, verify clean test baseline
3. **Writing Plans** - Break work into 2-5 minute tasks with exact file paths and verification steps
4. **Test-Driven Development** - Write failing test first, watch it fail, write minimal code, watch it pass, commit
5. **Code Review** - Review against plan, report issues by severity, critical issues block progress
6. **Branch Completion** - Verify tests, present merge/PR options, cleanup worktree

### Go Pre-flight Checklist (Mandatory for every Task)
Before declaring a task "done" or providing the final solution, you MUST:

1. **Dependency & Impact Analysis:**
   - Scan the workspace to ensure changes do not break other packages.
   - Consider side effects on shared states or configurations.
2. **Unittest Verification & Supplement:**
   - Check if the modified logic has existing tests.
   - **If missing or insufficient:** You MUST generate high-quality unit tests.
   - For Go: Use the standard `testing` package or `testify`.
3. **Static Analysis & Quality Hooks:**
   - Run and pass `go fmt` and `go vet`.
   - Run the project's `pre-commit` hooks.
   - Ensure compliance with `golangci-lint` if available.

### Go Execution Workflow
1. **Plan:** Briefly state how the change adheres to Uber Go style and assess potential impact.
2. **Code:** Implement using Idiomatic Go.
3. **Verify:** Run `go test ./...` and `pre-commit run`.
4. **Refactor:** Fix any linting or test failures before finalizing.

### Skill Usage Rules

#### Mandatory Skill Invocation
**If there's even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke it.**

**This is not negotiable. This is not optional.**

#### Priority Order
1. **Process skills first** (brainstorming, debugging) - determine HOW to approach
2. **Implementation skills second** (writing-plans, executing-plans) - guide execution

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
- **MANDATORY**: Watch it fail correctly

#### GREEN - Minimal Code
- Write simplest code to pass the test
- Don't add features, refactor other code, or "improve"
- Just enough to pass
- **MANDATORY**: Watch it pass with pristine output

#### REFACTOR - Clean Up
- Remove duplication, improve names, extract helpers
- Keep tests green, don't add behavior
- Only after GREEN is confirmed

### Problem-Solving Techniques

#### When Stuck
1. **Collision Zone Thinking** - Force unrelated concepts together for emergent insights
2. **Inversion Exercise** - Flip assumptions to reveal hidden constraints
3. **Meta-Pattern Recognition** - Spot universal principles across domains
4. **Scale Game** - Test at extremes to expose fundamental truths
5. **Simplification Cascades** - Find insights that eliminate multiple components

#### Debugging Methodology
1. **Form a hypothesis** - What do you think is wrong?
2. **Create test** - Prove or disprove hypothesis
3. **Observe results** - What actually happened?
4. **Refine hypothesis** - Based on observations
5. **Repeat** - Until problem is solved

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

## Superpowers Integration

### Native Skills Available
This repository includes native Superpowers skills integration. Run `./scripts/ai-rules.sh skills` to install:

**Process Skills:**
- **using-superpowers** - Mandatory skill invocation rules
- **brainstorming** - Design refinement through questions
- **writing-plans** - Implementation planning with TDD cycles
- **test-driven-development** - RED-GREEN-REFACTOR methodology
- **using-git-worktrees** - Isolated development environments

**Implementation Skills:**
- **executing-plans** - Batch execution with checkpoints
- **subagent-driven-development** - Fresh agents per task
- **requesting-code-review** - Two-stage review process
- **finishing-a-development-branch** - Branch completion workflow

**Advanced Skills:**
- **writing-skills** - Creating and testing new skills

### Skill Usage Rules

#### Mandatory Invocation
**If there's even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke it.**

#### Priority Order
1. **Process skills first** (brainstorming, writing-plans) - determine HOW to approach
2. **Implementation skills second** (executing-plans, git-worktrees) - guide execution

#### Installation
```bash
# Install native skills to your editors
./scripts/ai-rules.sh skills

# Skills are installed to:
# ~/.codeium/windsurf/skills/
# ~/.cursor/skills/
# ~/.claude/skills/
# ~/.codex/skills/
```

## Coding Standards

### Language-Agnostic Rules
- **Single responsibility principle** - Each function/class does one thing well
- **Descriptive naming** - Variables, functions, and classes reveal intent
- **Small functions** - Maximum 20 lines, ideally 5-10
- **No magic numbers** - Extract to named constants
- **Error handling** - Handle errors at appropriate levels, never swallow silently

### TypeScript/JavaScript Specific
- **Strict mode always** - `use strict` and TypeScript strict mode enabled
- **Async/await preferred** - Over promises or callbacks
- **Type safety** - No `any` types, explicit return types
- **Interface over type** - For object shapes that might be extended
- **Prefer const** - Use `let` only when reassignment is necessary

### Python Specific
- **PEP 8 compliance** - Follow Python style guide strictly
- **Type hints required** - All functions and variables
- **Docstrings** - Google or NumPy style for all public functions
- **List comprehensions** - Over map/filter where readable

### Go Specific
- **KSS + Idiomatic Go:** Prioritize clarity. "Clear is better than clever."
- **Uber Go Style Guide:** Strictly follow the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
  - Use `Pointers to Interfaces` only when necessary (rarely).
  - Be explicit about `Slices` and `Maps` initialization.
  - Follow Uber's rules for `Errors` (wrapping and types).
  - Function grouping and ordering (Exported first).
- **Composition over Inheritance:** Use struct embedding. No deep hierarchies.
- **CSP Concurrency:** Use channels/goroutines. Proverb: "Don't communicate by sharing memory; share memory by communicating."
- **Interface Design:** "Accept interfaces, return structs". Keep interfaces tiny (1-2 methods).

## Code Organization

### File Structure

#### Go Project Layout (Standard)
```
.
├── cmd/                  # Main applications for this project
│   └── myapp/           # Application entry points
├── internal/            # Private application and library code
│   ├── app/             # Application code
│   └── pkg/             # Internal shared libraries
├── pkg/                 # Public library code (externally importable)
├── api/                 # OpenAPI/Swagger specs, JSON schema files
├── configs/             # Configuration file templates or default configs
├── init/                # System init (systemd, upstart, sysv) configs
├── scripts/             # Build, install, analysis scripts
├── bin/               # Packaging and CI configurations
│   ├── ci/              # CI configurations
│   └── package/         # Package configurations
├── deployments/         # IaaS, PaaS, container orchestration configs
├── test/                # External test apps and test data
│   └── testdata/        # Test data ignored by Go
├── docs/                # Design and user documents
├── tools/               # Supporting tools for this project
├── examples/            # Examples for applications and libraries
├── third_party/         # External helper tools, forked code
├── githooks/            # Git hooks
├── assets/              # Other assets (images, logos, etc)
├── website/             # Project website data
├── go.mod               # Go module file
├── go.sum               # Go module checksums
├── Makefile             # Build automation
└── README.md            # Project overview
```

#### General Application Layout (Non-Go)
```
src/
├── components/          # UI components
├── services/           # Business logic
├── utils/              # Pure functions
├── types/              # Type definitions
├── tests/              # Test files
└── docs/               # Documentation
```

### Naming Conventions
- **Files**: kebab-case (`user-service.ts`)
- **Components**: PascalCase (`UserProfile.tsx`)
- **Functions**: camelCase (`getUserData()`)
- **Constants**: UPPER_SNAKE_CASE (`API_BASE_URL`)
- **Variables**: camelCase (`userName`)

## Testing Strategy

### TDD Requirements
- **RED phase**: Write failing test first, watch it fail
- **GREEN phase**: Write minimal code to pass
- **REFACTOR phase**: Improve without changing behavior
- **Coverage**: Minimum 80% line coverage, 100% for critical paths

### Test Types
- **Unit tests** - Single function/class in isolation
- **Integration tests** - Multiple components working together
- **End-to-end tests** - Full user workflows
- **Property tests** - Verify invariants with random inputs

## Editor-Specific Instructions

### For Windsurf
- **Always follow Superpowers workflow**
- **Trigger brainstorming before coding**
- **Use subagent-driven development for complex tasks**
- **Maintain strict TDD discipline**
- **Provide contextual suggestions based on current workflow phase**

### For Cursor
- **Apply Superpowers methodology automatically**
- **Suggest improvements following YAGNI and DRY principles**
- **Follow project conventions consistently**
- **Use two-stage review process**
- **Generate test cases before implementation**

### For VSCode
- **Workspace settings enforce TDD workflow**
- **Extensions support Superpowers methodology**
- **Integrate with git worktrees for branch isolation**
- **Automated formatting and linting**
- **Test runner integration**

### For GitHub Copilot
- **Generate code following Superpowers standards**
- **Consider project context and current workflow phase**
- **Maintain consistency with existing patterns**
- **Prefer test-driven suggestions**
- **Follow strict naming conventions**

### For Aider
- **System prompt integration for Superpowers workflow**
- **Enforce RED-GREEN-REFACTOR cycle**
- **Use git worktrees for isolated development**
- **Implement two-stage code review**
- **Maintain strict coding standards**

## Best Practices

### Development Process
- **Never write code without failing test first**
- **Delete code written before tests**
- **Commit after each GREEN phase**
- **Use feature flags for incomplete features**
- **Document decisions, not obvious code**

### Code Quality
- **Readability over cleverness**
- **Explicit over implicit**
- **Consistent style across project**
- **Meaningful comments for why, not what**
- **Regular refactoring sessions**

### Performance
- **Profile before optimizing**
- **Consider algorithmic complexity first**
- **Cache strategically**
- **Measure real-world usage**
- **Avoid premature optimization**

## Security Guidelines

### General Principles
- **Principle of least privilege**
- **Validate all inputs**
- **Use parameterized queries**
- **Implement proper authentication**
- **Keep dependencies updated**

### Specific Practices
- **Never trust client data**
- **Use HTTPS everywhere**
- **Implement rate limiting**
- **Log security events**
- **Regular security audits**

## Git Workflow

### Branch Strategy
- **main** - Production-ready code
- **develop** - Integration branch
- **feature/*** - New features
- **bugfix/*** - Bug fixes
- **hotfix/*** - Critical production fixes

### Commit Standards
- **Conventional commits** - `type(scope): description`
- **Atomic commits** - One logical change per commit
- **Clear messages** - Explain what and why
- **Sign commits** - For accountability

## Documentation Standards

### Code Documentation
- **API docs** - Auto-generated from type definitions
- **README** - Project overview and setup
- **ARCHITECTURE** - System design decisions
- **CONTRIBUTING** - Development guidelines

### Comments
- **Explain why, not what**
- **Document complex algorithms**
- **Mark TODOs with dates**
- **Link to external resources**
- **Keep comments up-to-date**

## Tool Configuration

### Required Tools
- **Git** - Version control
- **Node.js/npm** - Package management
- **TypeScript** - Type safety
- **ESLint/Prettier** - Code formatting
- **Jest/Vitest** - Testing framework

### Development Environment
- **Docker** - Consistent environments
- **GitHub Actions** - CI/CD pipeline
- **Dependabot** - Dependency updates
- **CodeClimate** - Code quality
- **Sentry** - Error tracking

## Continuous Integration

### Pipeline Requirements
- **Lint checks** - Code style enforcement
- **Type checking** - TypeScript validation
- **Unit tests** - All tests must pass
- **Integration tests** - Critical paths
- **Security scans** - Vulnerability detection

### Deployment Standards
- **Semantic versioning** - Consistent versioning
- **Release notes** - Document changes
- **Rollback plans** - Quick recovery
- **Monitoring** - System health
- **Alerting** - Proactive notifications

## Go Maintenance & Cleanup
- Remove unnecessary annotations, unused imports, and redundant helper functions.
- Maintain consistent file structure and naming conventions.
