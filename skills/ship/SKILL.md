---
name: ship
description: 查看、設計、執行 Jira ticket，建立 PR 並處理後續 Review 評論、CI 與 Dev 部署，直到 PR Approved；沒有 ticket 的 PR（如 dependabot、infra）也走同一流程
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, open-pr, git-commit
---

查看並理解 Jira ticket (經 MCP)，結合 Codebase/PRD/PR 評論前後文完成任務設計、執行、PR 建立與後續 Review 修正。

沒有 Jira ticket 的 PR（dependabot、infra 等）直接從第 4 步開始，略過所有 Jira 相關步驟。

## 優先順序與原則
1. 權重順序：他人 Review 評論 > Jira Ticket > PRD（PRD 視為可能過期，矛盾時以 Jira + 評論 + 現有實作為準）。
2. 跨服務 Contract 與 Enum Mapping 規範：
   - Wire DTO ≠ Domain Model：嚴禁對傳輸層 (Wire Payload) 原始字串直接進行列舉/Enum 強制轉型。必須經由專屬轉換層 (Mapper) 明確隔離外部傳輸協定與內部 Domain 邏輯。
   - 鎖定 Serialization 細節：查驗 Producer Code 時，必須確認 JSON 序列化定義（如 Annotation、Field Name、kebab-case / snake_case 轉換或 Enum Custom Text），嚴禁僅憑 Producer 內部的常數名稱猜測傳輸字串。
   - 多型 Payload 獨立處理：針對包含 `type`/`kind` 等區分多型的 Payload，必須建立 Truth Table 獨立處理，嚴禁以單一結構硬套。
   - 防禦性解析與 Fallback：Mapping 邏輯必須包含未知列舉值 (Unknown Enum) 的退回機制，避免 Producer 未來擴充欄位時導致反序列化崩潰。
3. 拒絕純 Unit Interface Stubs (Raw Payload HTTP 測試原則)：
   - 涉及外部 API 通訊時，禁止僅以 Client/Interface 方法 Mock 作為測試驗證（這會隱藏 JSON 反序列化與 Mapping 錯誤）。
   - 必須使用 HTTP 層級 Mock 工具（如 WireMock, MSW, MockWebServer 等），填入從 Producer/Postman/Log 取得的真實 Raw JSON Response Body 進行反序列化與 Mapping 整合測試。
4. 最小變更與架構收斂：優先重用既有邏輯。每次 Pull/Merge Main 後，必須重新比對 Codebase，確認 Main 最新變更是否有新增可重用的共用工具，或規格調整需隨之同步。
5. 範圍約束：不做 Out of scope 變更，也不做非必要 refactoring。
6. 狀態延續與重複呼叫：此技能可能被多次呼叫。重複執行時不重複已完成的步驟（如建立分支、重複建立 PR），但每次執行皆需重新載入 Jira ticket 與 PR 評論確認最新狀態。
7. Session 續用：任務中途的追問（含 PR commenter 以外的他人插問）直接以現有 session 回答，不重啟調查；用 runtime 的 session 續用（OMP `-c` / `-r`）延續上下文，唯有超出 session 理解範圍才重新調查。

## 執行流程

### 1. 準備與分支
- 讀取或建立共用狀態檔 `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md`（key = ticket ID；規則見 rules.md §8）；已存在的 `Scope & constraints` 不改寫。建立時填 `repos:`；任務無 ticket 時，分支以 T- key 命名。
- 重新載入或讀取 Jira Ticket 並補全缺漏規格。
- 找出相關 repo：使用者有提供專案地圖時（例如上層資料夾的 `CLAUDE.md` / `AGENTS.md`，列出 repo、用途與別名）先查地圖，地圖找不到才搜尋；確定 repo 後只在這些 repo 與其 worktree 內搜尋，不要整個上層資料夾掃描。
- 團隊慣例盤點：目標 repo 為新 service，或某類寫法（持久層、測試、Migration、Commit 格式）前例少於 3 個時，先到同團隊已知高度活躍開發中的 repo 整理該類慣例，於 plan 列出「要遵循的慣例」並附出處檔案；嚴禁僅照抄目標 repo 內最近的單一前例，偏離慣例必須列為待人類決定的事項。
- 使用內建 `plan` 進行任務拆解，並以 `todo` 追蹤執行狀態。
- 若尚未建立分支，執行 `git pull origin main` 後建立 worktree 分支 `<ticket-id>`（即 Jira ticket ID）；若已在對應分支則直接延續。

