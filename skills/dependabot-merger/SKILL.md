---
name: dependabot-merger
description: Merge dependabot PRs
user-invocable: true
---

# dependabot-merger

## Workflow

- 找 Repository 中的 dependabot PRs
- 設 Auto "Squash and merge"
- Approve PR
- 在其中一個PR留言"@dependabot rebase"以觸發 rebase 流程。但如果有多個PR就等其中一個Merge後再留言rebase
- 監控這流程直到所有的dependabot PR 都被處理完畢。
- 取消 "TF plan and apply from main (auto)" pipeline (往往在等待await-confirmation)，只留最後一個dependabot merge PR的pipeline，避免浪費資源。
- 觸發最後一個pipeline中的 await-confirmation 的prod & sandbox。
