#!/usr/bin/env bash

# hour / minute are separate so the bar can stack them; long is the menu's
# full date line.
while true; do
    printf '{"time":"%s","date":"%s","hour":"%s","minute":"%s","long":"%s"}\n' \
        "$(date +'%-I:%M %p')" "$(date +'%a, %d %b %Y')" \
        "$(date +'%I')" "$(date +'%M')" "$(date +'%A, %-d %B')"
    sleep 1
done
