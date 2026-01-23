#!/bin/bash

# AI Rules Sync Script
# Synchronizes master rules to all editor files and commits changes

set -e

echo "🔄 Syncing AI rules..."

# Check if master rules file exists
if [ ! -f "ai_rules/master-rules.md" ]; then
    echo "❌ Error: ai_rules/master-rules.md not found!"
    echo "💡 Run ./scripts/setup.sh first"
    exit 1
fi

# Copy master rules to all editor files
echo "📋 Copying rules to editor files..."
cp ai_rules/master-rules.md .windsurfrules
cp ai_rules/master-rules.md .cursorrules
cp ai_rules/master-rules.md .clinerules
cp ai_rules/master-rules.md .copilot-instructions.md

# Git operations
echo "📦 Committing changes..."
git add ai_rules/ *.rules *.md
git commit -m "Update AI rules $(date '+%Y-%m-%d %H:%M:%S')" || echo "Git commit skipped (no changes)"

# Optional: Push to remote
if git remote get-url origin >/dev/null 2>&1; then
    echo "🚀 Pushing to remote..."
    git push
else
    echo "ℹ️  No remote repository configured. Skipping push."
fi

echo "✅ Rules synced successfully!"
echo "🎉 All AI editors now have the latest rules"
