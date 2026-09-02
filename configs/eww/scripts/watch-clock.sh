#!/usr/bin/env bash

while true; do
    printf '{"time":"%s","date":"%s"}\n' "$(date +'%-I:%M %p')" "$(date +'%a, %d %b %Y')"
    sleep 1
done
