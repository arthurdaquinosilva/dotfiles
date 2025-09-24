# Tokyo Night Oh My Zsh Theme
# A modern, clean theme with Tokyo Night colors and text descriptions
# Version: 2.0

# Tokyo Night Color Palette
local tn_bg="%F{#1a1b26}"
local tn_fg="%F{#c0caf5}"
local tn_blue="%F{#7aa2f7}"
local tn_purple="%F{#bb9af7}"
local tn_cyan="%F{#7dcfff}"
local tn_green="%F{#9ece6a}"
local tn_yellow="%F{#e0af68}"
local tn_red="%F{#f7768e}"
local tn_gray="%F{#565f89}"
local tn_light_gray="%F{#a9b1d6}"
local reset="%f"

# Icons for modern flat design
local label_git="󰊢"
local label_branch="󰘬"
local label_staged="󰐗"
local label_unstaged="󰛄"
local label_untracked="󰋖"
local label_stash="󰆼"
local label_ahead="󰶣"
local label_behind="󰶡"
local label_clean="󰸞"
local label_time="󰥔"

# Helper function to get current directory with icons
function _tn_current_dir() {
    local dir_path="${PWD/#$HOME/~}"
    
    # Show directory with appropriate colors and icons
    if [[ "$PWD" == "$HOME" ]]; then
        echo "${tn_blue}󰋜 ~${reset}"
    elif [[ -d ".git" ]]; then
        echo "${tn_blue}󰊢 ${dir_path}${reset}"
    else
        echo "${tn_blue}󰉋 ${dir_path}${reset}"
    fi
}

# Git status function with Tokyo Night colors
function _tn_git_status() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local git_status=""
    local branch_name
    local separator=" ${tn_gray}|${reset} "
    
    # Get branch name
    branch_name=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    
    if [[ -n "$branch_name" ]]; then
        git_status+="${tn_green}${label_branch} ${branch_name}${reset}"
        
        # Check for changes
        local staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        local unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
        local stashed=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
        
        # Show status indicators with separators
        [[ $staged -gt 0 ]] && git_status+="${separator}${tn_green}${label_staged} ${staged}${reset}"
        [[ $unstaged -gt 0 ]] && git_status+="${separator}${tn_yellow}${label_unstaged} ${unstaged}${reset}"
        [[ $untracked -gt 0 ]] && git_status+="${separator}${tn_red}${label_untracked} ${untracked}${reset}"
        [[ $stashed -gt 0 ]] && git_status+="${separator}${tn_cyan}${label_stash} ${stashed}${reset}"
        
        # Check for ahead/behind
        local ahead_behind
        ahead_behind=$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
        if [[ -n "$ahead_behind" ]]; then
            local behind=$(echo "$ahead_behind" | cut -f1)
            local ahead=$(echo "$ahead_behind" | cut -f2)
            
            [[ $ahead -gt 0 ]] && git_status+="${separator}${tn_cyan}${label_ahead} ${ahead}${reset}"
            [[ $behind -gt 0 ]] && git_status+="${separator}${tn_red}${label_behind} ${behind}${reset}"
        fi
        
        # Clean status
        if [[ $staged -eq 0 && $unstaged -eq 0 && $untracked -eq 0 ]]; then
            git_status+="${separator}${tn_green}${label_clean}${reset}"
        fi
    fi
    
    echo "$git_status"
}

# Command execution time
function _tn_exec_time() {
    if [[ -n "$_tn_command_start_time" ]]; then
        local end_time=$(date +%s)
        local elapsed=$((end_time - _tn_command_start_time))
        
        if [[ $elapsed -gt 2 ]]; then
            echo " ${tn_gray}${label_time} ${elapsed}s${reset}"
        fi
    fi
}

# Pre-command hook to capture start time
function _tn_preexec() {
    _tn_command_start_time=$(date +%s)
}

# Post-command hook to clear start time
function _tn_precmd() {
    unset _tn_command_start_time
}

# Add hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec _tn_preexec
add-zsh-hook precmd _tn_precmd

# Check if user has write permissions
function _tn_prompt_char() {
    if [[ ! -w "$PWD" ]]; then
        echo "${tn_red}[LOCKED]${reset}"
    elif [[ $UID -eq 0 ]]; then
        echo "${tn_red}#${reset}"
    else
        echo ""
    fi
}

# Virtual environment indicator
function _tn_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        echo " ${tn_yellow}󰌠 (${venv_name})${reset}"
    fi
}


# Main prompt construction
PROMPT='
${tn_purple}╭─${reset} $(_tn_current_dir)$(_tn_venv)
${tn_purple}├─${reset} $(_tn_git_status)$(_tn_exec_time)
${tn_purple}╰─$(_tn_prompt_char) '

# Right prompt (optional)
RPROMPT=''

# Continuation prompt
PROMPT2="${tn_purple}╰─${reset} ${tn_gray}>${reset} "

# Selection prompt
PROMPT3="${tn_yellow}?${reset} "

# Execution trace prompt
PROMPT4="${tn_gray}+${reset} "
