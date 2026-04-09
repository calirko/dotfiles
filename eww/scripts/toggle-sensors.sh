#!/usr/bin/env bash
# Sensors are now part of the unified quick menu.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/toggle-menu.sh"
