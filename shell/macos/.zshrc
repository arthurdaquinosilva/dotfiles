# ============================================================================
# MINIMAL ZSH CONFIGURATION (macOS)
# ============================================================================
# A clean, minimal zsh configuration using default terminal colors

# ============================================================================
# 🚀 INITIAL SETUP
# ============================================================================

# Amazon Q pre block (keep at the top)
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# ============================================================================
# 🎨 OH-MY-ZSH CONFIGURATION  
# ============================================================================

# Only load Oh My Zsh if it exists
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="robbyrussell"

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
# ⚙️  CORE SYSTEM SETTINGS
# ============================================================================

# Vi mode settings
set -o vi
export EDITOR=vi
export VISUAL=vi
export EDITOR_PREFIX=vi

# Make vi-yank copy to system clipboard (macOS)
  function vi-yank-pbcopy {
      zle vi-yank
      echo -n "$CUTBUFFER" | pbcopy
  }
  zle -N vi-yank-pbcopy
  bindkey -M vicmd 'y' vi-yank-pbcopy

# Path configuration
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
export PATH="$PATH:/opt/homebrew/bin/"
export PATH="$PATH:/Library/PostgreSQL/15/bin"
export PATH="$PATH:/opt/homebrew/bin/python3.12"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"

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
load-nvmrc() {
autoload -U add-zsh-hook
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

        if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
        elif [ "$nvmrc_node_version" != "$node_version" ]; then
            nvm use
        fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
        echo "Reverting to nvm default version"
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

# Java
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export JDK_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# MySQL
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/mysql@8.0/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql@8.0/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql@8.0/lib/pkgconfig"

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

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
        --color=bg+:-1,fg+:white:bold,hl+:red:bold
        --color=info:cyan,prompt:cyan,pointer:cyan
        --color=marker:yellow,spinner:cyan,header:dim
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

# ============================================================================
# 🎯 CUSTOM FUNCTIONS
# ============================================================================

# File opening functions
open_file_with_vim() {
  vim $(preview)
}

open_file_with_nvim() {
  nvim $(preview)
}

# Git functions
git_diff_file() {
  git status --porcelain | grep '^ M' | cut -c4- | \
  fzf --multi --preview 'git diff --color=always {}' | \
  xargs -r git diff
}

fzf_git_add_files() {
  git status --porcelain | grep '^ M' | cut -c4- | \
  fzf --multi --preview 'git diff --color=always {}' | \
  xargs -r git add
}

call_lazygit() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

fzf_git_branch() {
    git branch --color=always --all --sort=-committerdate |
        grep -v HEAD |
        fzf --height 50% --ansi --no-multi --preview-window right:65% \
            --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' \
            --print-query
}

fzf_git_checkout() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    local output query branch
    output=$(fzf_git_branch)
    query=$(echo "$output" | head -1)
    branch=$(echo "$output" | tail -1)
    
    if [[ -z "$branch" && -n "$query" ]]; then
        branch="$query"
    fi

    if [[ -z "$branch" ]]; then
        return
    fi

    branch=$(echo "$branch" | awk '{print $1}')
    branch=${branch#remotes/origin/}

    if git rev-parse --verify --quiet "$branch^{commit}" >/dev/null 2>&1; then
        git checkout "$branch"
    else
        echo -n "Branch '$branch' doesn't exist. Do you want to create it? (y/n): "
        read choice
        case "$choice" in 
            y|Y ) 
                echo "Creating and checking out branch '$branch'"
                git checkout -b "$branch" 
                ;;
            n|N ) 
                echo "Branch creation cancelled." 
                ;;
            * ) 
                echo "Invalid choice. Branch creation cancelled." 
                ;;
        esac
    fi
}

fzf_git_show_commits() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | git-split-diffs --color | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

fzf_to_clipboard() {
  local result
  result=$(fzf)
  if [ -n "$result" ]; then
    if [ "$(uname)" = "Darwin" ]; then
      echo -n "$result" | pbcopy
    elif [ -n "$WAYLAND_DISPLAY" ]; then
      echo -n "$result" | wl-copy
    elif [ -n "$DISPLAY" ]; then
      echo -n "$result" | xclip -selection clipboard
    else
      echo "Clipboard not supported"
      return 1
    fi
    echo "Copied to clipboard: $result"
  fi
}

