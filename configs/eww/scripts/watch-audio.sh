#!/usr/bin/env bash

get_audio_data() {
    local out volume mute
    out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    # round, don't truncate: 0.57 * 100 is 56.999... in floating point
    volume=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$out")
    [[ "$out" == *MUTED* ]] && mute=true || mute=false
    echo "{\"volume\": $volume, \"mute\": \"$mute\"}"
}

get_audio_data

# Sink events cover volume/mute; server events cover a default-sink switch
# (e.g. headphones connecting). One volume step fires several events, so drain
# whatever has queued up and re-read once — handling them one by one let a
# held key build a backlog, and the slider trailed behind and fed stale values
# back through its onchange.
pactl subscribe | grep --line-buffered -E "Event 'change' on (sink|server)" | while read -r _; do
    while read -r -t 0.03 _; do :; done
    get_audio_data
done
