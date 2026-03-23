#!/bin/bash

# Wofi power menu script with custom styling and icons

# Get user choice
choice=$(wofi --dmenu --style=/home/calirko/.config/wofi/style.css --width=300 --height=200 << EOF
Shutdown
Reboot
Logout
EOF
)

# Execute selected action
case "$choice" in
   "Shutdown")
      systemctl poweroff
      ;;
   "Reboot")
      systemctl reboot
      ;;
   "Logout")
      loginctl terminate-user "$USER"
      ;;
   *)
      exit 1
      ;;
esac