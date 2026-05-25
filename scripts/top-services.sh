#!/usr/bin/env bash
# Top systemd services by CPU and memory usage

set -euo pipefail

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'

TOP_N="${1:-20}"

header() { printf "${BOLD}${CYAN}%-45s %8s %10s %s${RESET}\n" "$1" "$2" "$3" "$4"; }
divider() { printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..75})"; }

running_services() {
    systemctl list-units --type=service --state=running --no-legend --plain \
        | awk '{print $1}'
}

get_service_resources() {
    local unit="$1"
    local cpu_ns mem_bytes tasks
    cpu_ns=$(  systemctl show "$unit" --property=CPUUsageNSec   --value 2>/dev/null || echo 0)
    mem_bytes=$(systemctl show "$unit" --property=MemoryCurrent  --value 2>/dev/null || echo 0)
    tasks=$(   systemctl show "$unit" --property=TasksCurrent    --value 2>/dev/null || echo 0)

    # CPUUsageNSec is cumulative nanoseconds; format as seconds
    local cpu_s=0
    if [[ "$cpu_ns" =~ ^[0-9]+$ ]] && (( cpu_ns > 0 )); then
        cpu_s=$(awk "BEGIN {printf \"%.1f\", $cpu_ns / 1e9}")
    fi

    local mem_h="—"
    if [[ "$mem_bytes" =~ ^[0-9]+$ ]] && (( mem_bytes > 0 )); then
        mem_h=$(numfmt --to=iec-i --suffix=B "$mem_bytes" 2>/dev/null || echo "${mem_bytes}B")
    fi

    [[ "$tasks" =~ ^[0-9]+$ ]] || tasks=0

    printf "%s\t%s\t%s\t%s\n" "$unit" "$cpu_s" "$mem_bytes" "$mem_h"
}

export -f get_service_resources

echo
printf "${BOLD}  System Services — Resource Usage${RESET}\n"
printf "${DIM}  Sorted by memory. CPU shown as cumulative seconds since start.${RESET}\n"
echo

header "  SERVICE" "CPU (s)" "MEMORY" "TASKS"
divider

mapfile -t services < <(running_services)

# Gather data in parallel, then sort by raw memory bytes (field 3) descending
data=$(for svc in "${services[@]}"; do
    get_service_resources "$svc"
done | sort -t$'\t' -k3 -rn | head -n "$TOP_N")

while IFS=$'\t' read -r unit cpu_s mem_bytes mem_h; do
    # Colour memory: red >500MiB, yellow >100MiB, green otherwise
    local_mem_color="$GREEN"
    if (( mem_bytes > 524288000 )); then
        local_mem_color="$RED"
    elif (( mem_bytes > 104857600 )); then
        local_mem_color="$YELLOW"
    fi

    short="${unit%.service}"
    printf "  %-43s ${DIM}%8s${RESET} ${local_mem_color}%10s${RESET}\n" \
        "$short" "${cpu_s}s" "$mem_h"
done <<< "$data"

echo
divider

# User services (if any are running)
user_units=$(systemctl --user list-units --type=service --state=running --no-legend --plain 2>/dev/null | awk '{print $1}' || true)
if [[ -n "$user_units" ]]; then
    echo
    printf "${BOLD}  User Services${RESET}\n"
    echo
    header "  SERVICE" "CPU (s)" "MEMORY" ""
    divider
    for u in $user_units; do
        cpu_ns=$(systemctl --user show "$u" --property=CPUUsageNSec  --value 2>/dev/null || echo 0)
        mem=$(   systemctl --user show "$u" --property=MemoryCurrent --value 2>/dev/null || echo 0)
        cpu_s=0
        [[ "$cpu_ns" =~ ^[0-9]+$ ]] && (( cpu_ns > 0 )) && \
            cpu_s=$(awk "BEGIN {printf \"%.1f\", $cpu_ns / 1e9}")
        mem_h="—"
        [[ "$mem" =~ ^[0-9]+$ ]] && (( mem > 0 )) && \
            mem_h=$(numfmt --to=iec-i --suffix=B "$mem" 2>/dev/null || echo "${mem}B")
        printf "  %-43s ${DIM}%8s${RESET} %10s\n" "${u%.service}" "${cpu_s}s" "$mem_h"
    done < <(echo "$user_units")
    echo
fi
