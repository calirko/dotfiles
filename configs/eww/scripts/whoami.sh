#!/usr/bin/env bash

# Menu header subtitle: "host · up 3h 12m".
read -r secs _ < /proc/uptime
secs=${secs%.*}
d=$(( secs / 86400 )) h=$(( secs % 86400 / 3600 )) m=$(( secs % 3600 / 60 ))
if (( d > 0 )); then up="${d}d ${h}h"
elif (( h > 0 )); then up="${h}h ${m}m"
else up="${m}m"; fi
name=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
jq -nc --arg name "${name:-$USER}" --arg host "$(< /etc/hostname)" --arg up "$up" \
    '{name: $name, host: $host, uptime: $up}'
