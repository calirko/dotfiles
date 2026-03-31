#!/usr/bin/env bash
set -euo pipefail

HOSTNAME=$(uname -n)

get_screen() {
  case "$HOSTNAME" in
    shark) echo 0 ;;
    fox)
      if hyprctl monitors -j | jq -e '.[] | select(.name == "eDP-1")' > /dev/null 2>&1; then
        echo 0
      else
        hyprctl monitors -j | jq -r 'sort_by(.id) | .[0].id'
      fi
      ;;
    *) echo 0 ;;
  esac
}

is_open() {
  eww active-windows | tr ' ' '\n' | grep -qx "sensors"
}

if is_open; then
  eww close sensors || true
  eww close menu_scrim || true
else
  local_screen=$(get_screen)
  eww open menu_scrim --screen $(hyprctl activewindow -j | jq '.monitor')
  eww open sensors --screen "$local_screen"
fi