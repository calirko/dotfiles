#!/usr/bin/env bash

set -euo pipefail

icon_connected="󰒓"

if ! command -v wg >/dev/null 2>&1; then
  echo ""
  exit 0
fi

active=$(sudo wg show interfaces 2>/dev/null | tr ' ' '\n' | sed '/^$/d' | head -1)

if [[ -z "$active" ]]; then
  echo ""
else
  echo "$icon_connected $active"
fi
