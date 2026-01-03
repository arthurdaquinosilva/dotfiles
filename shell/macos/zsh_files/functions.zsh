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
