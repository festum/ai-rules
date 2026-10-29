# ai-rules

**The rule set and skill set behind your AI coding agents: Zed, Claude Code, Cursor, Copilot, Codex, Continue, opencode, OMP, Hermes.**

`system/rules.md` is the always-on contract every tool reads through a symlink. `skills/` holds the workflows the rules dispatch to. One setup script links both; edit here, each tool picks it up next session.

Tested rules, not a template: each one replaces a failure seen in daily multi-agent use since 2026-01.

## Layout

| Path | Role |
|---|---|
| `system/rules.md` | Execution-Layer Rules, 10 sections, read by every coding agent |
| `system/sticky_rules.md` | Hard rules for OMP (`~/.omp/agent/RULES.md`) |
| `system/hermes.md` | Hermes contract (`~/.hermes/SOUL.md`), self-contained |
| `system/templates/STATE.md` | STATE.md template, linked to `~/.local/state/templates/STATE-template.md`, per rules.md §8.6 |
| `skills/<name>/SKILL.md` | One folder per skill |
| `scripts/setup.sh` | Links rules and skills into each tool's native paths, syncs external packs |
| `~/.ai-rules.local.md` | Private overlay: read as a second file, never merged, wins on conflict |

## Methodology

| Method | Source | Lives in | Effect |
|---|---|---|---|
| Agent-Computer Interface discipline | SWE-agent (arXiv:2405.15793) | `rules.md` §9 | Batch independent reads, use bounded file windows, cap output, run risk-scoped checks, and stop repeated unsuccessful fixes |
| Plan critique with a convergence exit | Self-refinement research (Self-Refine, Reflexion) | `rules.md` §1 | Review complex/high-risk plans for material gaps; stop when resolved, without a quota of clean rounds |
| Cross-session task state | GSD's per-project state records, adapted | `rules.md` §8 | One `STATE.md` per task, shared by every agent, session, and worktree, so work never restarts from zero |

## Validated in use

Each rule below replaced a real failure:

- **Claims without evidence**: check-pass claims require observed output; reliable operation results suffice for routine actions. Reporting never creates a need for tests (§10).
- **Re-diagnosis loops**: the root cause gets recorded once with its proving command; later turns implement from it (§1).
- **Repetition under stress**: a tripwire in `sticky_rules.md` forces a rewrite from a clean angle.
- **Behavior overturned on ticket say-so**: origin gets traced before any reversing change (§4).
- **Rule bloat**: two trimming passes were needed once the file grew past readable size.
- **Drift**: critique checks the plan, `STATE.md` findings and verification keep each turn checkable, and the rules themselves get revised on a fixed cadence (today's rules are revisions of earlier ones, not additions on top).

What held: long procedures belong in skills, session memory is not state, wording decays while structure holds, one name per concept (§1).

## Quick start

```bash
git clone https://github.com/festum/ai-rules
cd ai-rules
chmod +x scripts/setup.sh
./scripts/setup.sh
```

One run links the rules in `system/` into each tool's native rules path and links each repo skill into each tool's skills directory. The script prints every target it creates; re-running is safe and refreshes the links.

Sub-commands: `rules` links rules only, `skills` refreshes skill links and external packs, `update` is an alias for `skills`, plain `./scripts/setup.sh` does both.

External packs (real directories under `~/.agents/skills`, symlinked into other agents): `cc-skills-golang` via `npx skills`, a subset of `obra/superpowers` (systematic-debugging), a subset of `anthropics/skills` (doc-coauthoring, docx, pdf, skill-creator, xlsx), plus humanizer and task-observer.

### Verification and activation scope

Simple questions, lookups, prose edits, and clear low-risk commands do not start a verification loop. Behavior changes, material risk, consequential uncertainty, explicit verification requests, and required acceptance/security/contract checks determine what must run. Delivery still requires the repository's applicable CI-equivalent checks. Valid evidence is reused; no extra unchanged `CLEAN` round or routine host retest is required.

Rules links control local instructions; skill frontmatter controls discovery, and skill bodies supply dispatch prompts. Third-party bundles, including task-observer, remain unchanged. Local activation rules do not change a third-party description or guarantee that a harness will suppress automatic loading. Where needed, use the harness's supported skill-permission or discovery settings; do not rewrite the third-party bundle.

## Daily workflow

Edit `system/rules.md` and every linked tool picks it up next session. Edit the overlay the same way, no re-link needed. Task state lives in a folder per task that all agents read and write, per `rules.md` §8.

## Setup invariants

setup.sh must keep these; change the design, not as afterthought:

- Path-independent: the repo can live anywhere; `REPO_ROOT` derives from the script's own location, and every link is an absolute direct symlink re-pointed on each run.
- One-hop symlinks only: tools read the files fine through one symlink; never nest symlinks or copy the linked files.
- Re-running `./scripts/setup.sh` re-syncs submodules and upstream skill packs (`skills`/`update` refreshes external packs, including task-observer and humanizer); rules links are idempotent. After moving the repo, re-run to re-point the links.

## Skills

Edit a skill in this repo and existing links pick it up. A new skill folder needs one run of `./scripts/setup.sh skills`.

| Skill | Use it for |
|---|---|
| `ship` | Jira ticket through PR, review comments, CI, Dev deploy |
| `delegate` | Plan-only mode: plans a cheaper agent executes, verified, PR loop to approval |
| `open-pr` | Review-ready pull requests with title, description, linked issues, reviewers |
| `review-pr` | Review a teammate's PR against its Jira spec and current base branch |
| `git-commit` | Commit, merge, push rules: Conventional Commits, base-branch sync, push gate, squash |
| `dependabot` | Find, approve, auto-merge dependabot PRs; deploy gates and monitoring |
| `omp` | Dispatch the headless executor with required checks and conditional same-session follow-ups (Hermes/OpenClaw only) |
| `voice` | Shape every generated or edited prose output |
| `humanizer-ref` | Reference-register documents: CVs, API docs, specs, changelogs, READMEs |
| `humanizer-zh` | Edit Chinese prose: cut filler, repetition, and templated phrasing while keeping facts and the author's voice |
| `snapshot` | Cited, incremental project knowledge snapshot (arch, facts, defects, history, plan, conflicts); manual sync at most hourly, ask mode for snapshot-only Q&A, read mode for other skills |
| `wiz` | Wiz GraphQL writes with browser session auth and Chrome CDP cookie refresh |

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
