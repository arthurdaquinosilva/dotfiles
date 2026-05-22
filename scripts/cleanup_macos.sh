#!/bin/bash
# ============================================================================
# macOS Development Environment Cleanup
# ============================================================================
# Removes all tools and configs installed by setup_macos*.sh.
# Useful for clean testing of the setup scripts.
# ============================================================================

set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/common.sh"

BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

cleanup_homebrew_packages() {
    log_info "Uninstalling Homebrew packages..."

    local packages=(
        mactop asitop htop btop glances
        ripgrep the_silver_searcher tree fzf zoxide bat
        tmux lazygit lazydocker
        gh translate-shell git-split-diffs
        nvm pyenv go make vim
        mysql postgresql@15
    )

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            brew uninstall --ignore-dependencies "$pkg" \
                || log_warning "Failed to remove $pkg"
        fi
    done

    log_success "Homebrew packages removed"
}

cleanup_symlinks() {
    log_info "Removing dotfile symlinks..."

    local symlink_targets=(
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.config/lazygit/config.yml"
        "$HOME/.config/lazydocker/config.yml"
    )

    for tgt in "${symlink_targets[@]}"; do
        if [[ -L "$tgt" ]]; then
            rm "$tgt"
            log_info "Removed symlink: $tgt"
        elif [[ -e "$tgt" ]]; then
            log_warning "$tgt exists but is not a symlink — skipping"
        fi
    done

    log_success "Symlinks removed"
}

cleanup_oh_my_zsh() {
    log_info "Removing Oh My Zsh..."
    [[ -d "$HOME/.oh-my-zsh" ]] \
        && rm -rf "$HOME/.oh-my-zsh" && log_success "Oh My Zsh removed" \
        || log_warning "Oh My Zsh not found"
}

cleanup_nvm() {
    log_info "Removing NVM and Node.js..."
    [[ -d "$HOME/.nvm" ]] && rm -rf "$HOME/.nvm" && log_success "NVM removed"
    [[ -d "$HOME/.npm-global" ]] && rm -rf "$HOME/.npm-global"
    log_success "NVM cleanup complete"
}

cleanup_pyenv() {
    log_info "Removing pyenv..."
    [[ -d "$HOME/.pyenv" ]] && rm -rf "$HOME/.pyenv" && log_success "pyenv removed"
    log_success "pyenv cleanup complete"
}

cleanup_vim() {
    log_info "Removing vim config and plugins..."
    [[ -d "$HOME/.vim" ]] && rm -rf "$HOME/.vim" && log_success "~/.vim removed"
    log_success "Vim cleanup complete"
}

cleanup_fzf() {
    log_info "Removing FZF shell integration files..."
    [[ -f "$HOME/.fzf.bash" ]] && rm "$HOME/.fzf.bash"
    [[ -f "$HOME/.fzf.zsh" ]]  && rm "$HOME/.fzf.zsh"
    log_success "FZF cleanup complete"
}

cleanup_tmux() {
    log_info "Removing tmux plugins..."
    [[ -d "$HOME/.tmux" ]]        && rm -rf "$HOME/.tmux"        && log_success "~/.tmux removed"
    [[ -d "$HOME/.config/tmux" ]] && rm -rf "$HOME/.config/tmux" && log_info "~/.config/tmux removed"
    log_success "Tmux cleanup complete"
}

cleanup_databases() {
    log_info "Stopping database services..."

    command_exists brew || return 0

    brew services list | grep -E '^mysql.*started'      >/dev/null 2>&1 \
        && brew services stop mysql       && log_info "MySQL stopped"
    brew services list | grep -E '^postgresql.*started' >/dev/null 2>&1 \
        && brew services stop postgresql@15 && log_info "PostgreSQL stopped"

    log_success "Database services stopped (data preserved)"
}

cleanup_misc() {
    log_info "Removing miscellaneous files..."

    local files=(
        "$HOME/.zsh_history"
        "$HOME/.viminfo"
        "$HOME/.psql_history"
        "$HOME/.mysql_history"
        "$HOME/.zshrc.pre-oh-my-zsh"
        "$HOME/.gitconfig.local"
    )

    for f in "${files[@]}"; do
        [[ -f "$f" || -L "$f" ]] && rm "$f" && log_info "Removed $f"
    done

    local config_dirs=(
        "$HOME/.config/coc"
        "$HOME/.config/gh"
        "$HOME/.config/git-split-diffs"
    )

    for d in "${config_dirs[@]}"; do
        [[ -d "$d" ]] && rm -rf "$d" && log_info "Removed $d"
    done

    find "$HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d -exec rm -rf {} \; 2>/dev/null || true

    log_success "Miscellaneous cleanup complete"
}

restore_default_shell() {
    log_info "Restoring minimal shell config..."

    cat > "$HOME/.zshrc" << EOF
# Minimal zsh config — restore by running setup_macos.sh
export PATH="$BREW_PREFIX/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PS1="%~ %# "
alias ls='ls -G'
alias ll='ls -alF'
EOF

    log_success "Minimal .zshrc written"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    log_warning "========================================================"
    log_warning "WARNING: This will COMPLETELY REMOVE your dev environment"
    log_warning "========================================================"
    log_warning "  - All Homebrew packages from setup_macos*.sh"
    log_warning "  - All dotfile symlinks"
    log_warning "  - Oh My Zsh, NVM, pyenv, vim plugins, tmux plugins"
    log_warning "  - Database services (data is preserved)"
    log_warning "========================================================"
    echo ""
    echo -e "${RED}Type 'yes' to proceed, anything else to cancel:${NC}"
    read -r confirmation

    [[ "$confirmation" != "yes" ]] && { log_info "Cleanup cancelled."; exit 0; }

    cleanup_databases
    cleanup_vim
    cleanup_tmux
    cleanup_fzf
    cleanup_pyenv
    cleanup_nvm
    cleanup_oh_my_zsh
    cleanup_symlinks
    cleanup_homebrew_packages
    cleanup_misc
    restore_default_shell

    log_success "========================================================"
    log_success "Cleanup complete!"
    log_success "========================================================"
    log_info "Restart your terminal, then run scripts/setup_macos.sh to reinstall."
}

main "$@"
