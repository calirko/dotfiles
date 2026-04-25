#!/usr/bin/env bash

get_audio_data() {
    volume_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    volume=$(echo "$volume_output" | awk '{print int($2*100)}')
    if echo "$volume_output" | grep -q 'MUTED'; then
        mute="\"true\""
    else
        mute="\"false\""
    fi
    echo "{\"volume\": $volume, \"mute\": $mute}"
}

get_audio_data

# Filter out client events entirely, only care about sink changes
pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r event; do
    echo "GOT: $event" >&2
    get_audio_data
    # Small debounce for rapid volume changes
    sleep 0.1
done

echo "DIED" >&2
