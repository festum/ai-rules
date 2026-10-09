# AI Rules Template

Synchronize AI coding rules across Windsurf, Cursor, VS Code, Cline, GitHub Copilot, and Aider.

## Quick Setup

```bash
# Clone this repo
git clone <ai-rules-repo-url>
cd ai-rules

# Setup rules and skills (default: both)
chmod +x scripts/setup.sh
./scripts/setup.sh              # Setup both rules and skills
```

## Repository Structure

```
ai-rules/
├── system/
│   ├── rules.md                  # Shared rules (SSOT)
│   ├── sticky_rules.md           # OMP sticky rules
│   └── hermes.md                 # Hermes layer contract
├── skills/
│   └── <skill-name>/SKILL.md    # One folder per skill
├── scripts/
│   └── setup.sh                 # Universal setup script
├── .gitignore
├── README.md
└── LICENSE
```

## What Gets Set Up

### Editor Rules (symlinks from `system/rules.md`)
- **Windsurf**: `~/.codeium/windsurf/memories/global_rules.md`
- **Cursor**: `~/.cursor/memories/global_rules.md`
- **Claude**: `~/.claude/CLAUDE.md`
- **Codex**: `~/.codex/memories/global_rules.md`
- **Continue**: `~/.continue/rules/ai-rules.md`
- **GitHub Copilot**: `~/.github/copilot-instructions.md`
- **Opencode**: `~/.config/opencode/AGENTS.md`
- **Zed**: `~/.config/zed/AGENTS.md`
- **Home**: `~/AGENTS.md`
- **OMP**: `~/.omp/agent/AGENTS.md`
- **OMP sticky**: `~/.omp/agent/RULES.md` ← `system/sticky_rules.md`
- **Hermes**: `~/.hermes/SOUL.md` ← `system/hermes.md`

### Private overlay (`~/.ai-rules.local.md`)
Company- or machine-specific rules stay out of this repo, like `~/.zshrc.local`. If `~/.ai-rules.local.md` exists (override with `AI_RULES_LOCAL`), `./scripts/setup.sh rules` writes `system/rules.md` + the overlay to `~/.cache/ai-rules/rules.md` and links every editor above to that merged file. Re-run `./scripts/setup.sh rules` after editing either file.

### Skills ownership
Two layers:

1. **Repo skills** (`ai-rules/skills/`): per-skill symlinks into each agent skills dir. Never whole-folder symlink.
2. **Downloaded shared packs** (golang / Anthropic / Superpowers / humanizer / task-observer): real files live in `~/.agents/skills/<name>`; Claude / Cursor / Opencode / Hermes / pi only get symlinks to that.
3. **`omp` skill**: Hermes + OpenClaw only (`~/.hermes/skills`, `~/.openclaw/skills`); not linked into coding agents.

Agent skill dirs:
- **Agents (canonical store)**: `~/.agents/skills`
- **Cursor**: `~/.cursor/skills`
- **Claude**: `~/.claude/skills`
- **Opencode**: `~/.opencode/skills` and `~/.config/opencode/skills`
- **Hermes**: `~/.hermes/skills`
- **pi**: `~/.pi/agent/skills`
- **OpenClaw**: `~/.openclaw/skills`

## Daily Workflow

1. **Edit rules:**
   ```bash
   vim system/rules.md
   ```

2. **Update skills (if needed):**
   ```bash
   ./scripts/setup.sh skills
   ```

3. **Shared skill edits are live via per-skill links.** `./scripts/setup.sh skills` also installs external packs (currently `cc-skills-golang` via `npx skills`).

### Shared task state

Every task keeps one state folder under `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/` (`STATE.md`, `plan-v<N>.md`, `log.md`), read and written by all agents across sessions, agents, and worktrees. The convention lives in `system/rules.md` §8.

## Available Commands

```bash
./scripts/setup.sh              # Setup/update both rules and skills (default)
./scripts/setup.sh rules        # Setup/update editor rules only
./scripts/setup.sh skills       # Setup/update skills + external packs
./scripts/setup.sh update       # Alias for skills (refresh everything)
./scripts/setup.sh help         # Show help
```

Safe to re-run. Later runs refresh ai-rules skill links, git submodules (if any), `cc-skills-golang`, selective Anthropic / Superpowers skills, humanizer, task-observer.

`rules` / `skills` / `all` first pull git submodules when `git` and network are available (`git submodule update --init --recursive --remote`). Offline or no-git environments skip that step and continue.

`skills` / `all` then install external packs outside `ai-rules/skills` (canonical store = `~/.agents/skills`, others symlink):
- **cc-skills-golang**: `npx skills add https://github.com/samber/cc-skills-golang -g --all` → flattened `golang-*` in `~/.agents/skills`, then linked out
- **Anthropic skills (selective)**: sync selected skills from `anthropics/skills` into `~/.agents/skills` (not full pack; lifestyle example dirs stay Claude-owned)
- **Superpowers (selective)**: sync `systematic-debugging` from `obra/superpowers` into `~/.agents/skills` (not the full 14-skill plugin)
- **humanizer**: sync `blader/humanizer` into `~/.agents/skills/humanizer` (not a git submodule)
- **task-observer**: sync `rebelytics/one-skill-to-rule-them-all` into `~/.agents/skills/task-observer` (not a git submodule)

## Skills

Each skill is a folder under `skills/` with a `SKILL.md` (or a nested skill pack). Edit the skill in this repo, then run `./scripts/setup.sh skills` if a new skill directory was added. Existing per-skill links stay live. Go / Anthropic / Superpowers / humanizer / task-observer come from the external installer above, not from this repo. Local `humanizer-ref` / `humanizer-zh` stay in `ai-rules/skills`.

## Cleanup

```bash
# Remove editor rule symlinks
rm ~/.codeium/windsurf/memories/global_rules.md
rm ~/.cursor/memories/global_rules.md
rm ~/.claude/CLAUDE.md
rm ~/.codex/memories/global_rules.md
rm ~/.continue/rules/ai-rules.md
rm ~/.github/copilot-instructions.md
rm ~/.config/opencode/AGENTS.md
rm ~/.config/zed/AGENTS.md
rm ~/AGENTS.md
rm ~/.omp/agent/AGENTS.md
rm ~/.omp/agent/RULES.md
rm ~/.hermes/SOUL.md

# Remove only ai-rules skill links (keep agent-owned skills)
for d in ~/.cursor/skills ~/.agents/skills ~/.claude/skills ~/.opencode/skills ~/.config/opencode/skills ~/.hermes/skills ~/.pi/agent/skills; do
  [ -d "$d" ] || continue
  find "$d" -maxdepth 1 -type l -lname "$PWD/skills/*" -delete
done
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
