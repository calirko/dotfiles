#!/usr/bin/env bash

emit() {
    makoctl mode 2>/dev/null | grep -q "do-not-disturb" && echo "1" || echo "0"
}

emit

dbus-monitor --session \
    "type='signal',sender='fr.emersion.Mako'" \
    2>/dev/null | while read -r _; do
    emit
done

# Fallback if dbus-monitor exits: slow poll
while true; do
    sleep 10
    emit
done
