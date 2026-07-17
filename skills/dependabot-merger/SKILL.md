---
name: dependabot-merger
description: Merge dependabot PRs
user-invocable: true
---

# dependabot-merger

## Workflow

- 找 Repository 中的 dependabot PRs
- Approve PR
- 如果有任何非dependabot的用戶做了commit，則退出這PR，到下一個dependabot PR。
- 設 Auto "Squash and merge" (禁止自己merge)
- 如果目標PR過期了就在其中一個PR留言"@dependabot rebase"以觸發 rebase 流程。但如果有多個PR就等其中一個Merge後再留言rebase。
- 監控這流程直到所有的dependabot PR 都被處理完畢。
- 取消 "TF plan and apply from main (auto)" pipeline (往往在等待await-confirmation)，只留最後一個dependabot merge PR的pipeline，避免浪費資源。
- 觸發最後一個pipeline中的 await-confirmation 的prod & sandbox。
- 進行dd logs監控15分鐘看看有沒有異常。若有，緊急調查。
- 最後要到下一個 repo 前先暫停等我的訊號。
