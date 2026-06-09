#!/usr/bin/env bash

ICON_DIR="$HOME/Projects/dotfiles/eww/icons"

emit() {
    local data temp code is_day icon
    data=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=-29.5911&longitude=-51.1606&current=temperature_2m,is_day,weather_code" 2>/dev/null || true)

    if [[ -z "$data" ]]; then
        echo '{"temperature":"N/A","icon":""}'
        return
    fi

    temp=$(echo "$data" | grep -o '"temperature_2m":[0-9.]*' | cut -d: -f2 | cut -d. -f1)
    code=$(echo "$data" | grep -oP '"current":\{[^}]*"weather_code":\K[0-9]+' | head -1)
    is_day=$(echo "$data" | grep -oP '"is_day":\K[0-9]+' | head -1)

    case "$code" in
        0)            [[ "$is_day" == "1" ]] && icon="sun.svg" || icon="moon.svg" ;;
        1)            [[ "$is_day" == "1" ]] && icon="cloud-sun.svg" || icon="cloud-moon.svg" ;;
        2)            icon="cloud-sun.svg" ;;
        3)            icon="cloud.svg" ;;
        45|48)        icon="cloud-fog.svg" ;;
        51|53|55|56|57) icon="cloud-drizzle.svg" ;;
        61|63|65|66|67) icon="cloud-rain.svg" ;;
        71|73|75|77|85|86) icon="cloud-snow.svg" ;;
        80|81|82)     icon="cloud-rain.svg" ;;
        95|96|99)     icon="cloud-lightning.svg" ;;
        *)            icon="cloud.svg" ;;
    esac

    printf '{"temperature":"%s°C","icon":"%s"}\n' "$temp" "${ICON_DIR}/${icon}"
}

emit

while true; do
    sleep 1200
    emit
done
