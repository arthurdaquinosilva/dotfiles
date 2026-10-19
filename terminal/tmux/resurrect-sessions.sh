#!/usr/bin/env bash
# Opt-in session persistence for tmux-resurrect.
# Only sessions listed in $KEEP_FILE are kept in resurrect snapshots.
#
#   toggle            mark/unmark the current session and save right away
#   filter <file>     drop unmarked sessions from a snapshot (post-save-layout hook)
#   status <session>  print a marker when the session is kept (status bar)

KEEP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/keep-sessions"
SAVE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"

mkdir -p "$(dirname "$KEEP_FILE")"
touch "$KEEP_FILE"

is_kept() { grep -Fxq -- "$1" "$KEEP_FILE"; }

case "$1" in
toggle)
	session="$(tmux display-message -p '#{session_name}')"
	if is_kept "$session"; then
		grep -Fxv -- "$session" "$KEEP_FILE" >"$KEEP_FILE.tmp"
		mv "$KEEP_FILE.tmp" "$KEEP_FILE"
		message="Session '$session' will no longer be restored"
	else
		echo "$session" >>"$KEEP_FILE"
		message="Session '$session' will be restored"
	fi
	"$SAVE_SCRIPT" quiet
	tmux display-message "$message"
	;;
filter)
	file="$2"
	[ -f "$file" ] || exit 0
	# Session name is field 2 of pane/window/grouped_session lines; keep state lines as-is
	awk -F'\t' -v keep="$KEEP_FILE" '
		BEGIN { while ((getline name < keep) > 0) kept[name] = 1 }
		$1 == "state" || ($2 in kept) { print }
	' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
	;;
status)
	is_kept "$2" && printf ' #[fg=#9ece6a]saved#[default]'
	;;
esac
