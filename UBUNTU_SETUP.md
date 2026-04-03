# Ubuntu/Linux Setup Guide

This guide explains the current Linux setup flow for the symlink-first dotfiles repo.

## Prerequisites

- Fresh Ubuntu installation (20.04+ or 22.04+ recommended)
- Internet connection
- Git

## Quick Start

1. **Clone the dotfiles repo:**
   ```bash
   git clone <repo-url> ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Run Linux bootstrap:**
   ```bash
   scripts/bootstrap.sh
   ```

3. **Link tracked config into your home directory:**
   ```bash
   scripts/install-home-links.sh
   ```

4. **Log into Bitwarden and generate local secret artifacts:**
   ```bash
   bw login
   scripts/refresh-secrets.sh
   ```
   Linux bootstrap now provisions the Bitwarden CLI needed for this step.

5. **Review the general flow doc if needed:**
   - `docs/bootstrap.md`

## What's Included

### Core Tools (Both Platforms)
- **Zsh + Oh-My-Zsh** - Shell with Starship prompt on Linux
- **Neovim + LazyVim** - Editor with 20+ language extras
- **Kitty** - Terminal with custom Python kitten
- **asdf** - Version manager for Node.js, Java, etc.
- **Git + GitHub CLI** - Version control
- **fzf + ripgrep** - Fuzzy finding and search
- **lazygit** - Terminal UI for git

### Linux-Specific Additions

#### Window Manager: i3
Replaces Hammerspoon functionality:
- **Tiling window management** - Automatically tile windows
- **Keyboard shortcuts** - Vim-like navigation (Mod+h/j/k/l)
- **Window resizing** - Mod+Shift+9/0 for half-screen, Mod+Shift+= for fullscreen
- **Workspaces** - 10 virtual desktops (Mod+1-0)

#### Status Bar: Polybar
Replaces macOS menu bar:
- Workspace indicators
- System resources (CPU, RAM, disk)
- Battery status
- Clock and date

#### App Launcher: Rofi
Replaces Alfred/Spotlight:
- **Mod+Space** - Launch applications
- **Mod+Shift+Space** - Switch windows
- Custom theme matching your color scheme

#### Key Bindings

| Key | Action |
|-----|--------|
| Mod+Return | Open terminal |
| Mod+Space | Open app launcher (rofi) |
| Mod+Shift+Space | Window switcher |
| Mod+h/j/k/l | Focus window (left/down/up/right) |
| Mod+Shift+h/j/k/l | Move window |
| Mod+Shift+9 | Window to left half |
| Mod+Shift+0 | Window to right half |
| Mod+Shift+q | Close window |
| Mod+r | Resize mode |
| Mod+1-0 | Switch to workspace |
| Mod+Shift+1-0 | Move window to workspace |

*Mod = Super/Windows key*

## Platform Differences

| Feature | macOS | Linux |
|---------|-------|-------|
| Window Manager | Hammerspoon | i3 |
| Status Bar | macOS menu bar | Polybar |
| App Launcher | Alfred/Spotlight | Rofi |
| Package Manager | Homebrew | apt + direct installers |
| Shell Prompt | Spaceship | Starship |
| Terminal Mod Key | Cmd | Ctrl |

## Secrets Management

Bitwarden CLI is used for secrets on both platforms:
- `scripts/bootstrap.sh` provisions `bw` on Linux
- Run `bw login` once if needed
- Run `scripts/refresh-secrets.sh` to generate local secret artifacts
- Shell secrets are sourced from `~/.config/secrets/env`
- npm auth is generated into `~/.npmrc`

## Post-Installation

1. **Change shell to zsh:**
   ```bash
   chsh -s $(which zsh)
   ```

2. **Log out and log back in** to start i3

3. **Install Node.js via asdf:**
   ```bash
   asdf plugin add nodejs
   asdf install nodejs latest
   asdf global nodejs latest
   ```

4. **Install Java via asdf (optional):**
   ```bash
   asdf plugin add java
   asdf install java latest:corretto
   asdf global java latest:corretto
   ```

## Troubleshooting

### i3 not starting
- Make sure you selected i3 at login (gear icon on login screen)
- Check `~/.local/share/xorg/Xorg.0.log` for errors

### Polybar not showing
- Run `~/.config/polybar/launch.sh` manually to see errors
- Check font installation: `fc-list | grep -i jetbrains`

### Fonts not rendering
- Nerd Fonts should be installed in `~/.local/share/fonts/`
- Run `fc-cache -fv` to rebuild font cache

### Bitwarden not unlocking
- Ensure `bw` is in PATH: `which bw`
- Run `bw login` first if not logged in

## Customization

Edit tracked files in `~/.dotfiles/home/` and rerun `scripts/install-home-links.sh` if you need to refresh links on a machine.

### Adding Linux-specific packages
Edit: `scripts/bootstrap-linux.sh`

### Changing i3 key bindings
Edit: `home/.config/i3/config`

### Changing rofi appearance
Edit: `home/.config/rofi/config.rasi`

## File Structure

```
home/
├── .zshenv
├── .zshrc
└── .config/
    ├── i3/
    ├── kitty/
    ├── nvim/
    ├── polybar/
    └── rofi/

scripts/
├── bootstrap.sh
├── bootstrap-linux.sh
├── install-home-links.sh
└── refresh-secrets.sh
```

## Uninstall

```bash
# Remove linked config carefully (review before deleting)
# Example:
# rm ~/.zshenv ~/.zshrc ~/.gitconfig ~/.rgignore

# Revert to bash
chsh -s /bin/bash
```
