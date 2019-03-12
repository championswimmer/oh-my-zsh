# af-magic-mod.zsh-theme 
#
# af-magic.zsh-theme tweaked
#
# Original author: Andy Fleming (http://andyfleming.com/)
# Direct link: https://github.com/andyfleming/oh-my-zsh/blob/master/themes/af-magic.zsh-theme

if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="green"; fi
local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

# source: https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/dieter.zsh-theme
time_enabled="%(?.%{$fg[green]%}.%{$fg[red]%})%*%{$reset_color%}"
time_disabled="%{$fg[green]%}%*%{$reset_color%}"
time=$time_enabled

# ranger info
if [ -n "$RANGER_LEVEL" ]; then RANGERPROMPT='(ranger)'; else RANGERPROMPT=''; fi

# primary prompt
PROMPT='$FG[237]%{$reset_color%}$FG[032]%~\
$(git_prompt_info)\
%{$reset_color%}$RANGERPROMPT $FG[105]%(!.#.»)%{$reset_color%}
$ '
PROMPT2='%{$fg[red]%}\ %{$reset_color%}'
RPS1='${return_code}'


# color vars
eval my_blue='$FG[032]'
eval my_orange='$FG[214]'

# right prompt
NTTY=$(echo $TTY | egrep -o "\w+$")
RPROMPT='${time} %{$reset_color%}%n@%m($NTTY)%{$reset_color%}%'

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX="$FG[075](branch:"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="$my_orange*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$FG[075])%{$reset_color%}"
