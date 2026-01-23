# AI Rules Template

Synchronize AI coding rules across Windsurf, Cursor, VS Code, Cline, GitHub Copilot, and Aider.

## 🚀 Quick Setup

```bash
# Clone this repo
git clone <ai-rules-repo-url>
cd ai-rules

# Setup rules and skills (default: both)
chmod +x scripts/setup.sh
./scripts/setup.sh              # Setup both rules and skills
```

## 📁 Repository Structure

```
ai-rules/
├── ai_rules/
│   └── master-rules.md          # Master rules + Superpowers methodology
├── scripts/
│   └── setup.sh                 # Universal setup script
├── .gitignore
├── README.md
└── LICENSE
```

## 🎯 What Gets Set Up

### Editor Rules (symlinks)
- **Windsurf**: `~/.codeium/windsurf/memories/global_rules.md`
- **Cursor**: `~/.cursor/memories/global_rules.md`
- **Claude**: `~/.claude/memories/global_rules.md`
- **Codex**: `~/.codex/memories/global_rules.md`

### VS Code Extensions (symlinks)
- **Continue**: `~/.continue/rules/ai-rules.md`
- **GitHub Copilot**: `.github/copilot-instructions.md`

### Superpowers Skills (native)
- **Process skills**: brainstorming, writing-plans, TDD, git-worktrees, systematic-debugging
- **Implementation skills**: executing-plans, code review, branch completion, verification-before-completion
- **Advanced skills**: writing skills, subagent development, parallel agents

## 📝 Daily Workflow

1. **Edit rules:**
   ```bash
   vim ai_rules/master-rules.md
   ```

2. **Update skills (if needed):**
   ```bash
   ./scripts/setup.sh skills
   ```

3. **Changes are immediately available in all editors!**

## 🔧 Available Commands

```bash
./scripts/setup.sh              # Setup both rules and skills (default)
./scripts/setup.sh rules        # Setup editor rules only
./scripts/setup.sh skills       # Setup Superpowers skills only
./scripts/setup.sh help         # Show help
```

## 📋 Superpowers Skills

The master rules include Superpowers methodology with native skill integration:

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

## 🗑️  Cleanup

```bash
# Remove editor symlinks
rm ~/.codeium/windsurf/memories/global_rules.md
rm ~/.cursor/memories/global_rules.md
rm ~/.claude/memories/global_rules.md
rm ~/.codex/memories/global_rules.md
rm ~/.continue/rules/ai-rules.md
rm .github/copilot-instructions.md
rm ~/.github/copilot-instructions.md

# Restore from .bak files if they exist
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
