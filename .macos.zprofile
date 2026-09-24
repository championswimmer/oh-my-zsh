# Zsh does not read ~/.profile on its own.
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile"

# Added by Toolbox App
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi
