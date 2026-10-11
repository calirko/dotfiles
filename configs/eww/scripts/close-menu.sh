#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

(
  flock -n 9 || exit 0
  eww close menu_overlay || true
  "$SCRIPT_DIR/scrim.sh" close menu || true
  eww update menu-open=false || true
) 9>/tmp/eww-menu.lock
