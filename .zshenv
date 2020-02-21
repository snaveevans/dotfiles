PATH="$HOME/bin:${PATH}"
PATH="/usr/local/bin:${PATH}"
PATH="/usr/local/share/dotnet:${PATH}"
PATH="$HOME/.dotnet/tools:${PATH}"
PATH="$HOME/bin/jdk/Contents/Home/bin:${PATH}"
PATH="/Library/Frameworks/Mono.framework/Versions/Current/Commands:${PATH}"
PATH="$HOME/.cargo/bin:${PATH}"
export PATH

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
export FZF_DEFAULT_COMMAND='ag --nocolor --hidden --ignore node_modules -g ""'
export ASPNETCORE_ENVIRONMENT=Development
export ASPNETCORE_HTTPS_PORT=5001
# export NODE_ENV=development
export JAVA_HOME="/usr/bin"
export LDFLAGS="-L/usr/local/opt/node@10/lib"
export CPPFLAGS="-I/usr/local/opt/node@10/include"
export MONO_GAC_PREFIX="/usr/local"
