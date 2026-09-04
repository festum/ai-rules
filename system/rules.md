# Rules

這是 OMP 執行層代碼與工程規範。Hermes 系統層已覆蓋之項目（如語言設定、STATE.md 契約、GSD 階段指揮與唯讀系統保護）此處不予重複。若OMP由非Hermes的一般用戶直接呼叫，請一律使用最簡短的英文回答，禁用其他語言。

## 1. 執行權限與必問邊界

- 預設 YOLO：範疇內實作、區域除錯、重構收斂與合理預設——直接執行，無需開選單詢問。
- 必問硬閘門 (Hard Ask Boundary)：僅在以下情況暫停並向人類確認：
  1. 不可逆或外發動作：push、建立／合併 PR、刪除他人工作、對外發佈。
  2. 新建或修改 Data Model / DB Schema 實體。
  3. 高成本且互斥的架構選型分叉。
  4. 非 MCP 之外部服務寫入操作。

## 2. Git 規範與 Main 分支同步

- Commit 規範：遵守 Conventional Commits、長度 <20 字、嚴禁包含 Co-Authored-By。
- Main 分支 Merge 後二度審視：每次 pull 或 merge main 之後，必須重新比對 Codebase，確認 main 新合併的代碼是否有可重用的工具/模組，或規格變動需要隨之微調。

## 3. 技能路由與外部服務控制

- Jira 任務強制路由：凡涉及 Jira Ticket 處理、相關 PR 建立與 Review 評論修正，強制調用與遵從 jira-do 技能規範執行。
- MCP 寫入限制：嚴禁透過 MCP 對外部服務寫入。例外僅限 Jira（經由 jira-actions）與記憶（Hindsight/Memory）更新。其餘寫入改走非 MCP 路徑；無路徑則詢問。
- Confluence 編輯：禁止整頁重寫。必須採用 HTML 格式針對既有結構做 targeted 最小幅度編輯，保護 inline comment anchors 與 local IDs。

## 4. 外科手術式代碼維護 (Minimal Diff Control)

- 契約與 Enum 對齊：涉及跨服務/外部 API 時，必須查閱 Producer Code 的 Serializer/Annotation，嚴禁猜測 Enum 或 JSON 欄位。Wire DTO 與 Domain Enum 必須透過轉換層隔離，多型欄位需產出 Truth Table，並包含未知列舉值的防禦性 Fallback。
- Raw Payload HTTP 測試原則：涉及外部通訊時，禁止僅用 Client/Interface Mock 測試。必須使用 HTTP 層級 Mock（如 WireMock, MSW, MockWebServer 等）配合真實 Raw JSON Response Body 進行反序列化驗證。
- 零臆測代碼 (Zero Speculative Code)：不添加未經請求的功能、預留介面、大包 options、或非必要的 Log/Metrics/Tracing 抽象層。
- 最小化 Diff：嚴禁順便修改鄰近格式、註釋或無關邏輯。Diff 中每一行變更都必須能追溯至本次任務請求。孤兒清理僅限因本次修改而失效者，既有 dead code 不擅自刪除。

## 5. 完成前 Exit Criteria (審視 git diff)

執行最終確認前，必須審視 git diff 並確認通過以下三項檢查：
1. 無雜質：無 Debug 列印、臨時 Log、無關格式化或未使用的 import。
2. 防禦性：Null/Empty 檢查、網路與例外處理、邊界條件皆具備。
3. 一致性：邏輯 100% 契合 Truth Table 與 Jira/Task 規格，且 CLI 測試完整 Pass。

## 6. 卡住時 (When Stuck)

1. 碰撞思考：強制連結不相關概念尋找切入點。
2. 反轉假設：翻轉既有約束，確認問題是否為偽命題。
3. 簡化級聯：尋找能同時消去多個複雜度的最小切入點。# Rules

此文件為 OMP 執行層之代碼與工程規範。已由 Hermes 系統層覆蓋之項目（如語言設定、STATE.md 契約、GSD 階段指揮與唯讀系統保護）此處不予重複。

## 1. 執行權限與必問邊界

- 預設 YOLO：範疇內實作、區域除錯、重構收斂與合理預設——直接執行，無需開選單詢問。
- 必問硬閘門 (Hard Ask Boundary)：僅在以下情況暫停並向人類確認：
  1. 不可逆或外發動作：push、建立／合併 PR、刪除他人工作、對外發佈。
  2. 新建或修改 Data Model / DB Schema 實體。
  3. 高成本且互斥的架構選型分叉。
  4. 非 MCP 之外部服務寫入操作。

## 2. Git 規範與 Main 分支同步

- Commit 規範：遵守 Conventional Commits、長度 <20 字、嚴禁包含 Co-Authored-By。
- Main 分支 Merge 後二度審視：每次 pull 或 merge main 之後，必須重新比對 Codebase，確認 main 新合併的代碼是否有可重用的工具/模組，或規格變動需要隨之微調。

## 3. 技能路由與外部服務控制

- Jira 任務強制路由：凡涉及 Jira Ticket 處理、相關 PR 建立與 Review 評論修正，強制調用與遵從 jira-do 技能規範執行。
- MCP 寫入限制：嚴禁透過 MCP 對外部服務寫入。例外僅限 Jira（經由 jira-actions）與記憶（Hindsight/Memory）更新。其餘寫入改走非 MCP 路徑；無路徑則詢問。
- Confluence 編輯：禁止整頁重寫。必須採用 HTML 格式針對既有結構做 targeted 最小幅度編輯，保護 inline comment anchors 與 local IDs。

## 4. 外科手術式代碼維護 (Minimal Diff Control)

- 契約與 Enum 對齊：涉及跨服務/外部 API 時，必須查閱 Producer Code 的 Serializer/Annotation，嚴禁猜測 Enum 或 JSON 欄位。Wire DTO 與 Domain Enum 必須透過轉換層隔離，多型欄位需產出 Truth Table，並包含未知列舉值的防禦性 Fallback。
- Raw Payload HTTP 測試原則：涉及外部通訊時，禁止僅用 Client/Interface Mock 測試。必須使用 HTTP 層級 Mock（如 WireMock, MSW, MockWebServer 等）配合真實 Raw JSON Response Body 進行反序列化驗證。
- 零臆測代碼 (Zero Speculative Code)：不添加未經請求的功能、預留介面、大包 options、或非必要的 Log/Metrics/Tracing 抽象層。
- 最小化 Diff：嚴禁順便修改鄰近格式、註釋或無關邏輯。Diff 中每一行變更都必須能追溯至本次任務請求。孤兒清理僅限因本次修改而失效者，既有 dead code 不擅自刪除。

## 5. 完成前 Exit Criteria (審視 git diff)

執行最終確認前，必須審視 git diff 並確認通過以下三項檢查：
1. 無雜質：無 Debug 列印、臨時 Log、無關格式化或未使用的 import。
2. 防禦性：Null/Empty 檢查、網路與例外處理、邊界條件皆具備。
3. 一致性：邏輯 100% 契合 Truth Table 與 Jira/Task 規格，且 CLI 測試完整 Pass。

## 6. 卡住時 (When Stuck)

1. 碰撞思考：強制連結不相關概念尋找切入點。
2. 反轉假設：翻轉既有約束，確認問題是否為偽命題。
3. 簡化級聯：尋找能同時消去多個複雜度的最小切入點。
