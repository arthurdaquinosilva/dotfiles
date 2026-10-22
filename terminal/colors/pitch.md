# pitch

One palette for the whole terminal: cool blue/violet hues on the terminal's own
pitch-black (`#000000`) background. Backgrounds stay transparent
(`default` / `NONE` / `-1`), including selected rows in lists and menus (shown
bold/bright instead); only Visual selections, search matches and diffs paint a
surface.

| Name      | Hex       | 256 | Role                                         |
|-----------|-----------|-----|----------------------------------------------|
| bg        | `#000000` | —   | terminal background (never painted)          |
| bg1       | `#0b0d14` | 233 | faint surface (color column, scrollbar)      |
| bg2       | `#161925` | 234 | Visual selection, copy-mode selection        |
| bg3       | `#232738` | 235 | search match, word under cursor              |
| border    | `#2a2e42` | 237 | borders, separators, inactive panes          |
| gutter    | `#3b4261` | 239 | line numbers, very dim text                  |
| comment   | `#565f89` | 60  | comments, secondary/muted text               |
| muted     | `#737aa2` | 103 | status text in the CLI tools                 |
| fg_dim    | `#a9b1d6` | 146 | regular list text                            |
| fg        | `#c0caf5` | 153 | main text                                    |
| blue      | `#7aa2f7` | 111 | primary accent: focus, active border, funcs  |
| cyan      | `#7dcfff` | 117 | prompt, matches, operators                   |
| teal      | `#73daca` | 80  | types, hints                                 |
| green     | `#9ece6a` | 149 | strings, added, success                      |
| yellow    | `#e0af68` | 179 | modified, warnings, time                     |
| orange    | `#ff9e64` | 215 | numbers/constants, matching paren            |
| red       | `#f7768e` | 210 | deleted, errors, alerts                      |
| magenta   | `#bb9af7` | 141 | keywords, session/branch names               |
| add_bg    | `#0e2016` | 22  | added line background                        |
| del_bg    | `#250c12` | 52  | deleted line background                      |
| chg_bg    | `#0d1830` | 17  | changed line background                      |
| txt_bg    | `#1d3260` | 24  | changed text within a line                   |

## Where it lives

| Tool            | File                                                   |
|-----------------|--------------------------------------------------------|
| Vim             | `~/.vim/colors/pitch.vim` (separate repo)              |
| tmux            | `terminal/tmux/.tmux.conf`, `battery.sh`, `resurrect-sessions.sh` |
| fzf             | `shell/macos/zsh_files/tools.zsh` (`FZF_DEFAULT_OPTS`) |
| bat             | `terminal/bat/themes/pitch.tmTheme`                    |
| git             | `terminal/git/.gitconfig` (`[color "…"]`)              |
| git-split-diffs | `terminal/git-split-diffs/pitch.json`                  |
| lazygit         | `terminal/lazygit/config.yml`                          |
| lazydocker      | `terminal/lazydocker/config.yml`                       |
| zsh prompt      | `shell/macos/oh-my-zsh-themes.backup/pitch.zsh-theme`  |
| bash prompt     | `shell/macos/.bashrc`                                  |
| CLI tools       | `theme.py` / `theme.js` / `theme.ts` in ember, shtick, cinder, flare, lore and querky (`~/projects`); each tool has its own accent: ember orange, cinder red, flare yellow, lore green, shtick cyan, querky teal |
