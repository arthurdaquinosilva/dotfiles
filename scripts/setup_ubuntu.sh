#!/bin/bash
# ============================================================================
# Ubuntu Development Environment Setup
# ============================================================================

set -eo pipefail
trap 'log_error "Setup failed at line $LINENO."' ERR

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/common.sh"

# ============================================================================
# UBUNTU-SPECIFIC FUNCTIONS
# ============================================================================

install_apt_packages() {
    log_info "Installing apt packages..."

    sudo apt-get update && sudo apt-get upgrade -y

    sudo apt-get install -y \
        build-essential curl wget git ca-certificates gnupg \
        lsb-release software-properties-common unzip zip make \
        htop btop glances \
        ripgrep silversearcher-ag tree fzf zoxide bat \
        tmux vim-gtk3 xclip zsh \
        libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libffi-dev liblzma-dev zlib1g-dev tk-dev \
        python3-pip python3-dev

    # bat is installed as batcat on Ubuntu
    if command_exists batcat && ! command_exists bat; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log_success "Created bat symlink for batcat"
    fi

    if [[ "$SHELL" != "$(which zsh)" ]]; then
        chsh -s "$(which zsh)"
        log_success "Default shell set to zsh (takes effect on next login)"
    fi

    log_success "APT packages installed"
}

install_github_cli() {
    log_info "Installing GitHub CLI..."
    command_exists gh && { log_info "GitHub CLI already installed"; return 0; }

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update && sudo apt-get install -y gh
    log_success "GitHub CLI installed"
}

install_lazygit() {
    log_info "Installing Lazygit..."
    command_exists lazygit && { log_info "Lazygit already installed"; return 0; }

    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
    log_success "Lazygit installed"
}

install_lazydocker() {
    log_info "Installing Lazydocker..."
    command_exists lazydocker && { log_info "Lazydocker already installed"; return 0; }

    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    [[ -f "$HOME/.local/bin/lazydocker" ]] && sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin/
    log_success "Lazydocker installed"
}

install_translate_shell() {
    log_info "Installing Translate Shell..."
    command_exists trans && { log_info "Translate Shell already installed"; return 0; }

    curl -Lo /tmp/trans \
        "https://raw.githubusercontent.com/soimort/translate-shell/develop/trans"
    chmod +x /tmp/trans
    sudo mv /tmp/trans /usr/local/bin/
    log_success "Translate Shell installed"
}

install_go() {
    log_info "Installing Go $GO_VERSION..."
    command_exists go && { log_info "Go already installed: $(go version)"; return 0; }

    curl -Lo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    export PATH="$PATH:/usr/local/go/bin"
    log_success "Go installed"
}

configure_fzf() {
    log_info "Configuring FZF shell integration..."

    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    else
        log_info "FZF already configured"
    fi

    log_success "FZF configured"
}

configure_mysql() {
    log_info "Configuring MySQL..."
    command_exists mysql || sudo apt-get install -y mysql-server

    sudo systemctl start mysql
    sudo systemctl enable mysql

    log_info "Waiting for MySQL to be ready..."
    for i in {1..30}; do
        sudo mysqladmin ping --silent 2>/dev/null && break || sleep 1
    done

    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;" 2>/dev/null \
        || log_warning "Could not set MySQL root password — run manually if needed."

    log_success "MySQL configured"
}

configure_postgresql() {
    log_info "Configuring PostgreSQL..."
    command_exists psql || sudo apt-get install -y postgresql postgresql-contrib

    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    log_info "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        pg_isready -q 2>/dev/null && break || sleep 1
    done

    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" 2>/dev/null \
        || log_warning "Could not set postgres password — run manually if needed."

    local pg_hba
    pg_hba=$(sudo -u postgres psql -t -c "SHOW hba_file;" 2>/dev/null | tr -d ' \n')
    if [[ -n "$pg_hba" ]] && sudo test -f "$pg_hba"; then
        sudo cp "$pg_hba" "$pg_hba.backup"
        sudo sed -i 's/local\s\+all\s\+postgres\s\+peer/local   all             postgres                                md5/' "$pg_hba"
        sudo sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$pg_hba"
        sudo systemctl restart postgresql
        log_success "PostgreSQL configured with password authentication"
    else
        log_warning "Could not locate pg_hba.conf — update authentication manually."
    fi
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    log_info "Starting Ubuntu development environment setup..."
    wait_for_user

    prompt_user_details
    install_apt_packages
    install_github_cli
    install_lazygit
    install_lazydocker
    install_translate_shell
    install_claude
    install_go
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
