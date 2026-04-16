#!/usr/bin/env bash

set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "disabled"
  exit 0
fi

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  echo "disabled"
  exit 0
fi

connected_alias=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
if [[ -n "$connected_alias" ]]; then
  echo "connected"
else
  echo "disconnected"
fi
