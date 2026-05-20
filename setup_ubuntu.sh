#!/bin/bash

# ============================================================================
# Ubuntu Development Environment Setup Script
# ============================================================================
# Sets up a complete development environment on a fresh Ubuntu installation
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

# ============================================================================
# CONFIGURABLE VARIABLES
# ============================================================================

PYTHON_VERSION="3.12.7"
GO_VERSION="1.22.2"
NVM_VERSION="0.39.7"
VIM_REPO_URL="https://github.com/arthurdaquinosilva/vim.git"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# ============================================================================
# MAIN INSTALLATION FUNCTIONS
# ============================================================================

prompt_user_details() {
    log_info "Please enter your details for Git and SSH configuration."

    echo -e "${YELLOW}Enter your full name (e.g., Arthur D'Aquino):${NC}"
    read -r USER_FULL_NAME

    echo -e "${YELLOW}Enter your email address (e.g., arthurdaquinosilva@gmail.com):${NC}"
    read -r USER_EMAIL

    if [[ -z "$USER_FULL_NAME" ]] || [[ -z "$USER_EMAIL" ]]; then
        log_error "User name and email cannot be empty."
        exit 1
    fi

    export USER_FULL_NAME
    export USER_EMAIL
    log_success "User details captured."
}

install_apt_packages() {
    log_info "Updating apt and installing packages..."

    sudo apt-get update
    sudo apt-get upgrade -y

    # Core build tools and utilities
    sudo apt-get install -y \
        build-essential \
        curl \
        wget \
        git \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        unzip \
        zip \
        make

    # System monitoring
    sudo apt-get install -y htop btop glances

    # Search and file tools
    sudo apt-get install -y ripgrep silversearcher-ag tree fzf zoxide bat

    # bat is installed as batcat on Ubuntu — create a bat symlink
    if command_exists batcat && ! command_exists bat; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log_success "Created /usr/local/bin/bat symlink for batcat"
    fi

    # Terminal and development tools
    sudo apt-get install -y tmux vim zsh

    # Python build dependencies (required by pyenv)
    sudo apt-get install -y \
        libssl-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libffi-dev \
        liblzma-dev \
        zlib1g-dev \
        tk-dev \
        python3-pip \
        python3-dev

    # Make zsh the default shell
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        chsh -s "$(which zsh)"
        log_success "Default shell changed to zsh (takes effect on next login)"
    fi

    log_success "APT packages installed successfully"
}

install_github_cli() {
    log_info "Installing GitHub CLI..."

    if command_exists gh; then
        log_info "GitHub CLI already installed"
        return 0
    fi

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh

    log_success "GitHub CLI installed successfully"
}

install_lazygit() {
    log_info "Installing Lazygit..."

    if command_exists lazygit; then
        log_info "Lazygit already installed"
        return 0
    fi

    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit

    log_success "Lazygit installed successfully"
}

install_lazydocker() {
    log_info "Installing Lazydocker..."

    if command_exists lazydocker; then
        log_info "Lazydocker already installed"
        return 0
    fi

    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

    # Move to a system-wide PATH location
    if [[ -f "$HOME/.local/bin/lazydocker" ]]; then
        sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin/lazydocker
    fi

    log_success "Lazydocker installed successfully"
}

install_translate_shell() {
    log_info "Installing Translate Shell..."

    if command_exists trans; then
        log_info "Translate Shell already installed"
        return 0
    fi

    curl -Lo /tmp/trans git.io/trans
    chmod +x /tmp/trans
    sudo mv /tmp/trans /usr/local/bin/

    log_success "Translate Shell installed successfully"
}

install_go() {
    log_info "Installing Go $GO_VERSION..."

    if command_exists go; then
        log_info "Go already installed: $(go version)"
        return 0
    fi

    curl -Lo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz

    export PATH="$PATH:/usr/local/go/bin"

    log_success "Go $(go version) installed successfully"
}

