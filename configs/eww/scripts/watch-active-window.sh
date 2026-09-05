#!/usr/bin/env bash
# watch-active-window.sh

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="/run/user/1000/hypr/${SIG}/.socket2.sock"

# Window classes are app-ids, not display names: reverse-DNS ("dev.zed.Zed")
# or lowercase slugs ("zen", "zen-browser"). Map the common ones to what the
# app is actually called; fall back to title-casing whatever's left.
pretty_name() {
  local class="$1" last=""

  case "$class" in
    kitty)                   echo "Kitty"; return ;;
    zen | zen-browser)       echo "Zen"; return ;;
    org.gnome.Nautilus)      echo "Files"; return ;;
    wofi)                    echo "Wofi"; return ;;
    firefox)                 echo "Firefox"; return ;;
    code | code-oss)         echo "VS Code"; return ;;
  esac

  # Reverse-DNS app-id (dev.zed.Zed, org.foo.Bar): use the last segment.
  if [[ "$class" == *.*.* ]]; then
    last="${class##*.}"
  else
    last="$class"
  fi

  # Title-case each hyphen/underscore-separated word.
  last="${last//[-_]/ }"
  echo "$last" | awk '{ for (i=1; i<=NF; i++) $i = toupper(substr($i,1,1)) substr($i,2); print }'
}

emit() {
  local class title
  class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')
  title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""')
  if [[ -z "$class" && -z "$title" ]]; then
    echo ""
  elif [[ -n "$class" ]]; then
    pretty_name "$class"
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
