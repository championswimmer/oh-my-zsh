# Zsh does not read ~/.profile on its own.
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile"

# Let zsh-autocomplete initialize completions after ~/.zshrc sets up fpath.
skip_global_compinit=1
