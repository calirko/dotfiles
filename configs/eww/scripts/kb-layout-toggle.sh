#!/usr/bin/env bash

set -euo pipefail

# Get the current keyboard layout
CURRENT_LAYOUT=$(hyprctl getoption input:kb_layout | head -1 | awk '{print $NF}')

# Toggle between br and us
if [ "$CURRENT_LAYOUT" = "br" ]; then
    NEW_LAYOUT="us"
else
    NEW_LAYOUT="br"
fi

# Set the new keyboard layout
hyprctl keyword input:kb_layout "$NEW_LAYOUT"

# Send a notification (optional)
notify-send "Keyboard Layout" "Changed to: $NEW_LAYOUT" -t 1000
