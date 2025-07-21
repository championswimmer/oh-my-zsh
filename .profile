eval "$(/opt/homebrew/bin/brew shellenv)"


export PATH="$HOME/bin:${PATH}"

export HOMEBREW_NO_AUTO_UPDATE=1

# export C="/opt/homebrew/opt/llvm/bin/clang" CXX="/opt/homebrew/opt/llvm/bin/clang++"
export C="/usr/bin/clang" CXX="/usr/bin/clang++"
export CMAKE_C_COMPILER="$C" CMAKE_CXX_COMPILER="$CXX"

export CMAKE_POLICY_VERSION_MINIMUM=3.10

export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

#curl
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# coreutils
export PATH="$PATH:/opt/homebrew/opt/coreutils/libexec/gnubin"

# glib
export PATH="/opt/homebrew/opt/glib/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/glib/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/glib/include $CPPFLAGS"


# binutils
export PATH="$PATH:/opt/homebrew/opt/binutils/bin"
export LDFLAGS="-L/opt/homebrew/opt/binutils/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/binutils/include $CPPFLAGS"

export LDFLAGS="-L/opt/homebrew/opt/readline/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# zlib 
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig:$PKG_CONFIG_PATH"

# FFI
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib $LDFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

# LLVM 
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib ${LDFLAGS}"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include ${CPPFLAGS}"

# JPEG Turbo 
export LDFLAGS="-L/opt/homebrew/opt/libjpeg-turbo/lib ${LDFLAGS}"
export CPPFLAGS="-I/opt/homebrew/opt/libjpeg-turbo/include ${CPPFLAGS}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libjpeg-turbo/lib/pkgconfig:$PKG_CONFIG_PATH"

# SQlite
export LDFLAGS="-L/opt/homebrew/opt/sqlite/lib  $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/sqlite/include  $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/sqlite/lib/pkgconfig:$PKG_CONFIG_PATH"

# openssl
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include  $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:$PKG_CONFIG_PATH"

# Python
export PATH="/opt/homebrew/opt/python@3/libexec/bin/:$PATH"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/build-tools/latest:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"

# export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@1.1"

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#export EDITOR=nano
export EDITOR="/usr/local/bin/mate -w"


export GITHUB_TOKEN="xxx"
export V18_GITHUB_TOKEN="xxx"
export TWITTER_BEARER_TOKEN="xxx"
export VSCODE_MARKETPLACE_TOKEN="xxx"
export BITBUCKET_KEY="xxx"
export BITBUCKET_SECRET="xxx"
export ANTHROPIC_API_KEY="xxx"
export GOOGLE_AI_API_KEY="xxx"
export GROQ_API_KEY="xxx"
export OPENAI_API_KEY="xxx"
export XAI_API_KEY="xxx"

export CHROME_EXECUTABLE="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
# export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

export NVM_DIR="$HOME/.nvm"

# Gradle
export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"
export GRADLE_USER_HOME="$HOME/.gradle"

# Go
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:${PATH}"

# Rust
export PATH="$HOME/.cargo/bin:${PATH}"
export VCPKG_ROOT="$HOME/bin/vcpkg" 

export PATH="${PATH}:$HOME/.pub-cache/bin"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:${PATH}"
alias curltime="curl -w \"@$HOME/.curl-time-format.txt\" -o /dev/null -s "
alias hs="npx live-server"

alias hub_cli="/opt/homebrew/bin/hub"
function hub() {
  if [[ $(pwd) =~ "$HOME/Development/Viacom18.*" ]]; then
	  	GHU="Arnav-Gupta_viacom18"
    	GHT=$V18_GITHUB_TOKEN
  	else
		GHU="championswimmer"
	  	GHT=$GITHUB_TOKEN
  	fi

  GITHUB_USER=$GHU GITHUB_TOKEN=$GHT hub_cli $@
}

alias gh_cli=$(which gh)
function gh() {
  if [[ $(pwd) =~ "$HOME/Development/Viacom18.*" ]]; then
	  	GHU="Arnav-Gupta_viacom18"
	  	GHT=$V18_GITHUB_TOKEN
  	else
		GHU="championswimmer"
	  	GHT=$GITHUB_TOKEN
  	fi

  GITHUB_USER=$GHU GITHUB_TOKEN=$GHT gh_cli $@
}

ssh-add -q --apple-use-keychain $HOME/.ssh/id_ed25519


# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

. "$HOME/.cargo/env"
