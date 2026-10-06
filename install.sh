#!/usr/bin/env bash
# Installs this personal oh-my-zsh setup onto a new machine.
#
# Usage:
#   git clone --recurse-submodules <this-repo-url> ~/.oh-my-zsh
#   ~/.oh-my-zsh/install.sh
#   ~/.oh-my-zsh/install.sh --update      # git pull + submodules to latest upstream + re-apply to $HOME (idempotent)
#   ~/.oh-my-zsh/install.sh --uninstall   # reverse it
#
# Options: --yes (no prompts, accept AI merge), --tool=claude|codex|pi|none.
#
# Re-running is idempotent: files already identical to the repo are skipped.
# For changed files a 3-way merge (git merge-file) is used: the "base" is the
# repo version installed last time (kept in ~/.oh-my-zsh-install-base; else the
# repo as of the newest <dest>.bak.<timestamp>, i.e. all commits since the last
# backup are applied; else the pre-pull commit on --update), so lines REMOVED upstream are removed locally
# while machine-local additions (secrets, PATH tweaks) are kept. Only real
# conflicts go to the AI tool; if that is unavailable
# the new repo version is applied plus your local-only added lines (nothing the
# repo removed is kept).
#
# What it does:
#   1. Makes sure this repo lives at ~/.oh-my-zsh and its plugin/theme submodules are cloned.
#   2. Detects macOS vs Linux and picks the matching .zshrc / .profile (/ .zprofile).
#   3. Installs those to $HOME, merging into any existing files instead of clobbering them.
#      Whenever a destination file already existed (merged or appended), the old
#      version is preserved as a <dest>.bak.<timestamp> file first.
#   4. Installs .p10k.zsh to $HOME (p10k.omp.json already lives inside this repo, no copy needed).
#   5. When an existing dotfile needs merging, detects Claude Code, Codex, and
#      Pi, then lets the user choose an installed tool (or skip AI merging).
#   6. If oh-my-posh (used as the prompt in the installed .zshrc) isn't already
#      installed and Homebrew is available, asks to install it via 'brew install
#      oh-my-posh'. --uninstall does not remove it.
#
# --uninstall reverses step 3/4 using the state file this script writes at
# $HOME/.oh-my-zsh-install-state during install: for each file that install
# touched, it restores the backup that was made if there was a pre-existing
# file, or removes the file entirely if it was installed fresh. The state
# file is deleted once uninstall finishes, so running --uninstall again (or
# on a machine this script never installed onto) is a safe no-op rather than
# guessing and possibly deleting a real file. It does not touch
# $HOME/.oh-my-zsh itself or the git submodules.

set -euo pipefail
shopt -s nullglob

UNINSTALL=false
UPDATE=false
NO_PULL=false
ASSUME_YES=false
TOOL_ARG=""
for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=true ;;
    --update)    UPDATE=true ;;
    --no-pull)   NO_PULL=true ;;   # internal: set when re-exec'd after pulling
    -y|--yes)    ASSUME_YES=true ;;
    --tool=*)    TOOL_ARG="${arg#--tool=}" ;;  # claude | codex | pi | none
    *)
      echo "error: unknown argument '$arg'"
      echo "usage: install.sh [--update] [--yes] [--tool=claude|codex|pi|none] [--uninstall]"
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# 0. Locate ourselves and make sure we end up at ~/.oh-my-zsh
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ_DIR="$HOME/.oh-my-zsh"

if ! $UNINSTALL; then
  if [[ "$SCRIPT_DIR" != "$OMZ_DIR" ]]; then
    if [[ -e "$OMZ_DIR" ]]; then
      echo "error: $OMZ_DIR already exists and this script is running from $SCRIPT_DIR."
      echo "Move or remove the existing $OMZ_DIR yourself, then re-run this script, to avoid clobbering anything."
      exit 1
    fi
    echo "Moving $SCRIPT_DIR -> $OMZ_DIR"
    mv "$SCRIPT_DIR" "$OMZ_DIR"
  fi

  cd "$OMZ_DIR"

  if $UPDATE && ! $NO_PULL && [[ -d .git ]]; then
    export OMZ_OLD_HEAD="$(git rev-parse HEAD)"
    echo "Updating repo (git pull --ff-only)..."
    git pull --ff-only || echo "warning: git pull failed (local changes/diverged?); continuing with the current checkout."
    # Re-exec so the (possibly updated) script is what actually runs.
    exec "$OMZ_DIR/install.sh" --no-pull "$@"
  fi

  # -------------------------------------------------------------------------
  # 1. Make sure plugin/theme submodules are cloned
  # -------------------------------------------------------------------------

  if [[ -d .git ]]; then
    echo "Initializing/updating git submodules (plugins + powerlevel10k)..."
    git submodule update --init --recursive
    if $UPDATE; then
      echo "Fetching latest upstream commits for submodules (--update)..."
      git submodule update --init --remote --jobs 4 \
        && git submodule update --init --recursive \
        || echo "warning: some submodules could not be advanced to their latest upstream; kept at the pinned commit."
    fi
  else
    echo "warning: $OMZ_DIR is not a git repo; skipping submodule init. Plugins under custom/plugins may be missing/empty."
  fi
