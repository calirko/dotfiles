#!/usr/bin/env bash
# phosphor-get.sh — download Phosphor SVG icons by name (regular weight)
# Usage: ./phosphor-get.sh <icon-name> [icon-name ...]
# Example: ./phosphor-get.sh hard-drive arrow-right warning cpu
set -euo pipefail

BASE_URL="https://unpkg.com/@phosphor-icons/core@latest/assets/regular"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <icon-name> [icon-name ...]"
  echo "Example: $(basename "$0") hard-drive arrow-right warning cpu"
  echo "Browse icons at https://phosphoricons.com"
  exit 1
fi

for icon in "$@"; do
  icon="${icon%.svg}"
  url="$BASE_URL/${icon}.svg"
  out="$DEST/${icon}.svg"
  printf "Downloading %-30s ... " "${icon}.svg"
  http_code=$(curl -sL -o "$out" -w "%{http_code}" "$url")
  if [[ "$http_code" == "200" ]]; then
    echo "OK"
  else
    rm -f "$out"
    echo "FAILED (HTTP $http_code) — check icon name at https://phosphoricons.com"
  fi
done
