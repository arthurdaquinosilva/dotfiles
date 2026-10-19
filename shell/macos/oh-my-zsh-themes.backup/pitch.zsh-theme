# pitch Oh My Zsh theme (palette: terminal/colors/pitch.md)

function _pitch_user_binary_raw() {
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

function _pitch_precmd() {
    local dir branch binary left_plain colored_left pad

    if [[ "$PWD" == "$HOME" ]]; then
        dir="~"
    else
        dir="${PWD##*/}"
    fi

    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    binary=$(_pitch_user_binary_raw)

    # Plain text for width calculation
    left_plain="${dir}"
    [[ -n "$branch" ]] && left_plain+=" ${branch}"

    pad=$(( COLUMNS - ${#left_plain} - ${#binary} ))
    (( pad < 1 )) && pad=1

    # Colored version
    colored_left="%F{#7aa2f7}%B${dir}%b%f"
    [[ -n "$branch" ]] && colored_left+=" %F{#bb9af7}${branch}%f"

    print -P "${colored_left}$(printf '%*s' $pad '')%F{#3b4261}${binary}%f"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _pitch_precmd

PROMPT='%F{#7dcfff}>%f '
RPROMPT=''
PROMPT2='%F{#7dcfff}>%f '
