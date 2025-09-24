#!/bin/bash

# ============================================================================
# macOS Development Environment Cleanup Script
# ============================================================================
# Completely removes all installations and configurations made by setup_macos.sh
# This allows for clean testing of the installation script
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Helper function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

cleanup_homebrew_packages() {
    log_info "Uninstalling Homebrew packages..."

    # List of packages to remove
    packages=(
        "mactop"
        "asitop"
        "htop"
        "btop"
        "glances"
        "ripgrep"
        "the_silver_searcher"
        "tree"
        "fzf"
        "zoxide"
        "tmux"
        "lazygit"
        "lazydocker"
        "gh"
        "translate-shell"
        "git-split-diffs"
        "nvm"
        "pyenv"
        "go"
        "make"
        "mysql"
        "postgresql@15"
        "vim"
        "bat"
    )

    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            log_info "Removing $package..."
            brew uninstall --ignore-dependencies "$package" || log_warning "Failed to remove $package"
        fi
    done

    log_success "Homebrew packages cleanup completed"
}

cleanup_symlinks() {
    log_info "Removing symbolic links..."

    # List of symlinks to remove
    symlinks=(
        "$HOME/.vim"
        "$HOME/.vimrc"
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
    )

    for symlink in "${symlinks[@]}"; do
        if [[ -L "$symlink" ]]; then
            log_info "Removing symlink: $symlink"
            rm "$symlink"
        elif [[ -f "$symlink" ]] || [[ -d "$symlink" ]]; then
            log_warning "Found non-symlink file/directory at $symlink, moving to backup"
            mv "$symlink" "${symlink}.cleanup_backup"
        fi
    done

    # Restore any backups if they exist
    backup_dirs=($HOME/.dotfiles_backup_*)
    if [[ ${#backup_dirs[@]} -gt 0 ]] && [[ -d "${backup_dirs[0]}" ]] && [[ "${backup_dirs[0]}" != "$HOME/.dotfiles_backup_*" ]]; then
        # Get the latest backup (last in sorted order)
        latest_backup=""
        for dir in "${backup_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                latest_backup="$dir"
            fi
        done

        if [[ -n "$latest_backup" ]]; then
            log_info "Restoring files from latest backup: $latest_backup"
            for file in "$latest_backup"/*; do
                if [[ -f "$file" ]]; then
                    filename=$(basename "$file")
                    cp "$file" "$HOME/$filename"
                    log_info "Restored $filename"
                fi
            done
        fi
    fi

    log_success "Symbolic links cleanup completed"
}

cleanup_oh_my_zsh() {
    log_info "Removing Oh My Zsh..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        rm -rf "$HOME/.oh-my-zsh"
        log_success "Oh My Zsh removed"
    else
        log_warning "Oh My Zsh not found"
    fi
}

cleanup_nvm() {
    log_info "Removing NVM and Node.js..."

    # Remove NVM directory
    if [[ -d "$HOME/.nvm" ]]; then
        rm -rf "$HOME/.nvm"
        log_success "NVM directory removed"
    fi

    # Remove any global npm packages directory
    if [[ -d "$HOME/.npm-global" ]]; then
        rm -rf "$HOME/.npm-global"
    fi

    log_success "NVM cleanup completed"
}

cleanup_pyenv() {
    log_info "Removing pyenv and Python installations..."

    # Remove pyenv directory
    if [[ -d "$HOME/.pyenv" ]]; then
        rm -rf "$HOME/.pyenv"
        log_success "Pyenv directory removed"
    fi

    log_success "Pyenv cleanup completed"
}

cleanup_vim_plugins() {
    log_info "Removing Vim plugins and configurations..."

    # Remove the entire vim repository (since we now clone to ~/.vim)
    if [[ -d "$HOME/.vim" ]]; then
        log_warning "Removing vim repository directory: $HOME/.vim"
        rm -rf "$HOME/.vim"
        log_success "Vim repository removed"
    fi

    log_success "Vim plugins cleanup completed"
}

cleanup_fzf() {
    log_info "Removing FZF configurations..."

    # Remove FZF configuration files
    [[ -f "$HOME/.fzf.bash" ]] && rm "$HOME/.fzf.bash"
    [[ -f "$HOME/.fzf.zsh" ]] && rm "$HOME/.fzf.zsh"

    log_success "FZF cleanup completed"
}

cleanup_tmux_plugins() {
    log_info "Removing tmux plugins and configuration..."

    # Remove the entire .tmux directory (includes plugins)
    if [[ -d "$HOME/.tmux" ]]; then
        log_warning "Removing tmux directory: $HOME/.tmux"
        rm -rf "$HOME/.tmux"
        log_success "Tmux directory removed"
    fi

    if [[ -d "$HOME/.config/tmux" ]]; then
        rm -rf "$HOME/.config/tmux"
        log_info "Removed $HOME/.config/tmux"
    fi

    log_success "Tmux plugins cleanup completed"
}

cleanup_databases() {
    log_info "Stopping and cleaning up databases..."

    # Stop MySQL service
    if command_exists brew && brew services list | grep mysql | grep started >/dev/null; then
        brew services stop mysql
        log_info "MySQL service stopped"
    fi

    # Stop PostgreSQL service
    if command_exists brew && brew services list | grep postgresql | grep started >/dev/null; then
        brew services stop postgresql@15
        log_info "PostgreSQL service stopped"
    fi

    # Remove database data directories (optional - uncomment if you want to remove data)
    # log_warning "Database data will be preserved. To remove completely, run:"
    # log_warning "rm -rf /opt/homebrew/var/mysql"
    # log_warning "rm -rf /opt/homebrew/var/postgresql@15"

    log_success "Database cleanup completed"
}

cleanup_misc_files() {
    log_info "Removing miscellaneous files and directories..."

    # Remove any remaining configuration files and backups
    files_to_remove=(
        "$HOME/.zsh_history"
        "$HOME/.viminfo"
        "$HOME/.tmux.conf.backup"
        "$HOME/.bash_profile.backup"
        "$HOME/.profile.backup"
        "$HOME/.zshrc.cleanup_backup"
        "$HOME/.zshrc.pre-oh-my-zsh"
        "$HOME/.vimrc.cleanup_backup"
        "$HOME/.tmux.conf.cleanup_backup"
        "$HOME/.gitconfig.cleanup_backup"
        "$HOME/.vim.cleanup_backup"
        "$HOME/.psql_history"
        "$HOME/.mysql_history"
    )

    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]] || [[ -L "$file" ]]; then
            rm "$file" && log_info "Removed $file"
        fi
    done

    # Remove directories
    directories_to_remove=(
        "$HOME/.ssh"
    )

    for dir in "${directories_to_remove[@]}"; do
        if [[ -d "$dir" ]]; then
            log_warning "Removing directory: $dir"
            rm -rf "$dir" && log_info "Removed $dir"
        fi
    done

    # Remove .config subdirectories
    config_dirs_to_remove=(
        "$HOME/.config/coc"
        "$HOME/.config/gh"
        "$HOME/.config/git-split-diffs"
    )

    for dir in "${config_dirs_to_remove[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Removing config directory: $dir"
            rm -rf "$dir" && log_info "Removed $dir"
        fi
    done

    # Remove backup directories from setup script
    find "$HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d -exec rm -rf {} \; 2>/dev/null || true

    log_success "Miscellaneous cleanup completed"
}

restore_default_shell() {
    log_info "Restoring default shell configuration..."

    # Create a minimal .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Default zsh configuration
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Basic prompt
export PS1="%~ %# "

# Basic aliases
alias ls='ls -G'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

    log_success "Default shell configuration restored"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_warning "============================================================================"
    log_warning "⚠️  WARNING: This will COMPLETELY REMOVE all development tools!"
    log_warning "============================================================================"
    log_warning "This script will remove:"
    log_warning "- All Homebrew packages installed by setup_macos.sh"
    log_warning "- All symbolic links to dotfiles"
    log_warning "- Oh My Zsh installation"
    log_warning "- NVM and all Node.js installations"
    log_warning "- Pyenv and all Python installations"
    log_warning "- Vim plugins and configurations"
    log_warning "- Tmux plugins"
    log_warning "- Database services (but not data)"
    log_warning "- FZF configurations"
    log_warning "============================================================================"

    echo -e "${RED}Are you sure you want to continue? This action cannot be undone!${NC}"
    echo -e "${YELLOW}Type 'yes' to proceed or anything else to cancel:${NC}"
    read -r confirmation

    if [[ "$confirmation" != "yes" ]]; then
        log_info "Cleanup cancelled."
        exit 0
    fi

    log_info "Starting cleanup process..."

    # Execute cleanup steps in reverse order of installation
    cleanup_databases
    cleanup_vim_plugins
    cleanup_tmux_plugins
    cleanup_fzf
    cleanup_pyenv
    cleanup_nvm
    cleanup_oh_my_zsh
    cleanup_symlinks
    cleanup_homebrew_packages
    cleanup_misc_files
    restore_default_shell

    log_success "============================================================================"
    log_success "🧹 Cleanup completed successfully!"
    log_success "============================================================================"
    log_info "Your system has been restored to its previous state."
    log_info "You may need to restart your terminal for all changes to take effect."
    log_info "To reinstall everything, run: ./setup_macos.sh"
    log_success "============================================================================"
}

# Confirmation prompt before running
echo -e "${BLUE}macOS Development Environment Cleanup Script${NC}"
echo -e "${YELLOW}This script will remove all installations made by setup_macos.sh${NC}"
echo ""

# Run main function
main "$@"