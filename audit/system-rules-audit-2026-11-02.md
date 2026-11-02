# System Rules 審計：去留與放置判定（2026-11-02）

## 0. 範圍、名詞與證據來源

- 審計對象：`system/hermes.md`（H）、`system/rules.md`（R）、`system/sticky_rules.md`（S）、本專案 auto-memory 唯一一條（M）。各 skill 只在「重複／衝突／搬移目的地」時引用，未逐條盤點。
- 「memory」在本報告指常駐載入面：三份檔案都是常駐（`~/.claude/CLAUDE.md`、`~/.hermes/SOUL.md`、`~/.omp/agent/RULES.md` 皆 symlink 到 repo，已用 `ls -la` 確認）。「skill」指 `skills/<name>/SKILL.md`，觸發時才載入。
- 證據來源（只用以下這些，沒有其他來源）：
  - `git log -- system/` 共 23 個 commit，以及其中 commit body 寫明的起因事件。
  - `skill-observations/observation-log/` 16 筆紀錄（0001–0016，含 archive）。
  - memory `review-rules-by-scenario`（2026-10-30）。
  - `git log -S` 查每條規則最早出現的 commit。
  - `grep -r` 查 `system/ skills/ scripts/` 有沒有其他地方引用。
- 限制：
  - `git fetch` 失敗（remote 權限），本報告讀的是本地 `d53e82d`，標 `UNVERIFIED: freshness`。
  - Hindsight `reflect` 逾時，沒有拿到其他歷史 session 的資料。
  - 沒有任何資料記錄「規則上線後同類情境何時再被攔下」。所以 A1 只能確認起因，無法確認「之後同類情境沒再出現」，任何條目都不能只憑 A1 判成封存。
- 證據狀態：
  - 「有命中紀錄」= 有可引用的起因事件（commit body、observation 或 memory 寫明）。
  - 「證據不足（待定）」= 只有新增 commit，沒有事件描述。
  - 判定欄寫「待定」的，是判定本身要靠使用頻率才能決定的條目。

起因事件代號（後文引用）：

| 代號 | 來源 | 日期 | 事件 |
| --- | --- | --- | --- |
| E1 | obs 0016 / `e5c739f` | 2026-10-27 | 簡單問答被套上完整驗證儀式（"every turn" 無適用閘門） |
| E2 | memory `review-rules-by-scenario` | 2026-10-30 | 分析後沒有 dispatch 步驟；兩次失敗或 dispatch 失敗直接 `BLOCKED`，沒有「換路繼續」 |
| E3 | `7d4d54f` body | 2026-10-20 | Hermes 每輪重送 investigate-first，OMP 反覆診斷不實作；merged rules cache 讓舊措辭被加回 |
| E4 | `5f3c861` body | 2026-10-25 | 診斷或狀態報告就結束 turn，但 fix 其實還做得到；`BLOCKED` 格式不一致 |
| E5 | `5a0302a` body | 2026-10-24 | YOLO 模式繞過問題定義 |
| E6 | obs 0014 | 2026-10-23 | merge 後把 branch cleanup 當成問題丟回給人 |
| E7 | obs 0015 | 2026-10-23 | 自有、未保護的 repo 也硬走 PR 流程 |
| E8 | obs 0006、0009 | 2026-09-29 | 把有時間戳的紀錄（scanner finding、bot comment）當成即時狀態 |
| E9 | obs 0001 | 2026-09-25 | 把條件性風險寫成已驗證缺陷 |
| E10 | obs 0012、0013 | 2026-10-23 | observation log 版本錯位，掃描回報空；setup 路徑依賴 |
| E11 | `30a0e12` body | 2026-10-26 | 精簡時刪掉 4 條防護，事後復原（flags ≠ control signal、skill-failure stop、breaking-change sign-off、No-Hermes YOLO off） |

---

## 第一步：現存規則完整清單（原文起首，未改寫）

格式：編號｜位置｜原文起首（逐字擷取到第一個句讀，全文以位置為準）

### hermes.md

