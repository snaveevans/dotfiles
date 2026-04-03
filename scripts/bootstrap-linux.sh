#!/usr/bin/env bash

set -euo pipefail

OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-linux.sh

Bootstrap Linux packages and shell dependencies for this dotfiles repo.
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

  log "Installing zsh plugins..."
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
}

install_asdf() {
  if [[ -d "$HOME/.asdf" ]]; then
    log "Skipping existing asdf install"
    return 0
  fi

  log "Installing asdf..."
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
}

install_kitty() {
  log "Installing Kitty terminal..."
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
}

install_bitwarden_cli() {
  local tmp_dir

  if command -v bw >/dev/null 2>&1; then
    log "Skipping existing Bitwarden CLI install"
    return 0
  fi

  log "Installing Bitwarden CLI..."

  if command -v snap >/dev/null 2>&1; then
    sudo snap install bw
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  curl -L "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o "$tmp_dir/bw.zip"
  unzip "$tmp_dir/bw.zip" -d "$tmp_dir"
  sudo install -m 0755 "$tmp_dir/bw" /usr/local/bin/bw
  rm -rf "$tmp_dir"
}

install_go() {
  local go_version

  log "Installing Go..."
  go_version="$(curl -s "https://go.dev/dl/?mode=json" | grep -o '"version": "go[^"]*"' | head -1 | sed 's/"version": "go//' | sed 's/"$//')"
  wget "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${go_version}.linux-amd64.tar.gz"
  rm "go${go_version}.linux-amd64.tar.gz"
}

install_lazygit() {
  local lazygit_version

  log "Installing lazygit..."
  lazygit_version="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${lazygit_version}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
}

install_github_cli() {
  log "Installing GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y gh
}

install_fd() {
  local fd_version

  log "Installing fd..."
  fd_version="$(curl -s "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')"
  wget "https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd_${fd_version}_amd64.deb"
  sudo dpkg -i "fd_${fd_version}_amd64.deb"
  rm "fd_${fd_version}_amd64.deb"
}

install_scc() {
  local scc_version

  log "Installing scc..."
  scc_version="$(curl -s "https://api.github.com/repos/boyter/scc/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')"
  wget "https://github.com/boyter/scc/releases/download/v${scc_version}/scc_${scc_version}_Linux_x86_64.tar.gz"
  tar -xzf "scc_${scc_version}_Linux_x86_64.tar.gz"
  sudo mv scc /usr/local/bin/
  rm "scc_${scc_version}_Linux_x86_64.tar.gz"
}

install_fonts() {
  local fonts_dir="$HOME/.local/share/fonts"

  log "Installing Nerd Fonts..."
  mkdir -p "$fonts_dir"

  (
    cd "$fonts_dir"
    curl -fLo "FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
    unzip -o "FiraCode.zip" -d FiraCode
    rm "FiraCode.zip"

    curl -fLo "JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
    unzip -o "JetBrainsMono.zip" -d JetBrainsMono
    rm "JetBrainsMono.zip"
  )

  fc-cache -fv
}

install_packages() {
  log "Installing packages for Linux..."
  sudo apt-get update

  sudo apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    zsh \
    fzf \
    ripgrep \
    bat \
    tree \
    jq \
    httpie \
    gnupg \
    pinentry-tty \
    unzip \
    zip \
    software-properties-common \
    apt-transport-https \
    ca-certificates

  log "Installing Neovim..."
  sudo add-apt-repository -y ppa:neovim-ppa/stable
  sudo apt-get update
  sudo apt-get install -y neovim

  sudo apt-get install -y pipx
  pipx ensurepath

  log "Installing i3 window manager..."
  sudo apt-get install -y \
    i3 \
    i3status \
    i3lock \
    rofi \
    dmenu \
    feh \
    picom \
    polybar \
    xclip \
    lxappearance \
    arandr

  log "Installing Starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y

  log "Installing stylua..."
  pipx install stylua || true
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
install_lazygit
install_kitty
install_bitwarden_cli
install_asdf
install_go
install_github_cli
install_fd
install_scc
install_fonts
install_oh_my_zsh
install_zsh_addons

log "Linux bootstrap complete."
