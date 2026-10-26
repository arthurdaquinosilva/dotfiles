#!/usr/bin/env bash
# Guard around tmux-resurrect's restore, used by continuum and prefix + C-r.
# A snapshot with no kept sessions restores nothing, then resurrect kills
# session 0 (the one just opened) and the client exits. Skip it instead.

LAST_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last"
RESTORE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

if grep -q '^pane' "$LAST_FILE" 2>/dev/null; then
	exec "$RESTORE_SCRIPT"
fi
tmux display-message "No saved sessions to restore"
