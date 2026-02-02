# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Locale (fixes UTF-8 warnings)
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

. "$HOME/.local/bin/env"


# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/build-tools/latest:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

export EDITOR=nano
# export EDITOR="/opt/homebrew/bin/zed -w"

# Tokens
export GITHUB_TOKEN=""
export V18_GITHUB_TOKEN=""
export TWITTER_BEARER_TOKEN="xxx"
export VSCODE_MARKETPLACE_TOKEN="xxx"
export BITBUCKET_KEY="xxx"
export BITBUCKET_SECRET="xxx"

# AI Keys
export ANTHROPIC_API_KEY="sk-ant-api03--qjFNggAA"
export GOOGLE_GENAI_API_KEY="-"
export GOOGLE_AI_API_KEY="$GOOGLE_GENAI_API_KEY"
export GEMINI_API_KEY="$GOOGLE_GENAI_API_KEY"
export GROQ_API_KEY=""
export OPENAI_API_KEY="sk-proj--"
export XAI_API_KEY="xai-"
export PERPLEXITY_API_KEY="pplx-"
export DEEPINFRA_API_KEY=""
export OPENROUTER_API_KEY="sk-or-v1-"

export GOOGLE_MAPS_API_KEY=""

# export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"


# Gradle
export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"
export GRADLE_USER_HOME="$HOME/.gradle"

# Go
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:${PATH}"

# Rust
# export PATH="$HOME/.cargo/bin:${PATH}"
# export VCPKG_ROOT="$HOME/bin/vcpkg"
# export PATH="$VCPKG_ROOT:$PATH"
# . "$HOME/.cargo/env"

# export PATH="${PATH}:$HOME/.pub-cache/bin"
# export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:${PATH}"

alias curltime="curl -w \"@$HOME/.curl-time-format.txt\" -o /dev/null -s "
alias hs="npx live-server"

alias env_priv="env | cut -d= -f1"

# . "$HOME/.cargo/env"

# ---- SSH agent: one per login session ----
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add ~/.ssh/id_ed25519
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/championswimmer/.lmstudio/bin"
# End of LM Studio CLI section
