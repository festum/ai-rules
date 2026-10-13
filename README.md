# AI Rules Template

A single place for the rules and skills your AI coding agents share. Every editor and agent reads its own rules file and skills folder; this repo is the one source that feeds them all, so a change here reaches every tool that links to it.

## Setup

```bash
git clone https://github.com/festum/ai-rules
cd ai-rules
chmod +x scripts/setup.sh
./scripts/setup.sh
```

One run links the rules in `system/` into each tool's native rules path and links each repo skill into each tool's skills directory. The script prints every target it creates; re-running is safe and refreshes the links.

Sub-commands: `rules` links rules only, `skills` refreshes skill links and external packs, `update` is an alias for `skills`, and plain `./scripts/setup.sh` does both.

## How it works

- `system/` holds the rules layer: the shared rules read by every tool, a companion rules file, and one system agent's contract.
- `skills/` holds one folder per skill.
- The setup script is where the mapping lives. It knows which path each editor and agent reads, and it owns the skill links and the external packs (a language skill pack plus a few selected upstream skills), so the details are documented in the script rather than mirrored here.
- A private overlay outside this repo carries personal or company rules. When it exists, the script merges it with the shared rules and links editors to the merged copy; after editing either file, run the script again.

## Daily workflow

Edit `system/rules.md` and every linked tool picks it up next session. Edit the overlay and re-run the script. Task state lives in a small folder per task that all agents read and update, so work survives sessions and worktrees; the convention is defined in the shared rules.

## Skills

Edit a skill in this repo and the existing links pick it up. A new skill folder needs one run of `./scripts/setup.sh skills` to get linked; the same command reinstalls external packs.

## Cleanup

Uninstalling means deleting the symlinks the script created; its output lists every rules link. Skill links created for this repo can be removed with:

```bash
for d in ~/.agents/skills ~/.claude/skills ~/.cursor/skills ~/.opencode/skills ~/.config/opencode/skills ~/.hermes/skills ~/.pi/agent/skills; do
  [ -d "$d" ] || continue
  find "$d" -maxdepth 1 -type l -lname "$PWD/skills/*" -delete
done
```

## License

MIT. See [LICENSE](LICENSE).
