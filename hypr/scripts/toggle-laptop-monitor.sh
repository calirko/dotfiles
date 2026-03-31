#!/bin/bash

LID_STATUS="$1"

if [ "$LID_STATUS" = "closed" ]; then
  hyprctl keyword monitor eDP-1,disable
elif [ "$LID_STATUS" = "open" ]; then
  hyprctl keyword monitor "eDP-1,1920x1200@60,auto-left,1"
fi