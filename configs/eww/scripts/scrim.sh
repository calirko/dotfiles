#!/usr/bin/env bash

# Open / close a blur scrim on every monitor, not just the one the menu or
# wofi lands on.
#
# Usage:
#   scrim.sh open  <menu|wofi>
#   scrim.sh close <menu|wofi>
#
# Each monitor gets its own instance of the <kind>_scrim window, with id
# <kind>_scrim_<index>. index is the eww --screen index: enabled monitors
# sorted by hyprctl id (see get-screen.sh).

set -uo pipefail

action="${1:?open|close}"
kind="${2:?menu|wofi}"
window="${kind}_scrim"

case "$action" in
  open)
    count=$(hyprctl monitors -j 2>/dev/null \
      | jq '[.[] | select((.disabled // false) == false)] | length' 2>/dev/null)
    for ((i = 0; i < ${count:-1}; i++)); do
      eww open "$window" --id "${window}_$i" --screen "$i" &
    done
    wait
    ;;
  close)
    # Close whatever instances are open, so a monitor unplugged while the
    # scrim was up doesn't leave one behind.
    ids=$(eww active-windows 2>/dev/null | cut -d: -f1 | grep -E "^${window}(_[0-9]+)?$")
    [[ -n "$ids" ]] && eww close $ids
    ;;
esac
exit 0