fi

# ---------------------------------------------------------------------------
# 2. Detect OS
# ---------------------------------------------------------------------------

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)
    echo "error: unsupported OS '$(uname -s)'. This installer only handles macOS and Linux."
    exit 1
    ;;
esac

echo "Detected OS: $OS"

STATE_FILE="$HOME/.oh-my-zsh-install-state"

# ---------------------------------------------------------------------------
# 3. Helpers to install/merge a dotfile
# ---------------------------------------------------------------------------

BASE_DIR="$HOME/.oh-my-zsh-install-base"

# record_state DEST BACKUP_OR_NONE
# Only the FIRST entry per dest is kept, so --uninstall always restores the
# original pre-install file even after many updates.
record_state() {
  [[ -f "$STATE_FILE" ]] && grep -qF "$1|" "$STATE_FILE" && return 0
  echo "$1|$2" >> "$STATE_FILE"
}

ask_yes() {
  $ASSUME_YES && return 0
  [[ -t 0 ]] || return 1
  local reply
  read -r -p "$1 [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

# The selected one-shot LLM CLI for conflict/merge resolution. We wait to
# prompt until a merge is actually needed.
MERGE_TOOL=""
MERGE_TOOL_DECIDED=false

if [[ -n "$TOOL_ARG" ]]; then
  MERGE_TOOL_DECIDED=true
  if [[ "$TOOL_ARG" != none ]]; then
    if command -v "$TOOL_ARG" >/dev/null 2>&1; then MERGE_TOOL="$TOOL_ARG"
    else echo "warning: --tool=$TOOL_ARG not found; AI merging disabled."; fi
  fi
fi

choose_merge_tool() {
  local -a tools=()
  local tool choice index=1

  for tool in claude codex pi; do
    command -v "$tool" >/dev/null 2>&1 && tools+=("$tool")
  done

  MERGE_TOOL_DECIDED=true
  (( ${#tools[@]} )) || return 0

  if [[ ! -t 0 ]]; then
    echo "  Detected ${tools[*]} CLI, but this is non-interactive; pass --tool=<name> to enable AI merging."
    return 0
  fi

  echo "  Detected AI merge tools: ${tools[*]}"
  echo "  Choose one to merge shell config files (or skip AI merging):"
  for tool in "${tools[@]}"; do
    echo "    $index) $tool"
    ((index++))
  done
  echo "    s) skip AI merging"

  while true; do
    read -r -p "  Tool [1-${#tools[@]}/s]: " choice || { echo ""; return 0; }
    case "$choice" in
      [sS]|"") return 0 ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#tools[@]} )); then
          MERGE_TOOL="${tools[choice - 1]}"
          echo "  -> selected '$MERGE_TOOL' for AI merges."
          return 0
        fi
        echo "  Please enter a number from 1 to ${#tools[@]}, or s to skip."
        ;;
    esac
  done
}

run_merge_tool() {
  local tool="$1" prompt="$2"
  case "$tool" in
    claude) claude -p "$prompt" 2>/dev/null ;;
    codex)  codex exec "$prompt" 2>/dev/null ;;
    pi)     pi --print "$prompt" 2>/dev/null ;;
  esac
}

