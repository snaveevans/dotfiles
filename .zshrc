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
)

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

source $ZSH/oh-my-zsh.sh
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# User configuration
unsetopt share_history

# Set zle to vi mode
# setopt vi
# bindkey -v

_git-status() {
    zle backward-kill-line
    BUFFER="git status"
	zle accept-line
}

_zen-git-remote-branch() {
	local command="$BUFFER"
    zle backward-kill-line
	local branch=$(git branch --remotes | fzf --height 40% | sed 's:remotes/origin/::g'| sed 's:origin/::g' | xargs)
	if [ ${#branch} -ge 1 ]; then
		# zle -U "$command $branch"
		zle -U "$command$branch"
		zle vi-end-of-line
	fi
	# zle accept-line
}

_zen-git-local-branch() {
	local command="$BUFFER"
    zle backward-kill-line
	local branch=$(git branch --list | fzf --height 40% | sed 's:remotes/origin/::g'| sed 's:origin/::g' | xargs)
	if [ ${#branch} -ge 1 ]; then
		# zle -U "$command $branch"
		zle -U "$command$branch"
		zle vi-end-of-line
	fi
	# zle accept-line
}

_zen-j() {
	zle backward-kill-line
	local jump=$(j --stat | fzf --height 40% | cut -d '/' -f2-)
	# echo $jump
	if [ ${#jump} -ge 1 ]; then
		zle -U "cd /$jump"
		zle vi-end-of-line
	fi
	zle accept-line
}

_zen-accept-autosuggest() {
	zle autosuggest-accept
	zle accept-line
}

q() {
	zle accept-line
}

# zle-line-init() { zle -K vicmd; }

# zle -N zle-line-init
zle -N _git-status
zle -N _zen-git-remote-branch
zle -N _zen-git-local-branch
zle -N _zen-j
# zle -N _zen-accept-autosuggest
zle -N q

bindkey -M vicmd 'st' _git-status
bindkey -M vicmd '_' vi-beginning-of-line
bindkey -M vicmd 'g_' vi-end-of-line
bindkey -M vicmd ',j' _zen-j

bindkey -M emacs '^h' fzf-history-widget
bindkey -M emacs '^j' fzf-file-widget
bindkey -M emacs '^k' _zen-git-remote-branch
bindkey -M emacs '^l' _zen-git-local-branch
bindkey '^ ' autosuggest-accept
# bindkey '^\r' _zen-accept-autosuggest

alias tabn='open . -a iterm'
alias gcob="gco beta"
alias gbda="git branch --no-color --merged | command grep -vE \"^(\*|\s*(master|develop|dev|beta)\s*$)\" | command xargs -n 1 git branch -d"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
autoload -Uz compinit
compinit

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
