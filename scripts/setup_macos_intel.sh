#!/bin/bash
# ============================================================================
# macOS Development Environment Setup (Intel x86_64)
# ============================================================================

set -eo pipefail
trap 'log_error "Setup failed at line $LINENO."' ERR

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/common.sh"

BREW_PREFIX="/usr/local"

# ============================================================================
# MACOS-SPECIFIC FUNCTIONS
# ============================================================================

wait_for_brew_lock() {
    local lock_dir="$HOME/Library/Caches/Homebrew/downloads"
    local max_wait=300 waited=0

    while true; do
        local locks
        locks=$(ls "$lock_dir"/*.incomplete 2>/dev/null || true)
        [[ -z "$locks" ]] && break

        if pgrep -x brew >/dev/null 2>&1; then
            [[ $waited -eq 0 ]] && log_warning "Waiting for another Homebrew process (up to ${max_wait}s)..."
            sleep 10; waited=$((waited + 10))
            [[ $waited -ge $max_wait ]] && { log_error "Timed out waiting for Homebrew."; exit 1; }
        else
            log_warning "Orphaned Homebrew lock files found — removing..."
            rm -f "$lock_dir"/*.incomplete
            break
        fi
    done
}

install_homebrew() {
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    log_success "Homebrew installed"
}

install_homebrew_packages() {
    log_info "Installing Homebrew packages..."
    wait_for_brew_lock

    # Clear stale cache before installing on older Intel hardware
    brew cleanup --prune=all 2>/dev/null || true
    brew update --force

    # mactop and asitop are Apple Silicon only — omitted for Intel
    brew install htop btop glances
    brew install ripgrep the_silver_searcher tree fzf zoxide bat
    brew install tmux lazygit lazydocker
    brew install gh translate-shell git-split-diffs
    brew install nvm pyenv go vim
    command_exists make || brew install make
    brew install mysql postgresql@15

    log_success "Homebrew packages installed"
}

configure_fzf() {
    log_info "Configuring FZF shell integration..."
    "$BREW_PREFIX/opt/fzf/install" --all --no-bash --no-fish
    log_success "FZF configured"
}

configure_mysql() {
    log_info "Configuring MySQL..."
    brew services start mysql

    log_info "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        mysql -u root -e "" 2>/dev/null && break || sleep 1
    done

    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" 2>/dev/null \
        || mysqladmin -u root password 'root' 2>/dev/null \
        || log_warning "Could not set MySQL root password — run manually if needed."

    log_success "MySQL configured"
}

configure_postgresql() {
    log_info "Configuring PostgreSQL..."
    brew services start postgresql@15

    log_info "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        "$BREW_PREFIX/opt/postgresql@15/bin/pg_isready" -q 2>/dev/null && break || sleep 1
    done

    "$BREW_PREFIX/opt/postgresql@15/bin/psql" -U "$(whoami)" -d postgres -c "
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
                CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD 'postgres';
            ELSE
                ALTER ROLE postgres WITH PASSWORD 'postgres';
            END IF;
        END
        \$\$;" 2>/dev/null || log_warning "Could not configure postgres user — run manually if needed."

    local pg_hba="$BREW_PREFIX/var/postgresql@15/pg_hba.conf"
    if [[ -f "$pg_hba" ]]; then
        cp "$pg_hba" "$pg_hba.backup"
        sed -i '' 's/local   all             all.*peer/local   all             all                                     md5/' "$pg_hba"
        sed -i '' 's/local   all             all.*trust/local   all             all                                     md5/' "$pg_hba"
        sed -i '' 's/host    all             all             127.0.0.1\/32.*trust/host    all             all             127.0.0.1\/32            md5/' "$pg_hba"
        sed -i '' 's/host    all             all             ::1\/128.*trust/host    all             all             ::1\/128                 md5/' "$pg_hba"
        brew services restart postgresql@15
        log_success "PostgreSQL configured with password authentication"
    else
        log_warning "pg_hba.conf not found at $pg_hba — update authentication manually."
    fi
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    log_info "Starting macOS (Intel x86_64) development environment setup..."

    if ! command_exists brew; then
        install_homebrew
    else
        log_info "Homebrew already installed"
        eval "$($BREW_PREFIX/bin/brew shellenv)" 2>/dev/null || true
    fi

    wait_for_user
    prompt_user_details

    install_homebrew_packages
    install_claude
    setup_github_ssh
    setup_github_cli
    setup_claude_auth
    clone_vim_repository
    setup_symlinks "shell/macos/.zshrc"
    install_oh_my_zsh
    setup_nvm_and_node "$BREW_PREFIX"
    setup_pyenv_and_python
    configure_fzf
    setup_tmux_plugins
    setup_vim_plugins "$BREW_PREFIX/bin/vim"
    configure_mysql
    configure_postgresql

    log_success "========================================================"
    log_success "Setup complete! Restart your terminal before continuing."
    log_success "========================================================"
    log_info ""
    log_info "Verify your setup:"
    log_info "  node --version && yarn --version   # Node via NVM"
    log_info "  python --version                   # Python via pyenv"
    log_info "  go version                         # Go"
    log_info "  gh auth status                     # GitHub CLI"
    log_info "  ssh -T git@github.com              # GitHub SSH"
    log_info "  git-split-diffs --version          # git-split-diffs"
    log_info "  claude --version                   # Claude Code"
    log_info "  bat --version                      # bat"
    log_info "  tmux                               # tmux"
    log_info "  vim                                # Vim with plugins"
}

main "$@"