# ai_merge PROMPT OUT_FILE  -> 0 if the tool produced sane output
ai_merge() {
  local prompt="$1" out="$2"
  $MERGE_TOOL_DECIDED || choose_merge_tool
  [[ -n "$MERGE_TOOL" ]] || return 1
  echo "  Note: this sends file contents (which may include secrets) to $MERGE_TOOL in one-shot mode."
  ask_yes "  Use $MERGE_TOOL for this merge?" || return 1
  run_merge_tool "$MERGE_TOOL" "$prompt" > "$out" || return 1
  [[ -s "$out" ]] || return 1
  # Reject leftover conflict markers or markdown fences.
  if grep -qE '^(<<<<<<<|>>>>>>>)|^```' "$out"; then return 1; fi
  # Syntax check when possible.
  if command -v zsh >/dev/null 2>&1; then zsh -n "$out" 2>/dev/null || return 1; fi
  return 0
}

# append_fallback SRC DEST LABEL
append_fallback() {
  local src="$1" dest="$2" label="$3"
  {
    echo ""
    echo "# ---- Appended by oh-my-zsh install.sh on $(date) — new $label from $src ----"
    cat "$src"
  } >> "$dest"
  echo "  -> appended new $label content to the bottom of $dest."
  echo "  !! Please review $dest by hand: your old config is above, the new one below, and there may be duplicate/conflicting settings."
}

# bak_epoch YYYYmmddHHMMSS -> epoch seconds (GNU and BSD date)
bak_epoch() {
  date -d "${1:0:4}-${1:4:2}-${1:6:2} ${1:8:2}:${1:10:2}:${1:12:2}" +%s 2>/dev/null \
    || date -j -f %Y%m%d%H%M%S "$1" +%s 2>/dev/null || true
}

save_base() { mkdir -p "$BASE_DIR"; cp "$1" "$BASE_DIR/$(basename "$2")"; }

# apply_result NEW_CONTENT DEST BACKUP LABEL HOWTO
apply_result() {
  local new="$1" dest="$2" backup="$3" label="$4" how="$5"
  echo "  Changes to $dest:"
  diff -u "$dest" "$new" | sed 's/^/    /' | head -60 || true
  cp "$new" "$dest"
  echo "  -> $label updated ($how). Old file kept at $backup"
}

