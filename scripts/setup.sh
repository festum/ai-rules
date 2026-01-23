#!/bin/bash

# AI Rules Setup Script
# Creates symlinks for all supported AI editors

set -e

echo "🚀 Setting up AI rules synchronization..."

# Create directories if they don't exist
mkdir -p ai_rules scripts

# Create master rules file if it doesn't exist
if [ ! -f "ai_rules/master-rules.md" ]; then
    echo "📝 Creating default master rules file..."
    cat > ai_rules/master-rules.md << 'EOF'
# AI Coding Rules - Master File
---
# Windsurf: trigger: always_on
# Cursor: alwaysApply: true
---

## Coding Standards
- Use TypeScript strict mode
- Prefer async/await over promises
- Single responsibility principle
EOF
fi

# Create symlinks for all supported editors
echo "🔗 Creating symlinks..."
ln -sf ai_rules/master-rules.md .windsurfrules
ln -sf ai_rules/master-rules.md .cursorrules
ln -sf ai_rules/master-rules.md .clinerules
ln -sf ai_rules/master-rules.md .copilot-instructions.md

# Git operations
echo "📦 Initializing git repository..."
git add .
git commit -m "Initial AI rules setup" || echo "Git commit skipped (no changes or not a git repo)"

echo "✅ Setup complete!"
echo "📝 Edit ai_rules/master-rules.md to customize your rules"
echo "🔄 Run ./scripts/sync.sh to sync changes to all editors"
