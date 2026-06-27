# ============================================================================
# ZSH CONFIGURATION (Ubuntu)
# ============================================================================
# Shared zsh files live in shell/macos/zsh_files (tools, functions, aliases).
# Ubuntu-specific environment overrides live in shell/ubuntu/zsh_files.
#
# Sourcing Order:
# 1. tools.zsh       (Oh My Zsh, FZF, NVM, pyenv, zoxide — shared)
# 2. environment.zsh (PATH and env vars — Ubuntu-specific)
# 3. functions.zsh   (Custom shell functions — shared)
# 4. aliases.zsh     (Command aliases — shared)
# 5. .zshrc.local    (Local secrets and overrides, sourced last)
# ============================================================================

SHARED_ZSH_DIR="$HOME/dotfiles/shell/macos/zsh_files"
UBUNTU_ZSH_DIR="$HOME/dotfiles/shell/ubuntu/zsh_files"

source "$SHARED_ZSH_DIR/tools.zsh"
source "$UBUNTU_ZSH_DIR/environment.zsh"
source "$SHARED_ZSH_DIR/functions.zsh"
source "$SHARED_ZSH_DIR/aliases.zsh"

if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

unset SHARED_ZSH_DIR UBUNTU_ZSH_DIR

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="$HOME/.dotnet/tools:$PATH"

# bun completions
[ -s "/home/arthurdaquino/.bun/_bun" ] && source "/home/arthurdaquino/.bun/_bun"
