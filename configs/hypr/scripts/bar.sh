#!/usr/bin/env bash
set -euo pipefail

# Open the eww bar on the preferred monitor (DP-1 first; see get-screen.sh).
#
# Boot is tricky. Hyprland starts with every monitor enabled, including
# the laptop panel (eDP-1), and ~2 s later lid-handler.sh disables eDP
# (lid closed + AC + external monitor). If we open the bar during that window
# we either land on a monitor that's about to vanish (and the bar disappears
# with it) or compute an index eww hasn't caught up to yet (open errors out).
#
# So we don't trust a single open: we open, then check with `hyprctl layers`
# that the bar actually landed on the intended connector. If not, we
# work out the target again and retry, until it lands or we hit the time cap.
#
# Serialized via a lockfile so rapid monitor-change events don't race.

BAR_SCREEN_FILE="/tmp/eww-bar-screen"
EWW_SCREEN_SCRIPT="$HOME/.config/eww/scripts/get-screen.sh"

# eww --screen index of the preferred monitor.
get_bar_screen() { "$EWW_SCREEN_SCRIPT" index 2>/dev/null || echo 0; }

# Connector name of the preferred monitor (e.g. DP-1), or empty.
get_bar_monitor() { "$EWW_SCREEN_SCRIPT" name 2>/dev/null || echo ""; }

# Enabled connectors, sorted and comma-joined (tags the recorded index).
get_monitor_set() { "$EWW_SCREEN_SCRIPT" set 2>/dev/null || echo ""; }

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

# Poll until the enabled-monitor set hasn't changed for 0.9 s (3 × 0.3 s).
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
    sleep 0.3
    attempts=$((attempts + 1))
    [[ $attempts -ge 50 ]] && break  # 15 s hard cap
  done
  # Return success on purpose. The loop's last body command is a failing
  # `[[ ... ]] &&` test, so without this the function returns 1 and `set -e`
  # would abort bar.sh here, before the bar is ever opened.
  return 0
}

# eww's monitor list as "INDEX MODEL" lines. eww has no command for this, but
# a failed open prints the list, so ask for a screen that can't exist.
eww_monitors() {
  eww open bar --id monitor-probe --screen 99 --arg on_laptop=false 2>&1 | sed -nE 's/^[[:space:]]*\[([0-9]+)\] (.*)$/\1 \2/p'
}

# eww indices that could be connector $1: the ones whose model matches its
# EDID model. Unique models (the laptop panel) give exactly one index, so no
# probing; identical monitors (the two Samsungs) give one index each.
candidate_screens() {
  local model
  model=$(hyprctl monitors -j 2>/dev/null \
    | jq -r --arg n "$1" '.[] | select(.name == $n) | .model' 2>/dev/null)
  eww_monitors | awk -v m="$model" '{ i = $1; $1 = ""; sub(/^ /, ""); if ($0 == m) print i }'
}

# Open the bar on --screen $1 and report (via exit status) whether it landed
# on connector $2. Polls instead of sleeping a fixed time so a correct guess
# shows up right away.
try_open() {
  local screen="$1" target="$2" on_laptop="false" on="" n=0
  [[ "$target" == eDP-1 ]] && on_laptop="true"
  eww close bar 2>/dev/null || true
  eww open bar --screen "$screen" --arg on_laptop="$on_laptop" 2>/dev/null || true
  until [[ -n "$on" || $n -ge 10 ]]; do
    sleep 0.1
    on=$(bar_on_monitor)
    n=$((n + 1))
  done
  [[ "$on" == "$target" ]]
}

record_screen() { echo "$1 $(get_monitor_set)" > "$BAR_SCREEN_FILE"; }

reopen_bar() {
  ensure_daemon
  wait_for_monitors_stable

  local target screen set i attempts=0
  local -a cands
  while [[ $attempts -lt 10 ]]; do
    target=$(get_bar_monitor)
    screen=$(get_bar_screen)

    # No usable monitor info (not on Hyprland / no jq): best-effort open, done.
    if [[ -z "$target" ]]; then
      eww open bar --screen "${screen:-0}" 2>/dev/null || true
      return
    fi

    mapfile -t cands < <(candidate_screens "$target")
    # eww hasn't caught up with the monitor change yet: wait for it.
    if [[ ${#cands[@]} -eq 0 ]]; then
      attempts=$((attempts + 1))
      sleep 0.3
      continue
    fi

    # Already on the right monitor: keep it there (no blink) and just make
    # sure the recorded index matches the current monitor set, so menus/OSD
    # follow it. If the index is ambiguous and stale, fall through and reopen.
    if [[ "$(bar_on_monitor)" == "$target" ]]; then
      if [[ ${#cands[@]} -eq 1 ]]; then
        record_screen "${cands[0]}"
        return
      fi
      set=$(get_monitor_set)
      [[ "$(cut -d' ' -f2 "$BAR_SCREEN_FILE" 2>/dev/null)" == "$set" ]] && return
    fi

    # Try the id-sorted guess first if it's a candidate, then the rest. Only
    # identical monitors are ever probed, so at most one wrong landing.
    for i in "$screen" "${cands[@]}"; do
      [[ " ${cands[*]} " == *" $i "* ]] || continue
      if try_open "$i" "$target"; then
        record_screen "$i"
        return
      fi
    done

    attempts=$((attempts + 1))
    sleep 0.3
  done
}

# Serialize concurrent calls so monitor-change events don't race each other.
exec 9>/tmp/eww-bar.lock
flock 9
reopen_bar