| # | 位置 | 原文起首 |
| --- | --- | --- |
| H00 | hermes.md:6 | `Goal: Route code implementation to OMP; verify only when …` |
| H01 | hermes.md:8 | `Local overlay: ~/.ai-rules.local.md (or $AI_RULES_LOCAL) exists → apply on top (wins on conflict).` |
| H02 | hermes.md:13 | `Mirror language: Traditional Chinese if user writes Chinese; English if English; default Traditional Chinese.` |
| H03 | hermes.md:14 | `English output (B1 style): direct, <20 words/sentence, <120 words total unless requested.` |
| H04 | hermes.md:15 | `Raw elements: code, commands, paths, logs, JSON as-is.` |
| H05 | hermes.md:16 | `External artifacts: PRs, Jira, docs, configs, rules in standard English.` |
| H06 | hermes.md:19 | `System & skills read-only: installed skills, agent engines, third-party tools immutable; …` |
| H07 | hermes.md:20 | `Configs/rules: modify only on explicit user request.` |
| H08 | hermes.md:21 | `Project code: modified only by OMP during task execution.` |
| H09 | hermes.md:22 | `Surgical changes: reuse config/tools/code before adding code; …` |
| H10 | hermes.md:23 | `Integration contracts: changed integrations → inspect producer serializers/annotations, …` |
| H11 | hermes.md:24 | `External writes: MCP writes only to Jira and memory; …` |
| H12 | hermes.md:27 | `Q&A / discussion / lookup: answer directly, …` |
| H13 | hermes.md:28 | `Config / rule update: modify specified config directly (§3). Never dispatch OMP.` |
| H14 | hermes.md:29 | `Workflow routing: Jira work implemented by Claude, plus its PR fixes → ship; …` |
| H15 | hermes.md:30 | `Git repo code task: dispatch canonical OMP command (§2.1). Hermes never writes code.` |
| H16 | hermes.md:31 | `Fix or change intent = code task, even phrased as question or needing analysis first.` |
| H17 | hermes.md:34 | `Verification trigger: extra checks only for explicit verification request, …` |
| H18 | hermes.md:35 | `Zero false-OK: never claim unrun check passed.` |
| H19 | hermes.md:36 | `Memory vs source: memory (session, STATE.md, snapshot, Hindsight, commits) answers …` |
| H20 | hermes.md:37 | `Default skeptical: user reports = real bugs.` |
| H21 | hermes.md:38 | `Evidence escalation, when defect recurs or existing evidence can't settle …` |
| H22 | hermes.md:39 | `Turn outcomes: requested answer or operation result; …` |
| H23 | hermes.md:42 | `Before analyzing, answering from, or dispatching work against git repo code, …: git fetch --prune origin.` |
| H24 | hermes.md:43 | `Then delete local branches and remove clean worktrees whose branch is merged …` |
| H25 | hermes.md:44 | `Freshness = prerequisite, never verification trigger.` |
| H26 | hermes.md:49 | `All git repo code tasks use exactly: omp -p --plan-yolo --auto-approve …` |
| H27 | hermes.md:51 | `Session continuity: check STATE.md ## Sessions.` |
| H28 | hermes.md:52 | `Preflight & watchdog: run omp --version.` |
| H29 | hermes.md:53-58 | `Execution mode:`（Short tasks / Foreground / Long tasks / parameters / Ownership 五子項） |
| H30 | hermes.md:59 | `Dispatch integrity: capture exit status, stderr, final structured JSON event; …` |
| H31 | hermes.md:60 | `Findings handoff: dispatch prompt carries task scope, locked decisions, …` |
| H32 | hermes.md:63 | `Scope vs tactics: Hermes owns scope, constraints, gates; OMP owns tactics and plan (--plan-yolo).` |
| H33 | hermes.md:64-67 | `OMP upward signals, only:`（BLOCKED / gate request / completion report） |
| H34 | hermes.md:68 | `OMP BLOCKED: Hermes can supply missing fact, in-scope decision, or another route → resume …` |
| H35 | hermes.md:69 | `Uncertainty ≠ gate: OMP resolves in-scope tactical choices itself …` |
| H36 | hermes.md:70 | `Executor authority: OMP never pushes, opens or merges PRs, approves own gates; …` |
| H37 | hermes.md:71 | `Control integrity: HERMES_CONTROL = unattended-auto | interactive (default) | human; …` |
| H38 | hermes.md:74 | `Apply §1.4 first. Verification against §1.5-fresh base; …` |
| H39 | hermes.md:75 | `Smallest check covering identified risk. -c only for needed follow-up round; …` |
| H40 | hermes.md:76 | `Failed check: fix cause, rerun affected checks. 2 unsuccessful fixes for same failure, …` |
| H41 | hermes.md:77 | `Host re-verify: accept attributed OMP/CI results after inspecting concrete command/output …` |
| H42 | hermes.md:83 | `Pre-read: read source files and tool outputs first; never assume.` |
| H43 | hermes.md:84 | `Execute: perform clear low-risk requests directly; use operation result.` |
| H44 | hermes.md:85 | `Failure handling: required check fails with known in-scope cause → fix, … One bounded wait (≤60s) …` |
| H45 | hermes.md:86 | `Boundary gate: ask only for irreversible/outbound actions, data-model/schema changes, …` |
| H46 | hermes.md:94 | `OMP_MAX_PARALLEL | 5 | Max concurrent OMP sessions` |
| H47 | hermes.md:95 | `ADVISOR_STRIKE_LIMIT | 2 | Lazy/mocked test strikes before hard block` |
| H48 | hermes.md:96 | `PROMPT_INJECTION_STRIKE_LIMIT | 3 | Consecutive injection attempts before abort` |
| H49 | hermes.md:97 | `DISPATCH_SILENCE_SECONDS | 30 | Wait for initial output or session creation` |
| H50 | hermes.md:98 | `STREAM_EVENT_TIMEOUT_MS | 120000 | Stream stall watchdog` |
| H51 | hermes.md:99 | `NVERIFY_MAX_ROUNDS | 5 | Max verify rounds per approach before stop and diagnose` |
| H52 | hermes.md:100 | `APPROACH_MAX | 3 | Distinct failed approaches per problem before BLOCKED (exhausted)` |
| H53 | hermes.md:103 | `One task state directory: ${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md, …` |
| H54 | hermes.md:104 | `No state files elsewhere (no state*.yaml, no .bak).` |
| H55 | hermes.md:107 | `Scripts → scripts/, kebab-case; ad-hoc names (tmp_*.md, new-final.*) forbidden.` |
| H56 | hermes.md:108 | `Modify documents in place; squash before human-approved push.` |
| H57 | hermes.md:109 | `Maintained documents not tracked by git keep Doc-ID, Version (SemVer), Updated-UTC …` |
| H58 | hermes.md:110 | `Re-point symlinks with ln -sfn; no backup copies of symlinks.` |
| H59 | hermes.md:115-117 | `Unapproved gate breach …` / `Repeated failure …` / `Missing critical data.` |
| H60 | hermes.md:119 | `Every blocker, one format: BLOCKED: <reason + needed auth or info>.` |
| H61 | hermes.md:122-126 | `Task not done while:`（四子項） |
| H62 | hermes.md:129 | `Mixed tasks (allowed + disallowed subtasks): never reject whole task.` |
| H63 | hermes.md:130 | `Classify subtasks on factual evidence (diffs, terms, security lines).` |
| H64 | hermes.md:131 | `Carve out only policy-disallowed work: record reason in existing task's ## Status / Not done: line, …` |
| H65 | hermes.md:132 | `No confirmation menus outside gates. Challenged refusal → inspect disputed evidence; …` |

### rules.md

