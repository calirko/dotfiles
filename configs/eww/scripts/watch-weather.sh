#!/usr/bin/env bash

# Current weather from open-meteo, one JSON line per refresh:
#   {"ok":true,"temperature":"25°","condition":"Partly cloudy",
#    "high":"25°","low":"13°","icon":"icons/cloud-sun.svg"}
#
# Parsed with jq: grepping for "temperature_2m" also matched the key in
# current_units, which put a newline in the value and split the JSON line.

LAT="-29.5911"
LON="-51.1606"
URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,is_day,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"

emit() {
    local data
    data=$(curl -sf --max-time 10 "$URL" 2>/dev/null)

    # icon paths are relative to the eww config dir, like the rest of the bar
    if ! jq -ce '
        def deg: (. | round | tostring) + "°";
        .current as $c
        | ($c.weather_code) as $w
        | ($c.is_day == 1) as $day
        | {
            ok: true,
            temperature: ($c.temperature_2m | deg),
            high: (.daily.temperature_2m_max[0] | deg),
            low: (.daily.temperature_2m_min[0] | deg),
            condition: (
                if $w == 0 then "Clear"
                elif $w == 1 then "Mostly clear"
                elif $w == 2 then "Partly cloudy"
                elif $w == 3 then "Cloudy"
                elif ($w == 45 or $w == 48) then "Fog"
                elif ($w >= 51 and $w <= 57) then "Drizzle"
                elif ($w >= 61 and $w <= 67) then "Rain"
                elif ($w >= 71 and $w <= 77) or $w == 85 or $w == 86 then "Snow"
                elif ($w >= 80 and $w <= 82) then "Showers"
                elif $w >= 95 then "Thunderstorm"
                else "Cloudy" end),
            icon: ("icons/" + (
                if $w == 0 then (if $day then "sun" else "moon" end)
                elif $w <= 2 then (if $day then "cloud-sun" else "cloud-moon" end)
                elif $w == 3 then "cloud"
                elif ($w == 45 or $w == 48) then "cloud-fog"
                elif ($w >= 71 and $w <= 77) or $w == 85 or $w == 86 then "cloud-snow"
                elif $w >= 95 then "cloud-lightning"
                else "cloud-rain" end) + ".svg")
          }' <<<"$data" 2>/dev/null; then
        echo '{"ok":false,"temperature":"","condition":"","high":"","low":"","icon":"icons/cloud.svg"}'
    fi
}

emit

while true; do
    sleep 1200
    emit
done
