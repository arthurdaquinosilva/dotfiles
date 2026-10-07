#!/bin/bash
# ============================================================================
# Kali Linux Development Environment Setup
# ============================================================================
# Designed for a Kali VM accessed over SSH (no browser): every login URL is
# printed so you can open it on your host. Force with HEADLESS=1 or HEADLESS=0.
#
# Differences from Ubuntu:
#   - gh comes from the Kali repos (no extra apt source needed)
#   - MariaDB instead of MySQL (mysql-server does not exist on Kali)
#   - full-upgrade, as recommended for Kali rolling
# ============================================================================

set -eo pipefail
trap 'log_error "Setup failed at line $LINENO."' ERR

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/common.sh"
source "$DOTFILES_DIR/scripts/lib/debian.sh"

# ============================================================================
# KALI-SPECIFIC FUNCTIONS
# ============================================================================

install_apt_packages() {
    log_info "Installing apt packages..."

    apt_upgrade full-upgrade

    apt_install \
        build-essential curl wget git ca-certificates gnupg \
        lsb-release unzip zip make \
        htop btop glances \
        ripgrep silversearcher-ag tree fzf zoxide bat \
        tmux vim-gtk3 xclip zsh gh \
        libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libffi-dev liblzma-dev zlib1g-dev tk-dev libncurses-dev xz-utils \
        python3-pip python3-dev

    link_batcat
    set_default_shell_zsh

    log_success "APT packages installed"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    log_info "Starting Kali development environment setup..."
    setup_headless_browser
    wait_for_user

    prompt_user_details
    install_apt_packages
    install_github_cli
    install_lazygit
    install_lazydocker
    install_translate_shell
    install_claude
    install_go
    install_pyenv
    setup_github_ssh
    setup_github_cli
    setup_claude_auth
    clone_vim_repository
    setup_symlinks "shell/ubuntu/.zshrc"
    install_oh_my_zsh
    setup_nvm_and_node
    setup_pyenv_and_python
    configure_fzf
    setup_tmux_plugins
    setup_vim_plugins "$(command -v vim)"
    configure_mysql
    configure_postgresql

    print_setup_complete
}

main "$@"
