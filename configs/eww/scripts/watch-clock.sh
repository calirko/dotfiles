#!/usr/bin/env bash

while true; do
    printf '{"time":"%s","date":"%s"}\n' "$(date +'%H:%M')" "$(date +'%a, %d %b %Y')"
    sleep 1
done
