# ============================================================================
# 🔧 DEVELOPMENT & TOOLING
# ============================================================================

# Amazon Q pre block (keep at the top)
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# ============================================================================
# 🎨 OH-MY-ZSH CONFIGURATION  
# ============================================================================

# Only load Oh My Zsh if it exists
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="retrowave"

    # Plugins (keep minimal for performance) - only load if they exist
    plugins=(git)
    if [[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]]; then
        plugins+=(zsh-autosuggestions)
    fi

    # Load oh-my-zsh
    source $ZSH/oh-my-zsh.sh
else
    # Simple prompt if Oh My Zsh is not available
    export PS1="%~ %# "
fi

# ============================================================================
# 🔧 DEVELOPMENT ENVIRONMENT
# ============================================================================

# Homebrew (only if installed)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Node.js / NVM (load from ~/.nvm if available)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
fi

# Automatic node version switching
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
      nvm use
  elif [ "$(nvm version)" != "$(nvm version default)" ]; then
      nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Python / Pyenv (only if installed)
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Go (only if installed)
if command -v go >/dev/null 2>&1; then
    export GOPATH=$HOME/go
    export PATH="$GOPATH/bin:$PATH"
fi

# ============================================================================
# 🔍 FZF SETTINGS - MINIMAL
# ============================================================================

# Load FZF if available
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
elif command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)" 2>/dev/null || true
fi 

# Use default bat theme
# export BAT_THEME="ansi"

# FZF configuration (only if FZF is available)
if command -v fzf >/dev/null 2>&1; then
    # Use ag if available, otherwise find
    if command -v ag >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
        export FZF_CTRL_T_COMMAND='ag --hidden --ignore .git -g ""'
    else
        export FZF_DEFAULT_COMMAND='find . -type f 2>/dev/null'
        export FZF_CTRL_T_COMMAND='find . -type f 2>/dev/null'
    fi

    # Minimal fzf configuration with custom colors
    export FZF_DEFAULT_OPTS="
        --extended
        --height=90%
        --preview-window=noborder
        --reverse
        --border=rounded
        --prompt='> '
        --pointer='→'
        --marker='*'
        --tiebreak=index
        --color=bg:-1,bg+:-1,fg:#e8e8f0,fg+:#e8e8f0:bold
        --color=hl:#e8607a:bold,hl+:#e8607a:bold
        --color=border:#3d2fd4,info:#a89bc2,prompt:#00e5ff
        --color=pointer:#cc6af4,marker:#f4b46a,spinner:#00e5ff,header:#6b5a8e
    "

    # Simple file preview
    export FZF_CTRL_T_OPTS="
        --preview 'bat --style=numbers --color=always {} 2>/dev/null || tree -C {} | head -200'
        --preview-window=right:60%:wrap
        --prompt='Files> '
        --header='Select File'
    "

    # Directory preview
    export FZF_ALT_C_OPTS="
        --preview 'tree -C {} | head -200'
        --preview-window=right:50%
        --prompt='Dirs> '
        --header='Change Directory'
    "

    # History search
    export FZF_CTRL_R_OPTS="
        --reverse
        --preview 'echo {}'
        --preview-window=down:3:hidden:wrap
        --bind='?:toggle-preview'
        --prompt='History> '
        --header='Command History'
    "
fi

# Tmux integration
export FZF_TMUX=1
export FZF_TMUX_OPTS='-p 80%,80%'

# ============================================================================
# 🗃️  ZOXIDE SETTINGS
# ============================================================================

# Only load zoxide if installed
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
