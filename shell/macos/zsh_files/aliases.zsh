# ============================================================================
# 🔗 ALIASES
# ============================================================================

# Function Aliases
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

# Tool Configuration Aliases
alias pls='pretty-ls.py'
alias bat="bat --style=numbers,changes,header"
alias preview="fzf --reverse --preview 'bat --style=numbers,changes,header --color always {} 2>/dev/null || tree -C {} | head -200'"
alias t1='tree -L 1 -a --filesfirst'
alias t2='tree -L 2 -a --filesfirst'
alias t3='tree -L 3 -a --filesfirst'
alias t4='tree -L 4 -a --filesfirst'
alias t5='tree -L 5 -a --filesfirst'
alias t6='tree -L 6 -a --filesfirst'
alias t7='tree -L 7 -a --filesfirst'
alias t8='tree -L 8 -a --filesfirst'
alias t9='tree -L 9 -a --filesfirst'
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
alias '?'=duck
alias '??'=google
alias '???'=stack
alias 'tp'=translatetopt
alias 'te'=translatetoen
alias 'tsp'=translatetoes
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
alias goto='xdg-open'
alias vim='/opt/homebrew/bin/vim'
alias mke="make -f ~/Makefile.personal"
alias gfr='git-foresta'
alias gptb="tgpt --provider blackboxai"
alias gptp="tgpt --provider phind"
alias gptd="tgpt --provider duckduckgo"
alias aws=/usr/local/aws-cli/aws
