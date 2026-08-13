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

Usage: $0 [COMMAND]

Commands:
    rules              Setup/update editor rules (symlinks from system/rules.md)
    skills             Setup/update skills (links + external packs)
    update             Alias for skills (refresh everything)
    all                Setup/update both rules and skills (default)
    help               Show this help message

Examples:
    $0                  # Setup/update both rules and skills (default)
    $0 rules            # Setup/update editor rules only
    $0 skills           # Setup/update per-skill links + external packs
    $0 update           # Same as skills: refresh all skills
    $0 all              # Setup/update both rules and skills

Notes:
    - Safe to re-run. Later runs update submodules and all external skill packs.
    - On start (rules/skills/update/all), if git + network are available, submodules are pulled first.
    - skills/ is NOT linked as a whole folder anymore.
    - Each skill directory under skills/ is linked individually.
    - Existing agent-owned skills (e.g. gsd-*) are left untouched by linking.
    - Downloaded shared packs live as real dirs under \`~/.agents/skills\`; other agents only get symlinks.
    - External packs (cc-skills-golang) are installed/updated via \`npx skills\`.
    - Selective Superpowers skills sync/update from obra/superpowers (not full plugin).
    - Selective Anthropic skills sync/update from anthropics/skills (not full pack).
    - GSD is installed/updated at the end via \`npx @opengsd/gsd-core\` (full profile).
EOF
}

# Get paths
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
RULES="$REPO_ROOT/system/rules.md"
STICKY_RULES="$REPO_ROOT/system/sticky_rules.md"
SKILLS_DIR="$REPO_ROOT/skills"
CC_SKILLS_GOLANG_REPO="https://github.com/samber/cc-skills-golang"
GSD_CORE_PKG="@opengsd/gsd-core"
GSD_PROFILE="full"
# Runtimes we actively use with ai-rules; zed unsupported by GSD.
GSD_RUNTIMES=(claude cursor pi hermes opencode)

# Selective Superpowers skills (obra/superpowers). Not the full plugin pack.
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"
SUPERPOWERS_CACHE="$HOME/.cache/ai-rules/superpowers"
SUPERPOWERS_SKILLS=(
    brainstorming
    executing-plans
    finishing-a-development-branch
    requesting-code-review
    subagent-driven-development
    systematic-debugging
    test-driven-development
    using-git-worktrees
    verification-before-completion
    writing-plans
)

# Selective Anthropic example skills (anthropics/skills). Not the full pack.
# Local lifestyle dirs (file-organizer, etc.) stay Claude-owned and are not managed here.
ANTHROPICS_REPO="https://github.com/anthropics/skills.git"
ANTHROPICS_CACHE="$HOME/.cache/ai-rules/anthropics-skills"
ANTHROPICS_SKILLS=(
    brand-guidelines
    canvas-design
    claude-api
    doc-coauthoring
    docx
    mcp-builder
    pdf
    skill-creator
    web-artifacts-builder
    webapp-testing
    xlsx
)

# Check shared rules file exists
if [ ! -f "$RULES" ]; then
    print_error "Rules file not found: $RULES"
    exit 1
fi

# Network probe shared by submodule + external pack installs.
network_available() {
    if command -v git >/dev/null 2>&1; then
        if git -C "$REPO_ROOT" ls-remote --exit-code origin HEAD >/dev/null 2>&1; then
            return 0
        fi
        if git ls-remote --exit-code https://github.com/git/git.git HEAD >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Pull all git submodules when git and network are available.
# Best-effort: never abort the rest of setup on failure.
update_submodules() {
    echo -e "${BLUE}📦 Checking git submodules...${NC}"

    if ! command -v git >/dev/null 2>&1; then
        print_warning "git not available; skipping submodule update"
        return 0
    fi

    if [ ! -e "$REPO_ROOT/.git" ]; then
        print_warning "Not a git checkout; skipping submodule update"
        return 0
    fi

    if [ ! -f "$REPO_ROOT/.gitmodules" ]; then
        print_info "No .gitmodules found; nothing to update"
        return 0
    fi

    if ! network_available; then
        print_warning "Network unavailable; skipping submodule update"
        return 0
    fi

    print_info "Syncing and pulling submodules..."
    if git -C "$REPO_ROOT" submodule sync --recursive \
        && git -C "$REPO_ROOT" submodule update --init --recursive --remote; then
        # Prefer fast-forward pull when a submodule is on a branch.
        git -C "$REPO_ROOT" submodule foreach --recursive '
            if git symbolic-ref -q HEAD >/dev/null 2>&1; then
                git pull --ff-only || true
            fi
        ' >/dev/null
        print_status "Submodules updated"
    else
        print_warning "Submodule update failed; continuing setup"
    fi
}

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
            local current_target
            current_target=$(readlink "$target")
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
    ln -sfn "$source" "$target"
    print_status "$editor linked"
}

# Ensure agent skills path is a real directory (never a whole-folder symlink to ai-rules)
ensure_skills_dir() {
    local target="$1"

    if [ -L "$target" ]; then
        local current_target
        current_target=$(readlink "$target")
        print_warning "Replacing whole-folder skills symlink: $target -> $current_target"
        rm "$target"
        mkdir -p "$target"
        return 0
    fi

    if [ -e "$target" ] && [ ! -d "$target" ]; then
        print_warning "Backing up non-directory skills path: $target -> $target.bak"
        mv "$target" "$target.bak"
    fi

    mkdir -p "$target"
}

# Link each skill from ai-rules/skills into an agent skills directory.
# Never overwrite agent-owned real dirs (GSD installs, Hermes packs, etc.).
link_skills_into() {
    local editor="$1"
    local target="$2"
    local linked=0
    local skipped=0
    local refreshed=0

    echo -e "${BLUE}🔗 Linking skills into $editor ($target)...${NC}"
    ensure_skills_dir "$target"

    # Remove stale ai-rules skill links that no longer exist upstream
    if [ -d "$target" ]; then
        for dest in "$target"/*; do
            [ -e "$dest" ] || [ -L "$dest" ] || continue
            local name
            name=$(basename "$dest")
            if [ -L "$dest" ]; then
                local current
                current=$(readlink "$dest")
                case "$current" in
                    "$SKILLS_DIR"/*)
                        if [ ! -e "$SKILLS_DIR/$name" ]; then
                            rm "$dest"
                            print_warning "$editor: removed stale link $name"
                        fi
                        ;;
                esac
            fi
        done
    fi

    local skill_path
    for skill_path in "$SKILLS_DIR"/*/; do
        [ -d "$skill_path" ] || continue
        local skill
        skill=$(basename "$skill_path")
        # Accept top-level SKILL.md or nested skill packs
        if [ ! -f "$skill_path/SKILL.md" ] && [ ! -d "$skill_path/skills" ]; then
            continue
        fi

        local dest="$target/$skill"
        local source="$SKILLS_DIR/$skill"

        if [ -L "$dest" ]; then
            local current
            current=$(readlink "$dest")
            if [ "$current" = "$source" ]; then
                linked=$((linked + 1))
                continue
            fi
            rm "$dest"
            ln -sfn "$source" "$dest"
            refreshed=$((refreshed + 1))
            continue
        fi

        if [ -e "$dest" ]; then
            print_warning "$editor: skip $skill (exists, not an ai-rules link)"
            skipped=$((skipped + 1))
            continue
        fi

        ln -sfn "$source" "$dest"
        linked=$((linked + 1))
    done

    print_status "$editor: linked/kept=$linked refreshed=$refreshed skipped_owned=$skipped"
}

# Setup editor rules (symlinks)
setup_rules() {
    echo -e "${BLUE}📋 Setting up editor rules from system/rules.md...${NC}"

    # Source of truth: system/rules.md → each editor's native rules path
    create_symlink "windsurf" "$RULES" "$HOME/.codeium/windsurf/memories/global_rules.md"
    create_symlink "cursor" "$RULES" "$HOME/.cursor/memories/global_rules.md"
    create_symlink "claude" "$RULES" "$HOME/.claude/CLAUDE.md"
    create_symlink "codex" "$RULES" "$HOME/.codex/memories/global_rules.md"
    create_symlink "continue" "$RULES" "$HOME/.continue/rules/ai-rules.md"
    create_symlink "copilot-user" "$RULES" "$HOME/.github/copilot-instructions.md"
    create_symlink "opencode" "$RULES" "$HOME/.config/opencode/AGENTS.md"
    create_symlink "zed" "$RULES" "$HOME/.config/zed/AGENTS.md"
    create_symlink "home-agents" "$RULES" "$HOME/AGENTS.md"
    create_symlink "omp" "$RULES" "$HOME/.omp/agent/AGENTS.md"
    if [ -f "$STICKY_RULES" ]; then
        create_symlink "omp-sticky" "$STICKY_RULES" "$HOME/.omp/agent/RULES.md"
    else
        print_warning "Missing $STICKY_RULES; skipping ~/.omp/agent/RULES.md"
    fi

    echo ""
    print_status "Editor rules setup complete!"
    echo ""
    echo -e "${BLUE}📁 Linked system/rules.md into:${NC}"
    echo "  ✅ Windsurf: ~/.codeium/windsurf/memories/global_rules.md"
    echo "  ✅ Cursor: ~/.cursor/memories/global_rules.md"
    echo "  ✅ Claude: ~/.claude/CLAUDE.md"
    echo "  ✅ Codex: ~/.codex/memories/global_rules.md"
    echo "  ✅ Continue: ~/.continue/rules/ai-rules.md"
    echo "  ✅ Copilot (user): ~/.github/copilot-instructions.md"
    echo "  ✅ Opencode: ~/.config/opencode/AGENTS.md"
    echo "  ✅ Zed: ~/.config/zed/AGENTS.md"
    echo "  ✅ Home: ~/AGENTS.md"
    echo "  ✅ OMP: ~/.omp/agent/AGENTS.md"
    echo "  ✅ OMP sticky: ~/.omp/agent/RULES.md <- system/sticky_rules.md"
    echo ""
    echo -e "${BLUE}🔄 To update rules:${NC}"
    echo "  Edit: $RULES"
    echo "  OMP sticky: $STICKY_RULES"
    echo "  Changes are immediately available in all editors!"
}


# Remove stale whole-pack link left over from the old ai-rules submodule layout.
remove_stale_cc_skills_golang_pack_link() {
    local target
    for target in \
        "$HOME/.cursor/skills/cc-skills-golang" \
        "$HOME/.agents/skills/cc-skills-golang" \
        "$HOME/.claude/skills/cc-skills-golang" \
        "$HOME/.opencode/skills/cc-skills-golang" \
        "$HOME/.config/opencode/skills/cc-skills-golang" \
        "$HOME/.hermes/skills/cc-skills-golang" \
        "$HOME/.pi/agent/skills/cc-skills-golang"
    do
        if [ -L "$target" ]; then
            local current
            current=$(readlink "$target")
            case "$current" in
                *"/ai-rules/skills/cc-skills-golang"|*"/Repo/ai-rules/skills/cc-skills-golang")
                    rm "$target"
                    print_warning "Removed stale pack link: $target"
                    ;;
            esac
        fi
    done
}

# Shared agent skill dirs that receive symlinks to ~/.agents/skills/<name>.
# Ownership rule for downloaded/shared packs:
#   real files  -> ~/.agents/skills/<name>
#   other agents -> symlink only
AGENT_SKILL_LINK_TARGETS=(
    "$HOME/.cursor/skills"
    "$HOME/.claude/skills"
    "$HOME/.opencode/skills"
    "$HOME/.config/opencode/skills"
    "$HOME/.hermes/skills"
    "$HOME/.pi/agent/skills"
)

# Symlink named skills from ~/.agents/skills into every agent skill dir.
# Args: skill names...
link_shared_skills_from_agents() {
    local agents_skills="$HOME/.agents/skills"
    local skill target src dest current
    mkdir -p "$agents_skills"
    for target in "${AGENT_SKILL_LINK_TARGETS[@]}"; do
        mkdir -p "$target"
        for skill in "$@"; do
            src="$agents_skills/$skill"
            [ -d "$src" ] || continue
            dest="$target/$skill"
            if [ -L "$dest" ]; then
                current=$(readlink "$dest")
                if [ "$current" = "$src" ] || [ "$current" = "../../.agents/skills/$skill" ] || [ "$current" = "../../../.agents/skills/$skill" ]; then
                    continue
                fi
                rm "$dest"
            elif [ -e "$dest" ]; then
                rm -rf "$dest"
            fi
            ln -sfn "$src" "$dest"
        done
    done
}

# Mirror flattened golang-* from ~/.agents/skills into agent skill dirs that
# the skills CLI may not always refresh (Cursor / OpenCode paths).
link_golang_skills_into_agents() {
    local src_root="$HOME/.agents/skills"
    local names=()
    local src
    for src in "$src_root"/golang-*; do
        [ -d "$src" ] || continue
        names+=("$(basename "$src")")
    done
    if [ "${#names[@]}" -gt 0 ]; then
        link_shared_skills_from_agents "${names[@]}"
    fi
}

cc_skills_golang_already_installed() {
    ls -1d "$HOME/.agents/skills"/golang-* >/dev/null 2>&1 && return 0
    if [ -f "$HOME/.agents/.skill-lock.json" ] && grep -q 'samber/cc-skills-golang' "$HOME/.agents/.skill-lock.json" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Install/update samber/cc-skills-golang via official skills CLI (flattened golang-*).
# Re-runs prefer `skills update`; first run uses `skills add`.
# Not kept inside ai-rules/skills — same ownership model as GSD.
install_cc_skills_golang() {
    echo -e "${BLUE}🐹 Updating cc-skills-golang (official skills CLI)...${NC}"

    if ! command -v npx >/dev/null 2>&1; then
        print_warning "npx not available; skipping cc-skills-golang"
        return 0
    fi

    remove_stale_cc_skills_golang_pack_link

    if ! network_available; then
        if cc_skills_golang_already_installed; then
            print_warning "Network unavailable; refreshing local golang-* links only"
            link_golang_skills_into_agents
            return 0
        fi
        print_warning "Network unavailable; skipping cc-skills-golang"
        return 0
    fi

    local ok=0
    if cc_skills_golang_already_installed; then
        print_info "Existing golang skills found; running skills update..."
        if npx --yes skills update -g -y; then
            ok=1
        else
            print_warning "skills update failed; falling back to skills add"
        fi
    fi

    if [ "$ok" -eq 0 ]; then
        if npx --yes skills add "$CC_SKILLS_GOLANG_REPO" -g --all; then
            ok=1
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        link_golang_skills_into_agents
        local count
        count=$(ls -1d "$HOME/.agents/skills"/golang-* 2>/dev/null | wc -l | tr -d ' ')
        print_status "cc-skills-golang up to date (golang-* in ~/.agents/skills: ${count:-0})"
    else
        print_warning "cc-skills-golang install/update failed; continuing setup"
    fi
}

# Install/update GSD via official npx installer.
# Not kept inside ai-rules/skills — same ownership model as cc-skills-golang.
install_gsd() {
    echo -e "${BLUE}🚀 Updating GSD (@opengsd/gsd-core)...${NC}"

    if ! command -v npx >/dev/null 2>&1; then
        print_warning "npx not available; skipping GSD"
        return 0
    fi

    if ! network_available; then
        print_warning "Network unavailable; skipping GSD"
        return 0
    fi

    local ok=0
    local fail=0
    local rt
    for rt in "${GSD_RUNTIMES[@]}"; do
        echo -e "${BLUE}  → GSD ${rt} (profile=${GSD_PROFILE})...${NC}"
        if npx --yes "$GSD_CORE_PKG" --"$rt" --global --profile="$GSD_PROFILE"; then
            ok=$((ok + 1))
        else
            fail=$((fail + 1))
            print_warning "GSD install failed for runtime: $rt"
        fi
    done

    if [ "$fail" -eq 0 ]; then
        print_status "GSD up to date for: ${GSD_RUNTIMES[*]}"
    elif [ "$ok" -gt 0 ]; then
        print_warning "GSD partial success (ok=$ok fail=$fail); continuing setup"
    else
        print_warning "GSD install failed for all runtimes; continuing setup"
    fi
}

# Sync selected Superpowers skills from upstream (not full plugin install).
# Official plugin installs all 14 + hooks; we only keep the subset listed in SUPERPOWERS_SKILLS.
install_superpowers() {
    echo -e "${BLUE}🦸 Updating selective Superpowers skills...${NC}"

    if ! command -v git >/dev/null 2>&1; then
        print_warning "git not available; skipping Superpowers"
        return 0
    fi

    mkdir -p "$(dirname "$SUPERPOWERS_CACHE")"
    if [ ! -d "$SUPERPOWERS_CACHE/.git" ]; then
        if ! network_available; then
            print_warning "Network unavailable and no Superpowers cache; skipping"
            return 0
        fi
        print_info "Cloning obra/superpowers into cache..."
        if ! git clone --depth 1 "$SUPERPOWERS_REPO" "$SUPERPOWERS_CACHE"; then
            print_warning "Superpowers clone failed; continuing setup"
            return 0
        fi
    elif network_available; then
        print_info "Updating Superpowers cache..."
        if ! git -C "$SUPERPOWERS_CACHE" fetch --depth 1 origin HEAD \
            || ! git -C "$SUPERPOWERS_CACHE" reset --hard FETCH_HEAD; then
            print_warning "Superpowers cache update failed; continuing with existing cache"
        fi
    else
        print_warning "Network unavailable; re-syncing Superpowers from existing cache"
    fi

    local agents_skills="$HOME/.agents/skills"
    mkdir -p "$agents_skills"

    local skill
    local synced=0
    local missing=0
    for skill in "${SUPERPOWERS_SKILLS[@]}"; do
        local src="$SUPERPOWERS_CACHE/skills/$skill"
        if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
            print_warning "Upstream Superpowers skill missing: $skill"
            missing=$((missing + 1))
            continue
        fi

        local dest="$agents_skills/$skill"
        rm -rf "$dest"
        mkdir -p "$dest"
        # Copy full skill tree (scripts/references), not just SKILL.md
        cp -a "$src"/. "$dest"/
        synced=$((synced + 1))
    done

    # Real files stay in ~/.agents/skills; other agents get symlinks only.
    link_shared_skills_from_agents "${SUPERPOWERS_SKILLS[@]}"

    if [ "$synced" -gt 0 ]; then
        print_status "Superpowers up to date: $synced skills in ~/.agents/skills (missing=$missing)"
    else
        print_warning "No Superpowers skills synced; continuing setup"
    fi
}

# Sync selected Anthropic skills from anthropics/skills (not full pack).
# Replaces stale Claude-owned copies for managed names (e.g. old artifacts-builder).
install_anthropics_skills() {
    echo -e "${BLUE}📘 Updating selective Anthropic skills...${NC}"

    if ! command -v git >/dev/null 2>&1; then
        print_warning "git not available; skipping Anthropic skills"
        return 0
    fi

    mkdir -p "$(dirname "$ANTHROPICS_CACHE")"
    if [ ! -d "$ANTHROPICS_CACHE/.git" ]; then
        if ! network_available; then
            print_warning "Network unavailable and no Anthropic skills cache; skipping"
            return 0
        fi
        print_info "Cloning anthropics/skills into cache..."
        if ! git clone --depth 1 "$ANTHROPICS_REPO" "$ANTHROPICS_CACHE"; then
            print_warning "Anthropic skills clone failed; continuing setup"
            return 0
        fi
    elif network_available; then
        print_info "Updating Anthropic skills cache..."
        if ! git -C "$ANTHROPICS_CACHE" fetch --depth 1 origin HEAD \
            || ! git -C "$ANTHROPICS_CACHE" reset --hard FETCH_HEAD; then
            print_warning "Anthropic skills cache update failed; continuing with existing cache"
        fi
    else
        print_warning "Network unavailable; re-syncing Anthropic skills from existing cache"
    fi

    local agents_skills="$HOME/.agents/skills"
    mkdir -p "$agents_skills"

    local skill
    local synced=0
    local missing=0
    for skill in "${ANTHROPICS_SKILLS[@]}"; do
        local src="$ANTHROPICS_CACHE/skills/$skill"
        if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
            print_warning "Upstream Anthropic skill missing: $skill"
            missing=$((missing + 1))
            continue
        fi

        local dest="$agents_skills/$skill"
        rm -rf "$dest"
        mkdir -p "$dest"
        cp -a "$src"/. "$dest"/
        synced=$((synced + 1))
    done

    # Real files stay in ~/.agents/skills; other agents get symlinks only.
    link_shared_skills_from_agents "${ANTHROPICS_SKILLS[@]}"

    # Upstream renamed artifacts-builder -> web-artifacts-builder
    local target stale
    for target in "${AGENT_SKILL_LINK_TARGETS[@]}"; do
        stale="$target/artifacts-builder"
        if [ -L "$stale" ] || [ -e "$stale" ]; then
            rm -rf "$stale"
            print_warning "Removed stale artifacts-builder from $target (now web-artifacts-builder)"
        fi
    done

    if [ "$synced" -gt 0 ]; then
        print_status "Anthropic skills up to date: $synced in ~/.agents/skills (missing=$missing)"
    else
        print_warning "No Anthropic skills synced; continuing setup"
    fi
}

# External/runtime packs that must not live in ai-rules/skills.
install_external_skills() {
    echo -e "${BLUE}📦 Updating external skill packs...${NC}"
    install_cc_skills_golang
    echo ""
    install_anthropics_skills
    echo ""
    install_superpowers
    echo ""
    install_gsd
}

# Setup skills (per-skill symlinks into each agent skills dir)
setup_skills() {
    echo -e "${BLUE}🚀 Updating skills (per-skill links + external packs)...${NC}"

    if [ ! -d "$SKILLS_DIR" ]; then
        print_error "❌ Skills folder not found: $SKILLS_DIR"
        exit 1
    fi

    # editor:target-skills-path pairs
    # Keep both OpenCode paths: legacy ~/.opencode/skills and GSD's ~/.config/opencode/skills
    EDITOR_NAMES=(
        "cursor"
        "agents"
        "claude"
        "opencode"
        "opencode-config"
        "hermes"
        "pi"
    )
    EDITOR_SKILLS_PATHS=(
        "$HOME/.cursor/skills"
        "$HOME/.agents/skills"
        "$HOME/.claude/skills"
        "$HOME/.opencode/skills"
        "$HOME/.config/opencode/skills"
        "$HOME/.hermes/skills"
        "$HOME/.pi/agent/skills"
    )

    local i
    for i in "${!EDITOR_NAMES[@]}"; do
        link_skills_into "${EDITOR_NAMES[$i]}" "${EDITOR_SKILLS_PATHS[$i]}"
    done

    echo ""
    install_external_skills

    echo ""
    print_status "Skills update complete!"
    echo ""
    echo -e "${BLUE}📁 Per-skill links refreshed in:${NC}"
    for path in "${EDITOR_SKILLS_PATHS[@]}"; do
        echo "  ✅ $path"
    done
    echo ""
    echo -e "${BLUE}🔄 Re-run anytime to update everything:${NC}"
    echo "  $0 skills   # or: $0 update"
    echo "  Updates: ai-rules skill links + submodules + golang + Anthropic skills + Superpowers + GSD"
}

# Main command handling
case "${1:-all}" in
    "rules")
        update_submodules
        echo ""
        setup_rules
        ;;
    "skills"|"update")
        update_submodules
        echo ""
        setup_skills
        ;;
    "all")
        update_submodules
        echo ""
        setup_rules
        echo ""
        setup_skills
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
