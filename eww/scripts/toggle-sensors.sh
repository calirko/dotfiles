#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

is_open() {
  eww active-windows | tr ' ' '\n' | grep -qx "sensors"
}

if is_open; then
  eww close sensors || true
  eww close menu_scrim || true
else
  local_screen=$("$SCRIPT_DIR/get-screen.sh")
  eww open menu_scrim --screen "$local_screen"
  eww open sensors --screen "$local_screen"
fi