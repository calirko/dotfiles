#!/usr/bin/env bash

set -euo pipefail

# Get the current keyboard layout from Hyprland
hyprctl getoption input:kb_layout | head -1 | awk '{print $NF}'
