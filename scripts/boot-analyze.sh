#!/usr/bin/env bash
# Analyze boot: timing, slow units, errors, and suspicious entries

set -euo pipefail

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'

SLOW_THRESHOLD="${1:-3000}"  # ms — units slower than this are flagged

section() { echo; printf "${BOLD}${CYAN}▸ %s${RESET}\n" "$1"; printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..70})"; }
warn() { printf "  ${YELLOW}⚠  %s${RESET}\n" "$1"; }
err()  { printf "  ${RED}✖  %s${RESET}\n" "$1"; }
ok()   { printf "  ${GREEN}✔  %s${RESET}\n" "$1"; }
info() { printf "  ${DIM}%s${RESET}\n" "$1"; }

# ── Boot time summary ─────────────────────────────────────────────────────────
section "Boot Time Summary"
if systemd-analyze time 2>/dev/null; then
    :
else
    warn "systemd-analyze not available"
fi

# ── Slow units (above threshold) ─────────────────────────────────────────────
section "Slow Units  (>${SLOW_THRESHOLD}ms)"

mapfile -t blame_lines < <(systemd-analyze blame 2>/dev/null | head -40)
found_slow=0
for line in "${blame_lines[@]}"; do
    # Format: "  1min 2.345s unit.service" or "  3.456s unit.service"
    ms=0
    if [[ "$line" =~ ([0-9]+)min ]]; then
        ms=$(( ${BASH_REMATCH[1]} * 60000 ))
    fi
    if [[ "$line" =~ ([0-9]+)\.([0-9]+)s ]]; then
        ms=$(( ms + ${BASH_REMATCH[1]} * 1000 ))
    fi
    if (( ms >= SLOW_THRESHOLD )); then
        warn "$line"
        found_slow=1
    fi
done
(( found_slow )) || ok "No units exceeded ${SLOW_THRESHOLD}ms"

# ── Failed units ──────────────────────────────────────────────────────────────
section "Failed Units"
failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
if [[ -z "$failed" ]]; then
    ok "No failed units"
else
    while IFS= read -r unit; do
        err "$unit"
    done <<< "$failed"
fi

failed_user=$(systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1}' || true)
if [[ -n "$failed_user" ]]; then
    while IFS= read -r unit; do
        err "(user) $unit"
    done <<< "$failed_user"
fi

# ── Boot errors from journal ──────────────────────────────────────────────────
section "Journal Errors  (this boot)"
error_count=$(journalctl -b -p err --no-pager -q 2>/dev/null | wc -l)
if (( error_count == 0 )); then
    ok "No errors in journal for this boot"
else
    warn "${error_count} error(s) found:"
    echo
    journalctl -b -p err --no-pager -q 2>/dev/null \
        | grep -v "^-- " \
        | head -40 \
        | while IFS= read -r line; do
            printf "  ${RED}│${RESET} %s\n" "$line"
        done
    if (( error_count > 40 )); then
        info "... and $(( error_count - 40 )) more. Run: journalctl -b -p err"
    fi
fi

# ── Warnings ──────────────────────────────────────────────────────────────────
section "Journal Warnings  (this boot)"
warn_count=$(journalctl -b -p warning --no-pager -q 2>/dev/null \
    | grep -v "^-- " | grep -v "^\s*$" | wc -l)
if (( warn_count == 0 )); then
    ok "No warnings"
elif (( warn_count > 100 )); then
    warn "${warn_count} warnings — too many to list. Run: journalctl -b -p warning"
else
    warn "${warn_count} warning(s):"
    echo
    journalctl -b -p warning --no-pager -q 2>/dev/null \
        | grep -v "^-- " | grep -v "^\s*$" \
        | head -20 \
        | while IFS= read -r line; do
            printf "  ${YELLOW}│${RESET} %s\n" "$line"
        done
    (( warn_count > 20 )) && info "... and $(( warn_count - 20 )) more."
fi

# ── Critical path ─────────────────────────────────────────────────────────────
section "Critical Chain"
systemd-analyze critical-chain 2>/dev/null | head -30 || true

# ── NetworkManager-wait-online ────────────────────────────────────────────────
section "Known Boot Killers"
if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
    nw_time=$(systemd-analyze blame 2>/dev/null | grep "NetworkManager-wait-online" | head -1 || true)
    if [[ -n "$nw_time" ]]; then
        warn "NetworkManager-wait-online is enabled and took: $nw_time"
        info "Disable with: sudo systemctl disable NetworkManager-wait-online.service"
    else
        info "NetworkManager-wait-online: enabled but fast this boot"
    fi
else
    ok "NetworkManager-wait-online is disabled"
fi

echo
