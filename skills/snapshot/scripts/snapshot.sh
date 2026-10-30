#!/usr/bin/env bash
# Cheap, LLM-free bookkeeping for the snapshot skill: throttle gate, run lock,
# repo preparation, per-source change detection, staging, and commit of a sync run.
set -euo pipefail

THROTTLE_MIN="${SNAPSHOT_THROTTLE_MIN:-60}"
LOCK_STALE_MIN="${SNAPSHOT_LOCK_STALE_MIN:-180}"
STATE_ROOT="${AGENT_STATE_DIR:-$HOME/.local/state/agents}"
GIT_CAP=200
FILE_CAP=500
PR_CAP=500
STATE_CAP=50

die() { echo "ERROR: $*" >&2; exit 1; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
epoch() { date -u -j -f %Y-%m-%dT%H:%M:%SZ "$1" +%s 2>/dev/null || date -u -d "$1" +%s; }
age_min() { echo $(( ( $(date -u +%s) - $(epoch "$1") ) / 60 )); }

jsonlist() { jq -nc '$ARGS.positional' --args "$@"; }
manifest() { echo "$1/manifest.json"; }
mjq() { local m; m=$(manifest "$1"); shift; [ -f "$m" ] && jq -r "$@" "$m" || echo ""; }
mput() {
  local dir=$1 m tmp; shift
  m=$(manifest "$dir"); tmp="$m.tmp.$$"
  mkdir -p "$dir"
  [ -f "$m" ] || echo '{"schema":1,"sources":{},"run":{}}' > "$m"
  jq "$@" "$m" > "$tmp" && mv "$tmp" "$m"
}
is_git() { git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || die "not a git checkout: $1"; }
default_ref() { git -C "$1" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main; }
capped() { awk -v cap="$1" 'NR<=cap {print} END {if (NR>cap) print "truncated=" NR-cap}'; }

# --- run lock -------------------------------------------------------------

lock_dir() { echo "$1/.lock"; }
lock_take() {
  local dir=$1 l started
  l=$(lock_dir "$dir"); mkdir -p "$dir"
  if mkdir "$l" 2>/dev/null; then now > "$l/started"; echo "$$" > "$l/pid"; return 0; fi
  started=$(cat "$l/started" 2>/dev/null || echo "")
  if [ -n "$started" ] && [ "$(age_min "$started")" -ge "$LOCK_STALE_MIN" ]; then
    rm -rf "$l"; mkdir "$l"; now > "$l/started"; echo "$$" > "$l/pid"
    echo "took over stale lock from $started"; return 0
  fi
  die "another sync holds the lock since ${started:-unknown} ($l)"
}
lock_drop() { rm -rf "$(lock_dir "$1")"; }

# --- gate / status --------------------------------------------------------

cmd_gate() {
  local dir=${1:?dir} l last age started
  l=$(lock_dir "$dir")
  if [ -d "$l" ]; then
    started=$(cat "$l/started" 2>/dev/null || echo "")
    if [ -z "$started" ] || [ "$(age_min "$started")" -lt "$LOCK_STALE_MIN" ]; then
      echo "LOCKED since=${started:-unknown}"; return
    fi
  fi
  [ -f "$(manifest "$dir")" ] || { echo "GO first-sync"; return; }
  if [ "$(mjq "$dir" '.run.status // ""')" = "incomplete" ]; then
    echo "RESUME started=$(mjq "$dir" '.run.started') error=$(mjq "$dir" '.run.error // "interrupted"')"
    return
  fi
  last=$(mjq "$dir" '.last_success // ""')
  [ -n "$last" ] || { echo "GO no-previous-success"; return; }
  age=$(age_min "$last")
  if [ "$age" -lt "$THROTTLE_MIN" ]; then
    echo "THROTTLED last_success=$last retry_in_min=$(( THROTTLE_MIN - age ))"
  else
    echo "GO last_success=$last"
  fi
}

cmd_status() {
  local dir=${1:?dir}
  [ -f "$(manifest "$dir")" ] || { echo "no snapshot at $dir"; return; }
  jq -r '"last_success: \(.last_success // "never")",
         "last_scanned: \(.last_scanned // "never")",
         "run: \(.run.status // "none")\(if .run.error then " (error: \(.run.error))" else "" end)",
         "mirror_pending: \((.mirror_pending // []) | join(", "))",
         "sources:",
         ((.sources // {}) | to_entries[] | "  \(.key): scanned \(.value.scanned // "never")")' "$(manifest "$dir")"
  [ -d "$(lock_dir "$dir")" ] && echo "lock: held since $(cat "$(lock_dir "$dir")/started" 2>/dev/null)"
  return 0
}

# --- repo preparation -----------------------------------------------------

cmd_refresh() {
  local repo=${1:?repo path} base
  is_git "$repo"
  git -C "$repo" fetch --quiet --prune origin || die "fetch failed: $repo"
  base=$(default_ref "$repo")
  echo "ref=$base @ $(git -C "$repo" rev-parse --short "$base")"
}

realdir() { local p=$1; case "$p" in "~"*) p="$HOME${p#\~}";; esac; (cd "$p" 2>/dev/null && pwd -P) || echo "$p"; }

# Lines "worktree <real path>" and "<repo name>#branch <name>" from open task state.
in_use_refs() {
  find "$STATE_ROOT" -maxdepth 2 -name STATE.md -not -path '*/_done/*' 2>/dev/null | while IFS= read -r f; do
    awk '/^## Repos & worktrees/{on=1; next} /^## /{on=0} on' "$f"
  done | while IFS= read -r line; do
    repo=$(printf '%s' "$line" | sed -E 's/^- *([^ |]+).*/\1/'); repo=${repo##*/}
    br=$(printf '%s' "$line" | grep -oE 'branch [^ |]+' | head -1 | cut -d' ' -f2 || true)
    wt=$(printf '%s' "$line" | grep -oE 'worktree [^ |]+' | head -1 | cut -d' ' -f2 || true)
    [ -n "$br" ] && echo "$repo#branch $br"
    [ -n "$wt" ] && echo "worktree $(realdir "$wt")"
  done
  return 0
}

cmd_prepare() {
  local repo=${1:?repo path}
  local base def cur slug name wt br top used
  is_git "$repo"
  git -C "$repo" fetch --quiet --prune origin || die "fetch failed: $repo"
  base=$(default_ref "$repo"); def=${base#origin/}
  cur=$(git -C "$repo" branch --show-current)
  slug=$(git -C "$repo" remote get-url origin | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')
  name=${slug##*/}
  top=$(realdir "$(git -C "$repo" rev-parse --show-toplevel)")
  used=$(in_use_refs)
  in_use() { printf '%s\n' "$used" | grep -xF "$1" >/dev/null; }

  if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "kept checkout on ${cur:-detached}: dirty; read $base"
  elif in_use "worktree $top" || { [ -n "$cur" ] && [ "$cur" != "$def" ] && in_use "$name#branch $cur"; }; then
    echo "kept checkout on ${cur:-detached}: in use; read $base"
  else
    if [ "$cur" != "$def" ]; then
      git -C "$repo" switch --quiet "$def" || die "cannot switch to $def in $repo"
      echo "switched ${cur:-detached} -> $def"
    fi
    git -C "$repo" pull --quiet --ff-only origin "$def" || die "pull --ff-only failed (diverged?) in $repo"
    echo "pulled $def @ $(git -C "$repo" rev-parse --short HEAD)"
  fi

  merged() {
    local b=$1 tip up
    tip=$(git -C "$repo" rev-parse "refs/heads/$b")
    [ "$(gh pr list -R "$slug" --state merged --head "$b" --limit 1 --json headRefOid -q '.[0].headRefOid' </dev/null 2>/dev/null)" = "$tip" ] && return 0
    git -C "$repo" merge-base --is-ancestor "$tip" "$base" || return 1
    up=$(git -C "$repo" config --get "branch.$b.merge" 2>/dev/null || true)
    [ -n "$up" ] && [ "$up" != "refs/heads/$def" ] && return 0
    git -C "$repo" reflog show --format=%gs "refs/heads/$b" 2>/dev/null | grep -E '^(commit|cherry-pick)|Merge made by' >/dev/null
  }

  git -C "$repo" worktree prune
  git -C "$repo" worktree list --porcelain \
    | awk '/^worktree /{w=substr($0,10)} /^branch /{print w "\t" substr($0,19)}' | tail -n +2 \
    | while IFS="$(printf '\t')" read -r wt br; do
        if in_use "worktree $(realdir "$wt")" || in_use "$name#branch $br"; then echo "kept worktree $wt ($br): in use"; continue; fi
        if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then echo "kept worktree $wt ($br): dirty"; continue; fi
        if merged "$br"; then
          git -C "$repo" worktree remove "$wt" && echo "removed worktree $wt ($br)"
        else
          echo "kept worktree $wt ($br): not merged"
        fi
      done

  git -C "$repo" for-each-ref refs/heads --format='%(refname:short)' | while IFS= read -r br; do
    [ "$br" = "$def" ] && continue
    in_use "$name#branch $br" && continue
    git -C "$repo" worktree list --porcelain | grep -x "branch refs/heads/$br" >/dev/null && continue
    if merged "$br"; then git -C "$repo" branch --quiet -D "$br" && echo "deleted branch $br"; fi
  done
}

# --- deltas ---------------------------------------------------------------

cmd_git_delta() {
  local repo=${1:?repo path} cursor=${2:--} days=${3:-} base head since=()
  is_git "$repo"
  base=$(default_ref "$repo")
  head=$(git -C "$repo" rev-parse "$base")
  echo "base=$base"
  echo "head=$head"
  if [ "$cursor" = "$head" ]; then echo "delta=unchanged"; return; fi
  if [ "$cursor" = "-" ] || ! git -C "$repo" merge-base --is-ancestor "$cursor" "$head" 2>/dev/null; then
    echo "delta=full"
    echo "## recent commits"
    [ -n "$days" ] && since=(--since="$days days ago")
    git -C "$repo" log --first-parent --format='%h %cI %an %s' ${since[@]+"${since[@]}"} -n "$GIT_CAP" "$head"
    return
  fi
  echo "delta=incremental"
  echo "## commits"
  git -C "$repo" log --first-parent --format='%h %cI %an %s' "$cursor..$head" | capped "$GIT_CAP"
  echo "## changed files"
  git -C "$repo" diff --name-status "$cursor" "$head" | capped "$FILE_CAP"
}

cmd_pr_delta() {
  local slug=${1:?owner/repo} dir=${2:?dir} key cur prev
  key="pr:$slug"
  cur=$(gh pr list -R "$slug" --state open --limit "$PR_CAP" \
    --json number,title,author,headRefName,headRefOid,updatedAt,isDraft,url) || die "gh pr list failed: $slug"
  prev=$(mjq "$dir" --arg k "$key" '.sources[$k].open // []')
  [ -n "$prev" ] || prev='[]'
  jq -n --argjson cur "$cur" --argjson prev "$prev" --argjson cap "$PR_CAP" '
    ($prev | map({key: (.number|tostring), value: .}) | from_entries) as $p
    | ($cur | length >= $cap) as $trunc
    | {
        truncated: $trunc,
        open: $cur,
        changed: [ $cur[] | select(($p[(.number|tostring)] == null)
                     or ($p[(.number|tostring)].headRefOid != .headRefOid)
                     or ($p[(.number|tostring)].updatedAt != .updatedAt)) | .number ],
        gone: (if $trunc then [] else
                [ $prev[] | .number as $n | select(($cur | map(.number) | index($n)) == null) | $n ] end)
      }'
}

cmd_state_delta() {
  local since=${1:--}; shift
  [ $# -gt 0 ] || die "state-delta needs at least one repo name"
  [ -d "$STATE_ROOT" ] || { echo "none"; return; }
  local ref newer=()
  ref=$(mktemp)
  if [ "$since" != "-" ]; then touch -d "$since" "$ref"; newer=(-newer "$ref"); fi
  find "$STATE_ROOT" -maxdepth 4 -name STATE.md ${newer[@]+"${newer[@]}"} 2>/dev/null \
    | while IFS= read -r f; do
        { grep -m1 '^repos:' "$f" || true; } | sed 's/^repos://' | tr ',' '\n' | sed 's/^ *//; s/ *$//' \
          | while IFS= read -r have; do
              for r in "$@"; do
                if [ "${have##*/}" = "${r##*/}" ]; then echo "$f"; break 2; fi
              done
            done
      done | sort -u | capped "$STATE_CAP"
  rm -f "$ref"
}

# --- run lifecycle --------------------------------------------------------

cmd_begin() {
  local dir=${1:?dir} st
  lock_take "$dir"
  st=$(mjq "$dir" '.run.status // ""')
  if [ "$st" = "incomplete" ] && [ -d "$dir/.staging" ]; then
    echo "resuming done_sources=$(mjq "$dir" '(.run.done_sources // []) | join(",")')"
    return
  fi
  rm -rf "$dir/.staging"; mkdir -p "$dir/.staging"
  for f in "$dir"/*.md; do [ -e "$f" ] && cp -p "$f" "$dir/.staging/"; done
  echo '{}' > "$dir/.staging/cursors.json"
  mput "$dir" --arg t "$(now)" '.run = {status: "incomplete", started: $t, done_sources: []} | .last_scanned = $t'
  echo "started staging=$dir/.staging"
}

cmd_mark() {
  local dir=${1:?dir} key=${2:?source key} val=${3:?cursor json} c tmp
  c="$dir/.staging/cursors.json"; [ -f "$c" ] || die "no active run; call begin first"
  tmp="$c.tmp.$$"
  jq --arg k "$key" --argjson v "$val" --arg t "$(now)" '.[$k] = ($v + {scanned: $t})' "$c" > "$tmp" && mv "$tmp" "$c"
  mput "$dir" --arg k "$key" '.run.done_sources = ((.run.done_sources // []) + [$k] | unique)'
  echo "marked $key"
}

cmd_abort() {
  local dir=${1:?dir} reason=${2:?reason}
  mput "$dir" --arg r "$reason" --arg t "$(now)" '.run.error = $r | .run.aborted = $t | .last_scanned = $t'
  lock_drop "$dir"
  if [ -d "$dir/.staging" ]; then
    echo "aborted: live files untouched; next sync resumes from staging"
  else
    echo "aborted before staging: live files untouched; nothing to resume"
  fi
}

STATUS_BEGIN='<!-- snapshot:status -->'
STATUS_END='<!-- /snapshot:status -->'
strip_status() { awk -v b="$STATUS_BEGIN" -v e="$STATUS_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$1"; }
write_status() {
  local dir=$1 idx="$1/index.md" blk tmp
  [ -f "$idx" ] || return 0
  blk=$(mktemp)
  { echo "$STATUS_BEGIN"; cmd_status "$dir"; echo "$STATUS_END"; } > "$blk"
  tmp="$idx.tmp.$$"
  if grep -qxF "$STATUS_BEGIN" "$idx"; then
    awk -v b="$STATUS_BEGIN" -v e="$STATUS_END" -v f="$blk" \
      '$0==b{while ((getline l < f) > 0) print l; skip=1; next} $0==e{skip=0; next} !skip{print}' "$idx" > "$tmp"
  else
    awk -v f="$blk" '
      function blk() { while ((getline l < f) > 0) print l }
      NR==1 && $0=="---" {fm=1; print; next}
      fm && $0=="---" {print; blk(); fm=0; done=1; next}
      NR==1 {blk(); done=1}
      {print}
      END {if (!done) blk()}' "$idx" > "$tmp"
  fi
  mv "$tmp" "$idx"; rm -f "$blk"
}

cmd_commit() {
  local dir=${1:?dir}
  local s="$dir/.staging" changed="" f b
  [ -d "$s" ] || die "no staging to commit"
  for f in "$s"/*.md; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    if [ ! -f "$dir/$b" ] || ! cmp -s <(strip_status "$f") <(strip_status "$dir/$b"); then changed="$changed $b"; fi
  done
  mput "$dir" --argjson ch "$(jsonlist $changed)" '.mirror_pending = (((.mirror_pending // []) + $ch) | unique)'
  for b in $changed; do mv "$s/$b" "$dir/$b"; done
  mput "$dir" --slurpfile c "$s/cursors.json" --arg t "$(now)" \
    '.sources = ((.sources // {}) * $c[0]) | .last_success = $t | .last_scanned = $t
     | .run = {status: "complete", started: .run.started, finished: $t}'
  rm -rf "$s"
  lock_drop "$dir"
  write_status "$dir"
  echo "changed:${changed:- none}"
}

cmd_mirrored() {
  local dir=${1:?dir}; shift
  mput "$dir" --argjson done "$(jsonlist "$@")" '.mirror_pending = ((.mirror_pending // []) - $done)'
  echo "mirror_pending=$(mjq "$dir" '(.mirror_pending // []) | join(",")')"
}

sub=${1:-}; shift || true
case "$sub" in
  gate) cmd_gate "$@";;
  status) cmd_status "$@";;
  refresh) cmd_refresh "$@";;
  prepare) cmd_prepare "$@";;
  git-delta) cmd_git_delta "$@";;
  pr-delta) cmd_pr_delta "$@";;
  state-delta) cmd_state_delta "$@";;
  begin) cmd_begin "$@";;
  mark) cmd_mark "$@";;
  abort) cmd_abort "$@";;
  commit) cmd_commit "$@";;
  mirrored) cmd_mirrored "$@";;
  *) cat >&2 <<'EOF'
usage: snapshot.sh <cmd> ...
  gate <dir>                         GO | RESUME | THROTTLED | LOCKED
  status <dir>                       manifest summary (run state, ages, sources)
  refresh <repo-path>                fetch --prune only; read mode reads origin/<default>
  prepare <repo-path>                sync only: switch idle clean checkout to default + pull --ff-only; drop merged local worktrees/branches
  git-delta <repo-path> <cursor|->   commits and changed files on origin/<default> since cursor (run prepare first)
  pr-delta <owner/repo> <dir>        open PRs + changed/gone vs manifest
  state-delta <since-iso|-> <repo>.. STATE.md files whose repos: header names these repos
  begin <dir>                        take the lock; start or resume a run (staging)
  mark <dir> <source-key> <json>     record a finished source and its new cursor
  abort <dir> <reason>               stop and release the lock; live files untouched
  commit <dir>                       promote changed files, advance cursors, write index status, release the lock
  mirrored <dir> <file>..            clear Hindsight mirror backlog
EOF
     exit 2;;
esac
