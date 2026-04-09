# Cycle through available power profiles using powerprofilesctl
cycle_power_profile() {
    local current next

    current=$(powerprofilesctl get 2>/dev/null)

    case "$current" in
        power-saver)
            next="balanced"
            ;;
        balanced)
            next="performance"
            ;;
        performance)
            next="power-saver"
            ;;
        *)
            next="balanced"
            ;;
    esac

    powerprofilesctl set "$next" && printf 'Power profile: %s -> %s\n' "$current" "$next"
}

cycle_power_profile
