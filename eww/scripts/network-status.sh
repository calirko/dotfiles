#!/usr/bin/env bash

set -euo pipefail

if ! command -v nmcli >/dev/null 2>&1; then
  echo "󰤮"
  exit 0
fi

wifi_line=$(nmcli -t -f IN-USE,SIGNAL dev wifi list 2>/dev/null | grep '^\*' | head -1 || true)

if [[ -n "$wifi_line" ]]; then
  signal=$(cut -d: -f2 <<< "$wifi_line")
  if [[ $signal -ge 80 ]]; then
    echo "󰤨"
  elif [[ $signal -ge 60 ]]; then
    echo "󰤥"
  elif [[ $signal -ge 40 ]]; then
    echo "󰤢"
  elif [[ $signal -ge 20 ]]; then
    echo "󰤟"
  else
    echo "󰤯"
  fi
  exit 0
fi


if nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | grep -qE 'ethernet:connected'; then
  echo ""
  exit 0
fi

echo "󰤮"