| # | 位置 | 原文起首 |
| --- | --- | --- |
| R01 | rules.md:3 | `On conflict: safety and explicit human instructions first, then this document.`（含同段 scope 句） |
| R02 | rules.md:5 | `Local overlay: ~/.ai-rules.local.md (or $AI_RULES_LOCAL) exists → read as second file, …` |
| R03 | rules.md:9 | `Use task-observer for multi-step implementation, explicit observation review, …` |
| R04 | rules.md:11 | `Workspace: TASK_OBSERVER_WORKSPACE when set; else repository root …` |
| R05 | rules.md:15-22 | File／Consumer 表 + `Per-consumer restatement deliberate; within one file, each rule once.` |
| R06 | rules.md:24-29 | Term 表（investigation / round / turn / gate） |
| R07 | rules.md:31 | `Explicit instruction beats ceremony: clear direct command … = own definition, plan, authorization.` |
| R08 | rules.md:32 | `Verification trigger: extra checks only for explicit verification request, …` |
| R09 | rules.md:33 | `Problem first, investigate once, every mode (headless, unattended-auto included): …` |
| R10 | rules.md:34 | `Plan critique: complex or high-risk changes → check requirements, omissions, …` |
| R11 | rules.md:35 | `Bias to act: human owns scope and gates; …` |
| R12 | rules.md:36 | `Extend before adding: before adding rule, section, or file, search concepts and synonyms …` |
| R13 | rules.md:38-42 | `Gates (exhaustive): confirm with human only for:`（四項） |
| R14 | rules.md:44 | `Gates vs blockers vs uncertainty: missing facts or credentials block only when …` |
| R15 | rules.md:45 | `Control signal: HERMES_CONTROL = unattended-auto | interactive | human (unset = interactive).` |
| R16 | rules.md:49 | `Follow git-commit skill: commit messages, base-branch merging, push squashing, safe stashing.` |
| R17 | rules.md:50 | `Commit and push: interactive sessions commit only on human approval; …` |
| R18 | rules.md:51-56 | `Repo freshness: before analyzing, answering from, or planning against git repo code, …` |
| R19 | rules.md:57 | `Branch/worktree cleanup: after merge and each freshness sync, delete local branches …` |
| R20 | rules.md:61 | `Skill unavailable → stop, report.` |
| R21 | rules.md:62 | `Routing: Jira ticket work implemented here, plus its PR creation/review fixes → ship; …` |
| R22 | rules.md:63 | `MCP writes: only Jira and memory.` |
| R23 | rules.md:64 | `Confluence: edit existing HTML minimally; preserve comment anchors, local IDs.` |
| R24 | rules.md:68 | `Solution ladder (stop at first fitting rung): 1. config/data change, …` |
| R25 | rules.md:69 | `Intent before overturning: before removing or altering behavior, trace origin …` |
| R26 | rules.md:70 | `Contract and enum alignment: read producer serializers, annotations for external APIs; …` |
| R27 | rules.md:71 | `Raw-payload HTTP testing: changed external integration behavior → HTTP-mock tests (WireMock, MSW, MockWebServer) …` |
| R28 | rules.md:72 | `Minimal diff: no speculative features, abstract wrappers, unused logging/metrics; …` |
| R29 | rules.md:73 | `Redundancy hygiene: duplicates, obsolete versions, temporary copies in touched scope → …` |
| R30 | rules.md:74 | `Symlinks: re-point in place (ln -sfn); never .bak copies.` |
| R31 | rules.md:80 | `No noise: no debug logs, temp prints, unused imports, irrelevant formatting.` |
| R32 | rules.md:81 | `Defensive: null checks, exception handling, edge cases addressed.` |
| R33 | rules.md:82 | `Consistency: matches request and applicable contracts.` |
| R34 | rules.md:83 | `No restatement: reply repeats no prompt, doc, earlier text.` |
| R35 | rules.md:87 | `Turn outcome: requested answer or operation result; …` |
| R36 | rules.md:88 | `Chat verdicts: prose first; append ISSUES: <list> only on failure; no trailing CLEAN.` |
| R37 | rules.md:89 | `Machine records: existing STATE.md → log checks actually run under ## Verification …` |
| R38 | rules.md:90 | `Pasteable drafts: voice skill, wrapped in raw markdown blocks.` |
| R39 | rules.md:94 | `Dead-end brake: two failed attempts on same approach, or two unsuccessful fixes for same check → …` |
| R40 | rules.md:95 | `Recovery heuristics: collision thinking …, reversal …, simplification cascade …` |
| R41 | rules.md:96 | `Missing required info (repos, specs, credentials) → BLOCKED: …; never guess.` |
| R42 | rules.md:102 | `Language: converse in Traditional Chinese or English. …` |
| R43 | rules.md:103 | `State: shared state per §8; todo lists stay session-local.` |
| R44 | rules.md:104 | `Plan control: native plan and todo features.` |
| R45 | rules.md:105 | `Read-only scope: only cwd or its worktree writable, except …` |
| R46 | rules.md:106 | `OMP dispatch: preflight omp --version; …` |
| R47 | rules.md:110 | `One state directory per task across all agents: … questions, lookups, one-off operations … never create it …` |
| R48 | rules.md:114 | `With ticket: ticket key (e.g. MO-2278). Without: T-<YYYYMMDD>-<kebab-name>; …` |
| R49 | rules.md:115 | `Local-ID task needing PR → formal ticket; rename folder, keep old ID under aliases.` |
| R50 | rules.md:116 | `Lookup order: key, branch name, aliases, then cwd matches in ## Repos & worktrees.` |
| R51 | rules.md:120-122 | `STATE.md: …` / `plan-v<N>.md: …` / `log.md: …` |
| R52 | rules.md:126 | `Start: existing state → read STATE.md, reconcile only systems relevant to request.` |
| R53 | rules.md:127 | `Progress: update STATE.md and log.md when findings, decisions, or status change; …` |
| R54 | rules.md:128 | `Sessions: record OMP sessions in ## Sessions as <name> (<id>) (<cwd>); resume by ID.` |
| R55 | rules.md:129 | `Mid-task interrupt: output Done / Not done / Next before stopping.` |
| R56 | rules.md:133 | `## Scope & constraints: Hermes or human only. …` |
| R57 | rules.md:134 | `Executors modify only ## Status, ## Decisions locked, …` |
| R58 | rules.md:135 | `External systems (git, PR, Jira) override STATE.md; reconcile, log.` |
| R59 | rules.md:139 | `Completed or cancelled tasks → _done/<YYYY>/<key>/; never delete.` |
| R60 | rules.md:140 | `Never write secrets (tokens, passwords, keys) to state files.` |
| R61 | rules.md:144 | `Copy ~/.local/state/templates/STATE-template.md (or system/templates/STATE.md) verbatim, …` |
| R62 | rules.md:148 | `Batching: batch independent reads, sequence dependent operations; …` |
| R63 | rules.md:149 | `Windowed reads: locate targets via grep line numbers, read bounded sections (sed -n 'A,Bp', ≤100 lines); …` |
| R64 | rules.md:150 | `Output: truncate command output at 100 lines; listings cap at 50 results …` |
| R65 | rules.md:151 | `Lint: only when §1 triggers verification. …` |
| R66 | rules.md:152 | `Ceilings: honor explicit runtime, turn, cost limits; …` |
| R67 | rules.md:156 | `Checks: claim pass only after observing output this session. …` |
| R68 | rules.md:157 | `Operations: confirm routine operations by tool result or exit status; …` |
| R69 | rules.md:158 | `Fact vs inference: ground technical claims in supplied material, …` |
| R70 | rules.md:159 | `Memory vs source: memory (session context, STATE.md, snapshot, Hindsight, commit messages) answers …` |
| R71 | rules.md:160 | `Scope of claims: negative claim states scope searched; …` |
| R72 | rules.md:161 | `External contracts: verify live schema before modifying; default additive, non-breaking; …` |
| R73 | rules.md:162 | `Challenged claims: inspect disputed evidence, correct unsupported claims; …` |

### sticky_rules.md（rule 2、4 內含多條獨立規則，拆子項編號）

