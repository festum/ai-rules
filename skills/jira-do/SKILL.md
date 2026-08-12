---
name: jira-do
description: 查看、設計、更新、執行 Jira ticket
user-invocable: true
---

查看用戶給你的 JIRA Ticket，並根據 ticket 的內容去相關 repo 跟文件找出相關前後文，全面正確理解後做任務的設計、更新(如果原Ticket寫的不完整)、執行相關的任務。
確認規格後，動手改之前先看過最相關的既有邏輯：共用 function、authorization/converter 這類語意相近的集中點，優先找有沒有現成的地方可以掛，而不是先假設要在每個呼叫點各加一次。
實作過程中若發現同一段邏輯要在第二個地方重複加一次，先停下來，那是訊號：該邏輯可能該往上收斂到共用的地方（例如轉換層、shared function），不要繼續複製貼上到第三、第四個地方。
相關任務的實施務必先 pull main branch，然後開啟新 branch，名字則用Ticket number (如: on-2099)，然後開始實作。
任何改動必須要在本地測試通過/lint通過後再進行commit，而commit message 必須遵循 https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13，且不得超過20字，還有不得放Co-Authored-By: Claude。
建立PR前必須在三檢查有無問題，要自我深度Code Review。
建立PR必須使用技能 /create-pr。PR的title、description、linked issues、reviewers都要符合規範。如果要放description，只放非常精簡的英文summary，且不要有任何段落，不要放任何AI標記。
