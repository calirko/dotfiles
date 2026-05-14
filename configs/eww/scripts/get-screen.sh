#!/usr/bin/env bash

set -euo pipefail

HOSTNAME=$(uname -n)

case "$HOSTNAME" in
  shark)
    echo 0
    ;;
  bear)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      if hyprctl monitors -j | jq -e '.[] | select(.name == "eDP-1")' >/dev/null 2>&1; then
        echo 0
      else
        count=$(hyprctl monitors -j | jq 'length')
        if [[ "$count" -gt 0 ]]; then
          echo $((count - 1))
        else
          echo 0
        fi
      fi
    else
      echo 0
    fi
    ;;
  *)
    echo 0
    ;;
esac
