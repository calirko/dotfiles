#!/usr/bin/env bash

if [ -d /sys/class/leds ] && ls /sys/class/leds 2>/dev/null | grep -qi "kbd_backlight\|::kbd_backlight\|keyboard_backlight"; then
    echo "1"
else
    echo "0"
fi

sleep infinity