### 2. 實作與驗證
- Contract/Enum 對齊與 Raw Payload 測試先行：
  1. 查驗 Producer Repo 的 Serialization 與 Enum 定義，產出對照表 (Truth Table)。
  2. 使用 Producer 真實 Payload Shape 建立 HTTP 層級 Raw Payload 測試，先寫 Failing Test 驗證反序列化與 Mapping 邏輯。
  3. 完成實作並讓測試 Pass。
- CLI 完整驗證：實作與修復後，必須使用 CLI 跑過所有 lint 與測試，確保本地 pass，保障 Push 後 CI/CD pipeline 必然不會失敗。
- 自我 Code Review (審視 `git diff`)：
  1. 無雜質：無臨時印表/Debug Code/無關的 Formatting/未使用的 import。
  2. 防禦性：Null/Empty 檢查、例外處理與邊界條件皆具備。
  3. 一致性：對照原本產出的 Truth Table 與 Jira 規格，確認邏輯 100% 契合。
  (未全部通過前禁止進入下一步)
- 階段結束時更新 STATE.md：`## Status` 與 `## Verification`（一行一筆），並在 `log.md` 附加一行。

### 3. 人類確認、Push 與 PR 建立
- 將修改成果與狀態（採用 3 行格式：Done / Not done / Next）交給人類做最終確認。必須等到人類明確指示「push」後才可進行 Commit 與 Push。
- 獲許 Push 後依 `git-commit`：merge main 並解衝突（以本分支為主）、Merge 後二度審視 (Main Code Re-evaluation，有調整需補跑 CLI 驗證)、將未 push 的修改整理成單一 commit。
- 建立 PR：使用 `open-pr` 建立 PR，Title/Reviewers/Linked issues 需合規與用模版；Description 僅留極簡單段英文 Summary，無 AI 標記。
- PR 建立後把網址寫入 STATE.md 的 `## Sessions`，並更新 `## Status`。

### 4. PR Review、CI 與 Dev 部署循環
循環：狀態 → 收集未回覆 thread → 判斷 → 本地修正 → lint/測試 → 草擬回覆 → 人類確認 → commit/push → 等 CI → 逐 thread 回覆 → 部署 Dev → 重來。
停止條件（兩者皆成立）：沒有未回覆的 thread（含已回覆 thread 上 reviewer 的新回覆），且 `reviewDecision` 為 `APPROVED`。遇到設計分歧，或約 3 次修正 → CI 仍失敗時，暫停並詢問人類。
- 每一輪更新 STATE.md：header `status:` 設 pr-loop；`## Status` 寫 PR 網址與未回覆 thread 數；遇到暫停點（等待人類核准等）把 Done / Not done / Next 寫進 `## Status`。

- 狀態：
  - 有 ticket 時重新載入 Jira ticket 檢查最新更新。
  - `gh pr view --json number,title,state,url,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews` 與 `gh pr checks`；區分人工核准類 job（change-record / sign-off，未核准前一定是紅的）與真正的失敗，前者不算 CI 失敗。失敗 log 用 `gh run view <run-id> --log-failed`。
- 收集未回覆 thread：
  - 用 `gh api` 讀 inline 與 conversation 評論，並以 GraphQL 取得 thread 狀態：
    ```bash
    gh api graphql -f query='
      query($owner:String!,$repo:String!,$number:Int!) {
        repository(owner:$owner,name:$repo) {
          pullRequest(number:$number) {
            reviewThreads(first:100) {
              nodes { id isResolved isOutdated comments(first:50) { nodes { databaseId author { login } body createdAt } } }
            }
          }
        }
      }' -F owner=... -F repo=... -F number=...
    ```
  - 需處理：未 resolved，且（最後一則不是自己，或自己從未回覆）。已回覆且 reviewer 沒有新回覆的 thread 跳過。
  - 檢查既有 `todo` 與 `plan`，跳過已完成項目；建立編號清單與真相對照表 (Truth Table)：file/line、作者、要求、相關程式碼。
  - 交叉比對 Jira 與 PRD，若 PRD 矛盾於 `todo` 標記 `PRD-stale`；超出 Jira 範圍者標記 `deferred` 不於此 PR 實作。
