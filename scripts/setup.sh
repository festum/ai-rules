#!/bin/bash

# AI Rules Universal Setup Script
# Unified setup for rules and skills

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Show help
show_help() {
    cat << EOF
AI Rules Universal Setup Script

USAGE:
    $0 [COMMAND]

COMMANDS:
    rules              Setup editor rules (symlinks to memory folders)
    skills             Setup skills (symlink skills/ into each editor)
    all                Setup both rules and skills (default)
    help               Show this help

EXAMPLES:
    $0                  # Setup both rules and skills (default)
    $0 rules            # Setup editor rules only
    $0 skills           # Setup Superpowers skills only
    $0 all              # Setup both rules and skills
    $0 help             # Show help

EOF
}

# Get paths
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
MASTER_RULES="$REPO_ROOT/ai_rules/master-rules.md"
SKILLS_DIR="$REPO_ROOT/skills"

# Check if master rules exists
if [ ! -f "$MASTER_RULES" ]; then
    print_error "❌ Master rules not found: $MASTER_RULES"
    exit 1
fi

# Function to create symlink (source -> target), backing up anything unexpected
create_symlink() {
    local editor="$1"
    local source="$2"
    local target="$3"

    echo -e "${BLUE}🔗 Setting up $editor...${NC}"

    # Create directory if needed
    mkdir -p "$(dirname "$target")"

    # Handle existing file/dir
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local current_target=$(readlink "$target")
            if [ "$current_target" = "$source" ]; then
                print_status "$editor already linked"
                return 0
            else
                print_warning "Backing up existing $editor: $target -> $target.bak"
                mv "$target" "$target.bak"
            fi
        else
            print_warning "Backing up existing $editor: $target -> $target.bak"
            mv "$target" "$target.bak"
        fi
    fi

    # Create symlink
    ln -sf "$source" "$target"
    print_status "$editor linked"
}

# Setup editor rules (symlinks)
setup_rules() {
    echo -e "${BLUE}📋 Setting up editor rules...${NC}"

    # Editor memory symlinks
    create_symlink "windsurf" "$MASTER_RULES" "$HOME/.codeium/windsurf/memories/global_rules.md"
    create_symlink "cursor" "$MASTER_RULES" "$HOME/.cursor/memories/global_rules.md"
    create_symlink "claude" "$MASTER_RULES" "$HOME/.claude/memories/global_rules.md"
    create_symlink "codex" "$MASTER_RULES" "$HOME/.codex/memories/global_rules.md"

    # VS Code extensions
    echo -e "${BLUE}🔧 Setting up VS Code extensions...${NC}"
    create_symlink "continue" "$MASTER_RULES" "$HOME/.continue/rules/ai-rules.md"

    # GitHub Copilot - user level only
    create_symlink "copilot-user" "$MASTER_RULES" "$HOME/.github/copilot-instructions.md"

    # Opencode configuration
    echo -e "${BLUE}🔧 Setting up Opencode configuration...${NC}"
    create_symlink "opencode" "$MASTER_RULES" "$HOME/.config/opencode/AGENTS.md"

    echo ""
    print_status "Editor rules setup complete!"
    echo ""
    echo -e "${BLUE}📁 Editor rules setup complete!${NC}"
    echo "  ✅ Claude: ~/.claude/memories/global_rules.md"
    echo "  ✅ Codex: ~/.codex/memories/global_rules.md"
    echo "  ✅ Continue: ~/.continue/rules/ai-rules.md"
    echo "  ✅ Copilot (user): ~/.github/copilot-instructions.md"
    echo "  ✅ Opencode: ~/.config/opencode/AGENTS.md"
    echo ""
    echo -e "${BLUE}🔄 To update rules:${NC}"
    echo "  Edit: $MASTER_RULES"
    echo "  Changes are immediately available in all editors!"
}

# Setup skills (symlink the repo's skills/ folder into each editor)
setup_skills() {
    echo -e "${BLUE}🚀 Setting up skills...${NC}"

    if [ ! -d "$SKILLS_DIR" ]; then
        print_error "❌ Skills folder not found: $SKILLS_DIR"
        exit 1
    fi

    # editor:target-skills-path pairs
    EDITOR_NAMES=("cursor" "agents" "claude" "opencode" "hermes")
    EDITOR_SKILLS_PATHS=("$HOME/.cursor/skills" "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.opencode/skills" "$HOME/.hermes/skills")

    for i in "${!EDITOR_NAMES[@]}"; do
        create_symlink "${EDITOR_NAMES[$i]}" "$SKILLS_DIR" "${EDITOR_SKILLS_PATHS[$i]}"
    done

    echo ""
    print_status "Skills setup complete!"
    echo ""
    echo -e "${BLUE}📁 Skills linked to:${NC}"
    for path in "${EDITOR_SKILLS_PATHS[@]}"; do
        echo "  ✅ $path -> $SKILLS_DIR"
    done
    echo ""
    echo -e "${BLUE}🔄 To update skills:${NC}"
    echo "  Edit files under: $SKILLS_DIR"
    echo "  Changes are immediately available in all editors!"
}

# Main command handling
case "${1:-all}" in
    "rules")
        setup_rules
        ;;
    "skills")
        setup_skills
        ;;
    "all")
        setup_rules
        echo ""
        setup_skills
        ;;
    "help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
