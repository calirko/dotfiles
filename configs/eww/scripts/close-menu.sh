#!/usr/bin/env bash

set -euo pipefail

(
  flock -n 9 || exit 0
  eww close menu_scrim menu_overlay || true
  eww update menu-open=false || true
) 9>/tmp/eww-menu.lock