# Utility functions
select_directories() {
  z $(zoxide query -l | fzf)
}

function tn() {
    tmux new -s $(pwd | sed 's/.*\///g')
}

function mk() {
    local target
    target=$(mke list | fzf)
    if [ -n "$target" ]; then
        mke "$target"
    fi
}

# ============================================================================
# 🔗 ALIASES - FUNCTION ALIASES
# ============================================================================

alias fshow=fzf_git_show_commits
alias gb=fzf_git_branch
alias gco=fzf_git_checkout
alias gdf=git_diff_file
alias gaf=fzf_git_add_files
alias lg=call_lazygit
alias v=open_file_with_vim
alias nv=open_file_with_nvim
alias fzcp=fzf_to_clipboard
alias tt=select_directories
alias tn=tn
alias mk=mk

# ============================================================================
# 🎨 ALIASES - TOOL CONFIGURATIONS
# ============================================================================

# Pretty ls
alias pls='pretty-ls.py'

# Bat - minimal
alias bat="bat --style=numbers,changes,header"
alias preview="fzf --reverse --preview 'bat --style=numbers,changes,header --color always {} 2>/dev/null || tree -C {} | head -200'"

# Tree
alias t1='tree -L 1 -a'
alias t2='tree -L 2 -a'
alias t3='tree -L 3 -a'
alias t4='tree -L 4 -a'
alias t5='tree -L 5 -a'
alias t6='tree -L 6 -a'
alias t7='tree -L 7 -a'
alias t8='tree -L 8 -a'
alias t9='tree -L 9 -a'
alias t10='tree -L 10 -a'

alias tt1='tree -L 1 -guphDA'
alias tt2='tree -L 2 -guphDA'
alias tt3='tree -L 3 -guphDA'
alias tt4='tree -L 4 -guphDA'
alias tt5='tree -L 5 -guphDA'
alias tt6='tree -L 6 -guphDA'
alias tt7='tree -L 7 -guphDA'
alias tt8='tree -L 8 -guphDA'
alias tt9='tree -L 9 -guphDA'
alias tt10='tree -L 10 -guphDA'

# Web search
alias '?'=duck
alias '??'=google
alias '???'=stack

# Translation
alias 'tp'=translatetopt
alias 'te'=translatetoen
alias 'tsp'=translatetoes

# Tmuxinator
alias tns='tmuxinator new'
alias tst='tmuxinator start'
tstp() {
    local session=$(tmux lsc 2>/dev/null | cut -d ' ' -f2)
    if [ -n "$session" ]; then
        tmuxinator stop "$session"
    else
        echo "No tmux sessions found"
    fi
}
alias ts='tmuxinator-fzf-start.sh'
alias tmux='tmux -u'

# Utilities
alias goto='xdg-open'
alias vim='/opt/homebrew/bin/vim'
alias mke="make -f ~/Makefile.personal"

# Git
alias gfr='git-foresta'

# AI Tools
alias gptb="tgpt --provider blackboxai"
alias gptp="tgpt --provider phind"
alias gptd="tgpt --provider duckduckgo"

# AWS
alias aws=/usr/local/aws-cli/aws

# ============================================================================
# 🔑 API KEYS & ENVIRONMENT VARIABLES
# ============================================================================

export GEMINI_API_KEY="AIzaSyADlXz_gxgIJZx-EJy2xnkY4p_jXU7b_XY"
export ANTHROPIC_API_KEY="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"
export OLLAMA_API_BASE="http://127.0.0.1:11434"
export SRC_ENDPOINT=https://sourcegraph.com
export SRC_ACCESS_TOKEN="sgp_fd1b4edb60bf82b8_3f67977b2d27bb76f4f4b80f5a91a0220680f2d7"

# ============================================================================
# 🔧 ADDITIONAL INTEGRATIONS
# ============================================================================

# Deno (only if installed)
if [[ -f "$HOME/.deno/env" ]]; then
    source "$HOME/.deno/env"
fi

# ============================================================================
# 🌟 END OF MINIMAL ZSH CONFIGURATION
# ============================================================================

# Final check to ensure homebrew is available if installed
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="/Library/TeX/texbin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
