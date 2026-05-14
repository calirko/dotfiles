#!/bin/bash
current=$(brightnessctl --device '*kbd_backlight*' get)
max=$(brightnessctl --device '*kbd_backlight*' max)

if [ "$current" -ge "$max" ]; then
    brightnessctl --device '*kbd_backlight*' set 0
else
    brightnessctl --device '*kbd_backlight*' set +1
fi
