#!/usr/bin/env bash

set -euo pipefail

state_file="/tmp/waybar-system-stats-prev"

read_temp_c() {
    local path="$1"
    if [[ -r "$path" ]]; then
        awk '{printf "%d", ($1 / 1000)}' "$path"
        return 0
    fi
    return 1
}

first_readable_from_glob() {
    local pattern="$1"
    local match
    for match in $pattern; do
        if [[ -r "$match" ]]; then
            printf "%s" "$match"
            return 0
        fi
    done
    return 1
}

cpu_temp="N/A"
gpu_temp="N/A"

if cpu_temp_file=$(first_readable_from_glob "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input"); then
    t=$(read_temp_c "$cpu_temp_file")
    cpu_temp="$t"
elif t=$(read_temp_c "/sys/class/thermal/thermal_zone0/temp" 2>/dev/null); then
    cpu_temp="$t"
fi

if gpu_temp_file=$(first_readable_from_glob "/sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0/0000:02:00.0/0000:03:00.0/hwmon/hwmon*/temp1_input"); then
    t=$(read_temp_c "$gpu_temp_file")
    gpu_temp="$t"
fi

read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat
total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 + st1))
idle1=$((i1 + w1))

cpu_usage="0"
if [[ -f "$state_file" ]]; then
    read -r prev_total prev_idle < "$state_file" || true
    if [[ -n "${prev_total:-}" && -n "${prev_idle:-}" ]]; then
        d_total=$((total1 - prev_total))
        d_idle=$((idle1 - prev_idle))
        if (( d_total > 0 )); then
            cpu_usage=$(( (100 * (d_total - d_idle)) / d_total ))
        fi
    fi
fi

printf "%s %s\n" "$total1" "$idle1" > "$state_file"

mem_used_pct=$(awk '
    /MemTotal:/ {t=$2}
    /MemAvailable:/ {a=$2}
    END {
        if (t > 0) {
            printf "%d", ((t - a) * 100 / t)
        } else {
            printf "0"
        }
    }
' /proc/meminfo)

bar_text="  ${cpu_temp}°C"
if [[ "$cpu_temp" == "N/A" ]]; then
    bar_text="  N/A"
fi

tooltip="CPU temp: ${cpu_temp}°C"
if [[ "$cpu_temp" == "N/A" ]]; then
    tooltip="CPU temp: N/A"
fi

tooltip+="\\nGPU temp: "
if [[ "$gpu_temp" == "N/A" ]]; then
    tooltip+="N/A"
else
    tooltip+="${gpu_temp}°C"
fi
tooltip+="\\nCPU usage: ${cpu_usage}%"
tooltip+="\\nRAM usage: ${mem_used_pct}%"

printf '{"text":"%s","tooltip":"%s"}\n' "$bar_text" "$tooltip"
