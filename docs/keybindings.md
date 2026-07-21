# Keybindings

Custom bindings only. Framework defaults (LazyVim, oh-my-zsh, Kitty) are not
listed here — in Neovim, press `<leader>` and let which-key show you the rest.

`kitty_mod` is `cmd` on macOS and `ctrl` on Linux, set in
`home/.config/kitty/os/darwin.conf` and `os/linux.conf`. This page writes it as
`cmd` since that is the machine you use.

## zsh

Defined in `home/.zshrc`. `Ctrl-k` is a two-key chord prefix: press `Ctrl-k`,
release, then the letter.

| Binding | Action |
| --- | --- |
| `Ctrl-k w` | pick a git worktree and cd into it |
| `Ctrl-k o` | pick a listening port and kill the process holding it |
| `Ctrl-g` | insert `$(git branch \| fzf)` and run it |
| `Ctrl-o` | run `nvim` |
| `Ctrl-Space` | accept the autosuggestion |
| `Ctrl-h` / `Ctrl-l` | move back / forward one character |
| `Ctrl-b` / `Ctrl-w` | move back / forward one word |
| `_` / `g_` | start / end of line (normal mode — the shell is in vi mode) |

Aliases: `e` editor, `lg` lazygit, `re` reload the shell, `se` grep-to-fzf
search, `tf` terraform, `pn` pnpm, `ij` open the current directory in IntelliJ.

## Kitty

Defined in `home/.config/kitty/kitty.conf`. `cmd+enter` is a chord prefix.

| Binding | Action |
| --- | --- |
| `cmd+enter w` | pick a git worktree, open or focus its tab |
| `cmd+enter p` | pick a project under `~/workspace`, open or focus its tab |
| `cmd+enter o` | pick an already-open tab |
| `cmd+enter n` | new window in the current directory |
| `F2` / `F3` | new tab / rename tab |
| `F1` | show Kitty environment variables |
| `cmd+shift+h/j/k/l` | focus the neighboring window left/down/up/right |
| `ctrl+shift+h/j/k/l` | resize window narrower/shorter/taller/wider |
| `cmd+shift+z` | toggle the stack layout (zoom one window) |
| `cmd+shift+o` | open a URL on screen with hints |
| `alt+u` / `alt+d` | scroll one line up / down |

The tab bar is hidden, so `cmd+enter o` is how you see what tabs exist. Tabs
are titled by directory: `<repo>` for a primary checkout, `<repo>:<directory>`
for a worktree.

`cmd+t` is deliberately disabled so it does not shadow anything.

## Neovim

Custom bindings from `home/.config/nvim/lua/config/keymaps.lua` and the plugin
specs in `lua/plugins/`. Everything else is LazyVim's.

| Binding | Action |
| --- | --- |
| `<leader>gw` | worktrees in this repo |
| `<leader>gW` | worktrees across every repo |
| `<leader><leader>` / `<leader>p` | find files |
| `<leader>o` | buffers |
| `<leader>i` | git changed files |
| `<leader>fn` / `<leader>fv` | new file / new file in a split |
| `<leader><cr>` | clear search highlight |
| `Ctrl-j` / `Ctrl-k` | half page down / up |
| `Alt-j` / `Alt-k` | move the line or selection down / up |

In the worktree picker: `Enter` opens a Kitty tab, `Ctrl-t` opens a Neovim tab
page scoped to the worktree, `Ctrl-y` yanks the path.

Custom commands: `:Gstash` stashes the current file, `:Gread` picks a tracked
file and discards its changes.

## Hammerspoon (macOS)

Defined in `home/.hammerspoon/init.lua`.

| Binding | Action |
| --- | --- |
| `cmd+shift+/` | focus Kitty |
| `cmd+shift+.` | pick a VS Code window |
| `cmd+shift+space` | app launcher modal (see below) |
| `cmd+shift+9` / `cmd+shift+0` | snap the window to the left / right half |
| `cmd+shift+=` | maximize the window |
| `cmd+alt+ctrl+R` | reload the Hammerspoon config |

After `cmd+shift+space`, press one key to launch or focus:

| Key | App | Key | App |
| --- | --- | --- | --- |
| `return` | Brave | `m` | Outlook |
| `'` | Claude | `y` | Messages |
| `p` | OpenCode | `h` | Music |
| `o` | VS Code | `t` | Reminders |
| `i` | IntelliJ | `\` | Zoom |
| `u` | Slack | `l` | Teams |

In the VS Code window chooser, `cmd+n` and `cmd+p` move between rows.

## Where these live

| Surface | File |
| --- | --- |
| zsh | `home/.zshrc` |
| Kitty | `home/.config/kitty/kitty.conf` |
| Neovim | `home/.config/nvim/lua/config/keymaps.lua`, `lua/plugins/*.lua` |
| Hammerspoon | `home/.hammerspoon/init.lua` |

zsh and Hammerspoon reload without an install step: `re` for the shell,
`cmd+alt+ctrl+R` for Hammerspoon. Kitty needs a config reload, and Neovim
picks up changes on restart.
