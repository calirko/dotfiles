#!/usr/bin/env bash

set -euo pipefail

HOSTNAME=$(uname -n)

case "$HOSTNAME" in
  shark)
    echo 0
    ;;
  raccoon)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      monitors=$(hyprctl monitors -j)
      idx=$(echo "$monitors" | jq 'to_entries[] | select(.value.name == "DP-1") | .key' 2>/dev/null | head -1)
      if [[ -z "$idx" ]]; then
        idx=$(echo "$monitors" | jq 'to_entries[] | select(.value.name | test("^HDMI"; "i")) | .key' 2>/dev/null | head -1)
      fi
      if [[ -z "$idx" ]]; then
        idx=$(echo "$monitors" | jq 'to_entries[] | select(.value.name | test("^eDP"; "i")) | .key' 2>/dev/null | head -1)
      fi
      echo "${idx:-0}"
    else
      echo 0
    fi
    ;;
  *)
    echo 0
    ;;
esac
