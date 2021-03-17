# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-syntax-highlighting
  docker
  docker-compose
  npm
  autojump
  fzf
)

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

source $ZSH/oh-my-zsh.sh
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# User configuration
unsetopt share_history

bindkey '^ ' autosuggest-accept
bindkey '^h' backward-char
bindkey '^l' forward-char
bindkey '^b' backward-word
bindkey '^e' forward-word

alias vi='nvim'
alias tabn='open . -a iterm'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
autoload -Uz compinit
compinit

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion
