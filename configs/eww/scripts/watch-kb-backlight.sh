#!/usr/bin/env bash

# Emits {present, level, max, steps:[bool]} for the keyboard backlight.
# steps has one entry per non-zero level, true when lit, so the menu can
# draw one pip per step. sysfs LED brightness can't be inotify-watched, so
# poll and only print on change.

led=$(ls -d /sys/class/leds/*kbd_backlight* /sys/class/leds/*keyboard_backlight* 2>/dev/null | head -1)

if [[ -z "$led" ]]; then
    echo '{"present":false,"level":0,"max":0,"steps":[]}'
    sleep infinity
fi

max=$(<"$led/max_brightness")
last=""
while true; do
    level=$(<"$led/brightness")
    if [[ "$level" != "$last" ]]; then
        jq -cn --argjson level "$level" --argjson max "$max" \
            '{present:true,level:$level,max:$max,steps:[range(1;$max+1)|. <= $level]}'
        last="$level"
    fi
    sleep 0.5
done