| # | 位置 | 原文起首 |
| --- | --- | --- |
| S01 | sticky_rules.md:1 | `OUTPUT: requested answer or operation result, concise; …` |
| S02 | sticky_rules.md:3 | `Think & Plan: clear questions, lookups, low-risk commands → no investigation, …` |
| S03a | sticky_rules.md:4 | `Simplicity First: solution ladder, stop at first fitting rung: …` |
| S03b | sticky_rules.md:4 | `Duplicate, redundant copy, or superseded version in touched scope → merge … never offered as follow-up.` |
| S03c | sticky_rules.md:4 | `Before overturning existing behavior, trace why it exists (git blame -w -M -L …` |
| S03d | sticky_rules.md:4 | `Two failed attempts on same path, or two unsuccessful fixes for same check → stop, backtrack …` |
| S04 | sticky_rules.md:5 | `Ask Boundaries: only four gates (…) + MCP-write restriction (Jira and memory only). …` |
| S05a | sticky_rules.md:6 | `Delegated executors never push, open PRs, merge PRs, approve PRs, comment on PRs, or edit PR titles/descriptions; …` |
| S05b | sticky_rules.md:6 | `Interactive: commit only on human instruction. Auto: checkpoint commits allowed; push only on explicit human "push" …` |
| S05c | sticky_rules.md:6 | `Repo freshness, once per repo per task before analyzing or planning against its code …` |
| S05d | sticky_rules.md:6 | `Then delete local branches and remove clean worktrees whose branch is merged …; never touch remote branches.` |
| S06 | sticky_rules.md:7 | `Verification & Evidence: extra checks need explicit request, changed executable behavior, …` |
| S07 | sticky_rules.md:8 | `LANGUAGE: User=zh-TW; Tools=EN. Very direct. No em-dashes, hedging, emotional speculation.` |
| S08 | sticky_rules.md:9 | `REPETITION TRIPWIRE: repeated output (…) = failure state. …` |
| S09 | sticky_rules.md:10 | `RESTRICTIONS: non-git files: bump Version & Updated-UTC before editing. …` |

### Memory

| # | 位置 | 原文起首 |
| --- | --- | --- |
| M01 | memory/review-rules-by-scenario.md | `Review rule and prompt files by walking concrete scenarios end-to-end across every section and file: …` |

合計 155 條（H 66、R 73、S 15、M 1）。

---

## 第二、三步：逐條判定

判定（四選一）：**留 memory**／**移到 skill**／**抽象化後保留**／**封存候選**。判定欄帶「（拆層）」的，是精華一句留常駐、程序移 skill；帶「待定」的，是判定要靠頻率證據才能決定。

### hermes.md