setup_github_ssh() {
    log_info "Setting up GitHub SSH keys..."

    git config --global user.email "$USER_EMAIL"
    git config --global user.name "$USER_FULL_NAME"
    log_info "Git config updated with your credentials"

    SSH_DIR="$HOME/.ssh"
    SSH_KEY="$SSH_DIR/id_ed25519"
    SSH_CONFIG="$SSH_DIR/config"

    if [[ ! -d "$SSH_DIR" ]]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi

    if [[ -f "$SSH_KEY" ]]; then
        log_warning "SSH key already exists at $SSH_KEY"
        log_info "To regenerate with a different email, delete it and run again:"
        log_info "rm $SSH_KEY $SSH_KEY.pub"
    else
        log_info "Generating SSH key for $USER_EMAIL..."
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY" -N ""
        chmod 600 "$SSH_KEY"
        chmod 644 "$SSH_KEY.pub"
        log_success "SSH key generated successfully"
    fi

    if [[ ! -f "$SSH_CONFIG" ]]; then
        log_info "Creating SSH config..."
        cat > "$SSH_CONFIG" << EOF
# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
EOF
        chmod 600 "$SSH_CONFIG"
        log_success "SSH config created"
    fi

    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add "$SSH_KEY" >/dev/null 2>&1

    log_info "Your public SSH key (copy this to GitHub):"
    echo -e "${GREEN}$(cat "$SSH_KEY.pub")${NC}"
    echo ""
    log_info "Steps to add this key to GitHub:"
    log_info "1. Copy the key above"
    log_info "2. Go to GitHub.com → Settings → SSH and GPG keys"
    log_info "3. Click 'New SSH key'"
    log_info "4. Paste the key and give it a title"
    log_info "5. Click 'Add SSH key'"
    echo ""

    echo -e "${YELLOW}Press Enter after adding the SSH key to GitHub...${NC}"
    read -r

    log_info "Testing GitHub SSH connection..."
    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH connection successful!"
    else
        log_warning "GitHub SSH test failed. Test later with: ssh -T git@github.com"
    fi

    log_success "GitHub SSH setup completed"
}

setup_github_cli() {
    log_info "Setting up GitHub CLI authentication..."

    if ! command_exists gh; then
        log_error "GitHub CLI (gh) not found. Install it first."
        return 1
    fi

    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI already authenticated"
        return 0
    fi

    log_info "Authenticating with GitHub CLI..."
    log_info "This will open GitHub in your browser for authentication."
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r

    gh auth login --git-protocol ssh --web

    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI authenticated successfully"
        gh auth status
    else
        log_warning "GitHub CLI authentication may have failed"
    fi

    log_success "GitHub CLI setup completed"
}

clone_vim_repository() {
    log_info "Cloning vim configuration repository..."

    VIM_DIR="$HOME/.vim"

    if [[ -d "$VIM_DIR" ]]; then
        if [[ -d "$VIM_DIR/.git" ]]; then
            log_warning "Vim repository already exists at $VIM_DIR"
            log_info "Pulling latest changes..."
            cd "$VIM_DIR"
            git pull origin main || log_warning "Could not pull. Resolve conflicts manually."
            cd - >/dev/null
        else
            log_warning "Existing .vim is not a git repo. Backing up..."
            mv "$VIM_DIR" "$VIM_DIR.backup_$(date +%Y%m%d_%H%M%S)"
            git clone "$VIM_REPO_URL" "$VIM_DIR" || {
                log_error "Failed to clone vim repository. Ensure your SSH key is set up."
                return 1
            }
        fi
    else
        git clone "$VIM_REPO_URL" "$VIM_DIR" || {
            log_error "Failed to clone vim repository. Ensure your SSH key is set up."
            return 1
        }
    fi

    log_success "Vim repository cloned to $VIM_DIR"
}

