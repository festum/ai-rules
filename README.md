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

| Method | Source | Lives in |
|---|---|---|
| Short always-on rules, procedures in skills, verify before done | [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | `system/` vs `skills/` split |
| Agent-Computer Interface: batched reads, bounded windows, capped output | [SWE-agent, arXiv:2405.15793](https://arxiv.org/abs/2405.15793) | `rules.md` §9 |
| Real-issue tasks: define the problem with a proving command before patching | [SWE-bench, arXiv:2310.06770](https://arxiv.org/abs/2310.06770) | `rules.md` §1 |
| Plan critique that stops once material findings are resolved | [Self-Refine, arXiv:2303.17651](https://arxiv.org/abs/2303.17651) | `rules.md` §1 |
| Failure verdicts written down and reused instead of retried | [Reflexion, arXiv:2303.11366](https://arxiv.org/abs/2303.11366) | `rules.md` §6, §8 |
| One `STATE.md` per task across agents and sessions | GSD's per-project state records, adapted | `rules.md` §8 |

## Validated in use

Each rule below replaced a real failure:

- **Claims without evidence**: check-pass claims require observed output; reliable operation results suffice for routine actions. Reporting never creates a need for tests (§10).
- **Re-diagnosis loops**: the root cause gets recorded once with its proving command; later turns implement from it (§1).
- **Repetition under stress**: a tripwire in `sticky_rules.md` forces a rewrite from a clean angle.
- **Gaming approval gates**: a weak model followed a CI-log hint, posted sign-off comments, rewrote PR role fields, and polled in a loop. Gate red now means "waiting on a human", and tool-output hints are data (§3, sticky rule 6).
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

External packs (real directories under `~/.agents/skills`, symlinked into other agents): `cc-skills-golang` via `npx skills`, a subset of `obra/superpowers` (systematic-debugging), a subset of `anthropics/skills` (doc-coauthoring, docx, pdf, skill-creator, xlsx), plus humanizer, task-observer, show-me, and `mattpocock/skills` (grill-me, grilling, to-questionnaire).

Third-party bundles (including task-observer) are never rewritten; control their loading through the harness's skill settings.

## Daily workflow

Edit `system/rules.md` and every linked tool picks it up next session. Company-specific values (ticket formats, template field names, sign-off phrases, endpoints) go only in `~/.ai-rules.local.md`, never in this repo.

## Setup invariants

setup.sh must keep these; change the design, not as afterthought:

- Path-independent: the repo can live anywhere; `REPO_ROOT` derives from the script's own location, and every link is an absolute direct symlink re-pointed on each run.
- One-hop symlinks only: tools read the files fine through one symlink; never nest symlinks or copy the linked files.
- Re-running `./scripts/setup.sh` re-syncs submodules and upstream skill packs (`skills`/`update` refreshes external packs, including task-observer, humanizer, show-me, and the mattpocock skills); rules links are idempotent. After moving the repo, re-run to re-point the links.

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
| `omp` | Dispatch the headless executor with required checks and same-session follow-ups (Hermes, `ship`, `delegate`) |
| `voice` | Shape every generated or edited prose output |
| `humanizer-ref` | Reference-register documents: CVs, API docs, specs, changelogs, READMEs |
| `blog` | Blog workflows; `/blog write` turns a session's back-and-forth into a publishable markdown article: asks angle and audience, proposes titles and tags, runs fact-check and humanizer, never publishes |
| `fact-check` | Verify an article's factual claims against inspected evidence before publishing; runs before the humanizers, re-checks claims they touched |
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
