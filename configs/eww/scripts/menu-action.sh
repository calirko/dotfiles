#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

"$(dirname "$0")/close-menu.sh"

case "$action" in
  lock)
    pidof hyprlock >/dev/null 2>&1 || hyprlock
    ;;
  logout)
    loginctl terminate-user "$USER"
    ;;
  reboot)
    systemctl reboot
    ;;
  shutdown)
    systemctl poweroff
    ;;
  *)
    exit 1
    ;;
esac
