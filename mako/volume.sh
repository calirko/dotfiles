#!/bin/bash

step=5
case $1 in
    up)
        pamixer -i $step
        ;;
    down)
        pamixer -d $step
        ;;
    mute)
        pamixer -t
        ;;
esac

vol=$(pamixer --get-volume)
mute=$(pamixer --get-mute)

if [ "$mute" = "true" ]; then
    icon="audio-volume-muted"
    hint="value:0"
else
    icon="audio-volume-high"
    hint="value:$vol"
fi

notify-send "Volume: $vol%" -h string:x-canonical-private-synchronous:volume -h int:value:$vol -h string:x-canonical-private-icon:audio-volume-high -t 1000 --icon=$icon
