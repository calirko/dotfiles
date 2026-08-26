#!/usr/bin/env bash

set -euo pipefail

# Print the monitor the bar/menus/osd should open on.
#
# Usage:
#   get-screen.sh          # (default) eww --screen *index* of the preferred monitor
#   get-screen.sh index    # same as above
#   get-screen.sh name     # connector name of the preferred monitor (e.g. DP-1)
#
# eww enumerates monitors in Wayland-registry order, which corresponds to
# hyprctl's monitor `id` ascending (NOT the order hyprctl returns them in its
# JSON array, and NOT by connector name — eww names monitors by EDID model,
# which is ambiguous when two identical displays are attached, so the numeric
# index is the only thing we can target reliably).
#
# So we sort the *enabled* monitors by `id` and report the 0-based position of
# the preferred monitor. This stays correct across lid/monitor enable-disable
# events, where the array order and active-monitor count both change.
#
# Preference order:
#   - Lid open (laptop panel eDP-1 in use): eDP-1 always wins, even if DP-1 or
#     HDMI are also connected (docked with lid open still targets the laptop
#     screen).
#   - Otherwise: DP-1 → any HDMI* → any eDP* → first enabled monitor.
# That fallback ordering also produces the right answer on single-monitor
# hosts (shark), where it just falls through to "first enabled monitor" = index 0.

MODE="${1:-index}"

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  [[ "$MODE" == "name" ]] && echo "" || echo 0
  exit 0
fi

lid_open() {
  for f in /proc/acpi/button/lid/*/state; do
    [[ -f "$f" ]] || continue
    grep -q "closed" "$f" 2>/dev/null && return 1
    return 0
  done
  return 1  # no lid (desktop-only host): treat as "not open"
}

EDP_FIRST=false
lid_open && EDP_FIRST=true

# Emit "INDEX NAME" for the preferred enabled monitor, or empty if none.
read -r idx name < <(
  hyprctl monitors -j 2>/dev/null | jq -r --argjson edp_first "$EDP_FIRST" '
    ([.[] | select((.disabled // false) == false)] | sort_by(.id) | to_entries) as $m
    | ($m | map(select(.value.name | test("^eDP"; "i")))) as $edp
    | ( (if $edp_first then $edp else [] end)
        + ($m | map(select(.value.name == "DP-1")))
        + ($m | map(select(.value.name | test("^HDMI"; "i"))))
        + $edp
        + $m )
    | .[0] // empty
    | "\(.key) \(.value.name)"
  ' 2>/dev/null
) || true

if [[ "$MODE" == "name" ]]; then
  echo "${name:-}"
else
  echo "${idx:-0}"
fi
