#!/usr/bin/env bash
set -euo pipefail

# Open the eww bar on the preferred monitor (DP-1 first; see get-screen.sh).
#
# The hard part is boot. Hyprland starts with every monitor — including the
# laptop panel (eDP-1) — enabled, and ~2 s later lid-handler.sh disables eDP
# (lid closed + AC + external monitor). If we open the bar during that window
# we either land on a monitor that's about to vanish (and the bar disappears
# with it) or compute an index eww hasn't caught up to yet (open errors out).
#
# So we don't trust a single open: we open, then VERIFY via `hyprctl layers`
# that the bar actually landed on the intended connector, and keep retrying —
# re-deriving the target each pass — until it does or we hit the time cap.
#
# Serialized via a lockfile so rapid monitor-change events don't race.

BAR_SCREEN_FILE="/tmp/eww-bar-screen"
EWW_SCREEN_SCRIPT="$HOME/.config/eww/scripts/get-screen.sh"

# eww --screen index of the preferred monitor.
get_bar_screen() { "$EWW_SCREEN_SCRIPT" index 2>/dev/null || echo 0; }

# Connector name of the preferred monitor (e.g. DP-1), or empty.
get_bar_monitor() { "$EWW_SCREEN_SCRIPT" name 2>/dev/null || echo ""; }

# Connector the eww bar layer-surface is currently on, or empty if not mapped.
bar_on_monitor() {
  hyprctl layers -j 2>/dev/null | jq -r '
    to_entries[] | .key as $mon | .value.levels | to_entries[].value[]
    | select(.namespace == "eww-bar") | $mon
  ' 2>/dev/null | head -1
}

# Make sure a daemon is up. Spawn it immediately rather than pinging for 10 s
# first (nothing else starts it at login). Close fd 9 (the flock lock) for the
# daemon: it's long-lived and would otherwise inherit the lock's open file
# description and hold the flock forever, deadlocking every later bar.sh.
ensure_daemon() {
  eww ping &>/dev/null && return
  setsid eww daemon 9>&- &
  disown
  local n=0
  until eww ping &>/dev/null; do
    sleep 0.5
    n=$((n + 1))
    [[ $n -ge 20 ]] && break
  done
  return 0
}

# Poll until the enabled-monitor set hasn't changed for 1.5 s (3 × 0.5 s).
# On raccoon this rides out the lid-handler disabling eDP shortly after start.
wait_for_monitors_stable() {
  [[ "$(uname -n)" != "raccoon" ]] && return

  local prev="" cur="" stable=0 attempts=0
  while [[ $stable -lt 3 ]]; do
    cur=$(hyprctl monitors -j 2>/dev/null \
      | jq -r '[.[] | select((.disabled // false) == false) | .name] | sort | join(",")' \
      2>/dev/null || echo "err")
    if [[ "$cur" == "$prev" && "$cur" != "err" && -n "$cur" ]]; then
      stable=$((stable + 1))
    else
      stable=0
    fi
    prev="$cur"
    sleep 0.5
    attempts=$((attempts + 1))
    [[ $attempts -ge 30 ]] && break  # 15 s hard cap
  done
  # IMPORTANT: return success. The loop's last body command is a failing
  # `[[ ... ]] &&` test, so without this the function returns 1 and `set -e`
  # would abort bar.sh here — before the bar is ever opened.
  return 0
}

reopen_bar() {
  ensure_daemon
  wait_for_monitors_stable

  local target screen onmon attempts=0
  while [[ $attempts -lt 40 ]]; do  # ~30 s budget
    target=$(get_bar_monitor)
    screen=$(get_bar_screen)
    echo "$screen" > "$BAR_SCREEN_FILE"

    local on_laptop="false"
    [[ "$target" == eDP-1 ]] && on_laptop="true"

    # No usable monitor info (not on Hyprland / no jq): best-effort open, done.
    if [[ -z "$target" ]]; then
      eww open bar --screen "${screen:-0}" 2>/dev/null || true
      return
    fi

    # Already on the right monitor — nothing to do.
    [[ "$(bar_on_monitor)" == "$target" ]] && return

    eww close bar 2>/dev/null || true
    sleep 0.3
    eww open bar --screen "$screen" --arg on_laptop="$on_laptop" 2>/dev/null || true
    sleep 0.5

    # Verify it actually landed where we wanted; if so we're done, else retry
    # (the layout may still be settling — e.g. eDP not disabled yet).
    [[ "$(bar_on_monitor)" == "$target" ]] && return

    attempts=$((attempts + 1))
    sleep 0.5
  done
}

# Serialize concurrent calls so monitor-change events don't race each other.
exec 9>/tmp/eww-bar.lock
flock 9
reopen_bar
