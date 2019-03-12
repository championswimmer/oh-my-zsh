# oh-my-zsh Customized Bureau Theme

### NVM
ZSH_THEME_NVM_PROMPT_PREFIX="(node-"
ZSH_THEME_NVM_PROMPT_SUFFIX=")"

### RVM
ZSH_THEME_RVM_PROMPT_PREFIX="("
ZSH_THEME_RVM_PROMPT_SUFFIX=""

### Git
ZSH_THEME_GIT_PROMPT_PREFIX="[%{$fg_bold[green]%}±%{$reset_color%}%{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}]"

ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%} চ%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%} দ%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[cyan]%}▴%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}▾%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}•%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNSTAGED="%{$fg[yellow]%}•%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[red]%}•%{$reset_color%}"

### Prompt
if [[ $EUID -eq 0 ]]; then
  _USERNAME="%{$fg_bold[red]%}%n"
  _LIBERTY="%{$fg[red]%}#"
else
  _USERNAME="%{$fg_bold[white]%}%n"
  _LIBERTY="%{$fg[green]%}$"
fi
_USERNAME="$_USERNAME%{$reset_color%}"
_LIBERTY="$_LIBERTY%{$reset_color%}"

setopt prompt_subst
PROMPT="${_USERNAME} > $_LIBERTY "
RPROMPT="[%*]"

bureau_precmd () {
  _PATH="%{$fg_bold[white]%}%~%{$reset_color%}"
  print
  print -rP "${_PATH} $(git_prompt_status)$(git_prompt_info) $(nvm_prompt_info) $(rvm_prompt_info)"
}

autoload -U add-zsh-hook
add-zsh-hook precmd bureau_precmd