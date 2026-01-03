# ============================================================================
# ZSH CONFIGURATION (macOS)
# ============================================================================
# This zsh configuration is modular and sources files from the zsh_files/
# directory. This makes it easier to manage and maintain.
#
# The order of sourcing is important:
# 1. .zshrc.local   (secrets and local overrides)
# 2. environment.zsh (environment variables and PATH)
# 3. tools.zsh       (tool configurations like fzf, nvm, etc.)
# 4. functions.zsh   (custom shell functions)
# 5. aliases.zsh     (command aliases)
# ============================================================================

# Source local secrets and overrides if the file exists
if [[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.local"
fi

# Define the base directory for zsh configuration files
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME}/shell/macos/zsh_files"

# Source modular zsh files if they exist
if [[ -d "$ZSH_CONFIG_DIR" ]]; then
    for file in "$ZSH_CONFIG_DIR"/*.zsh; do
        if [[ -r "$file" ]]; then
            source "$file"
        fi
    done
    unset file
fi

unset ZSH_CONFIG_DIR