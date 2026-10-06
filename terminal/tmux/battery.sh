#!/bin/sh
# Print a tmux-formatted battery segment for the status bar.
# Prints nothing on machines without a battery (e.g. Mac mini, desktops).
#
# Colors follow the theme: green while charging, red at 20% or below.

percent=""
state=""

case "$(uname -s)" in
  Darwin)
    batt=$(pmset -g batt 2>/dev/null | grep -Eo '[0-9]+%; [a-zA-Z ]+' | head -n 1)
    percent=${batt%%%*}
    case "$batt" in
      *"; charging"*|*"; charged"*|*"; finishing charge"*) state="charging" ;;
    esac
    ;;
  Linux)
    for dir in /sys/class/power_supply/BAT*; do
      [ -r "$dir/capacity" ] || continue
      percent=$(cat "$dir/capacity")
      case "$(cat "$dir/status" 2>/dev/null)" in
        Charging|Full) state="charging" ;;
      esac
      break
    done
    ;;
esac

[ -n "$percent" ] || exit 0

if [ "$state" = "charging" ]; then
  color="colour71"
elif [ "$percent" -le 20 ]; then
  color="colour131"
else
  color="default"
fi

printf 'bat #[fg=%s,bold]%s%%#[default]  ' "$color" "$percent"
