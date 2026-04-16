#!/usr/bin/env bash
# lucide-color.sh — set stroke color of all SVGs in the same folder
# Usage: ./lucide-color.sh <#hexcolor>
# Example: ./lucide-color.sh "#cdd6f4"

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
  sed -i "s/currentColor/${COLOR}/g; s/stroke=\"#[0-9a-fA-F]\{3,6\}\"/stroke=\"${COLOR}\"/g" "$svg"
  printf "Colored %s\n" "$(basename "$svg")"
done

echo "Done — ${#svgs[@]} file(s) set to ${COLOR}"
