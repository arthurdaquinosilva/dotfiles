# Retrowave Oh My Zsh Theme
# Version: 4.4

function _rw_user_binary_raw() {
    local result="" char val b i
    for char in ${(s::)USER}; do
        val=$(printf '%d' "'$char")
        b=""
        for (( i=7; i>=0; i-- )); do
            b="${b}$(( (val >> i) & 1 ))"
        done
        result+="$b "
    done
    echo "${result% }"
}

function _rw_precmd() {
    local dir branch binary left_plain colored_left pad

    if [[ "$PWD" == "$HOME" ]]; then
        dir="~"
    else
        dir="${PWD##*/}"
    fi

    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    binary=$(_rw_user_binary_raw)

    # Plain text for width calculation
    left_plain="${dir}"
    [[ -n "$branch" ]] && left_plain+=" ${branch}"

    pad=$(( COLUMNS - ${#left_plain} - ${#binary} ))
    (( pad < 1 )) && pad=1

    # Colored version
    colored_left="%F{cyan}%B${dir}%b%f"
    [[ -n "$branch" ]] && colored_left+=" %F{red}${branch}%f"

    print -P "${colored_left}$(printf '%*s' $pad '')%F{235}${binary}%f"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _rw_precmd

PROMPT='%F{yellow}>%f '
RPROMPT=''
PROMPT2='%F{yellow}>%f '
