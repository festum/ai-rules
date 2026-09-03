---
name: jira-do
description: 查看、設計、執行 Jira ticket，建立 PR 並處理後續 Review 評論
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, jira-actions, create-pr
---

查看並理解 Jira ticket (經 `jira-actions` 或 MCP)，結合 Codebase/PRD/PR 評論前後文完成任務設計、執行、PR 建立與後續 Review 修正。

## 優先順序與原則
1. 他人 Review 評論 >= Jira Ticket > PRD（PRD 視為可能過期，矛盾時以 Jira + 評論 + 現有實作爲準）。
2. 最小變更與架構收斂：優先重用既有邏輯（如共用轉換層、shared function）。若發現同一邏輯需要在第二處重複編寫，必須立即停下來向上收斂，禁止複製貼上。
3. 不做 Out of scope 變更，也不做非必要 refactoring。
4. 狀態延續與重複呼叫：此技能可能被多次呼叫（特別是在階段 4）。重複執行時不重複已完成的步驟（如建立分支、重複建立 PR），但每次執行皆需重新載入 Jira ticket 確認是否有最新更新。

## 執行流程

### 1. 準備與分支
- 重新載入或讀取 Jira Ticket 並補全缺漏規格。
- 使用內建 `plan` 進行任務拆解，並以 `todo` 追蹤執行狀態。
- 若尚未建立分支，執行 `git pull origin main` 後建立 worktree 分支 `on-<ticket-number>`；若已在對應分支則直接延續。

### 2. 實作與驗證
- 實作前先審視既有共用邏輯，使用 `todo` 規劃任務。
- CLI 完整驗證：實作與修復後，必須使用 CLI 跑過所有 lint 與測試，確保本地 pass，保障 Push 後 CI/CD pipeline 必然不會失敗。
- 嚴格自檢：反覆進行自我 Code Review，主動找出潛在漏洞與疏漏，切勿擅自認為程式碼已經正確。

### 3. 人類確認、Push 與 PR 建立
- 將修改成果交給人類做最終確認。必須等到人類明確指示「push」後才可進行 Commit 與 Push。
- 獲許 Push 後：
  - 執行 `git pull origin main` 並 merge main，若有衝突先解決（衝突解決一律以本分支修改為主）。
  - 將這批所有修改整理並合併為單一 commit。
  - Commit 規範：遵循 Conventional Commits、長度 <20 字、嚴禁包含 `Co-Authored-By`。
- 使用 `create-pr` 建立 PR：Title/Reviewers/Linked issues 需合規與用模版；Description 僅留極簡單段英文 Summary，無 AI 標記。

### 4. PR Review 評論處理
- 收集與規劃：
  - 重新載入 Jira ticket 檢查是否有最新更新。
  - 讀取 `pr://<number>` 收集所有 review threads 與 comments。
  - 檢查既有 `todo` 與 `plan`，跳過已完成項目，僅針對新增或未處理之評論與更新進行規劃。
  - 交叉比對 Jira 與 PRD，若 PRD 矛盾於 `todo` 標記 `PRD-stale`；超出 Jira 範圍者標記 `deferred` 不於此 PR 實作。
  - 使用內建 `plan` 拆解評論修復任務，並以 `todo` 追蹤與管理執行狀態。
- 執行修改與 Push：
  - 使用 `edit` 進行修正，優先重用既有邏輯，不做不必要的抽象。
  - 補齊修復範圍對應的單元或整合測試。
  - 使用 CLI 跑過所有 lint 與測試，確保本地 pass，保障 Push 後 CI/CD 不會失敗。
  - 反覆做自我 Code Review，確認無漏洞後，交給人類做最終確認。
  - 人類指示「push」後，pull/merge main 並解衝突（以本分支為主），將該批修復內容整理為單一 commit 後 push。
- 回覆規範：
  - 先檢查既有留言，已回覆過的 thread 嚴禁新增留言，僅編輯既有內容。
  - 每 thread 限回一次，內容限制 1~15 個英文單字（如 `Fixed as suggested.` / `No, out of scope.`）。
  - 嚴禁中文、長篇解釋與道歉贅詞。
  - 請用人類語氣，使用技能 `eng` 產生簡短英文回覆。
  - 不要擅自將 thread 標記成 resolved。
