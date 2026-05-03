#!/usr/bin/env bash
# watch-active-window.sh

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="/run/user/1000/hypr/${SIG}/.socket2.sock"

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

last=""

emit_deduped() {
  local val
  val=$(emit)
  if [[ "$val" != "$last" ]]; then
    last="$val"
    echo "$val"
  fi
}

emit_deduped

socat -u UNIX-CONNECT:"$SOCK" STDOUT | while IFS= read -r line; do
  event="${line%%>>*}"
  case "$event" in
    activewindowv2|closewindow)
      emit_deduped
      ;;
  esac
done
