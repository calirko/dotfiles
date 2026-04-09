#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

is_open() {
  eww active-windows | tr ' ' '\n' | grep -qx "quick_menu"
}

if is_open; then
  eww close quick_menu  || true
  eww close menu_scrim  || true
else
  local_screen=$("$SCRIPT_DIR/get-screen.sh")
  eww open menu_scrim --screen "$local_screen"
  eww open quick_menu --screen "$local_screen"
fi
