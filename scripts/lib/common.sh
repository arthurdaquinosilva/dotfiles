#!/usr/bin/env bash
# ============================================================================
# SHARED SETUP LIBRARY
# ============================================================================
# Sourced by all setup_*.sh scripts. Not meant to be executed directly.
# Requires DOTFILES_DIR to be set by the calling script before sourcing.
# ============================================================================

# ============================================================================
# CONFIGURABLE VERSIONS (override before sourcing if needed)
# ============================================================================
PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"
GO_VERSION="${GO_VERSION:-1.22.2}"
NVM_VERSION="${NVM_VERSION:-0.39.7}"
VIM_REPO_URL="${VIM_REPO_URL:-https://github.com/arthurdaquinosilva/vim.git}"
CLAUDE_INSTALL_URL="${CLAUDE_INSTALL_URL:-https://claude.ai/install.sh}"

# ============================================================================
# COLORS & LOGGING
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# HELPERS
# ============================================================================
command_exists() { command -v "$1" >/dev/null 2>&1; }

wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

prompt_user_details() {
    log_info "Please enter your details for Git and SSH configuration."

    echo -e "${YELLOW}Enter your full name (e.g., Arthur D'Aquino):${NC}"
    read -r USER_FULL_NAME

    echo -e "${YELLOW}Enter your email address (e.g., arthurdaquinosilva@gmail.com):${NC}"
    read -r USER_EMAIL

    if [[ -z "$USER_FULL_NAME" || -z "$USER_EMAIL" ]]; then
        log_error "Name and email cannot be empty."
        exit 1
    fi

    export USER_FULL_NAME USER_EMAIL
    log_success "User details captured."
}

# ============================================================================
# SYMLINKS
# ============================================================================
# Usage: setup_symlinks <zshrc_relative_path>
#   e.g. setup_symlinks "shell/ubuntu/.zshrc"
setup_symlinks() {
    local zshrc_source="$1"
    log_info "Setting up dotfile symlinks..."

    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    log_info "Existing files will be backed up to $backup_dir"

    _link() {
        local src="$DOTFILES_DIR/$1"
        local tgt="$2"
        if [[ -e "$tgt" || -L "$tgt" ]]; then
            mv "$tgt" "$backup_dir/"
        fi
        mkdir -p "$(dirname "$tgt")"
        ln -sf "$src" "$tgt"
        log_success "Linked $tgt -> $src"
    }

    _link "$zshrc_source"                   "$HOME/.zshrc"
    _link "bin"                             "$HOME/bin"
    _link "terminal/tmux/.tmux.conf"        "$HOME/.tmux.conf"
    _link "terminal/git/.gitconfig"         "$HOME/.gitconfig"
    _link "terminal/lazygit/config.yml"     "$HOME/.config/lazygit/config.yml"
    _link "terminal/lazydocker/config.yml"  "$HOME/.config/lazydocker/config.yml"

    if [[ -f "$HOME/.vim/.vimrc" ]]; then
        ln -sf "$HOME/.vim/.vimrc" "$HOME/.vimrc"
        log_success "Linked ~/.vimrc -> ~/.vim/.vimrc"
    else
        log_warning "~/.vim/.vimrc not found — skipping .vimrc symlink"
    fi

    local gitconfig_local="$HOME/.gitconfig.local"
    if [[ ! -f "$gitconfig_local" ]]; then
        printf '[split-diffs]\n\ttheme-directory = %s/terminal/git-split-diffs\n' \
            "$DOTFILES_DIR" > "$gitconfig_local"
        log_success "Created $gitconfig_local"
    else
        log_info "$gitconfig_local already exists — skipping"
    fi

    log_success "Symlinks set up (backups in $backup_dir)"
}

