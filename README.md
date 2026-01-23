# AI Rules Template

Synchronize AI coding rules across Windsurf, Cursor, VS Code, Cline, and GitHub Copilot editors.

## 🚀 Quick Setup

```bash
# Make scripts executable and run setup
chmod +x scripts/setup.sh scripts/sync.sh
./scripts/setup.sh
```

## 📝 Daily Workflow

1. **Edit your rules:**
   ```bash
   vim ai_rules/master-rules.md
   ```

2. **Sync to all editors + cloud:**
   ```bash
   ./scripts/sync.sh
   ```

## 📁 Repository Structure

```
ai-rules-template/
├── ai_rules/
│   └── master-rules.md          # Main rules file (edit here only)
├── .windsurfrules               # Symlink → ai_rules/master-rules.md
├── .cursorrules                 # Symlink → ai_rules/master-rules.md
├── .clinerules                  # Symlink → ai_rules/master-rules.md
├── .copilot-instructions.md     # Symlink → ai_rules/master-rules.md
├── scripts/
│   ├── setup.sh                 # Create symlinks + git init
│   └── sync.sh                  # Copy rules + git commit/push
├── .gitignore
├── README.md
└── LICENSE
```

## 🎯 Supported Editors

| Editor | Config File | Status |
|--------|-------------|--------|
| Windsurf | `.windsurfrules` | ✅ Supported |
| Cursor | `.cursorrules` | ✅ Supported |
| Cline | `.clinerules` | ✅ Supported |
| GitHub Copilot | `.copilot-instructions.md` | ✅ Supported |

## ⚙️ How It Works

1. **Single Source of Truth:** Edit only `ai_rules/master-rules.md`
2. **Automatic Sync:** Scripts copy rules to all editor config files
3. **Version Control:** Git tracks all changes automatically
4. **Cloud Backup:** Push to remote repository for backup

## 🛠️ Script Details

### setup.sh
- Creates directory structure
- Sets up symlinks for all editors
- Initializes git repository
- Creates default rules file if needed

### sync.sh
- Copies master rules to all editor files
- Commits changes with timestamp
- Pushes to remote repository (if configured)

## 📋 Customization

Edit `ai_rules/master-rules.md` to add your own coding standards, preferences, and project-specific rules. The file supports:

- Markdown formatting
- Front matter for editor-specific settings
- Code blocks and examples
- Custom sections and categories

## 🔧 Troubleshooting

**Symlinks not working?**
```bash
# Remove broken symlinks and recreate
rm .windsurfrules .cursorrules .clinerules .copilot-instructions.md
./scripts/setup.sh
```

**Git push failing?**
```bash
# Configure remote repository
git remote add origin <your-repo-url>
git push -u origin main
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Happy coding with consistent AI rules! 🎉**
