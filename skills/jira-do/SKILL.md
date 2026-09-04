---
name: jira-do
description: 查看、設計、執行 Jira ticket，建立 PR 並處理後續 Review 評論
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, jira-actions, create-pr
---

查看並理解 Jira ticket (經 `jira-actions` 或 MCP)，結合 Codebase/PRD/PR 評論前後文完成任務設計、執行、PR 建立與後續 Review 修正。

## 優先順序與原則
1. 權重順序：他人 Review 評論 >= Jira Ticket > PRD（PRD 視為可能過期，矛盾時以 Jira + 評論 + 現有實作爲準）。
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

## 執行流程

### 1. 準備與分支
- 重新載入或讀取 Jira Ticket 並補全缺漏規格。
- 使用內建 `plan` 進行任務拆解，並以 `todo` 追蹤執行狀態。
- 若尚未建立分支，執行 `git pull origin main` 後建立 worktree 分支 `on-<ticket-number>`；若已在對應分支則直接延續。

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

### 3. 人類確認、Push 與 PR 建立
- 將修改成果與狀態（採用 3 行格式：Done / Not done / Next）交給人類做最終確認。必須等到人類明確指示「push」後才可進行 Commit 與 Push。
- 獲許 Push 後：
  - 執行 `git pull origin main` 並 merge main，若有衝突先解決（衝突解決一律以本分支修改為主）。
  - Merge 後二度審視 (Main Code Re-evaluation)：檢視 main 新合併的變更，主動確認是否有多出重疊的新功能/共用 Module 可替代當前實作，或規格變動需微調程式碼。若有調整，需補跑 CLI 驗證 Pass。
  - 將這批所有修改整理並合併為單一 commit。
  - Commit 規範：遵循 Conventional Commits、長度 <20 字、嚴禁包含 `Co-Authored-By`。
- 建立 PR：使用 `create-pr` 建立 PR，Title/Reviewers/Linked issues 需合規與用模版；Description 僅留極簡單段英文 Summary，無 AI 標記。

### 4. PR Review 評論處理
- 全域收集與真相對照：
  - 重新載入 Jira ticket 檢查最新更新。
  - 讀取 `pr://<number>` 並透過 `gh` 工具自動掃描所有 unresolved review threads，建立全域修復清單與真相對照表 (Truth Table)。
  - 檢查既有 `todo` 與 `plan`，跳過已完成項目，僅針對新增或未處理之評論進行規劃。
  - 交叉比對 Jira 與 PRD，若 PRD 矛盾於 `todo` 標記 `PRD-stale`；超出 Jira 範圍者標記 `deferred` 不於此 PR 實作。
  - 使用內建 `plan` 拆解評論修復任務，並以 `todo` 追蹤與管理執行狀態。
- 執行修改與驗證：
  - 使用 `edit` 進行修正，優先重用既有邏輯。
  - 補齊修復範圍對應的單元測試與 Raw Payload HTTP 測試（關鍵路徑必須包含真實 Payload Shape 測試）。
  - 使用 CLI 跑過所有 lint 與測試，確保本地 pass。
  - 檢視 `git diff` 執行自我 Code Review (驗證無雜質、防禦性與 Truth Table 一致性)。
- Push 與回覆前硬閘門 (Hard Gate)：
  1. 使用 `gh` 工具重新掃描 PR unresolved threads，確認預期修復項目皆已處理且無遺漏。
  2. 確保關鍵路徑皆有 Raw Response Payload 測試保護。
  3. 回報人類時，統一使用三行狀態模板：
     - Done：已落地的 commit/SHA 或修復項目
     - Not done：尚未完成的項目
     - Next：下一步與預估
  4. 獲得人類指示「push」後，pull/merge main 並解衝突（以本分支為主）。
  5. Merge 後二度審視 (Main Code Re-evaluation)：檢查 main 新新增的代碼是否有可重用的 component/helper 或規格異動，若有則立即修正並重新完成 CLI 驗證，最後將修復內容整理為單一 commit 後 push。
- 回覆規範：
  - 僅回覆已百分百驗證的事實，尚待釐清者直說「去查驗 Producer Repo」，嚴禁過度承諾或搶先宣告完成。
  - 先檢查既有留言，已回覆過的 thread 嚴禁新增留言，僅編輯既有內容。
  - 每 thread 限回一次，內容限制 1~15 個英文單字（如 `Fixed as suggested.` / `No, out of scope.`）。
  - 嚴禁中文、長篇解釋、道歉贅詞、commit/SHA。
  - 請用人類語氣，使用技能 `eng` 產生簡短英文回覆。
  - 不要擅自將 thread 標記成 resolved。
