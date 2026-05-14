#!/usr/bin/env bash

set -euo pipefail

if ! command -v wpctl >/dev/null 2>&1; then
  echo " N/A"
  exit 0
fi

state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)

if [[ -z "$state" ]]; then
  echo " N/A"
  exit 0
fi

if [[ "$state" == *"[MUTED]"* ]]; then
  echo ""
  exit 0
fi

vol=$(awk '{printf "%d", $2 * 100}' <<< "$state")

icon=""
if (( vol >= 70 )); then
  icon=""
elif (( vol <= 30 )); then
  icon=""
fi

echo "$icon ${vol}%"
