export ASDF_DATA_DIR="$HOME/.asdf"

PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
PATH="$PATH:$HOME/bin"
PATH="$PATH:/usr/local/bin"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$HOME/.cargo/bin"
export PATH

export EDITOR=nvim
export LANG="en_US.UTF-8"
export BAT_THEME="TwoDark"

export FZF_BASE="${FZF_BASE:-$(command -v fzf 2>/dev/null || true)}"
export FZF_DEFAULT_COMMAND="rg --files"
export FZF_DEFAULT_OPTS="-m --height 50% --border"
export FZF_CTRL_T_COMMAND="rg --files --follow --hidden --no-ignore --glob=\!.git --glob=\!node_modules --glob=\!.next"

# Optional generated secrets env for the future secret projection layer.
# This file can export values like SYNTHETIC_API_KEY without templating tracked shell files.
if [[ -r "$HOME/.config/secrets/env" ]]; then
  source "$HOME/.config/secrets/env"
fi

# Optional per-machine non-secret environment overrides.
if [[ -r "$HOME/.config/zsh/local.env" ]]; then
  source "$HOME/.config/zsh/local.env"
fi
