#!/usr/bin/env bash
# lucide-color.sh — set fill color of all SVGs in the same folder
# Usage: ./lucide-color.sh <#hexcolor>
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <#hexcolor>"
  echo "Example: $(basename "$0") \"#cdd6f4\""
  exit 1
fi

COLOR="$1"

svgs=("$DEST"/*.svg)
if [[ ! -e "${svgs[0]}" ]]; then
  echo "No SVG files found in $DEST"
  exit 1
fi

for svg in "${svgs[@]}"; do
  sed -i \
    -e "s/fill=\"#[0-9a-fA-F]\{3,6\}\"/fill=\"${COLOR}\"/g" \
    -e "s/fill=\"currentColor\"/fill=\"${COLOR}\"/g" \
    -e "s/stroke=\"#[0-9a-fA-F]\{3,6\}\"/stroke=\"${COLOR}\"/g" \
    -e "s/stroke=\"currentColor\"/stroke=\"${COLOR}\"/g" \
    "$svg"
  printf "Colored %s\n" "$(basename "$svg")"
done

echo "Done — ${#svgs[@]} file(s) set to ${COLOR}"
