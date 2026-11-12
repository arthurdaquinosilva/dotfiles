#!/bin/bash
# ============================================================================
# macOS Development Environment Setup (older Intel Macs, MacPorts)
# ============================================================================
# For Intel Macs on macOS versions Homebrew no longer supports well (e.g.
# Ventura 13). Uses MacPorts (/opt/local) instead of Homebrew; everything
# else (symlinks, GitHub, oh-my-zsh, nvm, vim, tmux) comes from lib/common.sh.
#
# Prerequisite: MacPorts installed — https://www.macports.org/install.php
# Re-running is safe: every step skips what is already set up.
# ============================================================================

set -eo pipefail
trap 'log_error "Setup failed at line $LINENO."' ERR

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/common.sh"

PORT_PREFIX="/opt/local"
export PATH="$PORT_PREFIX/bin:$PORT_PREFIX/sbin:$PATH"

# ============================================================================
# MACPORTS
# ============================================================================

check_macports() {
    if ! command_exists port; then
        log_error "MacPorts not found. Install the package for macOS $(sw_vers -productVersion) from:"
        log_error "  https://www.macports.org/install.php"
        open_url "https://www.macports.org/install.php"
        exit 1
    fi
    log_info "MacPorts $(port version | awk '{print $2}') found"
}

# Ask for the sudo password once and keep it fresh for the rest of the run.
keep_sudo_alive() {
    log_info "MacPorts needs sudo."
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

install_macports_packages() {
    log_info "Updating MacPorts..."
    sudo port -N selfupdate

    log_info "Installing MacPorts packages..."
    # mactop and asitop are Apple Silicon only — omitted
    sudo port -N install htop btop glances
    sudo port -N install ripgrep the_silver_searcher tree fzf zoxide bat
    sudo port -N install tmux lazygit lazydocker
    sudo port -N install git gh translate-shell
    sudo port -N install go vim gmake ruby33
    # Build dependencies for pyenv's Python
    sudo port -N install openssl3 readline xz zlib libffi
    log_success "MacPorts packages installed"
}

# ============================================================================
# TMUXINATOR (no port — install the gem with MacPorts' Ruby; system Ruby is too old)
# ============================================================================

install_tmuxinator() {
    log_info "Installing tmuxinator..."

    if command_exists tmuxinator || [[ -x "$HOME/.local/bin/tmuxinator" ]]; then
        log_info "tmuxinator already installed"
        return
    fi

    /opt/local/bin/gem3.3 install --user-install --no-document --bindir "$HOME/.local/bin" tmuxinator
    log_success "tmuxinator installed"
}

# ============================================================================
# PYTHON (pyenv has no port — install from git, build against MacPorts libs)
# ============================================================================

install_pyenv() {
    if [[ -d "$HOME/.pyenv/.git" ]]; then
        log_info "Updating pyenv..."
        git -C "$HOME/.pyenv" pull --ff-only -q || log_warning "Could not update pyenv"
    else
        log_info "Installing pyenv..."
        git clone -q https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
    fi

    export CPPFLAGS="-I$PORT_PREFIX/include"
    export LDFLAGS="-L$PORT_PREFIX/lib"
    export PKG_CONFIG_PATH="$PORT_PREFIX/lib/pkgconfig"
    export PYTHON_CONFIGURE_OPTS="--with-openssl=$PORT_PREFIX"

    setup_pyenv_and_python || log_warning "Python build failed — retry later: pyenv install $PYTHON_VERSION"
}

# ============================================================================
# CLIPBOARD SERVER (same as setup_macos.sh)
# ============================================================================

install_clipboard_server() {
    log_info "Installing clipboard server LaunchAgent..."

    local python3_path
    python3_path=$(command -v python3) \
        || { log_warning "python3 not found — skipping clipboard server install"; return 0; }

    local plist_src="$DOTFILES_DIR/launchagents/com.user.clipboard-server.plist"
    local plist_dest="$HOME/Library/LaunchAgents/com.user.clipboard-server.plist"

    mkdir -p "$HOME/Library/LaunchAgents"
    sed -e "s|__PYTHON3__|$python3_path|g" \
        -e "s|__SCRIPT__|$HOME/bin/clipboard-server|g" \
        "$plist_src" > "$plist_dest"

    launchctl unload "$plist_dest" 2>/dev/null || true
    launchctl load "$plist_dest"
    log_success "Clipboard server LaunchAgent installed and started"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    log_info "Starting macOS (Intel, MacPorts) development environment setup..."
    setup_headless_browser
    check_macports

    wait_for_user
    prompt_user_details
    keep_sudo_alive

    install_macports_packages
    install_claude
    setup_github_ssh
    setup_github_cli
    setup_claude_auth
    clone_vim_repository
    setup_symlinks "shell/macos/.zshrc"
    install_clipboard_server
    install_oh_my_zsh
    setup_nvm_and_node          # no brew prefix → nvm installed via its curl script
    install_pyenv
    install_tmuxinator
    setup_tmux_plugins
    setup_vim_plugins "$PORT_PREFIX/bin/vim"

    print_setup_complete
}

main "$@"
