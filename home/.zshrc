# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

case "$OSTYPE" in
  darwin*)
    ZSH_THEME="spaceship"
    ;;
  linux*)
    # Use starship prompt on Linux (installed separately from shell config).
    if command -v starship >/dev/null 2>&1; then
      eval "$(starship init zsh)"
    fi
    ;;
esac

plugins=(
  fast-syntax-highlighting
  fzf
  fzf-tab
  git
  zsh-autosuggestions
)

case "$OSTYPE" in
  darwin*)
    plugins+=(spaceship-vi-mode)
    ;;
esac

plugins+=(chezmoi)

source "$ZSH/oh-my-zsh.sh"

case "$OSTYPE" in
  darwin*)
    # if type brew &>/dev/null; then
    #   FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    # fi
    ;;
esac

# source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

function _clear () {
  zle && { zle send-break; zle -R }
}

function _re-source () {
  printf "reloading...\n"
  exec zsh
}
zle -N _re-source

function _search() {
  grep -rl --exclude-dir=node_modules "$1" | fzf
}
zle -N _search

function _kill-port () {
  local process_id

  case "$OSTYPE" in
    darwin*)
      process_id="$(lsof -P -i TCP -s TCP:LISTEN | fzf -m | awk '{print $2}')"
      ;;
    *)
      process_id="$(ss -tlnp | fzf -m | awk '{print $7}' | grep -oP '\d+' | head -1)"
      ;;
  esac

  if [[ -n $process_id ]]
  then
    eval "kill -9 $process_id"
    echo "killed pid:$process_id"
  else
    echo "no pid selected"
  fi
  _clear
}
zle -N _kill-port

function _kitty-opener () {
  kitty-opener
}
zle -N _kitty-opener

# User configuration
unsetopt share_history

# vi mode
bindkey -v
case "$OSTYPE" in
  darwin*)
    spaceship add --before char vi_mode
    eval spaceship_vi_mode_enable
    ;;
esac

bindkey '^h' backward-char
bindkey '^l' forward-char
bindkey '^b' backward-word
bindkey '^w' forward-word
bindkey -M viins '^ ' autosuggest-accept
bindkey -M viins '^ko' _kill-port
bindkey -M vicmd '_' vi-beginning-of-line
bindkey -M vicmd 'g_' vi-end-of-line
bindkey -M viins '^kp' _kitty-opener

bindkey -s '^g' '$(git branch | fzf)^M'
bindkey -s '^o' 'nvim^M'

alias cz=chezmoi
alias tf=terraform
alias pn=pnpm
alias lg=lazygit
alias e="$EDITOR"
# alias e='NVIM_APPNAME=lvim nvim'
# alias cat="bat"
alias re=_re-source
alias se=_search

case "$OSTYPE" in
  darwin*)
    alias ij='open -a "IntelliJ IDEA" .'
    ;;
  *)
    alias ij='idea .'
    ;;
esac

case "$OSTYPE" in
  darwin*)
    # alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Helpers/jsc'
    ;;
esac

# Initialize asdf
case "$OSTYPE" in
  darwin*)
    . "$(brew --prefix)/opt/asdf/libexec/asdf.sh"
    ;;
  *)
    . "$HOME/.asdf/asdf.sh"
    ;;
esac

# add JAVA_HOME dynamically to path
if [[ -f ~/.asdf/plugins/java/set-java-home.zsh ]]; then
  . ~/.asdf/plugins/java/set-java-home.zsh
fi

# Optional per-machine interactive shell overrides.
if [[ -r "$HOME/.config/zsh/local.zsh" ]]; then
  source "$HOME/.config/zsh/local.zsh"
fi

# autoload -Uz compinit; compinit
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
