#!/usr/bin/env bash
set -euo pipefail

direction="${1:-next}"
month="${2:-$(date +%-m)}"
year="${3:-$(date +%Y)}"

if [[ "$direction" == "prev" ]]; then
    if [[ "$month" -eq 1 ]]; then
        month=12
        year=$((year - 1))
    else
        month=$((month - 1))
    fi
else
    if [[ "$month" -eq 12 ]]; then
        month=1
        year=$((year + 1))
    else
        month=$((month + 1))
    fi
fi

eww update cal-month="$month" cal-year="$year"
