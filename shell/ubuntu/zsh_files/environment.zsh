# ============================================================================
# ⚙️  CORE SYSTEM SETTINGS (Ubuntu)
# ============================================================================

# Vi mode settings
set -o vi
export EDITOR=vi
export VISUAL=vi
export EDITOR_PREFIX=vi

# Path configuration
export PATH="$PATH:$HOME/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"

# Go
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Deno (only if installed)
if [[ -f "$HOME/.deno/env" ]]; then
    source "$HOME/.deno/env"
fi
