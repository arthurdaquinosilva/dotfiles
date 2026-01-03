# ============================================================================
# ⚙️  CORE SYSTEM SETTINGS
# ============================================================================

# Vi mode settings
set -o vi
export EDITOR=vi
export VISUAL=vi
export EDITOR_PREFIX=vi

# Make vi-yank copy to system clipboard (macOS)
  function vi-yank-pbcopy {
      zle vi-yank
      echo -n "$CUTBUFFER" | pbcopy
  }
  zle -N vi-yank-pbcopy
  bindkey -M vicmd 'y' vi-yank-pbcopy

# Path configuration
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
export PATH="$PATH:/opt/homebrew/bin/"
export PATH="$PATH:/Library/PostgreSQL/15/bin"
export PATH="$PATH:/opt/homebrew/bin/python3.12"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"

# Java
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export JDK_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# MySQL
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/mysql@8.0/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql@8.0/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql@8.0/lib/pkgconfig"

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

# Deno (only if installed)
if [[ -f "$HOME/.deno/env" ]]; then
    source "$HOME/.deno/env"
fi

# Additional PATH entries
export PATH="/Library/TeX/texbin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
