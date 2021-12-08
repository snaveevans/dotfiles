PATH="$HOME/bin:${PATH}"
PATH="/usr/local/bin:${PATH}"
PATH="/usr/local/share/dotnet:${PATH}"
PATH="$HOME/.dotnet/tools:${PATH}"
PATH="$HOME/bin/jdk/Contents/Home/bin:${PATH}"
PATH="/Library/Frameworks/Mono.framework/Versions/Current/Commands:${PATH}"
PATH="$HOME/.cargo/bin:${PATH}"
PATH="/usr/local/opt/make/libexec/gnubin:${PATH}"
PATH="/usr/local/opt/openssl@1.1/bin:${PATH}"
export PATH

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
export ASPNETCORE_ENVIRONMENT=Development
export ASPNETCORE_HTTPS_PORT=5001
export JAVA_HOME="/usr/bin"
export MONO_GAC_PREFIX="/usr/local"
export BAT_THEME="TwoDark"

# Setting fd as the default source for fzf
export FZF_BASE='/usr/local/bin/fzf'
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
  export FZF_CTRL_T_COMMAND="rg --files --follow --hidden --glob=\!.git"
fi
