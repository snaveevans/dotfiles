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

  apply_general_defaults
  apply_input_defaults
  apply_screenshot_defaults
  apply_finder_defaults
  apply_dock_extra_defaults
  apply_app_defaults

  # SystemUIServer picks up the screencapture location change.
  local app
  for app in Dock Finder SystemUIServer; do
    killall "$app" >/dev/null 2>&1 || true
  done
}

apply_general_defaults() {
  # Sidebar icon size: medium
  defaults write -g NSTableViewDefaultSizeMode -int 2

  # Always show scrollbars
  defaults write -g AppleShowScrollBars -string "Always"

  # Faster window resize for Cocoa apps
  defaults write -g NSWindowResizeTime -float 0.001

  # Expand save and print panels by default
  defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
  defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write -g PMPrintingExpandedStateForPrint -bool true
  defaults write -g PMPrintingExpandedStateForPrint2 -bool true

  # Save to disk, not iCloud, by default
  defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false

  # Quit the printer app once jobs complete
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  # Skip the "are you sure you want to open this application?" dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # Disable smart text substitutions that get in the way when typing code
  defaults write -g NSAutomaticCapitalizationEnabled -bool false
  defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

  # Require password immediately after sleep or screen saver begins
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Menu bar clock format
  defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  H:mm"
}

apply_input_defaults() {
  # Tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
  defaults write -g com.apple.mouse.tapBehavior -int 1

  # Full keyboard access for all controls (e.g. Tab in modal dialogs)
  defaults write -g AppleKeyboardUIMode -int 3
}

apply_screenshot_defaults() {
  local screenshots_dir="$HOME/screenshots"

  mkdir -p "$screenshots_dir"
  defaults write com.apple.screencapture location -string "$screenshots_dir"
}

apply_finder_defaults() {
  # New windows open in the home directory
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

  # Disable window and Get Info animations
  defaults write com.apple.finder DisableAllAnimations -bool true

  # Show drives, servers, and removable media on the desktop
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

  # Show hidden files and all extensions
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write -g AppleShowAllExtensions -bool true

  # Status bar, path bar, and full POSIX path in the title
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  # Folders first, search current folder, no extension-change warning
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Spring loading for directories, with no delay
  defaults write -g com.apple.springing.enabled -bool true
  defaults write -g com.apple.springing.delay -float 0

  # No .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Open a Finder window when a volume is mounted
  defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
  defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
  defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

  # List view by default
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

  # No warning before emptying the Trash
  defaults write com.apple.finder WarnOnEmptyTrash -bool false

  # Show ~/Library
  chflags nohidden "$HOME/Library"

  # Expand the General, Open with, and Sharing & Permissions info panes
  defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true
}

apply_dock_extra_defaults() {
  # Hover highlight for stack grid view
  defaults write com.apple.dock mouse-over-hilite-stack -bool true

  # Scale minimize effect, minimizing into the app icon
  defaults write com.apple.dock mineffect -string "scale"
  defaults write com.apple.dock minimize-to-application -bool true

  # Spring loading for all Dock items
  defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

  # Open-app indicator lights, no launch animation
  defaults write com.apple.dock show-process-indicators -bool true
  defaults write com.apple.dock launchanim -bool false

  # Faster Mission Control; keep Spaces in a fixed order
  defaults write com.apple.dock expose-animation-duration -float 0.1
  defaults write com.apple.dock mru-spaces -bool false

  # Translucent icons for hidden apps; no recent apps
  defaults write com.apple.dock showhidden -bool true
  defaults write com.apple.dock show-recents -bool false
}

apply_app_defaults() {
  # Terminal.app: UTF-8 only
  defaults write com.apple.terminal StringEncodings -array 4

  # Time Machine: don't offer new disks as backup volumes
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  # Activity Monitor: show main window, CPU Dock icon, all processes by CPU
  defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
  defaults write com.apple.ActivityMonitor IconType -int 5
  defaults write com.apple.ActivityMonitor ShowCategory -int 0
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
  defaults write com.apple.ActivityMonitor SortDirection -int 0

  # TextEdit: plain text, UTF-8
  defaults write com.apple.TextEdit RichText -int 0
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

  # Don't open Photos when devices are plugged in
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
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
