
export GITHUB_USER="championswimmer"

# Let Hub reuse the active championswimmer token from GitHub CLI without
# copying the credential into this file or exporting it to every process.
hub() {
  local github_token
  github_token="$(command gh auth token --hostname github.com --user championswimmer)" || return
  GITHUB_TOKEN="$github_token" command hub "$@"
}

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if (( ! ${fpath[(I)/usr/local/share/zsh/site-functions]} )); then
  FPATH=/usr/local/share/zsh/site-functions:$FPATH
fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# autoload -U compinit && compinit


# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="spaceship"
# ZSH_THEME="powerlevel10k/powerlevel10k"


# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

export NVM_AUTO_USE=true
export NVM_LAZY_LOAD=true

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(
	match_prev_cmd
	completion
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	dotenv
	direnv
	git
	github
	zsh-completions
# brew
	docker
	zsh-nvm
#	npm
	zsh-npm-scripts-autocomplete
	rbenv
	bun
	zsh-llm-assist
	zsh-autosuggestions
)

# zsh-autocomplete must be sourced BEFORE oh-my-zsh (it runs its own compinit).
source $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

source $ZSH/oh-my-zsh.sh

# Fix: zsh-autocomplete creates history-search-backward (the Alt+Up widget) inside a
# precmd hook that runs after zsh-autosuggestions' one-time widget binding pass, and
# zsh-autocomplete puts it on autosuggestions' ignore list, so it never gets wrapped and
# a pending ghost suggestion is left stranded (as real-looking text) after the Alt+Up
# menu's ';' suffix while cycling matches. Un-ignore it and re-bind after it's created.
_fix_autosuggest_history_menu() {
  ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(${ZSH_AUTOSUGGEST_IGNORE_WIDGETS:#history-search-backward})
  _zsh_autosuggest_bind_widgets
}
add-zsh-hook precmd _fix_autosuggest_history_menu

# Autocomplete
bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

# Shift+Right takes next word of suggestion
bindkey "$terminfo[kRIT]" forward-word

# Place this AFTER sourcing zsh-autocomplete
# zstyle ':completion:*:*:*:*:parameters' verbose no
zstyle ':completion:*:parameters' list-colors '=*=90'

# ZSH LLM Assist Configuration
export ZSH_LLM_CLI_TOOL="gemini" # copilot, gemini, claude, codex
export ZSH_LLM_CLI_MODEL="gemini-3-flash"
# export ZSH_LLM_CLI_DEBUG=true
bindkey '^_' llm_explain # bind Option+? to explain
bindkey '^@' llm_suggest # bind Option+Space to suggest


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#alias pg_start='brew services start postgresql'
#alias pg_stop='brew services stop postgresql'
#alias pg_restart='brew services restart postgresql'
#alias bash='/opt/homebrew/bin/bash -l'

alias nicedate='date "+ %Y-%m-%d_%H:%M:%p"'
alias ls='ls --color -p'

command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"

unalias git

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"


# Load Powerlevel10k configuration.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# bun completions
[ -s "$HOME/.oh-my-zsh/completions/_bun" ] && source "$HOME/.oh-my-zsh/completions/_bun"

export PATH="$HOME/.local/bin:$PATH"

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# Use oh-my-posh instead of powerlevel10k
setopt TRANSIENT_RPROMPT
eval "$(oh-my-posh init zsh --config '~/.oh-my-zsh/p10k.omp.json')"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# GitHub MCP server auth (reuses gh CLI keyring token)
export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)

if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"

  # `wt switch --create` rejects an existing branch. Switch normally when the
  # branch exists instead: Worktrunk will reuse its linked worktree, or create
  # one for an existing branch that is not currently checked out.
  wt-cmd() {
    (( $# >= 2 )) || { print -u2 'usage: wt-cmd <claude|codex|pi> <branch> [--base <branch>] [args...]'; return 2; }
    local agent=$1 branch=$2 base=''
    local -a agent_args
    shift 2
    case $agent in claude|codex|pi) ;; *) print -u2 'usage: wt-cmd <claude|codex|pi> <branch> [--base <branch>] [args...]'; return 2 ;; esac

    # `--base` belongs to Worktrunk, while everything else remains an argument
    # to the agent. A `--` stops wrapper parsing so an agent can still receive
    # its own `--base` option.
    while (( $# )); do
      case $1 in
        --base)
          (( $# >= 2 )) || { print -u2 'wt-cmd: --base requires a branch'; return 2; }
          base=$2
          shift 2
          ;;
        --base=*)
          base=${1#--base=}
          [[ -n $base ]] || { print -u2 'wt-cmd: --base requires a branch'; return 2; }
          shift
          ;;
        --)
          shift
          agent_args+=("$@")
          break
          ;;
        *)
          agent_args+=("$1")
          shift
          ;;
      esac
    done

    if command git show-ref --verify --quiet "refs/heads/$branch"; then
      [[ -z $base ]] || { print -u2 "wt-cmd: $branch already exists; --base only applies when creating a branch"; return 2; }
      wt switch "$branch" --execute "$agent" -- "${agent_args[@]}"
    elif [[ -n $base ]]; then
      wt switch --create "$branch" --base "$base" --execute "$agent" -- "${agent_args[@]}"
    else
      wt switch --create "$branch" --execute "$agent" -- "${agent_args[@]}"
    fi
  }
  # Agent subcommands retain Worktrunk's directory-switching and completion behavior.
  # Keep a copy of Worktrunk's shell wrapper so normal subcommands retain its
  # directory-switching and dynamically generated completion behavior.
  functions -c wt _wt_worktrunk
  wt() {
    case ${1-} in
      claude|codex|pi)
        local agent=$1
        shift
        wt-cmd "$agent" "$@"
        ;;
      *) _wt_worktrunk "$@" ;;
    esac
  }

  # Worktrunk's own `switch` completion includes branches that are not linked
  # worktrees. Agent commands intentionally complete only active worktrees.
  _wt_active_worktree_names() {
    local line
    while IFS= read -r line; do
      case $line in
        'branch refs/heads/'*) print -r -- "${line#branch refs/heads/}" ;;
      esac
    done < <(command git worktree list --porcelain 2>/dev/null)
  }
  _wt_complete_active_worktree() {
    local -a worktrees
    worktrees=("${(@f)$(_wt_active_worktree_names)}")
    (( $#worktrees )) && _describe -t worktrees 'active worktree' worktrees
  }
  _wt_complete_local_branch() {
    local -a branches
    branches=("${(@f)$(command git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)}")
    (( $#branches )) && _describe -t branches 'local branch' branches
  }
  _wt_complete() {
    local -a agents
    agents=(claude codex pi)
    if (( CURRENT == 2 )); then
      _wt_lazy_complete "$@"
      _describe -t agents agent agents
    elif (( CURRENT == 3 )) && [[ ${words[2]} == (claude|codex|pi) ]]; then
      _wt_complete_active_worktree
    elif (( CURRENT == 4 )) && [[ ${words[2]} == (claude|codex|pi) && ${words[3]} == --base ]]; then
      _wt_complete_local_branch
    else
      _wt_lazy_complete "$@"
    fi
  }
  compdef _wt_complete wt
fi