# ============================================================================
# GITHUB
# ============================================================================
setup_github_ssh() {
    log_info "Setting up GitHub SSH keys..."

    git config --global user.email "$USER_EMAIL"
    git config --global user.name "$USER_FULL_NAME"

    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    local ssh_config="$ssh_dir/config"

    [[ ! -d "$ssh_dir" ]] && mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"

    if [[ -f "$ssh_key" ]]; then
        log_warning "SSH key already exists at $ssh_key"
        log_info "To regenerate: rm $ssh_key $ssh_key.pub"
    else
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$ssh_key" -N ""
        chmod 600 "$ssh_key"
        chmod 644 "$ssh_key.pub"
        log_success "SSH key generated"
    fi

    if [[ ! -f "$ssh_config" ]]; then
        {
            echo "Host github.com"
            echo "    HostName github.com"
            echo "    User git"
            echo "    IdentityFile $ssh_key"
            echo "    AddKeysToAgent yes"
            [[ "$(uname)" == "Darwin" ]] && echo "    UseKeychain yes"
        } > "$ssh_config"
        chmod 600 "$ssh_config"
        log_success "SSH config created"
    fi

    eval "$(ssh-agent -s)" >/dev/null 2>&1
    if [[ "$(uname)" == "Darwin" ]]; then
        ssh-add --apple-use-keychain "$ssh_key" >/dev/null 2>&1 || true
    else
        ssh-add "$ssh_key" >/dev/null 2>&1 || true
    fi

    log_info "Your public SSH key:"
    echo -e "${GREEN}$(cat "$ssh_key.pub")${NC}"
    echo ""

    if [[ "$(uname)" == "Darwin" ]]; then
        echo -e "${YELLOW}Open GitHub SSH settings in browser? (y/n):${NC}"
        read -r _open_browser
        [[ "$_open_browser" =~ ^[Yy]$ ]] && open "https://github.com/settings/ssh/new"
    else
        log_info "Add the key at: https://github.com/settings/ssh/new"
    fi

    echo -e "${YELLOW}Press Enter after adding the key to GitHub...${NC}"
    read -r

    if ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH connection successful!"
    else
        log_warning "SSH test failed — run later: ssh -T git@github.com"
    fi
}

setup_github_cli() {
    log_info "Setting up GitHub CLI authentication..."

    if ! command_exists gh; then
        log_error "GitHub CLI not found."
        return 1
    fi

    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI already authenticated"
        return 0
    fi

    log_info "This will open GitHub in your browser for authentication."
    wait_for_user

    gh auth login --git-protocol ssh --web

    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI authenticated"
        gh auth status
    else
        log_warning "GitHub CLI authentication may have failed"
    fi
}

# ============================================================================
# VIM
# ============================================================================
clone_vim_repository() {
    log_info "Cloning vim configuration..."

    local vim_dir="$HOME/.vim"

    if [[ -d "$vim_dir/.git" ]]; then
        log_info "Pulling latest vim config..."
        git -C "$vim_dir" pull origin main || log_warning "Could not pull — resolve conflicts manually."
    elif [[ -d "$vim_dir" ]]; then
        log_warning "~/.vim exists but is not a git repo — backing up..."
        mv "$vim_dir" "${vim_dir}.backup_$(date +%Y%m%d_%H%M%S)"
        git clone "$VIM_REPO_URL" "$vim_dir" || { log_error "Failed to clone vim repo."; return 1; }
    else
        git clone "$VIM_REPO_URL" "$vim_dir" || { log_error "Failed to clone vim repo."; return 1; }
    fi

    log_success "Vim config ready at $vim_dir"
}

# Usage: setup_vim_plugins <vim_binary_path>
setup_vim_plugins() {
    local vim_path="${1:-$(command -v vim)}"
    log_info "Installing Vim plugins..."

    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    "$vim_path" -c 'PlugInstall --sync' -c 'qa' || true

    if [[ -d "$HOME/.vim/plugged/vim-hexokinase" ]]; then
        log_info "Compiling vim-hexokinase..."
        make -C "$HOME/.vim/plugged/vim-hexokinase" hexokinase
        log_success "vim-hexokinase compiled"
    fi

    log_success "Vim plugins installed"
    command_exists node || log_warning "Some plugins (CoC) need Node.js — restart terminal and run vim."
}