setup_symlinks() {
    log_info "Setting up symbolic links for dotfiles..."

    backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    log_info "Backups for any existing files will be placed in $backup_dir"

    create_symlink() {
        local source="$1"
        local target="$2"

        if [[ -e "$target" ]] || [[ -L "$target" ]]; then
            log_warning "Backing up existing $target"
            mv "$target" "$backup_dir/"
        fi

        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
        log_success "Linked $target -> $source"
    }

    local symlinks=(
        "shell/ubuntu/.zshrc"            "$HOME/.zshrc"
        "terminal/tmux/.tmux.conf"       "$HOME/.tmux.conf"
        "terminal/git/.gitconfig"        "$HOME/.gitconfig"
        "terminal/lazygit/config.yml"    "$HOME/.config/lazygit/config.yml"
        "terminal/lazydocker/config.yml" "$HOME/.config/lazydocker/config.yml"
    )

    for ((i=0; i<${#symlinks[@]}; i+=2)); do
        source_rel="${symlinks[i]}"
        target="${symlinks[i+1]}"
        create_symlink "$PWD/$source_rel" "$target"
    done

    if [[ -f "$HOME/.vim/.vimrc" ]]; then
        create_symlink "$HOME/.vim/.vimrc" "$HOME/.vimrc"
    else
        log_warning "Could not find $HOME/.vim/.vimrc to create symlink."
    fi

    # Write machine-specific gitconfig (theme-directory uses absolute path)
    GITCONFIG_LOCAL="$HOME/.gitconfig.local"
    if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
        cat > "$GITCONFIG_LOCAL" << EOF
[split-diffs]
	theme-directory = $HOME/dotfiles/terminal/git-split-diffs
EOF
        log_success "Created $GITCONFIG_LOCAL with split-diffs theme-directory"
    else
        log_info "$GITCONFIG_LOCAL already exists — skipping"
    fi

    log_success "Symbolic links created successfully"
}

install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        if [[ -L "$HOME/.zshrc" ]]; then
            CUSTOM_ZSHRC_TARGET=$(readlink "$HOME/.zshrc")
        fi

        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Restore our custom .zshrc symlink (Oh My Zsh overwrites it)
        if [[ -n "$CUSTOM_ZSHRC_TARGET" ]]; then
            log_info "Restoring custom .zshrc symlink"
            rm "$HOME/.zshrc"
            ln -sf "$CUSTOM_ZSHRC_TARGET" "$HOME/.zshrc"
        fi

        log_success "Oh My Zsh installed"
    else
        log_warning "Oh My Zsh already installed"
    fi

    # Install zsh-autosuggestions regardless of whether OMZ was just installed
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions plugin installed"
    else
        log_info "zsh-autosuggestions already installed"
    fi
}

setup_nvm_and_node() {
    log_info "Setting up NVM and Node.js..."

    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"

    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash

    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    if type nvm &>/dev/null; then
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*

        npm install -g yarn
        npm install -g git-split-diffs
        npm install -g @anthropic-ai/claude-code

        log_success "Node.js $(node --version), Yarn $(yarn --version) installed via NVM"
        log_success "Claude Code installed globally via npm"
    else
        log_error "NVM installation failed"
        return 1
    fi
}

setup_pyenv_and_python() {
    log_info "Setting up pyenv and Python..."

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    if [[ ! -d "$PYENV_ROOT" ]]; then
        curl https://pyenv.run | bash
    fi

    if command_exists pyenv; then
        eval "$(pyenv init -)"

        log_info "Installing Python $PYTHON_VERSION (this may take a few minutes)..."
        pyenv install "$PYTHON_VERSION" --skip-existing
        pyenv global "$PYTHON_VERSION"

        if python --version >/dev/null 2>&1; then
            log_success "Python $(python --version | cut -d' ' -f2) installed via pyenv"
        else
            log_warning "Python installed but not immediately available. Restart terminal needed."
        fi
    else
        log_error "Pyenv not found in PATH"
        return 1
    fi
}

configure_fzf() {
    log_info "Configuring FZF key bindings..."

    # Install fzf from source for a reliable shell integration script
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    else
        log_info "FZF source installation already present"
    fi

    log_success "FZF configured with key bindings"
}

setup_tmux_plugins() {
    log_info "Setting up tmux plugin manager and plugins..."

    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    ~/.tmux/plugins/tpm/bin/install_plugins || true

    log_success "Tmux plugins installed"
}

setup_vim_plugins() {
    log_info "Setting up Vim plugins..."

    VIM_PATH="$(which vim)"

    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    log_info "Installing vim plugins (some may show Node.js warnings)..."
    $VIM_PATH -c 'PlugInstall --sync' -c 'qa' || true

    if [[ -d "$HOME/.vim/plugged/vim-hexokinase" ]]; then
        log_info "Compiling vim-hexokinase..."
        cd "$HOME/.vim/plugged/vim-hexokinase"
        make hexokinase
        cd - >/dev/null
        log_success "vim-hexokinase compiled successfully"
    fi

    log_success "Vim plugins installed"
    if ! command_exists node; then
        log_warning "Some vim plugins (like CoC) require Node.js. Restart terminal and run vim again."
    fi
}

configure_mysql() {
    log_info "Configuring MySQL..."

    if ! command_exists mysql; then
        sudo apt-get install -y mysql-server
    fi

    sudo systemctl start mysql
    sudo systemctl enable mysql
    sleep 3

    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;" 2>/dev/null || {
        log_warning "Could not set MySQL root password automatically"
        log_info "Run manually: sudo mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;\""
    }

    log_success "MySQL configured with root password"
}

configure_postgresql() {
    log_info "Configuring PostgreSQL..."

    if ! command_exists psql; then
        sudo apt-get install -y postgresql postgresql-contrib
    fi

    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 3

    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" 2>/dev/null || {
        log_warning "Could not set postgres password automatically"
    }

    # Switch local connections to md5 authentication
    PG_HBA_CONF=$(sudo -u postgres psql -t -c "SHOW hba_file;" 2>/dev/null | tr -d ' \n')

    if [[ -n "$PG_HBA_CONF" ]] && sudo test -f "$PG_HBA_CONF"; then
        sudo cp "$PG_HBA_CONF" "$PG_HBA_CONF.backup"
        sudo sed -i 's/local\s\+all\s\+postgres\s\+peer/local   all             postgres                                md5/' "$PG_HBA_CONF"
        sudo sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$PG_HBA_CONF"
        sudo systemctl restart postgresql
        sleep 3
        log_success "PostgreSQL configured to enforce password authentication"
    else
        log_warning "Could not find pg_hba.conf to update authentication method"
    fi

    log_success "PostgreSQL configured with postgres user and password enforcement"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Starting Ubuntu development environment setup..."
    log_info "This script will install and configure your development tools"

    if [[ ! -f "setup_ubuntu.sh" ]]; then
        log_error "Please run this script from the dotfiles directory"
        exit 1
    fi

    log_info "Starting installation process..."
    wait_for_user

    prompt_user_details

    install_apt_packages
    install_github_cli
    install_lazygit
    install_lazydocker
    install_translate_shell
    install_go
    setup_github_ssh
    setup_github_cli
    clone_vim_repository
    setup_symlinks
    install_oh_my_zsh
    setup_nvm_and_node
    setup_pyenv_and_python
    configure_fzf
    setup_tmux_plugins
    setup_vim_plugins
    configure_mysql
    configure_postgresql

    log_success "============================================================================"
    log_success "Setup completed successfully!"
    log_success "============================================================================"
    log_warning "IMPORTANT: You MUST restart your terminal completely for everything to work!"
    log_info ""
    log_info "After restarting your terminal, test these commands:"
    log_info "1. node --version && npm --version && yarn --version  # Node.js, Yarn via NVM"
    log_info "2. python --version                   # Python via pyenv"
    log_info "3. go version                         # Go language"
    log_info "4. make --version                     # Build tool"
    log_info "5. gh --version && gh auth status        # GitHub CLI"
    log_info "6. ssh -T git@github.com              # Test GitHub SSH connection"
    log_info "7. bat --version                      # Better cat with syntax highlighting"
    log_info "8. trans --version                    # Translate shell"
    log_info "9. git-split-diffs --version          # Git split diffs via npm"
    log_info "10. mysql -u root -p                  # MySQL (password: root)"
    log_info "11. psql -U postgres                  # PostgreSQL (password: postgres)"
    log_info "12. vim                               # Should work with all plugins"
    log_info "13. tmux                              # Custom tmux configuration"
    log_info ""
    log_warning "If any command doesn't work after restart, run: source ~/.zshrc"
    log_success "============================================================================"
}

# Run main function
main "$@"
