#!/usr/bin/env bash
set -uo pipefail

# Power mode on top of auto-cpufreq (raccoon).
#
#   power-mode.sh get     {"present":true,"mode":"auto|powersave|performance"}
#   power-mode.sh cycle   auto -> powersave -> performance -> auto
#
# "auto" is auto-cpufreq's own charger/battery switching; the other two force
# a governor via `auto-cpufreq --force=…`. That needs root, so it goes through
# the sudoers rule from configs/hypr/power-mode.sudoers (sudo -n: never
# prompt). power-mode-reset.service drops the override at every boot.

OVERRIDE=/opt/auto-cpufreq/override.pickle

present() {
    command -v auto-cpufreq >/dev/null 2>&1 && systemctl is-active --quiet auto-cpufreq
}

current() {
    if [[ -f "$OVERRIDE" ]]; then
        # the override is a pickled string: "powersave" or "performance"
        python3 -I -c 'import pickle,sys; print(pickle.load(open(sys.argv[1],"rb")))' "$OVERRIDE" 2>/dev/null || echo auto
    else
        echo auto
    fi
}

emit() {
    if present; then
        jq -nc --arg m "$(current)" '{present: true, mode: $m}'
    else
        echo '{"present":false,"mode":"auto"}'
    fi
}

case "${1:-get}" in
    get)
        emit
        ;;
    cycle)
        present || exit 0
        case "$(current)" in
            auto)      next=powersave ;;
            powersave) next=performance ;;
            *)         next=reset ;;
        esac
        if ! sudo -n /usr/bin/auto-cpufreq --force="$next" >/dev/null 2>&1; then
            notify-send -i dialog-warning "Power mode" \
                "Couldn't change it: the sudoers rule isn't installed. Run install.sh."
            exit 1
        fi
        eww update power-mode="$(emit)"
        ;;
esac
