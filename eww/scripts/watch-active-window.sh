#!/usr/bin/env bash
# watch-active-window.sh
# Emits the active window class + title on every focus change via Hyprland IPC.
# Used by the bar-active-window widget.

emit() {
  local class title
  class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')
  title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""')

  if [[ -z "$class" && -z "$title" ]]; then
    echo ""
  elif [[ -n "$class" ]]; then
    echo "$class"
  else
    echo "$title"
  fi
}

emit

socat - "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | \
  while IFS= read -r line; do
    event="${line%%>>*}"
    if [[ "$event" == "activewindow" || "$event" == "activewindowv2" || "$event" == "closewindow" ]]; then
      emit
    fi
  done
