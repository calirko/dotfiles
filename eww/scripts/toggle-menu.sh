#!/usr/bin/env bash

set -euo pipefail

is_open() {
  eww active-windows | tr ' ' '\n' | grep -qx "top_right_menu"
}

if is_open; then
  eww close top_right_menu || true
  eww close menu_scrim || true
else
  eww open menu_scrim --screen $(hyprctl activewindow -j | jq '.monitor')
  eww open top_right_menu
fi
