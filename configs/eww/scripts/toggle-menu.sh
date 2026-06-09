#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

(
  flock -n 9 || exit 0

  if eww active-windows | tr ' ' '\n' | grep -qx "menu_overlay"; then
    eww close menu_overlay
  else
    eww update cal-month="$(date +%-m)" cal-year="$(date +%Y)"
    local_screen=$("$SCRIPT_DIR/get-screen.sh")
    eww open menu_overlay --screen "$local_screen"
  fi
) 9>/tmp/eww-menu.lock
