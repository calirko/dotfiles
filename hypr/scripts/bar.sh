#!/usr/bin/env bash
set -euo pipefail
sleep 1

# Determine which monitor the bar should live on.
# Writes the screen index to /tmp/eww-bar-screen and (re)opens the bar there.

BAR_SCREEN_FILE="/tmp/eww-bar-screen"
EWW_SCREEN_SCRIPT="$HOME/.config/eww/scripts/get-screen.sh"

get_bar_screen() {
  if [[ -x "$EWW_SCREEN_SCRIPT" ]]; then
    "$EWW_SCREEN_SCRIPT"
  else
    echo 0
  fi
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