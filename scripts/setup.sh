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
    skills             Setup Superpowers skills (download from GitHub)
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

# Check if master rules exists
if [ ! -f "$MASTER_RULES" ]; then
    print_error "❌ Master rules not found: $MASTER_RULES"
    exit 1
fi

# Function to create symlink
create_symlink() {
    local editor="$1"
    local target="$2"

    echo -e "${BLUE}🔗 Setting up $editor...${NC}"

    # Create directory if needed
    mkdir -p "$(dirname "$target")"

    # Handle existing file
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            local current_target=$(readlink "$target")
            if [ "$current_target" = "$MASTER_RULES" ]; then
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
    ln -sf "$MASTER_RULES" "$target"
    print_status "$editor linked"
}

# Setup editor rules (symlinks)
setup_rules() {
    echo -e "${BLUE}📋 Setting up editor rules...${NC}"

    # Editor memory symlinks
    create_symlink "windsurf" "$HOME/.codeium/windsurf/memories/global_rules.md"
    create_symlink "cursor" "$HOME/.cursor/memories/global_rules.md"
    create_symlink "claude" "$HOME/.claude/memories/global_rules.md"
    create_symlink "codex" "$HOME/.codex/memories/global_rules.md"

    # VS Code extensions
    echo -e "${BLUE}🔧 Setting up VS Code extensions...${NC}"
    create_symlink "continue" "$HOME/.continue/rules/ai-rules.md"

    # GitHub Copilot - user level only
    create_symlink "copilot-user" "$HOME/.github/copilot-instructions.md"

    # Opencode configuration
    echo -e "${BLUE}🔧 Setting up Opencode configuration...${NC}"
    create_symlink "opencode" "$HOME/.config/opencode/AGENTS.md"

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

# Setup Superpowers skills
setup_skills() {
    echo -e "${BLUE}🚀 Setting up Superpowers skills...${NC}"

    # Define editor names and their skill paths in parallel arrays (Bash 3.x compatible)
    EDITOR_NAMES=("windsurf" "cursor" "claude" "codex" "opencode")
    EDITOR_SKILLS_PATHS=("$HOME/.codeium/windsurf/skills" "$HOME/.cursor/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills")

    # Function to get skills list from GitHub API
    get_skills_list() {
        local api_url="https://api.github.com/repos/obra/superpowers/contents/skills"
        local response=$(curl -s "$api_url" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "❌ Failed to fetch skills list from GitHub API"
            return 1
        fi

        # Simple fallback to known skills
        echo "using-superpowers brainstorming writing-plans test-driven-development using-git-worktrees executing-plans subagent-driven-development requesting-code-review finishing-a-development-branch writing-skills"
    }

    # Function to download skill
    download_skill() {
        local skill_name="$1"
        local skill_path="skills/$skill_name/SKILL.md"
        local url="https://raw.githubusercontent.com/obra/superpowers/main/$skill_path"

        echo -e "${BLUE}📥 Downloading: $skill_name${NC}"

        if curl -s -f -L "$url" > "/tmp/$skill_name.md"; then
            print_status "Downloaded: $skill_name"
            return 0
        else
            print_warning "Failed to download: $skill_name"
            return 1
        fi
    }

    # Function to install skill
    install_skill() {
        local editor="$1"
        local skill_name="$2"
        local skills_dir="$3"

        mkdir -p "$skills_dir"
        local skill_dir="$skills_dir/$skill_name"
        mkdir -p "$skill_dir"

        if [ -f "/tmp/$skill_name.md" ]; then
            local target_file="$skill_dir/SKILL.md"

            # Check if skill already exists
            if [ -f "$target_file" ]; then
                # Compare files to see if update is needed
                if ! cmp -s "/tmp/$skill_name.md" "$target_file"; then
                    print_warning "Updating $skill_name in $editor (version changed)"
                    cp "/tmp/$skill_name.md" "$target_file"
                else
                    print_info "Skipped $skill_name in $editor (already up to date)"
                fi
            else
                cp "/tmp/$skill_name.md" "$target_file"
                print_status "Installed $skill_name to $editor"
            fi
        fi
    }

    # Get skills list dynamically
    SKILLS_LIST=$(get_skills_list)
    if [ $? -ne 0 ] || [ -z "$SKILLS_LIST" ]; then
        echo "❌ Could not get skills list. Using fallback list."
        # Fallback to known skills
        SKILLS_LIST="using-superpowers brainstorming writing-plans test-driven-development using-git-worktrees executing-plans subagent-driven-development requesting-code-review finishing-a-development-branch writing-skills"
    fi

    # Check available editors
    echo -e "${BLUE}🔍 Checking for editors...${NC}"
    AVAILABLE_EDITORS=()
    AVAILABLE_SKILLS_DIRS=()
    for i in "${!EDITOR_NAMES[@]}"; do
        editor="${EDITOR_NAMES[$i]}"
        skills_dir="${EDITOR_SKILLS_PATHS[$i]}"
        if mkdir -p "$(dirname "$skills_dir")" 2>/dev/null; then
            AVAILABLE_EDITORS+=("$editor")
            AVAILABLE_SKILLS_DIRS+=("$skills_dir")
            print_info "Found: $editor"
        fi
    done

    if [ ${#AVAILABLE_EDITORS[@]} -eq 0 ]; then
        echo "❌ No supported editors found"
        exit 1
    fi

    # Download skills
    echo -e "${BLUE}📥 Downloading skills...${NC}"
    echo -e "${BLUE}📋 Found skills: $SKILLS_LIST${NC}"

    DOWNLOADED_SKILLS=()
    for skill_name in $SKILLS_LIST; do
        if download_skill "$skill_name"; then
            DOWNLOADED_SKILLS+=("$skill_name")
        fi
    done

    # Download humanizer skill
    HUMANIZER_SKILL_URL="https://raw.githubusercontent.com/blader/humanizer/refs/heads/main/SKILL.md"
    echo -e "${BLUE}📥 Downloading: humanizer${NC}"
    if curl -s -f -L "$HUMANIZER_SKILL_URL" > "/tmp/humanizer.md"; then
        print_status "Downloaded: humanizer"
        DOWNLOADED_SKILLS+=("humanizer")
    else
        print_warning "Failed to download: humanizer"
    fi

    # Install to editors
    echo -e "${BLUE}🔧 Installing skills...${NC}"
    for i in "${!AVAILABLE_EDITORS[@]}"; do
        editor="${AVAILABLE_EDITORS[$i]}"
        skills_dir="${AVAILABLE_SKILLS_DIRS[$i]}"
        for skill_name in "${DOWNLOADED_SKILLS[@]}"; do
            install_skill "$editor" "$skill_name" "$skills_dir"
        done
    done

    # Clean up
    rm -f /tmp/*.md

    echo ""
    print_status "Superpowers skills setup complete!"
    echo ""
    echo -e "${BLUE} Summary:${NC}"
    echo "  Skills: ${#DOWNLOADED_SKILLS[@]} downloaded"
    echo ""
    echo -e "${BLUE}🔄 To update skills:${NC}"
    echo "  $0 skills"
    echo ""
    echo -e "${BLUE}📚 Skills now available in your editors!${NC}"
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
