# ============================================================================
# TOKYO NIGHT BASH CONFIGURATION (macOS)
# ============================================================================
# A beautiful, well-organized bash configuration with Tokyo Night theming
# Converted from zsh configuration for compatibility

# ============================================================================
# 🚀 INITIAL SETUP
# ============================================================================

# Amazon Q pre block (keep at the top)
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/bashrc.pre.bash"

# ============================================================================
# ⚙️  CORE SYSTEM SETTINGS
# ============================================================================

# Vi mode settings
set -o vi
export EDITOR=vi
export VISUAL=vi
export EDITOR_PREFIX=vi

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

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Node.js / NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Python / Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Go
export GOPATH=$HOME/go
export PATH="$GOPATH/bin:$PATH"

# Java
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export JDK_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# MySQL
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/mysql@8.0/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql@8.0/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql@8.0/lib/pkgconfig"

# ============================================================================
# 🔍 FZF SETTINGS - TOKYO NIGHT THEME
# ============================================================================

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
eval "$(fzf --bash)" 

# Tokyo Night theme for bat
export BAT_THEME="TokyoNight"

# FZF configuration with Tokyo Night colors
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_CTRL_T_COMMAND='ag --hidden --ignore .git -g ""'

# Tokyo Night color scheme for fzf
export FZF_DEFAULT_OPTS="
    --extended
    --height=90%
    --preview-window=noborder
    --reverse
    --border=rounded
    --prompt='🔍 '
    --pointer='▶ '
    --marker='✓ '
    --color=fg:#c0caf5,bg:-1,hl:#bb9af7
    --color=fg+:#c0caf5,bg+:-1,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#bb9af7,pointer:#f7768e
    --color=marker:#9ece6a,spinner:#f7768e,header:#9ece6a
    --color=border:#414868
    --tiebreak=index
"

# Enhanced preview with bat Tokyo Night theme
export FZF_CTRL_T_OPTS="
    --preview 'bat --theme=TokyoNight --style=numbers --color=always {} 2>/dev/null || tree -C {} | head -200'
    --preview-window=right:60%:wrap
    --prompt='📁 '
    --header='📂 Select File'
"

# Directory preview with tree
export FZF_ALT_C_OPTS="
    --preview 'tree -C {} | head -200'
    --preview-window=right:50%
    --prompt='📂 '
    --header='🗂️  Change Directory'
"

# History search
export FZF_CTRL_R_OPTS="
    --reverse
    --preview 'echo {}'
    --preview-window=down:3:hidden:wrap
    --bind='?:toggle-preview'
    --prompt='📜 '
    --header='🕒 Command History'
"

# Tmux integration
export FZF_TMUX=1
export FZF_TMUX_OPTS='-p 80%,80%'

# ============================================================================
# 🗃️  ZOXIDE SETTINGS (bash version)
# ============================================================================

# Initialize zoxide for bash
eval "$(zoxide init bash)"

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

tn() {
    tmux new -s $(pwd | sed 's/.*\///g')
}

mk() {
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

# ============================================================================
# 🎨 ALIASES - TOOL CONFIGURATIONS
# ============================================================================

# Pretty ls
alias pls='pretty-ls.py'

# Bat - Tokyo Night
alias bat="bat --theme=TokyoNight --style=numbers,changes,header"
alias preview="fzf --reverse --preview 'bat --theme=TokyoNight --style=numbers,changes,header --color always {} 2>/dev/null || tree -C {} | head -200'"

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

# Broot
source /Users/arthurdaquino/.config/broot/launcher/bash/br

# Deno
. "/Users/arthurdaquino/.deno/env"

# ============================================================================
# 🎨 BASH-SPECIFIC ENHANCEMENTS & TOKYO NIGHT PROMPT
# ============================================================================

# Tokyo Night Prompt with Git Integration
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Tokyo Night Colors
TOKYO_PURPLE='\[\033[38;5;177m\]'
TOKYO_BLUE='\[\033[38;5;75m\]'
TOKYO_GREEN='\[\033[38;5;158m\]'
TOKYO_YELLOW='\[\033[38;5;221m\]'
TOKYO_RED='\[\033[38;5;203m\]'
TOKYO_CYAN='\[\033[38;5;117m\]'
TOKYO_GRAY='\[\033[38;5;59m\]'
TOKYO_WHITE='\[\033[38;5;250m\]'
RESET='\[\033[0m\]'

# Beautiful Tokyo Night Prompt
PS1="${TOKYO_PURPLE}❯${RESET} ${TOKYO_BLUE}\u${RESET}${TOKYO_GRAY}@${RESET}${TOKYO_CYAN}\h${RESET} ${TOKYO_YELLOW}\w${RESET} ${TOKYO_GREEN}\$(parse_git_branch)${RESET}\n${TOKYO_PURPLE}❯${RESET} "

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Homebrew bash completion
if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "$COMPLETION"
    done
  fi
fi

# ============================================================================
# 🌃 END OF TOKYO NIGHT BASH CONFIGURATION
# ============================================================================
