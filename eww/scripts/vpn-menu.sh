#!/usr/bin/env bash

set -euo pipefail

VPN_CONFIG_DIR="$HOME/Documents/vpn"
ICON_CONNECTED="󰒓"

if ! command -v wg >/dev/null 2>&1; then
  case "${1:-status}" in
    status)
      echo ""
      ;;
    menu)
      notify-send "VPN" "WireGuard is not installed"
      ;;
  esac
  exit 0
fi

get_active_vpns() {
  sudo wg show interfaces 2>/dev/null | tr -d '\n' | sed 's/ /\n/g' | grep -v '^$' || true
}

show_status() {
  local active
  active=$(get_active_vpns | head -1 || true)
  if [[ -z "$active" ]]; then
    echo ""
  else
    echo "$ICON_CONNECTED $active"
  fi
}

show_menu() {
  local options=""

  if [[ -n "$(get_active_vpns)" ]]; then
    options+="Disconnect\n"
  fi

  if [[ -d "$VPN_CONFIG_DIR" ]]; then
    for conf in "$VPN_CONFIG_DIR"/*.conf; do
      if [[ -f "$conf" ]]; then
        options+="$(basename "$conf" .conf)\n"
      fi
    done
  fi

  if [[ -z "$options" ]]; then
    notify-send "VPN" "No VPN configs found in $VPN_CONFIG_DIR"
    exit 0
  fi

  local choice
  choice=$(echo -e "$options" | wofi --style "$HOME/.config/wofi/style.css" --allow-images --dmenu -p "Select VPN:")

  if [[ -z "$choice" ]]; then
    exit 0
  fi

  if [[ "$choice" == "Disconnect" ]]; then
    for iface in $(get_active_vpns); do
      sudo wg-quick down "$iface" 2>/dev/null || true
    done
    notify-send "VPN" "Disconnected"
  else
    local conf_file="$VPN_CONFIG_DIR/$choice.conf"
    if [[ -f "$conf_file" ]]; then
      sudo wg-quick up "$conf_file" >/dev/null 2>&1 || true
      notify-send "VPN" "Connecting to $choice..."
    fi
  fi
}

case "${1:-status}" in
  status)
    show_status
    ;;
  menu)
    show_menu
    ;;
  *)
    show_status
    ;;
esac
