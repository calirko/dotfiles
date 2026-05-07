#!/usr/bin/env bash
set -euo pipefail

if ! command -v nmcli >/dev/null 2>&1; then
  printf '{"active": false, "name": ""}\n'
  exit 0
fi

name=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
  | awk -F: '$2 == "wireguard" { print $1 }' | head -n1 || true)

if [[ -n "$name" ]]; then
  printf '{"active": true, "name": "%s"}\n' "$name"
else
  printf '{"active": false, "name": ""}\n'
fi
