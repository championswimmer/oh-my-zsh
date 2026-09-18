#!/usr/bin/env bash
# Installs this personal oh-my-zsh setup onto a new machine.
#
# Usage:
#   git clone --recurse-submodules <this-repo-url> ~/.oh-my-zsh
#   ~/.oh-my-zsh/install.sh
#   ~/.oh-my-zsh/install.sh --uninstall   # reverse it
#
# What it does:
#   1. Makes sure this repo lives at ~/.oh-my-zsh and its plugin/theme submodules are cloned.
#   2. Detects macOS vs Linux and picks the matching .zshrc / .profile (/ .zprofile).
#   3. Installs those to $HOME, merging into any existing files instead of clobbering them.
#      Whenever a destination file already existed (merged or appended), the old
#      version is preserved as a <dest>.bak.<timestamp> file first.
#   4. Installs .p10k.zsh to $HOME (p10k.omp.json already lives inside this repo, no copy needed).
#   5. If oh-my-posh (used as the prompt in the installed .zshrc) isn't already
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
for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=true ;;
    *)
      echo "error: unknown argument '$arg'"
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

  # -------------------------------------------------------------------------
  # 1. Make sure plugin/theme submodules are cloned
  # -------------------------------------------------------------------------

  if [[ -d .git ]]; then
    echo "Initializing/updating git submodules (plugins + powerlevel10k)..."
    git submodule update --init --recursive
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

# record_state DEST BACKUP_OR_NONE
record_state() {
  echo "$1|$2" >> "$STATE_FILE"
}

# Looks for a one-shot LLM CLI we can use for smart merges. Empty string if none found.
detect_merge_tool() {
  if command -v claude >/dev/null 2>&1; then
    echo "claude"
  elif command -v codex >/dev/null 2>&1; then
    echo "codex"
  else
    echo ""
  fi
}

MERGE_TOOL="$(detect_merge_tool)"

run_merge_tool() {
  local tool="$1" prompt="$2"
  case "$tool" in
    claude) claude -p "$prompt" 2>/dev/null ;;
    codex)  codex exec "$prompt" 2>/dev/null ;;
  esac
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

# install_dotfile SRC DEST LABEL
install_dotfile() {
  local src="$1" dest="$2" label="$3"

  if [[ ! -f "$src" ]]; then
    echo "  -> skipping $label: $src not found in repo."
    return
  fi

  if [[ ! -s "$dest" ]]; then
    cp "$src" "$dest"
    record_state "$dest" "NONE"
    echo "  -> installed $label to $dest"
    return
  fi

  echo "$dest already exists and is not empty."

  # Preserve the pre-existing file no matter which merge path is taken below.
  local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$dest" "$backup"
  record_state "$dest" "$backup"

  if [[ -n "$MERGE_TOOL" ]]; then
    echo "  Detected '$MERGE_TOOL' CLI on this machine."
    echo "  It can merge your existing $label with the new one intelligently instead of just appending."
    echo "  Note: this sends the full contents of both files (existing $dest may contain secrets/API keys) to $MERGE_TOOL in one-shot mode."
    read -r -p "  Use $MERGE_TOOL to merge $label? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      local prompt
      prompt="You are merging two shell config files, both meant to end up as $dest.
FILE A is the user's EXISTING file already on this machine.
FILE B is the NEW file being installed from the user's personal dotfiles repo.

Merge them into a single valid file that:
- keeps every export, alias, PATH addition, and plugin/tool setup from BOTH files
- de-duplicates exact duplicate lines and obviously-conflicting settings (same variable set twice, same plugin listed twice), preferring FILE B's value on a genuine conflict since it's the newer config
- preserves existing comments and structure where reasonable
- is a plain, directly-sourceable shell file

Output ONLY the final merged file's raw contents. No explanation, no markdown code fences.

===== FILE A (existing $dest) =====
$(cat "$dest")

===== FILE B (new, from $src) =====
$(cat "$src")
"

      local tmp_out
      tmp_out="$(mktemp)"
      if run_merge_tool "$MERGE_TOOL" "$prompt" > "$tmp_out" && [[ -s "$tmp_out" ]]; then
        cp "$tmp_out" "$dest"
        rm -f "$tmp_out"
        echo "  -> merged $label using $MERGE_TOOL. Your old file was kept at $backup"
        echo "  !! Please double-check $dest — an LLM did this merge, verify it looks right."
        return
      else
        rm -f "$tmp_out"
        echo "  $MERGE_TOOL merge failed or produced no output; falling back to appending instead."
        append_fallback "$src" "$dest" "$label"
        echo "  Your old file was kept at $backup"
        return
      fi
    fi
  fi

  append_fallback "$src" "$dest" "$label"
  echo "  Your old file was kept at $backup"
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

  echo ""
  echo "Uninstall done. $OMZ_DIR and its submodules were left untouched — remove that yourself if you want it fully gone."
  exit 0
fi

# Fresh state for this install run (so re-running install doesn't pile up stale entries).
: > "$STATE_FILE"

# ---------------------------------------------------------------------------
# 4. Install oh-my-posh via Homebrew if it's missing
# ---------------------------------------------------------------------------

if ! command -v oh-my-posh >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo ""
    echo "oh-my-posh isn't installed, but the .$OS.zshrc being installed uses it as the prompt."
    read -r -p "Install it now via 'brew install oh-my-posh'? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      brew install oh-my-posh
    else
      echo "  -> skipping oh-my-posh install. The prompt line in .$OS.zshrc will fail until you install it yourself."
    fi
  else
    echo "warning: oh-my-posh isn't installed and 'brew' isn't available either; skipping. Install oh-my-posh yourself, or the prompt line in .$OS.zshrc will fail."
  fi
fi

# ---------------------------------------------------------------------------
# 5. Install .zshrc / .profile (/ .zprofile on macOS) / .p10k.zsh
# ---------------------------------------------------------------------------

install_dotfile "$OMZ_DIR/.$OS.zshrc"   "$HOME/.zshrc"   ".zshrc"
install_dotfile "$OMZ_DIR/.$OS.profile" "$HOME/.profile" ".profile"

if [[ "$OS" == "macos" ]]; then
  install_dotfile "$OMZ_DIR/.macos.zprofile" "$HOME/.zprofile" ".zprofile"
fi

# p10k.omp.json is referenced by the zshrc as ~/.oh-my-zsh/p10k.omp.json, so it
# already lives in the right place inside this repo — nothing to copy there.
# .p10k.zsh (used only if you switch back from oh-my-posh to powerlevel10k) is
# referenced as ~/.p10k.zsh, so it does need to land in $HOME.
install_dotfile "$OMZ_DIR/.p10k.zsh" "$HOME/.p10k.zsh" ".p10k.zsh"

echo ""
echo "Done. Open a new shell (or 'source ~/.zshrc') to pick up the changes."
echo "If any files were merged or appended above, go review them (backups were kept as <file>.bak.<timestamp>)."
