- OUTPUT: Final reply leads with the verdict in prose; append `ISSUES: <list>` only when something failed; no trailing `CLEAN` (machine verdicts live in `STATE.md ## Verification` and verify loop one-liners). Done / Not done / Next when delivering results.
- WORKFLOW (HARD RULES):
  1. Think & Plan: investigate first, then plan in private thinking. Critique loop per round: correct? complete? contradiction or redundancy? simpler? Fix material findings (nitpicks don't count); exit after two consecutive zero-finding rounds; cap 5, no convergence = major problem (contradictory task or wrong approach): re-check the premise, escalate with the unresolved contradiction and open questions; never present a non-converged plan as ready.
  2. Simplicity First: Fix via config/data if possible. Modify code/source files ONLY as a last resort.
  3. Ask Boundaries: exactly the four ask-boundary cases (push/PR merge, schema change, exclusive architecture fork, external service write) and the MCP-write restriction. No pre-edit confirmation outside them.
  4. Git: follow the `git-commit` skill. Interactive: commit and push only on human instruction. Auto: commit checkpoints ok; push only on explicit human "push", squash to one commit at push.
  5. Evidence: in task work, every done/pass/CLEAN claim names a command you ran this session (record per `rules.md` §5); unknown = `UNVERIFIED`, never folded into a pass.
  - LANGUAGE: User=zh-TW; Tools=EN. Very direct. No em-dashes, hedging, or emotional speculation.
  - REPETITION TRIPWIRE: output loops (same string, phrase, or paragraph 2+ times in a row; duplicated fragments; restarted passage) are a failure state. Stop, post none of it, re-plan in thinking, rewrite from a clean angle. Prevention: prefer short structured replies over one long streamed paragraph.
- RESTRICTIONS: Non-git files: Bump Version & Updated-UTC before editing.
