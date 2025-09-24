#!/bin/bash

# ============================================================================
# macOS Development Environment Setup Script
# ============================================================================
# Sets up a complete development environment on a new macOS computer
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

# Helper function to wait for user confirmation
wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# ============================================================================
# MAIN INSTALLATION FUNCTIONS
# ============================================================================

install_homebrew() {
    log_info "Installing Homebrew..."

    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"

    log_success "Homebrew installed successfully"
}

install_homebrew_packages() {
    log_info "Installing Homebrew packages..."

    # System monitoring tools
    brew install mactop asitop htop btop glances

    # Search and file tools
    brew install ripgrep the_silver_searcher tree fzf zoxide bat

    # Terminal and development tools
    brew install tmux lazygit lazydocker

    # GitHub and utilities
    brew install gh translate-shell git-split-diffs

    # Programming language managers and languages
    brew install nvm pyenv go

    # Build tools (install make if not available)
    if ! command -v make >/dev/null 2>&1; then
        brew install make
    fi

    # Databases
    brew install mysql postgresql@15

    # Vim (override system version)
    brew install vim

    log_success "All Homebrew packages installed successfully"
}

setup_symlinks() {
    log_info "Setting up symbolic links for dotfiles..."

    # Backup existing files if they exist
    backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Function to safely create symlink
    create_symlink() {
        local source="$1"
        local target="$2"

        if [[ -e "$target" ]] || [[ -L "$target" ]]; then
            log_warning "Backing up existing $target to $backup_dir"
            mv "$target" "$backup_dir/"
        fi

        ln -sf "$source" "$target"
        log_success "Created symlink: $target -> $source"
    }

    # Create symlinks
    create_symlink "$HOME/.vim/.vimrc" "$HOME/.vimrc"
    create_symlink "$PWD/shell/macos/.zshrc" "$HOME/.zshrc"
    create_symlink "$PWD/terminal/tmux/.tmux.conf" "$HOME/.tmux.conf"
    create_symlink "$PWD/terminal/git/.gitconfig" "$HOME/.gitconfig"


    log_success "Symbolic links created successfully"
}

install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        # Backup our custom zshrc if it exists
        if [[ -L "$HOME/.zshrc" ]]; then
            CUSTOM_ZSHRC_TARGET=$(readlink "$HOME/.zshrc")
            log_info "Backing up custom .zshrc symlink target: $CUSTOM_ZSHRC_TARGET"
        fi

        # Install Oh My Zsh
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Install zsh-autosuggestions plugin
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

        # Restore our custom zshrc symlink (Oh My Zsh overwrites it)
        if [[ -n "$CUSTOM_ZSHRC_TARGET" ]]; then
            log_info "Restoring custom .zshrc symlink"
            rm "$HOME/.zshrc"
            ln -sf "$CUSTOM_ZSHRC_TARGET" "$HOME/.zshrc"
        fi

        log_success "Oh My Zsh installed with autosuggestions plugin"
    else
        log_warning "Oh My Zsh already installed"
    fi
}

setup_nvm_and_node() {
    log_info "Setting up NVM and Node.js..."

    # Create nvm directory
    mkdir -p "$HOME/.nvm"

    # Source nvm script to make it available in this session
    export NVM_DIR="$HOME/.nvm"

    # Copy nvm script to the .nvm directory (homebrew installs it elsewhere)
    if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        cp "/opt/homebrew/opt/nvm/nvm.sh" "$HOME/.nvm/"
        cp "/opt/homebrew/opt/nvm/bash_completion" "$HOME/.nvm/" 2>/dev/null || true
    fi

    # Source nvm for this session
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    # Install latest LTS Node.js
    if command -v nvm >/dev/null 2>&1; then
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*

        # Install global npm packages
        npm install -g yarn
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

    # Add pyenv to PATH for this session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    # Initialize pyenv in this session
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"

        # Install latest Python 3.12
        PYTHON_VERSION="3.12.7"
        log_info "Installing Python $PYTHON_VERSION (this may take a few minutes)..."
        pyenv install $PYTHON_VERSION --skip-existing
        pyenv global $PYTHON_VERSION

        # Verify installation
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

setup_vim_plugins() {
    log_info "Setting up Vim plugins..."

    # Use the homebrew vim
    VIM_PATH="/opt/homebrew/bin/vim"

    # Install vim-plug if not already installed
    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    # Make sure Node.js is available for this session if possible
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    # Install plugins (some may require Node.js)
    log_info "Installing vim plugins (some may show Node.js warnings)..."
    $VIM_PATH -c 'PlugInstall --sync' -c 'qa'

    # Compile vim-hexokinase if it was installed
    if [[ -d "$HOME/.vim/plugged/vim-hexokinase" ]]; then
        log_info "Compiling vim-hexokinase..."
        cd "$HOME/.vim/plugged/vim-hexokinase"
        make hexokinase
        cd - >/dev/null
        log_success "vim-hexokinase compiled successfully"
    fi

    log_success "Vim plugins installed and compiled"
    if ! command -v node >/dev/null 2>&1; then
        log_warning "Some vim plugins (like CoC) require Node.js. Restart terminal and run vim again."
    fi
}

configure_fzf() {
    log_info "Configuring FZF key bindings..."

    # Install FZF key bindings and fuzzy completion
    /opt/homebrew/opt/fzf/install --all --no-bash --no-fish

    log_success "FZF configured with key bindings"
}

setup_tmux_plugins() {
    log_info "Setting up tmux plugin manager and plugins..."

    # Install TPM (Tmux Plugin Manager)
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    # Install tmux plugins
    ~/.tmux/plugins/tpm/bin/install_plugins

    log_success "Tmux plugins installed"
}

configure_mysql() {
    log_info "Configuring MySQL..."

    # Start MySQL service
    brew services start mysql

    # Wait a moment for MySQL to start
    sleep 5

    # Set root password
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" || {
        # If the above fails, try this alternative
        mysqladmin -u root password 'root' || {
            log_warning "Could not set MySQL root password automatically"
            log_info "Please run: mysqladmin -u root password 'root' manually"
        }
    }

    log_success "MySQL configured with root password"
}

