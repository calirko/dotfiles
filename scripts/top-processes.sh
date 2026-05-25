#!/usr/bin/env bash
# Top processes by CPU and memory

set -euo pipefail

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'

TOP_N="${1:-20}"

divider() { printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..85})"; }

mem_color() {
    local pct="$1"
    if awk "BEGIN {exit !($pct >= 5)}"; then
        printf "$RED"
    elif awk "BEGIN {exit !($pct >= 1)}"; then
        printf "$YELLOW"
    else
        printf "$GREEN"
    fi
}

cpu_color() {
    local pct="$1"
    if awk "BEGIN {exit !($pct >= 50)}"; then
        printf "$RED"
    elif awk "BEGIN {exit !($pct >= 10)}"; then
        printf "$YELLOW"
    else
        printf "$GREEN"
    fi
}

total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')

echo
printf "${BOLD}  Top Processes — CPU${RESET}\n"
echo
printf "${BOLD}${CYAN}  %-7s %-7s %-8s %-8s %s${RESET}\n" "PID" "CPU%" "MEM%" "MEM" "COMMAND"
divider

ps -eo pid,pcpu,pmem,rss,comm --sort=-%cpu --no-headers \
    | head -n "$TOP_N" \
    | while read -r pid cpu mem rss comm; do
        mem_kb=$(( rss ))
        mem_h=$(numfmt --to=iec-i --suffix=B "$(( mem_kb * 1024 ))" 2>/dev/null || echo "${mem_kb}K")
        cc=$(cpu_color "$cpu")
        mc=$(mem_color "$mem")
        printf "  %-7s ${cc}%-7s${RESET} ${mc}%-8s %-8s${RESET} %s\n" \
            "$pid" "${cpu}%" "${mem}%" "$mem_h" "$comm"
    done

echo
divider
echo
printf "${BOLD}  Top Processes — Memory${RESET}\n"
echo
printf "${BOLD}${CYAN}  %-7s %-7s %-8s %-8s %s${RESET}\n" "PID" "MEM%" "MEM" "CPU%" "COMMAND"
divider

ps -eo pid,pmem,rss,pcpu,comm --sort=-%mem --no-headers \
    | head -n "$TOP_N" \
    | while read -r pid mem rss cpu comm; do
        mem_kb=$(( rss ))
        mem_h=$(numfmt --to=iec-i --suffix=B "$(( mem_kb * 1024 ))" 2>/dev/null || echo "${mem_kb}K")
        mc=$(mem_color "$mem")
        cc=$(cpu_color "$cpu")
        printf "  %-7s ${mc}%-7s %-8s${RESET} ${cc}%-8s${RESET} %s\n" \
            "$pid" "${mem}%" "$mem_h" "${cpu}%" "$comm"
    done

echo
divider
echo
printf "${DIM}  Total RAM: $(numfmt --to=iec-i --suffix=B "$(( total_mem_kb * 1024 ))")${RESET}\n"
used_kb=$(grep -E "^MemAvailable" /proc/meminfo | awk '{print $2}')
used_pct=$(awk "BEGIN {printf \"%.1f\", (1 - $used_kb/$total_mem_kb)*100}")
printf "${DIM}  Used: ~${used_pct}%%${RESET}\n"
echo
