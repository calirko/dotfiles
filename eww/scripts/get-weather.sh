#!/usr/bin/env bash

set -euo pipefail

PARAM="${1:-temperature}"
ICON_DIR="$HOME/Projects/dotfiles/eww/icons"

data=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=-29.5911&longitude=-51.1606&current=temperature_2m,is_day,weather_code" 2>/dev/null)

if [[ -z "$data" ]]; then
  echo "N/A"
  exit 1
fi

temp=$(echo "$data" | grep -o '"temperature_2m":[0-9.]*' | cut -d: -f2 | cut -d. -f1)
code=$(echo "$data" | grep -oP '"current":\{[^}]*"weather_code":\K[0-9]+' | head -1)
is_day=$(echo "$data" | grep -oP '"is_day":\K[0-9]+' | head -1)

get_icon() {
  local code=$1
  local day=$2

  case "$code" in
    0)       [[ "$day" == "1" ]] && echo "sun.svg" || echo "moon.svg" ;;
    1)       [[ "$day" == "1" ]] && echo "cloud-sun.svg" || echo "cloud-moon.svg" ;;
    2)       echo "cloud-sun.svg" ;;
    3)       echo "cloud.svg" ;;
    45|48)   echo "cloud-fog.svg" ;;
    51|53|55|56|57) echo "cloud-drizzle.svg" ;;
    61|63|65|66|67) echo "cloud-rain.svg" ;;
    71|73|75|77|85|86) echo "cloud-snow.svg" ;;
    80|81|82) echo "cloud-rain.svg" ;;
    95|96|99) echo "cloud-lightning.svg" ;;
    *)       echo "cloud.svg" ;;
  esac
}

case "$PARAM" in
  temperature)
    echo "${temp}°C"
    ;;
  icon)
    echo "${ICON_DIR}/$(get_icon "$code" "$is_day")"
    ;;
  *)
    echo "Unknown param: $PARAM" >&2
    exit 1
    ;;
esac
