---
name: jira-do
description: 查看、設計、更新、執行 Jira ticket
user-invocable: true
---

查看用戶給你的 JIRA Ticket，並根據 ticket 的內容去相關 repo 跟文件找出相關前後文，全面正確理解後做任務的設計、更新(如果原Ticket寫的不完整)、執行相關的任務。
相關任務的實施務必先 pull main branch，然後開啟新 branch，名字則用Ticket number (如: on-2099)，然後開始實作。
任何改動必須要在本地測試通過/lint通過後再進行commit，而commit message 必須遵循 https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13，且不得超過20字，還有不得放Co-Authored-By: Claude。
建立PR前必須在三檢查有無問題，要自我深度Code Review。
建立PR必須使用技能 /create-pr。PR的title、description、linked issues、reviewers都要符合規範。如果要放description，只放非常精簡的英文summary，且不要有任何段落，不要放任何AI標記。
