#!/usr/bin/env bash
# lucide-get.sh — download Lucide SVG icons by name
# Usage: ./lucide-get.sh <icon-name> [icon-name ...]
# Example: ./lucide-get.sh volume-2 battery wifi cpu

set -euo pipefail

BASE_URL="https://unpkg.com/lucide-static@latest/icons"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <icon-name> [icon-name ...]"
  echo "Example: $(basename "$0") volume-2 battery wifi cpu"
  exit 1
fi

for icon in "$@"; do
  # strip .svg if someone passed it with extension
  icon="${icon%.svg}"
  url="$BASE_URL/${icon}.svg"
  out="$DEST/${icon}.svg"

  printf "Downloading %-30s ... " "${icon}.svg"

  http_code=$(curl -sL -o "$out" -w "%{http_code}" "$url")

  if [[ "$http_code" == "200" ]]; then
    echo "OK"
  else
    rm -f "$out"
    echo "FAILED (HTTP $http_code) — check icon name at https://lucide.dev/icons/"
  fi
done
