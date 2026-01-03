# macOS Development Environment Setup

Automated and opinionated setup scripts for a complete macOS development environment, tested on Apple Silicon (M-series chips).

This repository contains all the configuration files and scripts to bootstrap a new macOS machine for development. The setup is designed to be interactive, modular, and easy to maintain.

## Quick Start

1.  **Clone the Repository:**
    Clone this repository to your local machine, typically into `~/dotfiles`.

    ```bash
    git clone git@github.com:arthurdaquinosilva/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Run the Setup Script:**
    Execute the main setup script. It will guide you through the process, ask for your details (name and email for Git/SSH), and install all the necessary tools and configurations.

    ```bash
    ./setup_macos.sh
    ```

3.  **Restart Your Terminal:**
    After the script completes, quit and restart your terminal completely to ensure all new settings and shell configurations are loaded.

## What Gets Installed

### Core Tools
- **Homebrew:** The missing package manager for macOS (will be installed automatically).
- **Oh My Zsh:** A framework for managing Zsh configuration, with the `zsh-autosuggestions` plugin.
- **Git:** With a clean, consolidated configuration.

### System & File Utilities
- **Monitoring:** `mactop`, `asitop`, `htop`, `btop`, `glances`
- **File System:** `ripgrep` (rg), `the_silver_searcher` (ag), `tree`, `fzf`, `zoxide`, `bat`

### Development Environment
- **Terminal:** `tmux` (with a custom configuration), `lazygit`, `lazydocker`
- **Languages:** Node.js (via NVM), Python (via Pyenv), Go
- **Editor:** Vim (from Homebrew) with a curated set of plugins.
- **Databases:** MySQL and PostgreSQL (services started, default passwords set).
- **GitHub:** `gh` (CLI) and `git-split-diffs`.
- **Utilities:** `translate-shell`, `make`.

## File Structure
```
dotfiles/
├── setup_macos.sh          # Main interactive installation script
├── cleanup_macos.sh        # Uninstalls everything set up by the main script
├── .gitignore
├── bin/                    # Custom executable scripts for your $PATH
│   ├── copy_history
│   ├── cur
│   ├── eur
│   ├── git-foresta
│   └── ...
├── shell/
│   └── macos/              # macOS-specific shell configuration
│       ├── .zshrc          # Main Zsh entrypoint (loads modules)
│       └── zsh_files/      # Modular Zsh configuration files
│           ├── aliases.zsh
│           ├── environment.zsh
│           ├── functions.zsh
│           └── tools.zsh
└── terminal/
    ├── bat/                # `bat` configuration
    ├── git/                # `git` configuration
    ├── git-split-diffs/    # `git-split-diffs` theme
    ├── lazydocker/         # `lazydocker` configuration
    ├── lazygit/            # `lazygit` configuration
    └── tmux/               # `tmux` configuration
```

## Key Features

- **Interactive Setup:** Prompts for user-specific details like name and email.
- **Modular & Maintainable:** Configurations are broken down into logical files and directories.
- **Data-Driven Symlinking:** Symlink management is centralized, making it easy to add new dotfiles.
- **Safe Installation:** Automatically backs up any existing dotfiles before creating symlinks.
- **Complete Cleanup:** A `cleanup_macos.sh` script is provided to fully reverse the setup process, ideal for testing.
- **Ready-to-Use Environment:** Includes pre-configured settings for databases, shells, and development tools.

## Requirements

- A fresh macOS installation (tested on Apple Silicon).
- An internet connection for downloading packages and cloning repositories.

## Post-Installation Checks

After running the setup and restarting your terminal:

1.  **Test Development Tools:**
    ```bash
    node --version      # Should show Node.js version
    python --version    # Should show Python version from pyenv
    go version          # Should show Go version
    gh --version        # Should show GitHub CLI version
    vim --version       # Should show Vim from Homebrew
    ```

2.  **Test SSH and Git:**
    ```bash
    ssh -T git@github.com # Should show a welcome message from GitHub
    ```

3.  **Test Database Connections:**
    ```bash
    mysql -u root -p      # (password is 'root')
    psql -U postgres      # (password is 'postgres')
    ```

## Troubleshooting

If something goes wrong during the setup:

1.  **Check the logs:** The script provides detailed output with status messages, warnings, and errors.
2.  **Run the cleanup script:** To get back to a clean state, run `./cleanup_macos.sh`. This is the safest way to reset before trying again.
3.  **Manual fixes:** The scripts are well-commented, so you can also run functions individually for manual debugging.

---
Generated for Arthur Daquino's Mac setup.