# ============================================================================
# SHELL
# ============================================================================
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        local zshrc_target=""
        [[ -L "$HOME/.zshrc" ]] && zshrc_target=$(readlink "$HOME/.zshrc")

        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        if [[ -n "$zshrc_target" ]]; then
            rm -f "$HOME/.zshrc"
            ln -sf "$zshrc_target" "$HOME/.zshrc"
        fi

        log_success "Oh My Zsh installed"
    else
        log_info "Oh My Zsh already installed"
    fi

    # Install zsh-autosuggestions unconditionally — runs whether OMZ was just
    # installed or already existed, so re-running the script never skips it.
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$zsh_custom/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_info "zsh-autosuggestions already installed"
    fi

    # Custom themes — symlinked so edits in the repo take effect immediately.
    local theme_src="$DOTFILES_DIR/shell/macos/oh-my-zsh-themes.backup/retrowave.zsh-theme"
    if [[ -f "$theme_src" ]]; then
        mkdir -p "$zsh_custom/themes"
        ln -sf "$theme_src" "$zsh_custom/themes/retrowave.zsh-theme"
        log_success "retrowave theme installed"
    else
        log_warning "retrowave theme not found at $theme_src"
    fi
}

# ============================================================================
# NODE / NVM
# ============================================================================
# Usage: setup_nvm_and_node [brew_prefix]
#   brew_prefix: macOS only — homebrew prefix (e.g. /opt/homebrew or /usr/local)
#   Omit on Ubuntu; NVM will be installed via curl instead.
setup_nvm_and_node() {
    local brew_prefix="${1:-}"
    log_info "Setting up NVM and Node.js..."

    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"

    if [[ -n "$brew_prefix" ]]; then
        local brew_nvm_sh="$brew_prefix/opt/nvm/nvm.sh"
        if [[ -s "$brew_nvm_sh" ]]; then
            # Symlink so ~/.nvm/nvm.sh stays current when Homebrew updates nvm
            ln -sf "$brew_nvm_sh" "$NVM_DIR/nvm.sh"
            ln -sf "$brew_prefix/opt/nvm/bash_completion" "$NVM_DIR/bash_completion" 2>/dev/null || true
            source "$NVM_DIR/nvm.sh"
        else
            log_error "NVM not found at $brew_nvm_sh — run: brew install nvm"
            return 1
        fi
    else
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    fi

    if type nvm &>/dev/null; then
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
        npm install -g yarn
        npm install -g git-split-diffs
        log_success "Node.js $(node --version), Yarn $(yarn --version), git-split-diffs installed"
    else
        log_error "NVM not available after install"
        return 1
    fi
}

# ============================================================================
# PYTHON
# ============================================================================
setup_pyenv_and_python() {
    log_info "Setting up pyenv and Python $PYTHON_VERSION..."

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    if command_exists pyenv; then
        eval "$(pyenv init -)"
        pyenv install "$PYTHON_VERSION" --skip-existing
        pyenv global "$PYTHON_VERSION"
        python --version >/dev/null 2>&1 \
            && log_success "Python $(python --version | cut -d' ' -f2) set via pyenv" \
            || log_warning "Python installed but not yet in PATH — restart terminal."
    else
        log_error "pyenv not found in PATH"
        return 1
    fi
}

# ============================================================================
# TMUX
# ============================================================================
setup_tmux_plugins() {
    log_info "Setting up tmux plugins..."

    [[ ! -d "$HOME/.tmux/plugins/tpm" ]] && \
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    ~/.tmux/plugins/tpm/bin/install_plugins || true
    log_success "Tmux plugins installed"
}

# ============================================================================
# CLAUDE CODE
# ============================================================================
install_claude() {
    log_info "Installing Claude Code..."

    if command_exists claude; then
        log_info "Claude Code already installed"
        return 0
    fi

    curl -fsSL "$CLAUDE_INSTALL_URL" | bash
    export PATH="$HOME/.local/bin:$PATH"

    command_exists claude \
        && log_success "Claude Code installed" \
        || log_warning "Claude Code installed but not in PATH yet — available after terminal restart"
}

setup_claude_auth() {
    log_info "Authenticating Claude Code..."

    if ! command_exists claude; then
        log_warning "Claude Code not in PATH — authenticate manually by running: claude"
        return 0
    fi

    log_info "Claude Code requires a one-time browser login."
    log_info "Open a new terminal tab, run 'claude', and complete authentication in your browser."
    echo -e "${YELLOW}Press Enter once you have completed Claude authentication...${NC}"
    read -r

    log_success "Claude Code authentication step complete"
}
