# macOS Development Environment Setup

Automated setup scripts for a complete macOS development environment on Mac Mini M4.

## Quick Start

1. **Install the environment:**
   ```bash
   ./setup_macos.sh
   ```

2. **Test the cleanup script:**
   ```bash
   ./cleanup_macos.sh
   ```

## What Gets Installed

### System Monitoring Tools
- `mactop` - macOS system monitor
- `asitop` - Activity monitor for Apple Silicon
- `htop` - Interactive process viewer
- `btop` - Modern htop alternative
- `glances` - System monitoring tool

### Development Tools
- `ripgrep` (rg) - Fast text search
- `the_silver_searcher` (ag) - Code search tool
- `tree` - Directory tree viewer
- `fzf` - Fuzzy finder with key bindings
- `zoxide` - Smart directory jumper
- `tmux` - Terminal multiplexer with custom config
- `lazygit` - Git TUI
- `lazydocker` - Docker TUI

### Programming Languages
- **Node.js** - Latest LTS via NVM
- **Python** - Latest 3.12.x via pyenv
- **Vim** - Homebrew version with plugins

### Databases
- **MySQL** - With root user (password: `root`)
- **PostgreSQL** - With postgres user (password: `postgres`)

### Shell Environment
- **Oh My Zsh** - Enhanced shell with autosuggestions
- **Custom .zshrc** - With all tool configurations

## File Structure

```
dotfiles/
├── setup_macos.sh          # Main installation script
├── cleanup_macos.sh        # Complete removal script
├── vim_with_node.sh        # Vim launcher with Node.js
├── vim/                    # Vim configuration
│   ├── .vimrc             # Main vim config
│   └── ...                # Plugin configurations
├── shell/macos/
│   └── .zshrc             # Shell configuration
├── terminal/
│   ├── tmux/.tmux.conf    # Tmux configuration
│   └── git/.gitconfig     # Git configuration
└── README.md              # This file
```

## Usage

### Installation
Run the main setup script:
```bash
./setup_macos.sh
```

The script will:
1. Install all Homebrew packages
2. Create symbolic links to dotfiles
3. Install Oh My Zsh with plugins
4. Set up Node.js via NVM
5. Set up Python via pyenv
6. Configure databases with default users
7. Install vim plugins
8. Configure FZF key bindings
9. Install tmux plugins

### Testing/Cleanup
To completely remove everything and test again:
```bash
./cleanup_macos.sh
```

This will remove all installed packages, configurations, and restore your system to its previous state.

### Post-Installation

After running the setup:

1. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

2. **Test database connections:**
   ```bash
   mysql -u root -p          # password: root
   psql -U postgres          # password: postgres
   ```

3. **Test development tools:**
   ```bash
   vim                       # Should load with all plugins
   tmux                      # Custom configuration
   node --version            # Node.js via NVM
   python --version          # Python via pyenv
   ```

## Key Features

- **Safe installation** - Backs up existing configurations
- **Complete cleanup** - Fully reversible for testing
- **Homebrew integration** - Uses system package manager
- **Custom configurations** - Pre-configured dotfiles
- **Database setup** - Ready-to-use MySQL and PostgreSQL
- **Modern tools** - Latest versions of all development tools

## Requirements

- macOS (tested on Mac Mini M4)
- Homebrew already installed
- Internet connection for downloads

## Troubleshooting

If something goes wrong:

1. **Check the logs** - Scripts provide detailed output
2. **Run cleanup** - Use `./cleanup_macos.sh` to reset
3. **Manual fixes** - Scripts are well-commented for manual steps
4. **Database issues** - Restart services: `brew services restart mysql`

---

Generated for Arthur Daquino's Mac Mini M4 setup.