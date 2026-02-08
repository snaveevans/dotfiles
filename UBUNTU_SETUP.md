# Ubuntu/Linux Setup Guide

This dotfiles project now supports both macOS and Ubuntu/Linux. This guide explains how to use it on an Ubuntu development box.

## Prerequisites

- Fresh Ubuntu installation (20.04+ or 22.04+ recommended)
- Internet connection
- Git

## Quick Start

1. **Install chezmoi and clone dotfiles:**
   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)"
   chezmoi init https://github.com/yourusername/dotfiles.git
   ```

2. **Apply the configuration:**
   ```bash
   chezmoi apply
   ```

3. **The first run will:**
   - Install all packages via `run_once_before_install-packages-linux.sh`
   - Set up i3 window manager
   - Configure zsh, nvim, kitty, and other tools
   - Install Bitwarden CLI for secrets management

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
| Package Manager | Homebrew | apt + snap |
| Shell Prompt | Spaceship | Starship |
| Terminal Mod Key | Cmd | Ctrl |

## Secrets Management

Bitwarden CLI is used for secrets on both platforms:
- Run `chezmoi apply` will prompt for Bitwarden unlock
- Secrets are stored in templates (e.g., `private_dot_npmrc.tmpl`)

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

Edit files in `~/.local/share/chezmoi/` and run `chezmoi apply` to update.

### Adding Linux-specific packages
Edit: `run_once_before_install-packages-linux.sh.tmpl`

### Changing i3 key bindings
Edit: `dot_config/i3/config`

### Changing rofi appearance
Edit: `dot_config/rofi/config.rasi`

## File Structure

```
dot_config/
├── i3/
│   ├── config              # i3 window manager config
│   └── i3status.conf       # Simple status bar (fallback)
├── polybar/
│   ├── config.ini          # Polybar config
│   └── launch.sh           # Polybar startup script
├── rofi/
│   └── config.rasi         # App launcher config
└── kitty/
    ├── kitty.conf.tmpl     # Terminal config (cross-platform)
    └── kitty_selector.py   # Custom kitten for tab management

dot_zshrc.tmpl              # Cross-platform zsh config
dot_zshenv.tmpl             # Environment variables

run_once_before_install-packages-linux.sh.tmpl    # Linux package installer
run_once_before_install-packages-darwin.sh.tmpl   # macOS package installer
```

## Uninstall

```bash
# Remove chezmoi managed files
rm -rf ~/.local/share/chezmoi

# Remove dotfiles (be careful!)
chezmoi destroy

# Revert to bash
chsh -s /bin/bash
```
