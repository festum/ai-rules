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
├── skills/
│   └── <skill-name>/SKILL.md    # One folder per skill
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
- **GitHub Copilot**: `~/.github/copilot-instructions.md`

### Skills (symlinks)
The entire `skills/` folder is symlinked into every supported tool, so every skill is available everywhere:
- **Cursor**: `~/.cursor/skills`
- **Agents**: `~/.agents/skills`
- **Claude**: `~/.claude/skills`
- **Opencode**: `~/.opencode/skills`
- **Hermes**: `~/.hermes/skills`

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
./scripts/setup.sh skills       # Setup skills only
./scripts/setup.sh help         # Show help
```

## 📋 Skills

Each skill is a folder under `skills/` with a `SKILL.md` (Superpowers methodology, personal workflow skills, and language-specific skill packs all live side by side). To add or change a skill, edit its `SKILL.md` directly — the change is live in every tool immediately, no re-run of `setup.sh` needed.

## 🗑️  Cleanup

```bash
# Remove editor rule symlinks
rm ~/.codeium/windsurf/memories/global_rules.md
rm ~/.cursor/memories/global_rules.md
rm ~/.claude/memories/global_rules.md
rm ~/.codex/memories/global_rules.md
rm ~/.continue/rules/ai-rules.md
rm ~/.github/copilot-instructions.md
rm ~/.config/opencode/AGENTS.md

# Remove skill symlinks
rm ~/.cursor/skills
rm ~/.agents/skills
rm ~/.claude/skills
rm ~/.opencode/skills
rm ~/.hermes/skills

# Restore from .bak files if they exist
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
