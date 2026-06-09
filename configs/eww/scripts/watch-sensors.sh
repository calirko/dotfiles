#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

while true; do
    "$SCRIPT_DIR/sensors.sh"
    sleep 3
done
