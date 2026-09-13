#!/usr/bin/env bash

# mako emits no D-Bus signal when its mode changes, so there's nothing to
# listen for. The quick-menu toggle (toggle-dnd.sh) pushes its change to eww
# directly; this slow poll only catches toggles made elsewhere (makoctl).

emit() {
    makoctl mode 2>/dev/null | grep -qx "do-not-disturb" && echo "1" || echo "0"
}

last=""
while true; do
    state=$(emit)
    if [[ "$state" != "$last" ]]; then
        last="$state"
        echo "$state"
    fi
    sleep 5
done