| # | 規則名 | 現位置 | 判定 | 唯一理由 | 證據狀態 |
| --- | --- | --- | --- | --- | --- |
| H00 | Contract goal | hermes.md:6 | 留 memory | B-留：一句話講得完的路由總則 | 證據不足（待定） |
| H01 | Local overlay | hermes.md:8 | 留 memory | A3：overlay 本身就是承接固定值的抽象化出口，拿掉會讓 A3 失去去處 | 證據不足（待定） |
| H02 | Mirror language | hermes.md:13 | 留 memory | A4：和 S07（固定 zh-TW）、R42（中或英）三種說法互相衝突，要合併成一條 | 證據不足（待定） |
| H03 | English B1 style | hermes.md:14 | 移到 skill | A3：內含固定值（<20 字、<120 字、No Singlish），屬於 `voice` 的風格範圍 | 證據不足（待定） |
| H04 | Raw elements as-is | hermes.md:15 | 待定 | A1：無起因事件，頻率不可得 | 證據不足（待定） |
| H05 | External artifacts English | hermes.md:16 | 留 memory | A4：和 R42 第二句重複，合併 | 證據不足（待定） |
| H06 | System & skills read-only | hermes.md:19 | 留 memory | A5：防止不可逆竄改第三方工具 | 證據不足（待定） |
| H07 | Config/rules only on request | hermes.md:20 | 留 memory | A5：授權邊界 | 證據不足（待定） |
| H08 | Project code only by OMP | hermes.md:21 | 留 memory | A4：和 H15 重複，合併 | 證據不足（待定） |
| H09 | Surgical changes | hermes.md:22 | 移到 skill（拆層） | B-拆層：Hermes 不寫 code（H08），細則只在 dispatch 時要帶，放進 `skills/omp` 的 dispatch prompt | 證據不足（待定） |
| H10 | Integration contracts | hermes.md:23 | 抽象化後保留 | A5：合約義務一律保留；細則已存在於 `ship`／`delegate`（WireMock），hermes 只留阻斷條件 | 證據不足（待定） |
| H11 | External writes（MCP） | hermes.md:24 | 留 memory | A5：外部寫入屬 outbound | 證據不足（待定） |
| H12 | Q&A answer directly | hermes.md:27 | 留 memory | B-留：違反代價已經發生過（E1） | 有命中紀錄（E1） |
| H13 | Config update, never OMP | hermes.md:28 | 留 memory | B-留：一句話判準，漏載就派錯執行者 | 證據不足（待定） |
| H14 | Workflow routing | hermes.md:29 | 留 memory | B-留：路由必須在 skill 觸發之前生效，skill 沒辦法替自己路由 | 證據不足（待定） |
| H15 | Code task → OMP | hermes.md:30 | 留 memory | A4：和 H08 合併 | 證據不足（待定） |
| H16 | Fix intent = code task | hermes.md:31 | 留 memory | B-留：漏載代價已發生（E2、E4） | 有命中紀錄（E2、E4） |
| H17 | Verification trigger | hermes.md:34 | 留 memory | B-留：漏載代價已發生（E1） | 有命中紀錄（E1） |
| H18 | Zero false-OK | hermes.md:35 | 留 memory | A5：虛報檢查通過，後果高 | 證據不足（待定） |
| H19 | Memory vs source | hermes.md:36 | 留 memory（拆層） | B-拆層：判準一句常駐，staleness 程序（sha、`git log --since`、深度分級）移 skill | 有命中紀錄（E8） |
| H20 | Default skeptical | hermes.md:37 | 待定 | A1：`d217a41` 新增，無事件 | 證據不足（待定） |
| H21 | Evidence escalation | hermes.md:38 | 移到 skill | B-移：三步程序 | 證據不足（待定） |
| H22 | Turn outcomes | hermes.md:39 | 留 memory | B-留：每 turn 結尾都要用，漏載已出事（E1） | 有命中紀錄（E1） |
| H23 | Repo freshness | hermes.md:42 | 留 memory（拆層） | B-拆層：「不切換、不 stash／reset 使用中或 dirty checkout」一句留；四分支程序已由 `snapshot prepare` 實作，移 skill | 證據不足（待定） |
| H24 | Branch/worktree cleanup | hermes.md:43 | 留 memory（拆層） | B-拆層：刪除條件屬不可逆（A5）要留；判定細則移 skill | 有命中紀錄（E6） |
| H25 | Freshness ≠ verification trigger | hermes.md:44 | 封存候選 | A4：H17 的 not-trigger 清單已涵蓋 | 證據不足（待定） |
| H26 | Canonical dispatch command | hermes.md:49 | 移到 skill | A4：和 `skills/omp/SKILL.md:29` 衝突（hermes 寫 `exactly` 且含 `--plan-yolo --mode=json`，skill 的 base 兩者都沒有），衝突消解後單一來源放 skill | 證據不足（待定） |
| H27 | Session continuity | hermes.md:51 | 移到 skill | A4：和 `skills/omp`「Shared task state」重複 | 證據不足（待定） |
| H28 | Preflight & watchdog | hermes.md:52 | 移到 skill（拆層） | A4：和 `skills/omp`「Liveness」及 R46 重複，常駐只留「dispatch 失敗 ≠ BLOCKED，換路繼續」 | 有命中紀錄（E2） |
| H29 | Execution mode（fg/bg） | hermes.md:53-58 | 移到 skill | A4：和 `skills/omp`「Background dispatch & completion」逐項重複 | 有命中紀錄（E2：dispatch param rejected 情境） |
| H30 | Dispatch integrity | hermes.md:59 | 移到 skill（拆層） | A4：和 `skills/omp`「Liveness」重複，常駐只留「完成 = child exit + final result」 | 證據不足（待定） |
| H31 | Findings handoff | hermes.md:60 | 留 memory | B-留：漏載代價已發生（E3） | 有命中紀錄（E3） |
| H32 | Scope vs tactics | hermes.md:63 | 留 memory | B-留：一句話權責判準 | 證據不足（待定） |
| H33 | OMP upward signals | hermes.md:64-67 | 待定 | A1：無事件；要先確認 OMP 端是否也定義了同一套協定 | 證據不足（待定） |
| H34 | OMP BLOCKED handling | hermes.md:68 | 留 memory | B-留：死路已發生（E2） | 有命中紀錄（E2） |
| H35 | Uncertainty ≠ gate | hermes.md:69 | 留 memory | B-留：漏載已發生（E3） | 有命中紀錄（E3） |
| H36 | Executor authority | hermes.md:70 | 留 memory | A5：push／merge 不可逆 | 證據不足（待定） |
| H37 | Control integrity | hermes.md:71 | 留 memory | A5：授權不可轉移 | 有命中紀錄（E11：flags ≠ control signal 曾被刪後復原） |
| H38 | Verify against fresh base | hermes.md:74 | 封存候選 | A4：和 R70 末句、S06 重複；hermes 內合併到 H39 | 證據不足（待定） |
| H39 | Smallest check, no extra CLEAN | hermes.md:75 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| H40 | Failed-check loop | hermes.md:76 | 留 memory | A4：和 R39、S03d 同一條，跨 consumer 用同一句話 | 有命中紀錄（E2） |
| H41 | Host re-verify | hermes.md:77 | 留 memory | A4：和 R67 第二句重複，用同一句話 | 證據不足（待定） |
| H42 | Pre-read | hermes.md:83 | 待定 | A1：無事件 | 證據不足（待定） |
| H43 | Execute directly | hermes.md:84 | 封存候選 | A4：和 H12、R11 重複 | 證據不足（待定） |
| H44 | Failure handling（≤60s wait） | hermes.md:85 | 抽象化後保留 | A3：60s 是固定值，移進 §4.1 常數表 | 證據不足（待定） |
| H45 | Boundary gate | hermes.md:86 | 留 memory | A5：gate 本身 | 證據不足（待定） |
| H46 | OMP_MAX_PARALLEL | hermes.md:94 | 待定 | A1：`system/ skills/ scripts/` 都沒有引用，不知道有沒有在執行 | 證據不足（待定） |
| H47 | ADVISOR_STRIKE_LIMIT | hermes.md:95 | 封存候選 | A2：`system/ skills/` 都沒有定義「strike」的程序，服務的流程已不在文本中（`grep -rniE 'strike'`） | 證據不足（待定） |
| H48 | PROMPT_INJECTION_STRIKE_LIMIT | hermes.md:96 | 留 memory | A5：安全規則一律保留；但沒有任何條文定義觸發與計數，要補錨點 | 證據不足（待定） |
| H49 | DISPATCH_SILENCE_SECONDS | hermes.md:97 | 移到 skill | A4：和 `skills/omp` 的「30s」重複，單一來源 | 證據不足（待定） |
| H50 | STREAM_EVENT_TIMEOUT_MS | hermes.md:98 | 移到 skill | A4：`skills/omp` 已用 config 鍵 + 120s 實作 | 證據不足（待定） |
| H51 | NVERIFY_MAX_ROUNDS | hermes.md:99 | 留 memory | B-留：H40 引用的停止上限，一句話 | 證據不足（待定） |
| H52 | APPROACH_MAX | hermes.md:100 | 留 memory | A4：R39、S03d 寫死「3」，要統一成同一個常數 | 證據不足（待定） |
| H53 | State dir location | hermes.md:103 | 留 memory | A4：和 R47、R61 重複，合併 | 證據不足（待定） |
| H54 | No state elsewhere／Q&A 不建 state | hermes.md:104 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| H55 | Script naming | hermes.md:107 | 待定 | A1：無事件；`tmp_*` 等是範例固定值 | 證據不足（待定） |
| H56 | Docs in place; squash before push | hermes.md:108 | 封存候選 | A4：squash 已是 `git-commit` §4 | 證據不足（待定） |
| H57 | Doc-ID／Version bump | hermes.md:109 | 抽象化後保留 | A4：和 S09 衝突（S09「non-git 先 bump」並把上限套到 git 檔；H57 只管 non-git）；`hermes.md` 本身在 git 內卻帶 `Version: 4.10.0` | 證據不足（待定） |
| H58 | Symlink ln -sfn | hermes.md:110 | 移到 skill | B-移：只在 setup 情境，`scripts/setup.sh` 已實作；和 R30 重複 | 有命中紀錄（E3：cache 讓舊措辭回流） |
| H59 | Hard blockers | hermes.md:115-117 | 留 memory | B-留：死路已發生（E2） | 有命中紀錄（E2） |
| H60 | BLOCKED format | hermes.md:119 | 留 memory | B-留：格式不一致已發生（E4） | 有命中紀錄（E4） |
| H61 | Done criteria | hermes.md:122-126 | 留 memory | B-留：漏載會提早宣告完成，代價高 | 證據不足（待定） |
| H62 | Partial refusal: never reject whole | hermes.md:129 | 留 memory（拆層） | B-拆層：判準一句常駐，H63、H64 程序移 skill | 證據不足（待定） |
| H63 | Classify on evidence | hermes.md:130 | 移到 skill | B-移：程序性步驟，只在拒絕情境 | 證據不足（待定） |
| H64 | Carve-out recording | hermes.md:131 | 移到 skill | B-移：程序性步驟 | 證據不足（待定） |
| H65 | No menus／challenged refusal | hermes.md:132 | 封存候選 | A4：前半句和 R11 重複、後半句和 R73 重複 | 證據不足（待定） |

### rules.md

