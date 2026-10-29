#!/usr/bin/env bash
set -euo pipefail

# Move through the focused monitor's own workspaces (SUPER + Up / Down).
#
# Usage:
#   workspace-cycle.sh next|prev [focus|move] [--monitor NAME] [--no-new]
#   workspace-cycle.sh new [focus|move] [--monitor NAME]
#
# --monitor cycles that monitor's stack instead of the focused one's (the
# bar's dots, which live on one monitor). --no-new never opens a workspace,
# it only wraps (scrolling on the dots, where a fast scroll shouldn't
# leave empty workspaces behind).
#
# Workspaces aren't pinned to monitors, so each monitor keeps its own stack
# (shown as dots on the bar). `next` past the last one opens a fresh empty
# workspace on this monitor, as long as the current one has windows;
# otherwise both directions wrap around. `new` always opens one (the bar's
# + button). `move` takes the focused window along (SUPER + SHIFT + Up / Down).
#
# The stack is ordered by id, so a new workspace takes an id above every
# existing one and lands at the bottom. (Hyprland's `emptym` reuses the
# lowest free id, which could slot it in the middle.)
#
# hyprctl dispatch on this Lua-config fork takes a Lua dispatcher expression,
# same as eww/scripts/goto-workspace.sh.

dir="${1:?next|prev|new}"
# eww's :onscroll passes up / down; down goes down the stack
case "$dir" in
  up) dir=prev ;;
  down) dir=next ;;
esac
mode="focus"
monitor=""
allow_new=1
shift
while (( $# )); do
  case "$1" in
    focus|move) mode="$1" ;;
    --monitor) monitor="${2:-}"; shift ;;
    --no-new) allow_new=0 ;;
  esac
  shift
done

# Act on another monitor's stack by focusing it first, so a new workspace
# also opens there.
if [[ -n "$monitor" && "$(hyprctl activeworkspace -j | jq -r '.monitor')" != "$monitor" ]]; then
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
fi

active=$(hyprctl activeworkspace -j)
cur=$(jq '.id' <<<"$active")
mon=$(jq -r '.monitor' <<<"$active")
windows=$(jq '.windows' <<<"$active")

# This monitor's numbered workspaces, ascending (special ones are negative).
mapfile -t ids < <(hyprctl workspaces -j \
  | jq --arg m "$mon" '[.[] | select(.monitor == $m and .id > 0) | .id] | sort | .[]')

new_id() {
  hyprctl workspaces -j | jq '[.[] | .id] | max + 1 | if . < 1 then 1 else . end'
}

n=${#ids[@]}

i=0
for ((k = 0; k < n; k++)); do
  [[ "${ids[k]}" == "$cur" ]] && i=$k
done

if [[ "$dir" == new ]]; then
  (( windows == 0 )) && exit 0  # already on an empty one
  target=$(new_id)
elif (( n == 0 )); then
  exit 0
elif [[ "$dir" == next ]]; then
  if (( i == n - 1 )); then
    if (( windows > 0 && allow_new )); then
      target=$(new_id)
    else
      target="${ids[0]}"
    fi
  else
    target="${ids[i + 1]}"
  fi
else
  target="${ids[(i - 1 + n) % n]}"
fi

[[ "$target" == "$cur" ]] && exit 0

if [[ "$mode" == move ]]; then
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target\" })" >/dev/null
else
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$target\" })" >/dev/null
fi