setup_github_ssh() {
    log_info "Setting up GitHub SSH keys..."

    # Always set/update git config first (regardless of SSH key status)
    EMAIL="arthurdaquinosilva@gmail.com"
    git config --global user.email "$EMAIL"
    git config --global user.name "arthurdaquinosilva"
    log_info "Git config updated with your GitHub credentials"

    SSH_DIR="$HOME/.ssh"
    SSH_KEY="$SSH_DIR/id_ed25519"
    SSH_CONFIG="$SSH_DIR/config"

    # Create .ssh directory if it doesn't exist
    if [[ ! -d "$SSH_DIR" ]]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi

    # Check if SSH key already exists
    if [[ -f "$SSH_KEY" ]]; then
        log_warning "SSH key already exists at $SSH_KEY"
        log_info "If you want to regenerate with correct email, delete the key and run again:"
        log_info "rm $SSH_KEY $SSH_KEY.pub"
    else
        # Generate SSH key
        log_info "Generating SSH key for $EMAIL..."
        ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
        chmod 600 "$SSH_KEY"
        chmod 644 "$SSH_KEY.pub"
        log_success "SSH key generated successfully"
    fi

    # Create SSH config if it doesn't exist
    if [[ ! -f "$SSH_CONFIG" ]]; then
        log_info "Creating SSH config..."
        cat > "$SSH_CONFIG" << EOF
# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    UseKeychain yes
EOF
        chmod 600 "$SSH_CONFIG"
        log_success "SSH config created"
    fi

    # Start SSH agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add --apple-use-keychain "$SSH_KEY" >/dev/null 2>&1

    # Display public key for user to add to GitHub
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

    # Ask if user wants to open GitHub in browser
    echo -e "${YELLOW}Open GitHub SSH settings in browser? (y/n):${NC}"
    read -r OPEN_BROWSER
    if [[ "$OPEN_BROWSER" =~ ^[Yy]$ ]]; then
        open "https://github.com/settings/ssh/new"
    fi

    # Wait for user to add key to GitHub
    echo -e "${YELLOW}Press Enter after adding the SSH key to GitHub...${NC}"
    read -r

    # Test SSH connection
    log_info "Testing GitHub SSH connection..."
    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH connection successful!"
    else
        log_warning "GitHub SSH connection test failed. You may need to add the key manually."
        log_info "Test connection later with: ssh -T git@github.com"
    fi

    log_success "GitHub SSH setup completed"
}