| # | 規則名 | 現位置 | 判定 | 唯一理由 | 證據狀態 |
| --- | --- | --- | --- | --- | --- |
| R01 | Scope & conflict precedence | rules.md:3 | 留 memory | A5：安全優先序 | 證據不足（待定） |
| R02 | Local overlay | rules.md:5 | 留 memory | A3：固定值的去處（`~/.ai-rules.local.md` 已存放公司固定值） | 證據不足（待定） |
| R03 | task-observer activation | rules.md:9 | 留 memory | B-留：觸發條件一句話，漏載已發生（E1） | 有命中紀錄（E1） |
| R04 | task-observer workspace | rules.md:11 | 移到 skill（拆層） | B-移：約 110 字的程序加路徑；安裝版 task-observer 不可改（H06），要放進 repo 自有的位置 | 有命中紀錄（E10） |
| R05 | File／consumer table | rules.md:15-22 | 封存候選 | A4：和 `README.md:14-15` 重複；維護者規則，不是 agent 行為 | 證據不足（待定） |
| R06 | Term table | rules.md:24-29 | 留 memory | B-留：其他規則依賴的定義 | 證據不足（待定） |
| R07 | Explicit instruction beats ceremony | rules.md:31 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| R08 | Verification trigger | rules.md:32 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| R09 | Problem first, investigate once | rules.md:33 | 留 memory | B-留：漏載已發生（E3、E5） | 有命中紀錄（E3、E5） |
| R10 | Plan critique | rules.md:34 | 待定 | B：放置看頻率，無資料 | 證據不足（待定） |
| R11 | Bias to act | rules.md:35 | 留 memory | B-留：漏載已發生（E6） | 有命中紀錄（E6） |
| R12 | Extend before adding | rules.md:36 | 抽象化後保留 | A3：寫死 `system/ skills/` 路徑，只在 ai-rules 有效，但常駐於所有專案 | 證據不足（待定） |
| R13 | Gates (4) | rules.md:38-42 | 留 memory | A5：不可逆／outbound | 有命中紀錄（E7：merge gate 的 PR 例外） |
| R14 | Gates vs blockers vs uncertainty | rules.md:44 | 留 memory | B-留：漏載已發生（E3） | 有命中紀錄（E3） |
| R15 | Control signal | rules.md:45 | 留 memory | A5：授權來源 | 有命中紀錄（E11） |
| R16 | Follow git-commit／direct merge | rules.md:49 | 移到 skill（拆層） | A4：direct merge 條件已在 `git-commit:71`；常駐只留「follow git-commit」 | 有命中紀錄（E7） |
| R17 | Commit and push | rules.md:50 | 留 memory | A5：push 不可逆；細則在 `git-commit` §3 | 證據不足（待定） |
| R18 | Repo freshness | rules.md:51-56 | 留 memory（拆層） | B-拆層：同 H23 | 證據不足（待定） |
| R19 | Branch/worktree cleanup | rules.md:57 | 留 memory（拆層） | B-拆層：同 H24，條文自己寫明 `snapshot prepare` 實作 | 有命中紀錄（E6） |
| R20 | Skill unavailable／failing step | rules.md:61 | 留 memory | A4：E11 證明它是精簡時會被誤刪的防護，留著避免和 R39 的「換路」混淆 | 有命中紀錄（E11） |
| R21 | Skill routing | rules.md:62 | 留 memory | B-留：同 H14 | 證據不足（待定） |
| R22 | MCP writes only Jira/memory | rules.md:63 | 留 memory | A5：外部寫入 | 證據不足（待定） |
| R23 | Confluence minimal edit | rules.md:64 | 抽象化後保留 | A3：寫死產品名，可以泛化成「既有外部文件：最小編輯，保留錨點／ID」 | 證據不足（待定） |
| R24 | Solution ladder | rules.md:68 | 留 memory | B-留：一句話判準 | 證據不足（待定） |
| R25 | Intent before overturning | rules.md:69 | 留 memory（拆層） | B-拆層：判準留，三條 git 指令移 skill | 證據不足（待定） |
| R26 | Contract & enum alignment | rules.md:70 | 留 memory | A5：外部 API 合約 | 證據不足（待定） |
| R27 | Raw-payload HTTP testing | rules.md:71 | 抽象化後保留 | A3：寫死技術棧名（WireMock、MSW、MockWebServer），細節已在 `ship`／`delegate` | 證據不足（待定） |
| R28 | Minimal diff | rules.md:72 | 留 memory | B-留：一句話判準，每次編輯都適用 | 證據不足（待定） |
| R29 | Redundancy hygiene | rules.md:73 | 留 memory | A4：和 S03b 同一條，跨 consumer 用同一句話 | 有命中紀錄（E6：不得改成 follow-up） |
| R30 | Symlinks | rules.md:74 | 移到 skill | B-移：同 H58 | 有命中紀錄（E3） |
| R31 | No noise | rules.md:80 | 留 memory | B-留：一句話判準 | 證據不足（待定） |
| R32 | Defensive | rules.md:81 | 待定 | A1：無事件 | 證據不足（待定） |
| R33 | Consistency | rules.md:82 | 封存候選 | A4：後半句重述 R08 | 證據不足（待定） |
| R34 | No restatement | rules.md:83 | 留 memory | A4：和 S08、`voice` 重疊，合併成一條 | 證據不足（待定） |
| R35 | Turn outcome | rules.md:87 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| R36 | Chat verdicts | rules.md:88 | 留 memory | A4：和 S01 重複，用同一句話 | 證據不足（待定） |
| R37 | Machine records | rules.md:89 | 移到 skill | A4：`skills/omp`「Shared task state」已定義同格式 | 證據不足（待定） |
| R38 | Pasteable drafts → voice | rules.md:90 | 留 memory | B-留：一句話路由 | 證據不足（待定） |
| R39 | Dead-end brake | rules.md:94 | 留 memory | B-留：死路已發生（E2、E5） | 有命中紀錄（E2、E5） |
| R40 | Recovery heuristics | rules.md:95 | 移到 skill | B-移：多個範例，屬方法論 | 證據不足（待定） |
| R41 | Missing info → BLOCKED | rules.md:96 | 封存候選 | A4：和 R14、R39 末句重複 | 證據不足（待定） |
| R42 | Language（No-Hermes） | rules.md:102 | 留 memory | A4：和 H02、S07 衝突，合併 | 證據不足（待定） |
| R43 | Todo session-local | rules.md:103 | 封存候選 | A4：前半句重述 §8 | 證據不足（待定） |
| R44 | Plan control native | rules.md:104 | 待定 | A1：無事件 | 證據不足（待定） |
| R45 | Read-only scope | rules.md:105 | 留 memory | A5：寫入範圍邊界 | 證據不足（待定） |
| R46 | OMP dispatch（No-Hermes） | rules.md:106 | 移到 skill | A4：和 `skills/omp`「Liveness」及 H28 重複；且 skill 的「Still silent → BLOCKED」和本條「abort only when §6 leaves no path」衝突 | 有命中紀錄（E2） |
| R47 | State dir usage | rules.md:110 | 留 memory | B-留：「Q&A 不建 state」漏載已發生（E1） | 有命中紀錄（E1） |
| R48 | State keys | rules.md:114 | 移到 skill | A3：例子 `MO-2278` 是固定值；屬程序 | 證據不足（待定） |
| R49 | Local-ID → ticket | rules.md:115 | 移到 skill | B-移：偶發程序 | 證據不足（待定） |
| R50 | Lookup order | rules.md:116 | 移到 skill | A4：`skills/omp:36` 已有同一順序 | 證據不足（待定） |
| R51 | State files | rules.md:120-122 | 移到 skill | B-移：程序／格式，可併入 template | 證據不足（待定） |
| R52 | Start reconcile | rules.md:126 | 移到 skill | B-移：程序 | 證據不足（待定） |
| R53 | Progress → section mapping | rules.md:127 | 移到 skill | B-移：程序，併入 template | 證據不足（待定） |
| R54 | Sessions record | rules.md:128 | 移到 skill | A4：和 `skills/omp`、H27 重複 | 證據不足（待定） |
| R55 | Mid-task interrupt | rules.md:129 | 留 memory | B-留：一句話判準 | 證據不足（待定） |
| R56 | Section owners | rules.md:133 | 移到 skill | B-移：只在寫 STATE.md 時用，併入 template | 證據不足（待定） |
| R57 | Executor-writable sections | rules.md:134 | 移到 skill | B-移：同 R56 | 證據不足（待定） |
| R58 | External systems override STATE | rules.md:135 | 封存候選 | A4：R70 已涵蓋（memory = hypothesis） | 證據不足（待定） |
| R59 | Closeout, never delete | rules.md:139 | 留 memory | A5：刪除不可逆 | 證據不足（待定） |
| R60 | No secrets in state | rules.md:140 | 留 memory | A5：安全 | 證據不足（待定） |
| R61 | STATE template | rules.md:144 | 移到 skill | A4：和 H53 重複，路徑屬程序 | 有命中紀錄（E10：template 路徑依賴） |
| R62 | Batching | rules.md:148 | 待定 | A4：和 harness 平台指令重複，但非 Claude consumer（Zed、opencode）有沒有這條不知道 | 證據不足（待定） |
| R63 | Windowed reads ≤100 | rules.md:149 | 抽象化後保留 | A3：固定值 100、工具 `sed -n` | 證據不足（待定） |
| R64 | Output caps 100/50 | rules.md:150 | 抽象化後保留 | A3：固定值 100／50 | 證據不足（待定） |
| R65 | Lint only on trigger | rules.md:151 | 封存候選 | A4：R08 已涵蓋 | 證據不足（待定） |
| R66 | Ceilings | rules.md:152 | 待定 | A1：無事件 | 證據不足（待定） |
| R67 | Checks（claim pass） | rules.md:156 | 留 memory | A5：虛報通過 | 證據不足（待定） |
| R68 | Operations（no duplicate check） | rules.md:157 | 留 memory | B-留：漏載已發生（E1） | 有命中紀錄（E1） |
| R69 | Fact vs inference | rules.md:158 | 留 memory | B-留：漏載已發生（E9） | 有命中紀錄（E9） |
| R70 | Memory vs source | rules.md:159 | 留 memory（拆層） | B-拆層：同 H19 | 有命中紀錄（E8） |
| R71 | Scope of claims | rules.md:160 | 待定 | A1：`d217a41` 新增，無事件 | 證據不足（待定） |
| R72 | External contracts | rules.md:161 | 留 memory | A5：breaking change 要 owner sign-off | 有命中紀錄（E11） |
| R73 | Challenged claims | rules.md:162 | 留 memory | A4：吸收 H21 末句、H65 後半，成為唯一一條 | 證據不足（待定） |

