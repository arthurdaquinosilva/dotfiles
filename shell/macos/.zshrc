# ============================================================================
# ZSH CONFIGURATION (macOS)
# ============================================================================
# This zsh configuration is modular. The sourcing order is critical for it to
# function correctly.
#
# Sourcing Order:
# 1. tools.zsh       (Oh My Zsh, FZF, NVM, etc.)
# 2. environment.zsh (PATH and other environment variables)
# 3. functions.zsh   (Custom shell functions)
# 4. aliases.zsh     (Command aliases)
# 5. .zshrc.local    (Local secrets and overrides, sourced last)
# ============================================================================

# Get the directory of the current script to locate the other config files
ZSH_CONFIG_DIR="$(dirname "$0")/zsh_files"

# An array defines the precise order for sourcing configuration files
zsh_files_to_source=(
    "tools.zsh"
    "environment.zsh"
    "functions.zsh"
    "aliases.zsh"
)

# Loop through and source each configuration file in order
for file in "${zsh_files_to_source[@]}"; do
    if [[ -r "$ZSH_CONFIG_DIR/$file" ]]; then
        source "$ZSH_CONFIG_DIR/$file"
    fi
done
unset file
unset zsh_files_to_source

# Source local secrets and overrides as the final step.
# This allows local settings to override any defaults from the config files.
if [[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.local"
fi

unset ZSH_CONFIG_DIR