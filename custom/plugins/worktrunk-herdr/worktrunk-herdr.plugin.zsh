# worktrunk-herdr — Worktrunk shell integration, agent shortcuts and herdr bridge.
#
#   wt  <claude|codex|pi> <branch> [--base <ref>] [agent args...]
#       Create/reuse a Worktrunk worktree and run the agent in THIS terminal.
#   wth [<claude|codex|pi>] <branch> [--base <ref>] [--space <name>] [agent args...]
#       Create/reuse a Worktrunk worktree, open it in a new herdr space (named
#       with --space/-s, else the branch's last '/'-separated segment), and
#       optionally start the agent there.
#       This terminal stays where it is.
#
# Worktrunk runs the project's pre-start hooks in both cases. Everything after
# a literal `--` is passed to the agent untouched (so it can get its own --base).

(( $+commands[wt] )) || return 0

eval "$(command wt config shell init zsh)"

typeset -ga _WT_AGENTS=(claude codex pi)

# Parse `<branch> [--base <ref>] [args...]`.
# Sets: _wt_branch, _wt_base, _wt_args (array). $1 is the caller name for errors.
_wt_parse() {
  local caller=$1; shift
  typeset -g _wt_branch=$1 _wt_base=''
  typeset -ga _wt_args=()
  shift
  while (( $# )); do
    case $1 in
      --base)
        (( $# >= 2 )) || { print -u2 "$caller: --base requires a branch"; return 2; }
        _wt_base=$2; shift 2 ;;
      --base=*)
        _wt_base=${1#--base=}
        [[ -n $_wt_base ]] || { print -u2 "$caller: --base requires a branch"; return 2; }
        shift ;;
      --) shift; _wt_args+=("$@"); break ;;
      *)  _wt_args+=("$1"); shift ;;
    esac
  done
}

# Build the `wt switch` arguments for $_wt_branch/$_wt_base into _wt_switch.
# `wt switch --create` rejects an existing branch, so switch normally then:
# Worktrunk reuses its linked worktree or creates one for the existing branch.
_wt_switch_args() {
  local caller=$1
  typeset -ga _wt_switch=()
  if command git show-ref --verify --quiet "refs/heads/$_wt_branch"; then
    [[ -z $_wt_base ]] || { print -u2 "$caller: $_wt_branch already exists; --base only applies when creating a branch"; return 2; }
    _wt_switch=("$_wt_branch")
  else
    _wt_switch=(--create "$_wt_branch")
    [[ -z $_wt_base ]] || _wt_switch+=(--base "$_wt_base")
  fi
}

# wt <agent> <branch> ... — agent runs in the current terminal.
wt-cmd() {
  local usage='usage: wt <claude|codex|pi> <branch> [--base <ref>] [args...]'
  (( $# >= 2 )) && (( ${_WT_AGENTS[(Ie)$1]} )) || { print -u2 $usage; return 2; }
  local agent=$1; shift
  _wt_parse wt "$@" && _wt_switch_args wt || return
  # --execute bypasses shell functions, so add herdr scrollback flags here.
  local -a reply=()
  (( $+functions[_herdr_scrollback_flags] )) && _herdr_scrollback_flags "$agent" "${_wt_args[@]}"
  _wt_worktrunk switch "${_wt_switch[@]}" --execute "$agent" -- "${reply[@]}" "${_wt_args[@]}"
}

# Parse wth's worktree options plus its herdr-space option.  A space is always
# created; --space overrides the default name (the branch's last '/'-separated
# segment).
_wth_parse() {
  local caller=$1; shift
  typeset -g _wt_branch=$1 _wt_base='' _wth_space=''
  typeset -ga _wt_args=()
  shift
  while (( $# )); do
    case $1 in
      --base)
        (( $# >= 2 )) || { print -u2 "$caller: --base requires a branch"; return 2; }
        _wt_base=$2; shift 2 ;;
      --base=*)
        _wt_base=${1#--base=}
        [[ -n $_wt_base ]] || { print -u2 "$caller: --base requires a branch"; return 2; }
        shift ;;
      -s|--space)
        (( $# >= 2 )) || { print -u2 "$caller: $1 requires a space name"; return 2; }
        _wth_space=$2; shift 2 ;;
      --space=*)
        _wth_space=${1#--space=}
        [[ -n $_wth_space ]] || { print -u2 "$caller: --space requires a space name"; return 2; }
        shift ;;
      --) shift; _wt_args+=("$@"); break ;;
      *)  _wt_args+=("$1"); shift ;;
    esac
  done
}

# wth [agent] <branch> ... — open in a new herdr space, optionally starting
# the agent.  The space is unnamed unless --space/-s is supplied.
wth() {
  if [[ ${1-} == (-h|--help) ]]; then
    print -r -- 'wth — open a branch in a NEW herdr space (this terminal stays put)
  wth [agent] <branch> [--base <ref>] [--space <name>] [-- agent args]
  space name: --space/-s, else last /-segment of the branch
  agents: claude codex pi'
    return 0
  fi
  local usage='usage: wth [claude|codex|pi] <branch> [--base <ref>] [--space <name>] [args...]'
  local agent=''
  if (( $# >= 1 )) && (( ${_WT_AGENTS[(Ie)$1]} )); then agent=$1; shift; fi
  (( $# >= 1 )) || { print -u2 $usage; return 2; }
  (( $+commands[herdr] )) || { print -u2 'wth: herdr not found'; return 1; }
  (( $+commands[jq] ))    || { print -u2 'wth: jq not found'; return 1; }
  _wth_parse wth "$@" && _wt_switch_args wth || return
  if [[ -z $agent ]] && (( $#_wt_args )); then
    print -u2 "wth: unexpected arguments without an agent: ${_wt_args[*]}"; return 2
  fi
  # Default space name: last '/'-separated segment of the branch.
  [[ -n $_wth_space ]] || _wth_space=${_wt_branch##*/}

  # 1. Worktrunk: create/reuse the worktree (runs pre-start hooks).
  local out wtpath root ws pane
  out=$(command wt switch "${_wt_switch[@]}" --no-cd --yes --format json) || return
  wtpath=$(print -r -- "$out" | jq -r '.path // empty')
  [[ -d $wtpath ]] || { print -u2 'wth: worktrunk returned no path'; return 1; }

  # 2. Make a fresh herdr space, then open the checkout in it.  Specifying a
  #    workspace prevents Herdr from reusing a space where this worktree is
  #    already open.
  local -a space_args=(--label "$_wth_space")
  out=$(herdr workspace create "${space_args[@]}" --focus) || return
  ws=$(print -r -- "$out" | jq -r '.result.workspace.workspace_id // .result.workspace_id // empty')
  [[ -n $ws ]] || { print -u2 'wth: could not find the new herdr space'; return 1; }
  root=$(command git -C "$wtpath" worktree list --porcelain | sed -n '1s/^worktree //p')
  out=$(herdr worktree open --workspace "$ws" --cwd "$root" --path "$wtpath" --focus) || return
  print "opened $_wt_branch in new herdr space${_wth_space:+ ($_wth_space)} ($wtpath)"
  [[ -n $agent ]] || return 0

  # 3. The worktree opens in a fresh tab in the new space; start the agent in
  #    that tab's root pane.
  pane=$(print -r -- "$out" | jq -r '.result.root_pane.pane_id // .result.pane.pane_id // empty')
  [[ -n $pane ]] || { print -u2 'wth: could not find a herdr pane to run the agent in'; return 1; }
  local -a cmd=("$agent" "${_wt_args[@]}")
  herdr pane run "$pane" "${(j: :)${(q-)cmd[@]}}" >/dev/null &&
    print "started $agent in $pane"
}

# Keep Worktrunk's wrapper (directory switching, dynamic completion) for all
# normal subcommands; route agent names to wt-cmd.
functions -c wt _wt_worktrunk
wt() {
  # -h: concise wrapper help; --help still reaches Worktrunk itself.
  if [[ ${1-} == -h ]]; then
    print -r -- 'wt — run an agent in a worktree, in THIS terminal
  wt <agent> <branch> [--base <ref>] [-- agent args]
  agents: claude codex pi
  anything else (incl. --help) goes to worktrunk itself'
    return 0
  fi
  if (( ${_WT_AGENTS[(Ie)${1-}]} )); then wt-cmd "$@"; else _wt_worktrunk "$@"; fi
}

# --- completion ----------------------------------------------------------------
# Worktrunk's own `switch` completion includes branches that are not linked
# worktrees. Agent commands complete only active worktrees (plus local branches
# for wth, which is also used to create new workspaces).
_wt_active_worktree_names() {
  local line
  while IFS= read -r line; do
    [[ $line == 'branch refs/heads/'* ]] && print -r -- "${line#branch refs/heads/}"
  done < <(command git worktree list --porcelain 2>/dev/null)
}
_wt_complete_active_worktree() {
  local -a worktrees=("${(@f)$(_wt_active_worktree_names)}")
  (( $#worktrees )) && _describe -t worktrees 'active worktree' worktrees
}
_wt_complete_local_branch() {
  local -a branches=("${(@f)$(command git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)}")
  (( $#branches )) && _describe -t branches 'local branch' branches
}
_wt_complete() {
  if (( CURRENT == 2 )); then
    _wt_lazy_complete "$@"
    _describe -t agents agent _WT_AGENTS
  elif (( CURRENT == 3 )) && (( ${_WT_AGENTS[(Ie)${words[2]}]} )); then
    _wt_complete_active_worktree
  elif (( CURRENT == 4 )) && (( ${_WT_AGENTS[(Ie)${words[2]}]} )) && [[ ${words[3]} == --base ]]; then
    _wt_complete_local_branch
  else
    _wt_lazy_complete "$@"
  fi
}
_wth_complete() {
  local i=2
  (( ${_WT_AGENTS[(Ie)${words[2]}]} )) && i=3
  if (( CURRENT == 2 )); then
    _describe -t agents agent _WT_AGENTS
    _wt_complete_local_branch
  elif (( CURRENT == i )); then
    _wt_complete_local_branch
  elif [[ ${words[CURRENT-1]} == --base ]]; then
    _wt_complete_local_branch
  elif [[ ${words[CURRENT-1]} == (-s|--space) ]]; then
    _message 'new herdr space name'
  elif (( CURRENT > i )); then
    _describe -t options option '--base[base branch]:branch' '--space=[new herdr space name]:space name' '-s[new herdr space name]:space name'
  fi
}
compdef _wt_complete wt
compdef _wth_complete wth