### sticky_rules.md

| # | 規則名 | 現位置 | 判定 | 唯一理由 | 證據狀態 |
| --- | --- | --- | --- | --- | --- |
| S01 | OUTPUT | sticky:1 | 留 memory | A4：和 R35／R36 同義，跨 consumer 用同一句話 | 有命中紀錄（E1） |
| S02 | Think & Plan | sticky:3 | 留 memory | B-留：漏載已發生（E3、E5） | 有命中紀錄（E3、E5） |
| S03a | Solution ladder | sticky:4 | 留 memory | B-留：一句話判準 | 證據不足（待定） |
| S03b | Redundancy, never follow-up | sticky:4 | 留 memory | B-留：漏載已發生（E6） | 有命中紀錄（E6） |
| S03c | Trace intent | sticky:4 | 留 memory（拆層） | B-拆層：同 R25 | 證據不足（待定） |
| S03d | Dead-end brake | sticky:4 | 留 memory | B-留：死路已發生（E2） | 有命中紀錄（E2） |
| S04 | Ask boundaries | sticky:5 | 留 memory | A5：gate | 有命中紀錄（E3：uncertainty ≠ gate） |
| S05a | Executor never push/PR | sticky:6 | 留 memory | A5：不可逆；範圍比 H36 廣（含 comment／edit PR），要對齊 | 證據不足（待定） |
| S05b | Commit/push mode | sticky:6 | 留 memory | A5：push 不可逆 | 證據不足（待定） |
| S05c | Repo freshness | sticky:6 | 留 memory（拆層） | B-拆層：約 120 字程序放在 OMP hard rules | 證據不足（待定） |
| S05d | Cleanup | sticky:6 | 留 memory（拆層） | B-拆層：同 R19 | 有命中紀錄（E6） |
| S06 | Verification & Evidence | sticky:7 | 留 memory（拆層） | B-移：超過 200 字；判準留，memory-vs-source 程序移 skill | 有命中紀錄（E1、E8） |
| S07 | LANGUAGE | sticky:8 | 留 memory | A4：「User=zh-TW」和 H02 的 mirror 衝突；em-dash、hedging 和 `voice:145` 重複 | 證據不足（待定） |
| S08 | REPETITION TRIPWIRE | sticky:9 | 待定 | A1：`9795a0c`（2026-10-13）沒有 body，起因不明 | 證據不足（待定） |
| S09 | Version bump | sticky:10 | 抽象化後保留 | A4：和 H57 衝突，合併成一條 | 證據不足（待定） |

### Memory

| # | 規則名 | 現位置 | 判定 | 唯一理由 | 證據狀態 |
| --- | --- | --- | --- | --- | --- |
| M01 | Review rules by scenario | memory/review-rules-by-scenario.md | 留 memory | B-留：一句話判準；project memory 只在 ai-rules 載入，載入成本已限定 | 有命中紀錄（2026-10-30） |

### 統計

| 判定 | 條數 |
| --- | --- |
| 留 memory（含拆層 12 條） | 92 |
| 移到 skill（含拆層 5 條） | 29 |
| 抽象化後保留 | 9 |
| 封存候選 | 12 |
| 待定 | 13 |

---

## 衝突摘要（A4，重寫前必須先決定）

