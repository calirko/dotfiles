#!/usr/bin/env bash
set -euo pipefail

# Determine which monitor the bar should live on.
# Writes the screen index to /tmp/eww-bar-screen and (re)opens the bar there.

HOSTNAME=$(hostname)
BAR_SCREEN_FILE="/tmp/eww-bar-screen"

get_bar_screen() {
  case "$HOSTNAME" in
    shark)
      # Desktop — single AOC, always monitor 0
      echo 0
      ;;
    fox)
      # Laptop — check if eDP-1 is active
      if hyprctl monitors -j | jq -e '.[] | select(.name == "eDP-1")' > /dev/null 2>&1; then
        # Lid open: eDP-1 exists, bar on monitor 0 (eDP-1 or wherever you prefer)
        echo 0
      else
        # Lid closed: eDP-1 disabled, bar on the primary external
        # Pick the monitor with the lowest ID that is still active
        hyprctl monitors -j | jq -r 'sort_by(.id) | .[0].id'
      fi
      ;;
    *)
      echo 0
      ;;
  esac
}

reopen_bar() {
  local screen
  screen=$(get_bar_screen)
  echo "$screen" > "$BAR_SCREEN_FILE"

  # Close existing bar (ignore errors if not open)
  eww close bar 2>/dev/null || true

  # Small delay so eww processes the close
  sleep 0.3

  # Open on the target screen
  eww open bar --screen "$screen"
}

reopen_bar