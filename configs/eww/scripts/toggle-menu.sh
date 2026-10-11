#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

(
  flock -n 9 || exit 0

  if eww active-windows | tr ' ' '\n' | grep -qx "menu_overlay"; then
    eww close menu_overlay
    "$SCRIPT_DIR/scrim.sh" close menu
    eww update menu-open=false
  else
    eww update cal-month="$(date +%-m)" cal-year="$(date +%Y)" menu-open=true
    local_screen=$("$SCRIPT_DIR/get-screen.sh")
    "$SCRIPT_DIR/scrim.sh" open menu &
    eww open menu_overlay --screen "$local_screen" &
    wait
  fi
) 9>/tmp/eww-menu.lock
