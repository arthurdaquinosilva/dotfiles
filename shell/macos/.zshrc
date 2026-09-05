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

# Set the path to the zsh configuration directory directly.
# This avoids issues with resolving symlinks.
ZSH_CONFIG_DIR="$HOME/dotfiles/shell/macos/zsh_files"

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
    else
        echo "zsh config: could not read $ZSH_CONFIG_DIR/$file"
    fi
done
unset file
unset zsh_files_to_source

# Source local secrets and overrides as the final step.
# This allows local settings to override any defaults from the config files.
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

unset ZSH_CONFIG_DIR
export PATH="$HOME/.dotnet/tools:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/arthurdaquino/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

# bun completions
[ -s "/Users/arthurdaquino/.bun/_bun" ] && source "/Users/arthurdaquino/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/Users/arthurdaquino/.local/bin:$PATH"
