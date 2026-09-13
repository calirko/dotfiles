#!/usr/bin/env bash

# Toggle mako's do-not-disturb mode and push the new state to eww right away.
# mako emits no D-Bus signal on mode changes, so watch-mako.sh can only catch
# them by polling; this keeps the quick-menu button instant.

makoctl mode -t do-not-disturb >/dev/null
makoctl mode | grep -qx "do-not-disturb" && state=1 || state=0
eww update mako-paused="$state"
