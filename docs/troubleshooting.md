# Troubleshooting

## Neovim Crashes When Opening A File After `brew upgrade` Or `LazyVim Sync`

### Symptom

Neovim starts normally with no file, but crashes or gets killed when opening a file.

Examples:

```bash
nvim +q                     # works
nvim --clean README.md +q   # works
nvim README.md              # crashes or exits immediately
```

On macOS, the matching crash reports are usually in:

```bash
~/Library/Logs/DiagnosticReports/nvim-*.ips
```

Look for lines like:

```text
SIGKILL (Code Signature Invalid)
termination namespace: CODESIGNING
indicator: Invalid Page
```

### Cause

This happened after a `brew upgrade` combined with `LazyVim Sync` updating native Tree-sitter parser binaries under:

```bash
~/.local/share/nvim/site/parser/
```

The stale parser `.so` files were still loadable enough for Neovim startup, but macOS killed the process when those binaries were touched during file-open events.

### Quick Confirmation

If this only happens on file open, these checks should help narrow it down:

```bash
nvim +q
nvim --clean README.md +q
nvim -u NONE README.md +q
```

If those work but `nvim README.md` crashes, the issue is likely in the file-open plugin path rather than the base Neovim binary.

### Fix

Remove the cached Tree-sitter parser binaries, then rebuild them.

```bash
rm -rf ~/.local/share/nvim/site/parser
```

Then start Neovim and run:

```vim
:lua require("lazy").load({plugins={"nvim-treesitter"}})
:TSUpdate
```

### Optional Safe Backup Flow

If you want to keep a backup before deleting the parser directory:

```bash
mv ~/.local/share/nvim/site/parser ~/.local/share/nvim/site/parser.bak
```

After Neovim is stable again and parsers have been rebuilt, the backup can be deleted:

```bash
rm -rf ~/.local/share/nvim/site/parser.bak
```

### Notes

- Reinstalling Homebrew Neovim alone may not fix this.
- The failure can look like a binary corruption issue even though the real problem is stale parser artifacts.
- If this recurs after another plugin sync, clear `~/.local/share/nvim/site/parser/` first before rebuilding your whole Neovim setup.
