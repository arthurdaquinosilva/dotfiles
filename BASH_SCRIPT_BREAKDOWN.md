# Complete Line-by-Line Analysis of setup_macos.sh

## Table of Contents

- [Lines 1-50: Script Foundation](#lines-1-50-script-foundation)
- [Lines 51-93: Homebrew Installation](#lines-51-93-homebrew-installation)
- [Lines 95-126: Symlinks Setup](#lines-95-126-symlinks-setup)
- [Lines 127-154: Oh My Zsh Installation](#lines-127-154-oh-my-zsh-installation)
- [Lines 155-188: NVM and Node.js](#lines-155-188-nvm-and-nodejs)
- [Lines 189-217: Python Environment](#lines-189-217-python-environment)
- [Lines 218-252: Vim Plugins Setup](#lines-218-252-vim-plugins-setup)
- [Lines 253-261: FZF Configuration](#lines-253-261-fzf-configuration)
- [Lines 262-275: Tmux Plugin Setup](#lines-262-275-tmux-plugin-setup)
- [Lines 276-296: MySQL Configuration](#lines-276-296-mysql-configuration)
- [Lines 297-418: GitHub SSH Setup](#lines-297-418-github-ssh-setup)
- [Lines 379-418: GitHub CLI Setup](#lines-379-418-github-cli-setup)
- [Lines 419-458: Clone Vim Repository](#lines-419-458-clone-vim-repository)
- [Lines 459-514: PostgreSQL Configuration](#lines-459-514-postgresql-configuration)
- [Lines 515-551: Main Function & Execution](#lines-515-551-main-function--execution)
- [Summary of Advanced Techniques](#summary-of-advanced-bash-techniques)

## Lines 1-50: Script Foundation

### Line 1: Shebang

```bash
#!/bin/bash
```

- **Shebang line**: Tells the kernel which interpreter to use
- Must be the very first line, no spaces before `#!`
- `/bin/bash` is the absolute path to bash interpreter
- Alternative could be `#!/usr/bin/env bash` (more portable)

### Line 2: Whitespace

- **Empty line for readability** - good practice after shebang

### Lines 3-8: Documentation Header

```bash
# ============================================================================
# macOS Development Environment Setup Script
# ============================================================================
# Sets up a complete development environment on a new Mac Mini M4
# ============================================================================
```

# Author: Generated for Arthur Daquino

- **Documentation comments**: `#` makes everything after it a comment
- **ASCII art borders**: `=` characters create visual separation
- **Header documentation**: explains script purpose, author, target system

### Line 10: Error Handling

```bash
set -e  # Exit on any error
```

- **`set` builtin**: modifies shell behavior/options
- **`-e` flag**: "errexit" - script exits immediately if any command returns non-zero status
- **Critical for safety**: prevents script from continuing after failures
- **Alternative**: `set -euo pipefail` for even stricter error handling

### Lines 12-17: Color Variables

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
```

**ANSI Escape Codes Breakdown:**

- **`\033`**: ESC character (ASCII 27) - starts escape sequence
- **`[0;31m`**:
  - `[` starts the CSI (Control Sequence Introducer)
  - `0` = reset/normal style
  - `;` separates parameters
  - `31` = foreground red
  - `m` ends the sequence
- **`\033[1;33m`**:
  - `1` = bold/bright
  - `33` = foreground yellow
- **`\033[0m`**: Reset all formatting to default

### Lines 19-34: Logging Functions

```bash
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
```

**Function syntax breakdown:**

- **`log_info()`**: function name followed by parentheses
- **`{` and `}`**: function body delimiters
- **`echo -e`**:
  - `-e` enables interpretation of backslash escapes
  - Without `-e`, `\033` would print literally
- **`"${BLUE}[INFO]${NC} $1"`**:
  - `${BLUE}` expands to the color code variable
  - `[INFO]` is literal text
  - `${NC}` resets color
  - `$1` is the first parameter passed to function

### Lines 36-39: Command Existence Helper

```bash
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
```

**Detailed breakdown:**

- **`command -v "$1"`**:
  - `command` is a bash builtin
  - `-v` flag returns the pathname of command or alias
  - `"$1"` is quoted to handle commands with spaces
- **`>/dev/null`**:
  - `>` redirects stdout
  - `/dev/null` is a special file that discards all data
- **`2>&1`**:
  - `2` is stderr file descriptor
  - `>&1` redirects stderr to wherever stdout is going
  - Combined: both stdout and stderr go to /dev/null
- **Return value**: Function returns the exit code of `command -v`

### Lines 41-45: User Interaction Helper

```bash
wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}
```

**Breakdown:**

- **`read -r`**:
  - `read` gets input from user
  - `-r` prevents backslash interpretation (raw input)
  - No variable specified, so input goes to `$REPLY`
- **Purpose**: Pauses script execution until user presses Enter

## Lines 51-93: Homebrew Installation

### Lines 51-61: install_homebrew() Function

```bash
install_homebrew() {
    log_info "Installing Homebrew..."

    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"

    log_success "Homebrew installed successfully"
}
```

**Line-by-line breakdown:**

- **Line 52**: Call to `log_info` function we defined earlier
- **Line 55**: **Complex command breakdown**:
  - **`/bin/bash`**: Execute bash (full path for security)
  - **`-c`**: Execute the following string as a command
  - **`"$(...)"`**: Command substitution - run command and use output
  - **`curl -fsSL`**: Download file with options:
    - `-f`: Fail silently on HTTP errors
    - `-s`: Silent mode (no progress meter)
    - `-S`: Show errors even in silent mode
    - `-L`: Follow redirects
  - **URL**: GitHub's official Homebrew installer
  - **Net effect**: Downloads and immediately executes Homebrew installer

- **Line 58**: **Environment setup**:
  - **`$(...)`**: Command substitution
  - **`/opt/homebrew/bin/brew shellenv`**: Homebrew command that outputs environment variables
  - **`eval`**: Execute the string as shell commands
  - **Purpose**: Adds Homebrew to PATH for current script session

### Lines 63-93: install_homebrew_packages() Function

```bash
install_homebrew_packages() {
    log_info "Installing Homebrew packages..."

    # System monitoring tools
    brew install mactop asitop htop btop glances

    # Search and file tools
    brew install ripgrep the_silver_searcher tree fzf zoxide bat

    # Terminal and development tools
    brew install tmux lazygit lazydocker

    # GitHub and utilities
    brew install gh translate-shell

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
```

**Detailed breakdown:**

- **Lines 66-79**: **Multiple `brew install` commands**
  - Each installs multiple packages in one command
  - Grouped by functionality for organization
  - More efficient than individual install commands

- **Lines 81-84**: **Conditional installation**:
  - **`if ! command -v make >/dev/null 2>&1; then`**:
    - `!` negates the condition
    - Uses our `command_exists` pattern inline
    - Only installs `make` if it doesn't exist
  - **`fi`**: Closes the if statement

## Lines 95-126: Symlinks Setup

```bash
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
```

**Line 99-100**: **Backup directory creation**

- **`backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"`**:
  - `$HOME` expands to user's home directory
  - `$(date +%Y%m%d_%H%M%S)` is command substitution
  - `date` command with format specifiers:
    - `%Y` = 4-digit year
    - `%m` = 2-digit month
    - `%d` = 2-digit day
    - `%H` = 2-digit hour (24-hour)
    - `%M` = 2-digit minute
    - `%S` = 2-digit second
  - Creates unique timestamp for backup folder

**Line 101**: **`mkdir -p "$backup_dir"`**

- `mkdir` creates directories
- `-p` flag means "parents" - create parent directories as needed, no error if exists
- Quotes around variable prevent word splitting

**Lines 103-114**: **Nested function definition**

- **`local`**: Makes variables function-scoped instead of global
- **`source="$1"`**: First parameter to function
- **`target="$2"`**: Second parameter to function
- **`[[ -e "$target" ]]`**: Test if file/directory exists
- **`[[ -L "$target" ]]`**: Test if target is a symbolic link
- **`||`**: Logical OR operator
- **`mv "$target" "$backup_dir/"`**: Moves existing file to backup directory
- **`ln -sf "$source" "$target"`**: Creates symbolic link with force flag

## Lines 127-154: Oh My Zsh Installation

```bash
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
```

**Line 130**: **Directory existence check**

- **`[[ ! -d "$HOME/.oh-my-zsh" ]]`**: Only proceed if Oh My Zsh isn't already installed

**Lines 131-135**: **Symlink backup logic**

- **`[[ -L "$HOME/.zshrc" ]]`**: Tests if .zshrc is a symbolic link
- **`CUSTOM_ZSHRC_TARGET=$(readlink "$HOME/.zshrc")`**: `readlink` returns the target of a symbolic link

**Line 138**: **Oh My Zsh installation**

- **`"" --unattended`**: Empty string is first argument, `--unattended` makes installation non-interactive

**Line 141**: **Plugin installation**

- **`${ZSH_CUSTOM:-~/.oh-my-zsh/custom}`**: Parameter expansion with default value

**Lines 143-148**: **Restore custom configuration**

- **`[[ -n "$CUSTOM_ZSHRC_TARGET" ]]`**: `-n` tests if string is non-empty

## Lines 155-188: NVM and Node.js Setup

```bash
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

        # Install yarn and git-split-diffs globally
        npm install -g yarn git-split-diffs

        log_success "Node.js $(node --version), Yarn $(yarn --version), and git-split-diffs installed via NVM"
    else
        log_error "NVM installation failed"
        return 1
    fi
}
```

**Line 162**: **Export environment variable**

- **`export NVM_DIR="$HOME/.nvm"`**: Makes variable available to child processes

**Lines 164-167**: **Copy Homebrew's NVM files**

- **`if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then`**: `-s` tests if file exists AND has size > 0
- **`cp "/opt/homebrew/opt/nvm/bash_completion" "$HOME/.nvm/" 2>/dev/null || true`**:
  - `2>/dev/null`: Suppress errors
  - `|| true`: Prevent script failure if file doesn't exist

**Line 170**: **Source NVM script**

- **`[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"`**: Load NVM functions into current shell

**Lines 174-177**: **Node.js installation**

- **`nvm install --lts`**: Install latest Long Term Support version
- **`nvm use --lts`**: Switch to LTS version
- **`nvm alias default lts/*`**: Make LTS default for new shells

## Lines 189-217: Python Environment Setup

```bash
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
```

**Lines 193-195**: **Environment setup for pyenv**

- **`export PATH="$PYENV_ROOT/bin:$PATH"`**: Prepends pyenv's bin directory to PATH

**Line 198**: **Initialize pyenv**

- **`eval "$(pyenv init -)"`**: Sets up pyenv's shell integration

**Line 203**: **Python installation**

- **`pyenv install $PYTHON_VERSION --skip-existing`**: `--skip-existing` prevents reinstalling

**Lines 208-209**: **Version extraction**

- **`$(python --version | cut -d' ' -f2)`**:
  - `cut -d' '`: Use space as delimiter
  - `-f2`: Extract field 2 (version number)

## Lines 218-252: Vim Plugins Setup

```bash
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
```

**Line 223**: **Vim path specification**

- Ensures we use Homebrew's vim, not system vim

**Lines 226-227**: **Download vim-plug**

- **`curl -fLo ~/.vim/autoload/plug.vim --create-dirs`**:
  - `--create-dirs`: Create necessary parent directories
  - `\`: Line continuation character

**Line 236**: **Plugin installation**

- **`$VIM_PATH -c 'PlugInstall --sync' -c 'qa'`**:
  - `-c 'command'`: Execute vim command
  - `'PlugInstall --sync'`: Install plugins synchronously
  - `-c 'qa'`: Quit all windows

**Lines 242-244**: **Special plugin compilation**

- **`cd - >/dev/null`**: Return to previous directory silently

## Lines 253-261: FZF Configuration

```bash
configure_fzf() {
    log_info "Configuring FZF key bindings..."

    # Install FZF key bindings and fuzzy completion
    /opt/homebrew/opt/fzf/install --all --no-bash --no-fish

    log_success "FZF configured with key bindings"
}
```

**Line 258**: **FZF installation command**

- **`--all`**: Install all components
- **`--no-bash --no-fish`**: Only install zsh integration

## Lines 262-275: Tmux Plugin Setup

```bash
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
```

**Lines 266-268**: **TPM installation**

- Only clone TPM if not already present

**Line 271**: **Install plugins**

- Executes TPM's plugin installation script

## Lines 276-296: MySQL Configuration

```bash
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
```

**Line 281**: **Start MySQL service**

- **`brew services start mysql`**: Uses Homebrew's service management

**Line 284**: **Wait for startup**

- **`sleep 5`**: Gives MySQL time to fully start

**Lines 286-295**: **Complex password setup with fallbacks**

- **`mysql -u root -e "SQL_COMMAND" || { fallback; }`**: Multiple fallback strategies
- **Nested fallback structure**: If first method fails, try second, then provide manual instructions

## Lines 297-418: GitHub SSH Setup (Most Complex Function!)

```bash
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
```

**Lines 301-305**: **Git configuration setup**

- **`git config --global user.email "$EMAIL"`**: Sets global git email
- **`--global`**: Applies to all repositories on system

**Lines 313-315**: **SSH directory creation**

- **`chmod 700 "$SSH_DIR"`**: Permissions `rwx------` (owner only)

**Lines 322-327**: **SSH key generation**

- **`ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""`**:
  - `-t ed25519`: Use Ed25519 algorithm (modern, secure)
  - `-C "$EMAIL"`: Comment field
  - `-f "$SSH_KEY"`: Output file location
  - `-N ""`: Empty passphrase
- **`chmod 600 "$SSH_KEY"`**: Private key permissions (owner read/write only)
- **`chmod 644 "$SSH_KEY.pub"`**: Public key permissions

**Lines 332-339**: **SSH config file creation using HERE document**

- **`cat > "$SSH_CONFIG" << EOF`**: HERE document syntax
- **SSH config content**:
  - **`Host github.com`**: SSH host configuration
  - **`IdentityFile $SSH_KEY`**: Which key file to use
  - **`AddKeysToAgent yes`**: Auto-add to SSH agent
  - **`UseKeychain yes`**: Use macOS keychain

**Lines 345-346**: **SSH agent setup**

- **`eval "$(ssh-agent -s)"`**: Start SSH agent and set environment variables
- **`ssh-add --apple-use-keychain "$SSH_KEY"`**: Add key to agent with keychain

**Lines 360-364**: **Interactive browser opening**

- **`if [[ "$OPEN_BROWSER" =~ ^[Yy]$ ]]; then`**:
  - **`=~`**: Regular expression matching
  - **`^[Yy]$`**: Matches exactly "Y" or "y"

**Lines 369-376**: **SSH connection testing**

- **`ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"`**:
  - **`-T`**: Connect without pseudo-terminal
  - **`-o StrictHostKeyChecking=no`**: Skip host key verification
  - **`grep -q`**: Quiet search (exit code only)

## Lines 379-418: GitHub CLI Setup

```bash
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
```

**Lines 383-386**: **Check GitHub CLI availability**

- **`if ! command -v gh`**: Exit with error if GitHub CLI not found

**Lines 388-391**: **Check existing authentication**

- **`return 0`**: Exit function with success if already authenticated

**Line 399**: **GitHub CLI authentication**

- **`gh auth login --git-protocol ssh --web`**: Use SSH and web authentication

## Lines 419-458: Clone Vim Repository

```bash
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
```

**Complex conditional logic for handling existing directories:**

**Line 426**: **Check if it's a git repository**

- **`if [[ -d "$VIM_DIR/.git" ]]`**: Test for .git directory

**Line 429**: **Update existing repository**

- **`git pull origin main || { error_handling }`**: Try to update with fallback

**Lines 435-446**: **Handle non-git directory**

- **`mv "$VIM_DIR" "$VIM_DIR.backup_$(date +%Y%m%d_%H%M%S)"`**: Backup with timestamp
- Clone fresh repository

## Lines 459-514: PostgreSQL Configuration

```bash
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
```

**This is very complex PostgreSQL configuration:**

**Lines 467-468**: **Path variables**

- **`PSQL_PATH`**: PostgreSQL binaries location
- **`PG_DATA_DIR`**: Data directory

**Lines 473-485**: **Complex user creation using PL/pgSQL**

- **`"$(whoami)"`**: Get current username
- **`DO $$`**: Anonymous PL/pgSQL block
- **`\$\$`**: Dollar quoting (avoids quote escaping)
- **`IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres')`**: Check if user exists
- **`CREATE ROLE`** vs **`ALTER ROLE`**: Create or update user

**Lines 496-499**: **sed commands for authentication config**

- **`sed -i '' 's/pattern/replacement/'`**: In-place editing on macOS
- Changes from `peer`/`trust` to `md5` authentication:
  - **`peer`**: Use OS username (no password)
  - **`trust`**: No authentication required
  - **`md5`**: Password required

## Lines 515-551: Main Function & Execution

### Lines 515-523: Simple Shell Profile Function

```bash
update_shell_profile() {
    log_info "Updating shell profile..."

    # Don't try to source zsh config from bash script
    log_info "Shell configuration complete. Restart your terminal or run 'source ~/.zshrc'"

    log_success "Shell profile updated"
}
```

### Lines 529-565: Main Function - Heart of Execution Control

```bash
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
```

**Lines 533-539**: **Homebrew check and setup**

- **`if ! command_exists brew`**: Use our helper function
- **`eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true`**: Ensure PATH setup

**Lines 541-545**: **Directory validation**

- **`exit 1`**: Exit entire script with error code

**Lines 550-565**: **Sequential function execution (Order Matters!)**

1. **`install_homebrew_packages`**: Install all packages first
2. **`setup_github_ssh`**: SSH keys needed for git operations
3. **`setup_github_cli`**: GitHub CLI authentication
4. **`clone_vim_repository`**: Clone vim config (requires SSH)
5. **`setup_symlinks`**: Create symlinks (requires vim repo)
6. **`install_oh_my_zsh`**: Shell enhancement
7. **`setup_nvm_and_node`**: Node.js environment
8. **`setup_pyenv_and_python`**: Python environment
9. **`configure_fzf`**: Fuzzy finder setup
10. **`setup_tmux_plugins`**: Terminal multiplexer
11. **`setup_vim_plugins`**: Vim plugins (may need Node.js)
12. **`configure_mysql`**: Database setup
13. **`configure_postgresql`**: Database setup
14. **`update_shell_profile`**: Final configuration

### Lines 566-587: Success Messages and Testing Instructions

```bash
    log_success "============================================================================"
    log_success "🎉 Setup completed successfully!"
    log_success "============================================================================"
    log_warning "IMPORTANT: You MUST restart your terminal completely for everything to work!"
    log_info ""
    log_info "After restarting your terminal, test these commands:"
    log_info "1. node --version && npm --version && yarn --version  # Node.js, Yarn & git-split-diffs via NVM"
    log_info "2. python --version                   # Python via pyenv"
    log_info "3. go version                         # Go language"
    log_info "4. make --version                     # Build tool"
    log_info "5. gh --version && gh auth status        # GitHub CLI"
    log_info "6. ssh -T git@github.com              # Test GitHub SSH connection"
    log_info "7. bat --version                      # Better cat with syntax highlighting"
    log_info "8. trans --version                    # Translate shell"
    log_info "9. mysql -u root -p                   # MySQL (password: root)"
    log_info "10. psql -U postgres                  # PostgreSQL (password: postgres)"
    log_info "11. vim                               # Should work with all plugins"
    log_info "12. tmux                              # Custom tmux configuration"
    log_info ""
    log_warning "If any command doesn't work after restart, run: source ~/.zshrc"
    log_success "============================================================================"
}
```

**Comprehensive testing instructions with:**

- **`&&` operators**: Chain commands (second runs only if first succeeds)
- **Specific passwords**: Documents the credentials set up
- **Troubleshooting tip**: Manual shell reload command

### Lines 590-591: Script Entry Point

```bash
# Run main function
main "$@"
```

**Line 591**: **Script execution**

- **`main "$@"`**: Calls main function with all command-line arguments
- **`"$@"`**: Preserves argument spacing and handles spaces in arguments
- **This is where execution actually begins when script runs!**

## Summary of Advanced Bash Techniques

This script demonstrates **dozens of professional-level bash techniques**:

### 1. Error Handling & Safety

- **`set -e`**: Exit on any error
- **`|| { error_blocks }`**: Fallback error handling
- **`return 1`**: Function error codes
- **Multiple fallback strategies**: Robust failure handling

### 2. Function Design

- **Function parameters**: `$1`, `$2`, `"$@"`
- **Local variables**: `local var="value"`
- **Nested functions**: Functions defined inside functions
- **Return codes**: Success/failure indication

### 3. Conditional Logic & Testing

- **`[[ ]]` tests**: Modern bash test construct
- **File tests**: `-f`, `-d`, `-s`, `-L`, `-e`
- **String tests**: `-n`, `-z`
- **Logical operators**: `!`, `&&`, `||`
- **Regex matching**: `=~` operator

### 4. Variable Handling

- **Parameter expansion**: `${var:-default}`, `${var}`
- **Command substitution**: `$(command)`, `$(date +format)`
- **Environment variables**: `export`, `PATH` modification
- **Quoting strategies**: Prevent word splitting

### 5. Text Processing & I/O

- **HERE documents**: `<< EOF` multiline input
- **Redirection**: `>`, `>>`, `2>&1`, `>/dev/null`
- **Pipes**: `|` for command chaining
- **Text tools**: `sed`, `grep`, `cut`

### 6. Process & Service Management

- **Background processes**: SSH agents, services
- **Process substitution**: `eval "$(command)"`
- **Service control**: `brew services`
- **Session management**: Environment setup

### 7. User Interaction

- **Interactive prompts**: `read -r`
- **Color output**: ANSI escape sequences
- **Structured logging**: Consistent message formatting
- **Browser integration**: `open` command

### 8. File & Directory Operations

- **Permission management**: `chmod` with octal notation
- **Backup strategies**: Timestamped backups
- **Symbolic links**: Creation and management
- **Directory traversal**: `cd`, `cd -`

### 9. Network & Remote Operations

- **HTTP downloads**: `curl` with various flags
- **SSH operations**: Key generation, agent management
- **Git operations**: Clone, pull, authentication
- **Connection testing**: SSH connection validation

### 10. System Integration

- **Package management**: Homebrew integration
- **Database setup**: MySQL and PostgreSQL configuration
- **Development environments**: Node.js, Python version management
- **Shell customization**: zsh, Oh My Zsh integration

### 11. Advanced Patterns

- **Dependency orchestration**: Careful function ordering
- **State management**: Checking existing installations
- **Configuration management**: Multiple config file handling
- **Validation and verification**: Testing installations

This script represents **production-quality system automation** that could be used as a reference implementation for any complex development environment setup. The techniques demonstrated here are applicable to a wide range of system administration and automation tasks.

**Key Learning Points:**

- **Robust error handling** prevents partial installations
- **Modular design** makes maintenance easier
- **User experience** considerations (colors, prompts, instructions)
- **Idempotency** - script can be run multiple times safely
- **Comprehensive testing** - provides validation commands
- **Professional documentation** - clear comments and structure

This level of bash scripting demonstrates **advanced system administration skills** and **software engineering best practices** applied to shell scripting.