1. **OMP dispatch 命令**：`hermes.md:49` 寫「use exactly」，旗標含 `--plan-yolo --mode=json`；`skills/omp/SKILL.md:29` 的 base 兩者都沒有。
2. **dispatch 失敗收斂方式**：`skills/omp` 的 Silence rule 是「Retry once … Still silent → `BLOCKED: omp not dispatched`」；`rules.md:106`、`hermes.md:52` 則是「BLOCKED 只在所有路徑都需要外部輸入時」。這正是 M01（E2）記錄的死路模式。
3. **語言**：H02 是 mirror、預設繁中；S07 固定 `User=zh-TW`；R42 是中或英。
4. **Version bump**：H57 只管 non-git 檔，S09 把每日上限套到所有檔；`hermes.md` 本身在 git 內卻有 `Version`。
5. **Executor 權限範圍**：S05a 禁止 comment／edit PR；H36 只列 push／open／merge／approve。

### 消解紀錄（2026-11-02，未 commit）

| # | 採用的版本 | 依據 | 改動 |
| --- | --- | --- | --- |
| 1 | hermes 的命令作為 Hermes 的 turn 0；omp skill 的變體留給非 Hermes caller | skill 已經分出 turn 0、tiny one-shot、host-as-parent 三種；Hermes 是 host-as-parent，所以加 `--mode=json` | `hermes.md` §2.1 限定為「Turn 0」並補上 `-r` 接續；`skills/omp` 的 tiny one-shot 註明 Hermes 不適用 |
| 2 | rules §6 的「換路後才 BLOCKED」 | `a8cd6b7` 已加入「retry once by another route」，但收尾還是直接 BLOCKED，和 E2 是同一種死路 | `skills/omp` 的 Silence rule 改成「依 stderr 修 in-scope 原因再重試；只有剩下的修法需要外部輸入時才 BLOCKED」 |
| 3 | mirror 使用者語言，預設繁中 | hermes 從 `d217a41` 之前就是 mirror；sticky 的 `User=zh-TW`（`bd6c84f`）是它的特例 | `sticky_rules.md` 的 LANGUAGE 和 `rules.md` §7.1 對齊 |
| 4 | 兩邊取聯集：non-git 檔編輯前 bump；任何 in-file Version 每 session／日最多一次；read-only 不 bump | 兩條原本各缺一半 | `hermes.md` §4.3 和 `sticky_rules.md` RESTRICTIONS 改成同義 |
| 5 | sticky 的較廣清單 | `a8cd6b7`（2026-10-30）明確擴大；`grep` 確認沒有任何 skill 讓 executor 處理 PR comment | `hermes.md` §2.2 Executor authority 補上 approve／comment／edit PR |

`hermes.md` 依 repo 慣例 bump 到 4.11.0。

## 待確認事項（未知會影響判定）

- OMP 和 Hermes 除了 RULES.md／SOUL.md 之外，有沒有也載入 `~/AGENTS.md` 或 `rules.md`？若有，跨檔重複（R05 的「deliberate restatement」）可以大量刪減；若無，只能各檔保留一句。
- H46、H47、H48 這三個常數在 Hermes 執行端（repo 之外）有沒有被讀取？本報告只搜尋了 `system/ skills/ scripts/`。

---

## 操作清單（只搬移與歸檔，不改寫規則內容）

### 1. 先消解衝突（重寫前提）：已完成，見上方消解紀錄

1. 決定 OMP canonical command 單一來源放在 `skills/omp`，`hermes.md:49` 改成引用（衝突 1）。
2. 統一 dispatch 失敗收斂：`skills/omp` 的 Silence rule 對齊 `rules.md` §6 的「換路後才 BLOCKED」（衝突 2）。
3. 選定一種語言規則，H02、S07、R42 三處統一（衝突 3）。
4. H57 和 S09 合併成一條 Version 規則（衝突 4）。
5. H36 和 S05a 的 executor 禁止清單對齊（衝突 5）。

### 2. 封存候選（移出主清單觀察，不刪）

- 建 `system/archive/2026-11-02-rules-archive.md`，逐字搬入以下條目，並註明來源行號和理由：
  - hermes：H25、H38、H43、H47、H56、H65
  - rules：R05、R33、R41、R43、R58、R65
- 觀察期滿（建議兩到四週）沒有需要回收的，才正式移除。
- R05 搬出前確認 `README.md` 已涵蓋 file／consumer 表和 restatement 原則。

### 3. 移到既有 skill

| 目的地 | 搬入 |
| --- | --- |
| `skills/omp/SKILL.md` | H26、H27、H29、H49、H50、R46、R54；H09 的 dispatch prompt 細則；H28、H30 的程序部分 |
| `skills/git-commit/SKILL.md` | R16 的 direct-merge 條件（已存在於 :71，刪除常駐重複即可）；H56 squash（已在 §4） |
| `skills/snapshot`（`prepare` 已實作） | H23、R18、S05c 的 freshness 四分支程序；H24、R19、S05d 的 cleanup 判定細則 |
| `skills/voice/SKILL.md` | H03（B1 數字規格）、S07 的 em-dash／hedging（已在 :145） |
| `skills/ship`、`skills/delegate` | R27 的技術棧細節（WireMock 已存在） |
| `system/templates/STATE.md` | R48、R49、R50、R51、R52、R53、R56、R57、R61 |
| `scripts/setup.sh` 和 README | H58、R30 |

### 4. 新建 skill（repo 自有，因為安裝版 skill 依 H06 不可改）

- `evidence-discipline`（暫名）：H19、R70、S06 的 staleness 程序；H21 evidence escalation；R40 recovery heuristics；R25、S03c 的 git 溯源指令。
- `partial-refusal`（暫名）：H63、H64。
- R04 task-observer workspace 細則：放在 repo 自有的 reference 檔，不改安裝版 skill。

### 5. 抽象化後保留（固定值移到 overlay 或常數表）

- 固定值移到 `~/.ai-rules.local.md` 或 hermes §4.1 常數表：
  - H44 的 60s
  - R63 的 100 行
  - R64 的 100／50
  - R27 的技術棧名
  - R23 的 Confluence 泛化成「既有外部文件」
  - R12 的 `system/ skills/` 路徑改為「目標 repo 的規則／skill 目錄」
  - H10 只留阻斷條件
- H48 保留，並補一條定義「injection attempt」與計數方式的錨點規則（A5）。

### 6. 跨 consumer 合併（每個 consumer 留一句，措辭統一）

- H40 = R39 = S03d
- H52 的常數取代 R39、S03d 寫死的「3」
- R29 = S03b
- R36 = S01
- R34 和 S08 合併
- H41 = R67
- H53 = R47 = R61
- R73 吸收 H21 末句、H65 後半

### 7. 待定（補證據後再判）

H04、H20、H33、H42、H46、H55、R10、R32、R44、R62、R66、R71、S08。

- 從現在起在 task-observer 記錄每次命中或糾正。
- 兩週後重跑 A1。

### 8. Memory

M01 保留，不需要更新。
