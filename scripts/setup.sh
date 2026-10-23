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
    - Existing agent-owned skills are left untouched by linking.
    - Downloaded shared packs live as real dirs under \`~/.agents/skills\`; other agents only get symlinks.
    - External packs (cc-skills-golang) are installed/updated via \`npx skills\`.
    - Selective Superpowers skills sync/update from obra/superpowers (not full plugin).
    - Selective Anthropic skills sync/update from anthropics/skills (not full pack).
    - humanizer + task-observer sync from upstream repos into \`~/.agents/skills\` (not git submodules).
EOF
}

# Get paths
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
RULES="$REPO_ROOT/system/rules.md"
STICKY_RULES="$REPO_ROOT/system/sticky_rules.md"
STATE_TEMPLATE="$REPO_ROOT/system/templates/STATE.md"
# Optional private overlay kept outside the repo (like ~/.rc_local).
# Editors symlink system/rules.md directly; the overlay is never merged. The shared
# rules tell every agent to read it as a second file (see the top of system/rules.md).
LOCAL_RULES="${AI_RULES_LOCAL:-$HOME/.ai-rules.local.md}"
HERMES_CONTRACT="$REPO_ROOT/system/hermes.md"
SKILLS_DIR="$REPO_ROOT/skills"
CC_SKILLS_GOLANG_REPO="https://github.com/samber/cc-skills-golang"

# Selective Superpowers skills (obra/superpowers). Not the full plugin pack.
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"
SUPERPOWERS_CACHE="$HOME/.cache/ai-rules/superpowers"
SUPERPOWERS_SKILLS=(
    systematic-debugging
)

# Selective Anthropic example skills (anthropics/skills). Not the full pack.
# Local lifestyle dirs (file-organizer, etc.) stay Claude-owned and are not managed here.
ANTHROPICS_REPO="https://github.com/anthropics/skills.git"
ANTHROPICS_CACHE="$HOME/.cache/ai-rules/anthropics-skills"
ANTHROPICS_SKILLS=(
    doc-coauthoring
    docx
    pdf
    skill-creator
    xlsx
)

# Single-skill upstream repos (SKILL.md at repo root). Not kept as ai-rules submodules.
HUMANIZER_REPO="https://github.com/blader/humanizer.git"
HUMANIZER_CACHE="$HOME/.cache/ai-rules/humanizer"
TASK_OBSERVER_REPO="https://github.com/rebelytics/one-skill-to-rule-them-all.git"
TASK_OBSERVER_CACHE="$HOME/.cache/ai-rules/task-observer"

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

# Function to create symlink (source -> target)
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
            fi
            # A symlink is a pointer, not user content: re-point it in place.
            # Never back it up, never move it, never leave a .bak of it.
            print_status "$editor relinked: $target -> $source"
        else
            print_warning "Backing up existing $editor: $target -> $target.bak"
            mv "$target" "$target.bak"
        fi
    fi

    # Create symlink (ln -sfn replaces an existing link in place)
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
# Never overwrite agent-owned real dirs (Hermes packs, etc.).
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
    local non_coding_target=0
    local nc
    for nc in "${NON_CODING_SKILL_LINK_TARGETS[@]}"; do
        if [ "$target" = "$nc" ]; then
            non_coding_target=1
            break
        fi
    done

    for skill_path in "$SKILLS_DIR"/*/; do
        [ -d "$skill_path" ] || continue
        local skill
        skill=$(basename "$skill_path")
        # Accept top-level SKILL.md or nested skill packs
        if [ ! -f "$skill_path/SKILL.md" ] && [ ! -d "$skill_path/skills" ]; then
            continue
        fi

        # omp (and friends) are Hermes/OpenClaw only — skip coding agent dirs
        local only_nc=0
        local s
        for s in "${NON_CODING_ONLY_SKILLS[@]}"; do
            if [ "$skill" = "$s" ]; then
                only_nc=1
                break
            fi
        done
        if [ "$only_nc" -eq 1 ] && [ "$non_coding_target" -eq 0 ]; then
            if [ -L "$target/$skill" ]; then
                rm "$target/$skill"
                print_warning "$editor: removed non-coding-only skill $skill"
            fi
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

    # Drop the stale merged copy from the old merge design so nothing still points at it.
    if [ -e "$HOME/.cache/ai-rules/rules.md" ] || [ -L "$HOME/.cache/ai-rules/rules.md" ]; then
        rm -f "$HOME/.cache/ai-rules/rules.md"
        print_status "Removed stale merged copy: $HOME/.cache/ai-rules/rules.md"
    fi

    # Source of truth: system/rules.md → each editor's native rules path (direct symlink)
    create_symlink "cursor" "$RULES" "$HOME/.cursor/memories/global_rules.md"
    create_symlink "claude" "$RULES" "$HOME/.claude/CLAUDE.md"
    create_symlink "codex" "$RULES" "$HOME/.codex/memories/global_rules.md"
    create_symlink "continue" "$RULES" "$HOME/.continue/rules/ai-rules.md"
    create_symlink "copilot-user" "$RULES" "$HOME/.github/copilot-instructions.md"
    create_symlink "opencode" "$RULES" "$HOME/.config/opencode/AGENTS.md"
    create_symlink "zed" "$RULES" "$HOME/.config/zed/AGENTS.md"
    create_symlink "home-agents" "$RULES" "$HOME/AGENTS.md"
    create_symlink "omp" "$RULES" "$HOME/.omp/agent/AGENTS.md"
    if [ -f "$STATE_TEMPLATE" ]; then
        create_symlink "state-template" "$STATE_TEMPLATE" "$HOME/.ai-rules/STATE-template.md"
    else
        print_warning "Missing $STATE_TEMPLATE; skipping ~/.ai-rules/STATE-template.md"
    fi
    if [ -f "$STICKY_RULES" ]; then
        create_symlink "omp-sticky" "$STICKY_RULES" "$HOME/.omp/agent/RULES.md"
    else
        print_warning "Missing $STICKY_RULES; skipping ~/.omp/agent/RULES.md"
    fi
    if [ -f "$HERMES_CONTRACT" ] && [ -d "$HOME/.hermes" ]; then
        create_symlink "hermes" "$HERMES_CONTRACT" "$HOME/.hermes/SOUL.md"
    else
        print_warning "Missing $HERMES_CONTRACT or $HOME/.hermes; skipping Hermes contract link"
    fi

    echo ""
    print_status "Editor rules setup complete!"
    echo ""
    echo -e "${BLUE}📁 Linked system/rules.md into:${NC}"
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
    echo "  ✅ State template: ~/.ai-rules/STATE-template.md <- system/templates/STATE.md"
    echo "  ✅ Hermes: ~/.hermes/SOUL.md <- system/hermes.md"
    echo ""
    echo -e "${BLUE}🔄 To update rules:${NC}"
    echo "  Edit: $RULES (live immediately; editors symlink it)"
    echo "  OMP sticky: $STICKY_RULES"
    echo "  Private overlay: $LOCAL_RULES (separate file, read in addition; no re-link needed)"
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
                *"/ai-rules/skills/cc-skills-golang")
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
)
# ~/.hermes is Hermes-owned; only link into it when the install exists.
if [ -d "$HOME/.hermes" ]; then
    AGENT_SKILL_LINK_TARGETS+=("$HOME/.hermes/skills")
fi
AGENT_SKILL_LINK_TARGETS+=("$HOME/.pi/agent/skills")

# Non-coding agents only (Hermes / OpenClaw). Coding agents must not get these skills.
NON_CODING_SKILL_LINK_TARGETS=(
    "$HOME/.hermes/skills"
    "$HOME/.openclaw/skills"
)

# Repo skills that link only into NON_CODING_SKILL_LINK_TARGETS.
NON_CODING_ONLY_SKILLS=(
    omp
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

# Clone/update a single-skill upstream repo and copy into ~/.agents/skills/<name>.
# Repo root must contain SKILL.md. Extra rsync excludes can be passed after cache path.
# Args: skill_name repo_url cache_path [rsync-exclude-patterns...]
sync_single_skill_repo() {
    local skill="$1"
    local repo="$2"
    local cache="$3"
    shift 3
    local excludes=("$@")

    echo -e "${BLUE}📥 Updating $skill...${NC}"

    if ! command -v git >/dev/null 2>&1; then
        print_warning "git not available; skipping $skill"
        return 0
    fi

    mkdir -p "$(dirname "$cache")"
    if [ ! -d "$cache/.git" ]; then
        if ! network_available; then
            print_warning "Network unavailable and no $skill cache; skipping"
            return 0
        fi
        print_info "Cloning $skill into cache..."
        if ! git clone --depth 1 "$repo" "$cache"; then
            print_warning "$skill clone failed; continuing setup"
            return 0
        fi
    elif network_available; then
        print_info "Updating $skill cache..."
        if ! git -C "$cache" fetch --depth 1 origin HEAD \
            || ! git -C "$cache" reset --hard FETCH_HEAD; then
            print_warning "$skill cache update failed; continuing with existing cache"
        fi
    else
        print_warning "Network unavailable; re-syncing $skill from existing cache"
    fi

    if [ ! -f "$cache/SKILL.md" ]; then
        print_warning "Upstream $skill missing SKILL.md at repo root; skipping"
        return 0
    fi

    local agents_skills="$HOME/.agents/skills"
    local dest="$agents_skills/$skill"
    mkdir -p "$agents_skills"
    rm -rf "$dest"
    mkdir -p "$dest"

    if command -v rsync >/dev/null 2>&1; then
        local rsync_args=(-a --delete --exclude .git --exclude .DS_Store)
        local ex
        for ex in "${excludes[@]}"; do
            rsync_args+=(--exclude "$ex")
        done
        rsync "${rsync_args[@]}" "$cache"/ "$dest"/
    else
        # Fallback without rsync: copy then strip .git / excludes
        cp -a "$cache"/. "$dest"/
        rm -rf "$dest/.git" "$dest/.DS_Store"
        local ex
        for ex in "${excludes[@]}"; do
            rm -rf "$dest"/$ex
        done
    fi

    link_shared_skills_from_agents "$skill"
    print_status "$skill up to date in ~/.agents/skills"
}

install_humanizer() {
    sync_single_skill_repo "humanizer" "$HUMANIZER_REPO" "$HUMANIZER_CACHE"
}

install_task_observer() {
    # Upstream marketing images are large and unused by the skill runtime.
    sync_single_skill_repo "task-observer" "$TASK_OBSERVER_REPO" "$TASK_OBSERVER_CACHE" \
        "*.png" "*.jpg" "*.jpeg" "*.webp"
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
    install_humanizer
    echo ""
    install_task_observer
}

# Setup skills (per-skill symlinks into each agent skills dir)
setup_skills() {
    echo -e "${BLUE}🚀 Updating skills (per-skill links + external packs)...${NC}"

    if [ ! -d "$SKILLS_DIR" ]; then
        print_error "❌ Skills folder not found: $SKILLS_DIR"
        exit 1
    fi

    # editor:target-skills-path pairs
    # Keep both OpenCode paths: legacy ~/.opencode/skills and ~/.config/opencode/skills
    EDITOR_NAMES=(
        "cursor"
        "agents"
        "claude"
        "opencode"
        "opencode-config"
    )
    EDITOR_SKILLS_PATHS=(
        "$HOME/.cursor/skills"
        "$HOME/.agents/skills"
        "$HOME/.claude/skills"
        "$HOME/.opencode/skills"
        "$HOME/.config/opencode/skills"
    )
    # ~/.hermes is Hermes-owned; only link into it when the install exists.
    if [ -d "$HOME/.hermes" ]; then
        EDITOR_NAMES+=("hermes")
        EDITOR_SKILLS_PATHS+=("$HOME/.hermes/skills")
    fi
    EDITOR_NAMES+=("openclaw" "pi")
    EDITOR_SKILLS_PATHS+=("$HOME/.openclaw/skills" "$HOME/.pi/agent/skills")

    local i
    for i in "${!EDITOR_NAMES[@]}"; do
        link_skills_into "${EDITOR_NAMES[$i]}" "${EDITOR_SKILLS_PATHS[$i]}"
    done

    # Drop renamed/merged legacy skill links (oc -> omp, babysitting-pr -> ship, writing-commit-messages -> git-commit, jira-do -> ship, plan-and-review -> delegate, reviewing-github-pr -> review-pr, creating-pr -> open-pr, dependabot-merger -> dependabot, wiz-graphql -> wiz, eng -> voice)
    local legacy
    for path in "${EDITOR_SKILLS_PATHS[@]}"; do
        for legacy in oc babysitting-pr writing-commit-messages jira-do plan-and-review reviewing-github-pr creating-pr dependabot-merger wiz-graphql eng; do
            if [ -L "$path/$legacy" ] || [ -e "$path/$legacy" ]; then
                rm -rf "$path/$legacy"
                print_warning "Removed legacy $legacy link from $path"
            fi
        done
    done

    local retired
    for path in "${EDITOR_SKILLS_PATHS[@]}"; do
        for retired in writing-plans executing-plans subagent-driven-development using-git-worktrees requesting-code-review verification-before-completion brainstorming finishing-a-development-branch test-driven-development brand-guidelines canvas-design claude-api mcp-builder web-artifacts-builder webapp-testing parallel-ci-triage parallel-code-review parallel-exploring parallel-test-fixing setting-up-ci setting-up-terraform codebase-onboarding token-budget-advisor; do
            if [ -L "$path/$retired" ]; then
                rm -rf "${path:?}/${retired:?}"
                print_warning "Removed retired $retired link from $path"
            elif [ -f "$path/$retired/SKILL.md" ] && grep -q "^name: *$retired\$" "$path/$retired/SKILL.md"; then
                rm -rf "${path:?}/${retired:?}"
                print_warning "Removed retired $retired copy from $path"
            fi
        done
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
    echo "  Updates: ai-rules skill links + submodules + golang + Anthropic + Superpowers + humanizer + task-observer"
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
