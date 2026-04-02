#!/usr/bin/env bash

set -euo pipefail

VPN_CONFIG_DIR="$HOME/Documents/vpn"
NM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-vpn"
ICON_CONNECTED="  "
ICON_DISCONNECTED=""

nmcli_hint() {
  local msg="NetworkManager or its WireGuard plugin is unavailable. Install nmcli and the WireGuard plugin."
  notify-send "VPN" "$msg"
  echo "$msg" >&2
}

if ! command -v nmcli >/dev/null 2>&1; then
  case "${1:-status}" in
    status)
      echo "$ICON_DISCONNECTED"
      ;;
    menu)
      nmcli_hint
      ;;
  esac
  exit 0
fi

nmcli_c() {
  LC_ALL=C nmcli "$@"
}

connection_exists() {
  local name="$1"
  nmcli_c -t -f NAME connection show | grep -Fxq "$name"
}

connection_hash() {
  sha256sum "$1" | awk '{print $1}'
}

active_wireguard_connections() {
  nmcli_c -t -f NAME,TYPE connection show --active | awk -F: '$2 == "wireguard" { print $1 }'
}

active_wireguard_connection() {
  active_wireguard_connections | head -n1 || true
}

ensure_nm_connection() {
  local name="$1"
  local conf_file="$2"
  local hash_file="$NM_CACHE_DIR/$name.sha256"
  local current_hash
  local stored_hash
  local imported_name

  current_hash=$(connection_hash "$conf_file")
  stored_hash=$(cat "$hash_file" 2>/dev/null || true)

  if connection_exists "$name" && [[ "$stored_hash" == "$current_hash" ]]; then
    return 0
  fi

  if connection_exists "$name"; then
    nmcli_c connection down "$name" >/dev/null 2>&1 || true
    nmcli_c connection delete "$name" >/dev/null 2>&1 || true
  fi

  mkdir -p "$NM_CACHE_DIR"

  if ! nmcli_c connection import type wireguard file "$conf_file" >/dev/null 2>&1; then
    nmcli_hint
    return 1
  fi

  if ! connection_exists "$name"; then
    imported_name=$(nmcli_c -t -f NAME,TYPE connection show | awk -F: '$2 == "wireguard" { print $1 }' | tail -n1)
    if [[ -n "$imported_name" && "$imported_name" != "$name" ]]; then
      nmcli_c connection modify "$imported_name" connection.id "$name" >/dev/null 2>&1 || true
    fi
  fi

  if ! connection_exists "$name"; then
    nmcli_hint
    return 1
  fi

  printf '%s\n' "$current_hash" >"$hash_file"
  return 0
}

emit_status() {
  local active
  active=$(active_wireguard_connection)
  if [[ -z "$active" ]]; then
    echo "$ICON_DISCONNECTED"
  else
    echo "$ICON_CONNECTED $active"
  fi
}

refresh_eww_status() {
  eww update vpn-status="$(emit_status)" >/dev/null 2>&1 || true
}

show_status() {
  emit_status
}

bring_up_vpn() {
  local target="$1"
  local conf_file="$VPN_CONFIG_DIR/$target.conf"

  if [[ ! -f "$conf_file" ]]; then
    notify-send "VPN" "Config not found: $conf_file"
    return 1
  fi

  if ! ensure_nm_connection "$target" "$conf_file"; then
    return 1
  fi

  if nmcli_c connection up "$target" >/dev/null 2>&1; then
    notify-send "VPN" "Connected to $target"
    refresh_eww_status
    return 0
  fi

  notify-send "VPN" "Failed to connect $target"
  return 1
}

show_menu() {
  local options=""

  if [[ -n "$(active_wireguard_connection)" ]]; then
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
    while IFS= read -r iface; do
      [[ -z "$iface" ]] && continue
      nmcli_c connection down "$iface" >/dev/null 2>&1 || true
    done < <(active_wireguard_connections)
    notify-send "VPN" "Disconnected"
    refresh_eww_status
  else
    bring_up_vpn "$choice"
  fi
}

connect_named_vpn() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    notify-send "VPN" "No VPN name provided"
    exit 1
  fi

  if active_wireguard_connections | grep -Fxq "$target"; then
    refresh_eww_status
    exit 0
  fi

  bring_up_vpn "$target"
}

case "${1:-status}" in
  status)
    show_status
    ;;
  menu)
    show_menu
    ;;
  connect)
    connect_named_vpn "${2:-}"
    ;;
  *)
    show_status
    ;;
esac