- 判斷：在本 agent 內逐則分類為 accept / partial / reject / ask（產品或設計問題列入詢問，不要猜）。diff 超過 400 行，或涉及安全、付款、解析外部輸入時，才額外跑 multi-lens review（Claude built-in `/code-review`，或唯讀 omp：`omp -p --tools=read,grep,glob --advisor --max-time=15m "<review prompt>"`，依 `omp` skill 做 preflight 與 liveness 檢查）輔助判斷；各 lens **並行**執行（只取 findings，不從它發佈任何東西）。禁用 omp 預設 task 模式（那是 implement + multi-round verify，會寫碼又極慢）。
  - 優先修程式而不是爭論；合理建議就改，錯誤或有害的建議才拒絕，不可默默忽略。
- 本地修正：
  - 使用 `edit` 修正，優先重用既有邏輯；有衝突就依 `git-commit` merge main 並二度審視。
  - 補齊對應的單元測試與 Raw Payload HTTP 測試（關鍵路徑必須包含真實 Payload Shape 測試）。真正的 CI 失敗（lint / types / tests / build）也在此一併修正；不可為了變綠而削弱測試。
  - 使用 CLI 跑過所有 lint 與測試，確保本地 pass；檢視 `git diff` 做自我 Code Review（無雜質、防禦性、Truth Table 一致性）。
- 草擬回覆並等待人類（硬閘門）：
  1. 用 `gh` 重新掃描 unresolved threads，確認預期修復項目皆已處理且無遺漏。
  2. 列出編號表：`# | Thread | Decision | Local change | Draft reply`，並附上本輪 CI/衝突修正摘要。
  3. 以三行狀態回報：Done / Not done / Next。
  4. 在人類核准回覆並指示「push」之前，不 commit、不 push、不發任何留言。
- 核准後：
  1. 依 `git-commit` commit（只 stage 本輪修正）並 push。
  2. 只等真正的 CI check（輪詢 `statusCheckRollup` 或指定 check 名稱），不要直接用 `gh pr checks --watch`，它會卡在人工核准類 job 上。真正的 check 失敗就回到本地修正並重新詢問。
  3. CI 綠燈後，用 `gh` 逐 thread 回覆（inline reply / GraphQL `addPullRequestReviewThreadReply`）。
  4. 透過 repo 既有的 Dev 部署 workflow/script 自動部署到 Dev（不另外詢問；不清楚是哪個 workflow 才問），回報結果，然後回到循環開頭。
- 回覆規範：
  - 僅回覆已百分百驗證的事實，尚待釐清者直說「去查驗 Producer Repo」，嚴禁過度承諾或搶先宣告完成。
  - 每個 thread 只回一次並涵蓋所有要點；已回覆過的 thread 不新增留言，僅編輯既有內容，除非 reviewer 有新回覆。
  - 接受 / 已修正：只給結論，通常 1~5 個英文單字（上限 12），如 `Fixed.` / `Done.` / `Out of scope.`；不還原機制、不列檔案/行號/數值，不重述 diff。
  - 反駁 / 不採納：依 `voice` 的 PR review replies 規則：一句話給結論，判斷用 `IMO` / `I think` 標示，必要時補一句理由；只有真正開放的問題才以 `WDYT?` 結尾。
  - 嚴禁中文、道歉贅詞、commit/SHA、重複資訊；使用技能 `voice` 產生英文回覆（`voice` 自帶 humanizer 步驟），與本規範衝突時以本規範為準。
  - 只用 `gh` 發佈，不用 MCP 或網頁介面。不要擅自將 thread 標記成 resolved。
- 不可 force-push 共用的 PR 分支，不擴大 PR 範圍。若沒有需要修改的地方也沒有未回覆 thread，回報狀態並持續觀察直到 Approved（或詢問是否要提醒 reviewer）。