# install_dotfile SRC DEST LABEL
install_dotfile() {
  local src="$1" dest="$2" label="$3"
  local name; name="$(basename "$src")"

  if [[ ! -f "$src" ]]; then
    echo "  -> skipping $label: $src not found in repo."
    return
  fi

  if [[ ! -s "$dest" ]]; then
    cp "$src" "$dest"
    record_state "$dest" "NONE"
    save_base "$src" "$src"
    echo "  -> installed $label to $dest"
    return
  fi

  if cmp -s "$src" "$dest"; then
    save_base "$src" "$src"
    echo "  -> $label already up to date."
    return
  fi

  # Find the base (the repo version this machine's file was last in sync with):
  #   1. repo version recorded at last install (~/.oh-my-zsh-install-base)
  #   2. repo version as of the newest <dest>.bak.<timestamp> (git history)
  #   3. repo version before this --update's pull
  local base="" tmpbase="" base_commit="" base_how=""
  if [[ -f "$BASE_DIR/$name" ]]; then
    base="$BASE_DIR/$name"; base_how="last installed version"
  else
    local lastbak epoch
    lastbak="$(ls -1 "$dest".bak.* 2>/dev/null | grep -E '\.bak\.[0-9]{14}$' | sort | tail -1 || true)"
    if [[ -n "$lastbak" ]]; then
      epoch="$(bak_epoch "${lastbak##*.bak.}")"
      [[ -z "$epoch" ]] || base_commit="$(git -C "$OMZ_DIR" rev-list -1 --before="$epoch" HEAD -- "$name" 2>/dev/null || true)"
      [[ -z "$base_commit" ]] || base_how="repo as of last backup (${lastbak##*.bak.})"
    fi
    if [[ -z "$base_commit" && -n "${OMZ_OLD_HEAD:-}" ]]; then
      base_commit="$OMZ_OLD_HEAD"; base_how="repo before this update"
    fi
    if [[ -n "$base_commit" ]]; then
      tmpbase="$(mktemp)"
      if git -C "$OMZ_DIR" show "$base_commit:$name" > "$tmpbase" 2>/dev/null; then base="$tmpbase"
      else rm -f "$tmpbase"; tmpbase=""; base_commit=""; fi
    fi
  fi

  # Repo commits touching this file since the base (shown + given to the AI as context).
  local history=""
  if [[ -n "$base_commit" ]]; then
    history="$(git -C "$OMZ_DIR" log --format='%h %ad %s' --date=short "$base_commit..HEAD" -- "$name" 2>/dev/null || true)"
  fi
  if [[ -n "$base" ]]; then
    echo "  Base for $label: $base_how."
    if [[ -n "$history" ]]; then
      echo "  Repo commits to apply since then:"; echo "$history" | sed 's/^/    /'
    fi
  fi

  # Repo version unchanged since last install: local file is just customized.
  if [[ -n "$base" ]] && cmp -s "$base" "$src"; then
    echo "  -> $label: repo version unchanged; keeping your local $dest as is."
    save_base "$src" "$src"
    [[ -z "$tmpbase" ]] || rm -f "$tmpbase"
    return
  fi

  echo "$dest differs from the repo version."
  local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$dest" "$backup"
  record_state "$dest" "$backup"

  local out; out="$(mktemp)"

  if [[ -n "$base" ]]; then
    # 3-way merge: local changes are kept, upstream additions AND removals apply.
    local rc=0
    git merge-file -p -L "local ($dest)" -L "previous repo version" -L "new repo version" \
      "$dest" "$base" "$src" > "$out" || rc=$?
    if (( rc == 0 )); then
      apply_result "$out" "$dest" "$backup" "$label" "3-way merge, no conflicts"
      save_base "$src" "$src"
    elif (( rc > 0 )); then
      echo "  3-way merge of $label has $rc conflict(s)."
      local prompt="Resolve the git merge conflicts in this shell config file ($dest). The sections between <<<<<<< and >>>>>>> show the LOCAL machine version and the NEW repo version. Prefer the NEW repo version on genuine conflicts, but keep machine-local additions (exports, secrets, PATH entries). Anything the new repo version deliberately removed must stay removed. Output ONLY the final raw file, no explanation, no markdown fences, no conflict markers.
${history:+
Repo commits applied since the local file was last in sync (for context):
$history
}
$(cat "$out")"
      local res; res="$(mktemp)"
      if ai_merge "$prompt" "$res"; then
        apply_result "$res" "$dest" "$backup" "$label" "conflicts resolved by $MERGE_TOOL; please verify"
        save_base "$src" "$src"
      else
        # Deterministic fallback: new repo file + lines you added locally.
        # Anything the repo removed stays removed.
        { cat "$src"
          local extra; extra="$(diff --unchanged-line-format= --old-line-format= --new-line-format='%L' "$base" "$dest" | grep -vxFf "$src" | grep -v '^[[:space:]]*$' | grep -v '^# ---- Local additions' || true)"
          if [[ -n "$extra" ]]; then
            echo ""
            echo "# ---- Local additions kept by install.sh on $(date) ----"
            echo "$extra"
          fi
        } > "$res"
        apply_result "$res" "$dest" "$backup" "$label" "new repo version + your local-only lines (conflict fallback)"
        save_base "$src" "$src"
      fi
      rm -f "$res"
    else
      cp "$src" "$dest.new"
      echo "  -> merge failed; left $dest untouched. New repo version at $dest.new"
    fi
    rm -f "$out"; [[ -z "$tmpbase" ]] || rm -f "$tmpbase"
    return
  fi

  # No base known (first install onto a pre-existing file): AI merge or append.
  local prompt="You are merging two shell config files, both meant to end up as $dest.
FILE A is the user's EXISTING file already on this machine.
FILE B is the NEW file being installed from the user's personal dotfiles repo.

Merge them into a single valid file that:
- treats FILE B as authoritative: it is fine to DROP lines/blocks from A that B no longer has or that are superseded by B (old hardcoded tokens, obsolete wrappers, etc.)
- still keeps clearly machine-local content from A (secrets, API keys, local PATH additions, tool setup) that doesn't conflict with B
- de-duplicates exact duplicate lines and conflicting settings (same variable set twice, same plugin listed twice), preferring FILE B's value on a genuine conflict
- preserves existing comments and structure where reasonable
- is a plain, directly-sourceable shell file

Output ONLY the final merged file's raw contents. No explanation, no markdown code fences.

===== FILE A (existing $dest) =====
$(cat "$dest")

===== FILE B (new, from $src) =====
$(cat "$src")
"
  if ai_merge "$prompt" "$out"; then
    apply_result "$out" "$dest" "$backup" "$label" "merged by $MERGE_TOOL; please verify"
  else
    append_fallback "$src" "$dest" "$label"
    echo "  Your old file was kept at $backup"
  fi
  save_base "$src" "$src"
  rm -f "$out"
}

# uninstall_dotfile DEST BACKUP_OR_NONE
uninstall_dotfile() {
  local dest="$1" backup="$2"

  if [[ "$backup" != "NONE" ]]; then
    if [[ -e "$backup" ]]; then
      mv "$backup" "$dest"
      echo "  -> restored $dest from $(basename "$backup")"
    else
      echo "  -> $dest: expected backup $backup is missing, leaving $dest untouched."
    fi
  else
    rm -f "$dest"
    echo "  -> removed $dest (it was installed fresh, no prior version to restore)"
  fi
}

if $UNINSTALL; then
  # -------------------------------------------------------------------------
  # 4. Uninstall: replay the state file recorded during install, then drop it
  # -------------------------------------------------------------------------

  if [[ ! -f "$STATE_FILE" ]]; then
    echo "No install state found at $STATE_FILE — nothing to uninstall."
    echo "(Either this script never installed anything here, or --uninstall already ran.)"
    exit 0
  fi

  while IFS='|' read -r dest backup; do
    [[ -n "$dest" ]] || continue
    uninstall_dotfile "$dest" "$backup"
  done < "$STATE_FILE"

  rm -f "$STATE_FILE"
  rm -rf "$BASE_DIR"

  echo ""
  echo "Uninstall done. $OMZ_DIR and its submodules were left untouched — remove that yourself if you want it fully gone."
  exit 0
fi

# Keep any existing state file: it holds the ORIGINAL backups for --uninstall.
touch "$STATE_FILE"

# ---------------------------------------------------------------------------
# 4. Install oh-my-posh via Homebrew if it's missing
# ---------------------------------------------------------------------------

BREW_BIN="$(command -v brew 2>/dev/null || true)"
if [[ -z "$BREW_BIN" ]]; then
  if [[ "$OS" == linux ]]; then
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
      if [[ -x "$candidate" ]]; then BREW_BIN="$candidate"; break; fi
    done
  elif [[ "$(uname -m)" == arm64 ]]; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [[ -x "$candidate" ]]; then BREW_BIN="$candidate"; break; fi
    done
  else
    for candidate in /usr/local/bin/brew /opt/homebrew/bin/brew; do
      if [[ -x "$candidate" ]]; then BREW_BIN="$candidate"; break; fi
    done
  fi
fi

if ! command -v oh-my-posh >/dev/null 2>&1; then
  if [[ -n "$BREW_BIN" ]]; then
    echo ""
    echo "oh-my-posh isn't installed, but the .$OS.zshrc being installed uses it as the prompt."
    if ask_yes "Install it now via 'brew install oh-my-posh'?"; then
      "$BREW_BIN" install oh-my-posh
    else
      echo "  -> skipping oh-my-posh install. The prompt line in .$OS.zshrc will fail until you install it yourself."
    fi
  else
    echo "warning: oh-my-posh isn't installed and 'brew' isn't available either; skipping. Install oh-my-posh yourself, or the prompt line in .$OS.zshrc will fail."
  fi
fi

# ---------------------------------------------------------------------------
# 5. Install .zshrc / .profile / .zprofile / .p10k.zsh
# ---------------------------------------------------------------------------

install_dotfile "$OMZ_DIR/.$OS.zshrc"   "$HOME/.zshrc"   ".zshrc"
install_dotfile "$OMZ_DIR/.$OS.profile" "$HOME/.profile" ".profile"
install_dotfile "$OMZ_DIR/.$OS.zprofile" "$HOME/.zprofile" ".zprofile"

# p10k.omp.json is referenced by the zshrc as ~/.oh-my-zsh/p10k.omp.json, so it
# already lives in the right place inside this repo — nothing to copy there.
# .p10k.zsh (used only if you switch back from oh-my-posh to powerlevel10k) is
# referenced as ~/.p10k.zsh, so it does need to land in $HOME.
install_dotfile "$OMZ_DIR/.p10k.zsh" "$HOME/.p10k.zsh" ".p10k.zsh"

echo ""
echo "Done. Open a new shell (or 'source ~/.zshrc') to pick up the changes."
echo "If any files were merged or appended above, go review them (backups were kept as <file>.bak.<timestamp>)."