setup_github_cli() {
    log_info "Setting up GitHub CLI authentication..."

    # Check if gh is available
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) not found. Install it first."
        return 1
    fi

    # Check if already authenticated
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI already authenticated"
        return 0
    fi

    # Authenticate with GitHub CLI
    log_info "Authenticating with GitHub CLI..."
    log_info "This will open GitHub in your browser for authentication."
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r

    gh auth login --git-protocol ssh --web

    # Verify authentication
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

    # Check if .vim directory already exists
    if [[ -d "$VIM_DIR" ]]; then
        # Check if it's a git repository
        if [[ -d "$VIM_DIR/.git" ]]; then
            log_warning "Vim repository directory already exists at $VIM_DIR"
            log_info "Pulling latest changes..."
            cd "$VIM_DIR"
            git pull origin main || {
                log_warning "Could not pull latest changes. You may need to resolve conflicts manually."
            }
            cd - >/dev/null
        else
            log_warning "Existing .vim directory is not a git repository"
            log_info "Backing up existing .vim directory..."
            mv "$VIM_DIR" "$VIM_DIR.backup_$(date +%Y%m%d_%H%M%S)"

            # Clone the repository
            log_info "Cloning vim repository from git@github.com:arthurdaquinosilva/vim.git..."
            git clone git@github.com:arthurdaquinosilva/vim.git "$VIM_DIR" || {
                log_error "Failed to clone vim repository. Make sure your SSH key is set up correctly."
                return 1
            }
        fi
    else
        # Clone the repository directly as .vim
        log_info "Cloning vim repository from git@github.com:arthurdaquinosilva/vim.git..."
        git clone git@github.com:arthurdaquinosilva/vim.git "$VIM_DIR" || {
            log_error "Failed to clone vim repository. Make sure your SSH key is set up correctly."
            return 1
        }
    fi

    log_success "Vim repository cloned successfully to $VIM_DIR"
}

configure_postgresql() {
    log_info "Configuring PostgreSQL..."

    # Start PostgreSQL service
    brew services start postgresql@15

    # Wait a moment for PostgreSQL to start
    sleep 5

    # Use full path to PostgreSQL binaries
    PSQL_PATH="/opt/homebrew/opt/postgresql@15/bin"
    PG_DATA_DIR="/opt/homebrew/var/postgresql@15"

    # Create postgres user and set password in a single operation
    log_info "Setting up postgres user..."

    # Single command to create user with password (if not exists) and set password
    "$PSQL_PATH/psql" -U "$(whoami)" -d postgres -c "
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
                CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD 'postgres';
            ELSE
                ALTER ROLE postgres WITH PASSWORD 'postgres';
            END IF;
        END
        \$\$;" 2>/dev/null || {
        log_warning "Could not configure postgres user automatically"
        log_info "You may need to run manually: createuser -s postgres && psql -U $(whoami) -d postgres -c \"ALTER USER postgres PASSWORD 'postgres';\""
    }

    # Configure PostgreSQL to require password authentication
    log_info "Configuring PostgreSQL to enforce password authentication..."
    PG_HBA_CONF="$PG_DATA_DIR/pg_hba.conf"

    if [[ -f "$PG_HBA_CONF" ]]; then
        # Backup original pg_hba.conf
        cp "$PG_HBA_CONF" "$PG_HBA_CONF.backup"

        # Update authentication methods to require passwords (handle both peer and trust)
        sed -i '' 's/local   all             all                                     peer/local   all             all                                     md5/' "$PG_HBA_CONF"
        sed -i '' 's/local   all             all                                     trust/local   all             all                                     md5/' "$PG_HBA_CONF"
        sed -i '' 's/host    all             all             127.0.0.1\/32            trust/host    all             all             127.0.0.1\/32            md5/' "$PG_HBA_CONF"
        sed -i '' 's/host    all             all             ::1\/128                 trust/host    all             all             ::1\/128                 md5/' "$PG_HBA_CONF"

        # Restart PostgreSQL to apply changes
        brew services restart postgresql@15
        sleep 3

        log_success "PostgreSQL configured to enforce password authentication"
    else
        log_warning "Could not find pg_hba.conf file at $PG_HBA_CONF"
    fi

    log_success "PostgreSQL configured with postgres user and password enforcement"
}

update_shell_profile() {
    log_info "Updating shell profile..."

    # Don't try to source zsh config from bash script
    log_info "Shell configuration complete. Restart your terminal or run 'source ~/.zshrc'"

    log_success "Shell profile updated"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "Starting macOS development environment setup..."
    log_info "This script will install and configure your development tools"

    # Install Homebrew if not present
    if ! command_exists brew; then
        install_homebrew
    else
        log_info "Homebrew already installed"
        # Ensure it's in PATH for this session
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
    fi

    # Check if we're in the dotfiles directory
    if [[ ! -f "setup_macos.sh" ]]; then
        log_error "Please run this script from the dotfiles directory"
        exit 1
    fi

    log_info "Starting installation process..."
    wait_for_user

    # Execute installation steps
    install_homebrew_packages
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
    update_shell_profile

    log_success "============================================================================"
    log_success "🎉 Setup completed successfully!"
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
    log_info "9. git-split-diffs --version          # Git split diffs via Homebrew"
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
