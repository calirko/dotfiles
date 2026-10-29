#!/usr/bin/env bash
set -uo pipefail

# Run on every monitor change (hotplug, lid close/open): reopen the bar and
# re-apply the wallpaper. hyprpaper.conf only lists the monitors that were
# up when the wallpaper was last applied, so a monitor that appears later
# (the laptop panel after unplugging the externals) stays black otherwise.
#
# Unplugging a dock fires one event per monitor, so calls are coalesced:
# each call stamps a token and waits a moment; only the last one runs.
# bar.sh then waits for the monitor set to settle on its own.

TOKEN_FILE="/tmp/monitors-changed.token"
SCRIPTS="$HOME/.config/hypr/scripts"

token="$$.$(date +%s%N)"
echo "$token" > "$TOKEN_FILE"
sleep 0.4
[[ "$(cat "$TOKEN_FILE" 2>/dev/null)" == "$token" ]] || exit 0

"$SCRIPTS/bar.sh" &
"$SCRIPTS/wallpaper-default.sh" >/dev/null &
wait
