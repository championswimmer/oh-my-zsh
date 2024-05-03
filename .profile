eval "$(/opt/homebrew/bin/brew shellenv)"

export CXX=clang++

export PATH="$HOME/bin:${PATH}"

export HOMEBREW_NO_AUTO_UPDATE=1

export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export CPPFLAGS="-I/opt/homebrew/include $CPPFLAGS"
export LDFLAGS="-L/opt/homebrew/lib $LDFLAGS"

#curl 
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig:$PKG_CONFIG_PATH"

# coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"


# binutils
export PATH="/opt/homebrew/opt/binutils/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/binutils/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/binutils/include $CPPFLAGS"

export LDFLAGS="-L/opt/homebrew/opt/readline/lib $LDFLAGS"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include $CPPFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

export LDFLAGS="-L/opt/homebrew/opt/libffi/lib $LDFLAGS"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

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
export PATH="$ANDROID_HOME/tools:$PATH"
export PATH="$ANDROID_HOME/tools/bin:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"

# export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@1.1"

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#export EDITOR=nano
export EDITOR="/opt/homebrew/bin/mate -w"


export GITHUB_TOKEN="xxx"
export TARGET_GITHUB_TOKEN="xxx"
export SLICE_GITHUB_TOKEN="xxx"
export V18_GITHUB_TOKEN="xxx"
export TWITTER_BEARER_TOKEN="xxx"
export VSCODE_MARKETPLACE_TOKEN="xxx"
export BITBUCKET_KEY="xxx"
export BITBUCKET_SECRET="xxx"

export CHROME_EXECUTABLE="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
# export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

export NVM_DIR="$HOME/.nvm"

export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"
export GRADLE_USER_HOME="$HOME/.gradle"

export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:${PATH}"

export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:${PATH}"

alias curltime="curl -w \"@$HOME/.curl-time-format.txt\" -o /dev/null -s "

alias hub_cli=$(which hub)
function hub() {
  if [[ $(pwd) =~ "$HOME/Development/Slice.*" ]]; then
    	GHT=$SLICE_GITHUB_TOKEN
	elif [[ $(pwd) =~ "$HOME/Development/Viacom18.*" ]]; then
    	GHT=$V18_GITHUB_TOKEN
	else
	  	GHT=$GITHUB_TOKEN
  	fi

  GITHUB_TOKEN=$GHT hub_cli $@
}

alias gh_cli=$(which gh)
function gh() {
  if [[ $(pwd) =~ "$HOME/Development/Slice.*" ]]; then
    	GHT=$SLICE_GITHUB_TOKEN
  	else
	  	GHT=$GITHUB_TOKEN
  	fi

  GITHUB_TOKEN=$GHT gh_cli $@
}

ssh-add -q --apple-use-keychain $HOME/.ssh/id_rsa


# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

. "$HOME/.cargo/env"
