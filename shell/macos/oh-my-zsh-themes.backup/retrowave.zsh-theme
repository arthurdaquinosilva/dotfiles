# Retrowave Oh My Zsh Theme
# Version: 4.1 — minimal with branch

function _rw_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && echo " %F{#6b5a8e}|%f %F{#6b5a8e}branch:%f %F{#cc6af4}${branch}%f"
}

PROMPT='%F{#6b5a8e}user:%f %F{#f47caa}%n%f %F{#6b5a8e}|%f %F{#6b5a8e}dir:%f %F{#00e5ff}%1~%f$(_rw_branch)
%F{#6b5a8e}>%f '
RPROMPT=''
PROMPT2='%F{#6b5a8e}>%f '
