#!/usr/bin/env bash

set -euo pipefail

OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-darwin.sh

Bootstrap macOS packages, shell dependencies, and defaults for this dotfiles repo.
This does not link tracked config into $HOME.
EOF
}

clone_if_missing() {
  local repo_url="$1"
  local dest="$2"
  local extra_args=()

  shift 2
  if [[ $# -gt 0 ]]; then
    extra_args=("$@")
  fi

  if [[ -d "$dest" ]]; then
    log "Skipping existing repo: $dest"
    return 0
  fi

  git clone "${extra_args[@]}" "$repo_url" "$dest"
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Skipping existing oh-my-zsh install"
    return 0
  fi

  log "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OH_MY_ZSH_INSTALL_URL")" "" --unattended
}

install_zsh_addons() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  log "Installing zsh plugins and themes..."
  mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

  clone_if_missing \
    https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    "$zsh_custom/plugins/fast-syntax-highlighting"
  clone_if_missing \
    https://github.com/zsh-users/zsh-autosuggestions \
    "$zsh_custom/plugins/zsh-autosuggestions"
  clone_if_missing \
    https://github.com/Aloxaf/fzf-tab \
    "$zsh_custom/plugins/fzf-tab"
  clone_if_missing \
    https://github.com/spaceship-prompt/spaceship-prompt.git \
    "$zsh_custom/themes/spaceship-prompt" \
    --depth=1
  clone_if_missing \
    https://github.com/spaceship-prompt/spaceship-vi-mode.git \
    "$zsh_custom/plugins/spaceship-vi-mode"

  ln -snf \
    "$zsh_custom/themes/spaceship-prompt/spaceship.zsh-theme" \
    "$zsh_custom/themes/spaceship.zsh-theme"
}

install_packages() {
  command -v brew >/dev/null 2>&1 || die "Homebrew is required. Install brew first, then rerun this script."

  log "Installing macOS packages via brew bundle..."
  brew bundle --file=/dev/stdin <<'EOF'
tap "jdx/tap"
tap "jesseduffield/lazygit"

brew "git"
brew "bitwarden-cli"
brew "asdf"
brew "bat"
brew "chezmoi"
brew "fzf"
brew "gawk"
brew "gh"
brew "unbound"
brew "gnutls"
brew "libassuan"
brew "libksba"
brew "pinentry"
brew "gnupg"
brew "go"
brew "httpie"
brew "jq"
brew "lazygit"
brew "maven"
brew "neovim"
brew "pipx"
brew "ripgrep"
brew "scc"
brew "stylua"
brew "tree"
brew "usage"
brew "zsh"
cask "alfred"
cask "bitwarden"
cask "brave-browser"
cask "firefox"
cask "font-fira-code-nerd-font"
cask "hammerspoon"
cask "kitty"
cask "obsidian"
EOF
}

apply_defaults() {
  log "Applying macOS defaults..."

  # This enables cmd+ctrl+left mouse to be able to drag on the entire window.
  defaults write -g "NSWindowShouldDragOnGesture" -bool true

  # enable key repeat
  defaults write -g "ApplePressAndHoldEnabled" 0

  # Key repeat speed
  defaults write -g "InitialKeyRepeat" -int 25
  defaults write -g "KeyRepeat" -int 2

  # only show active applications
  defaults write com.apple.dock "static-only" -bool true

  # Set the size of the dock to 40 points
  defaults write com.apple.dock "tilesize" -int 40

  # Setup dock autohide
  defaults write com.apple.dock "autohide" -bool true
  defaults write com.apple.dock "autohide-delay" -int 0
  defaults write com.apple.dock "autohide-time-modifier" -float "0.12"

  # Drag with 3 finger drag
  defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool true

  killall Dock || true
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
fi

install_packages
install_oh_my_zsh
install_zsh_addons
apply_defaults

log "macOS bootstrap complete."
