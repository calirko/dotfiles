#!/bin/bash

# Get laptop lid state
lid_state=$(cat /proc/acpi/button/lid/LID*/state | awk '{print $NF}')

if [ "$lid_state" = "open" ]; then
   hyprctl keyword monitor "desc:BOE 0x0A2A",1920x1200@60,auto-left,1
else
   hyprctl keyword monitor "desc:BOE 0x0A2A",disable
fi