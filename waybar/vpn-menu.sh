#!/bin/bash

# VPN management script for Waybar
# Shows active WireGuard connections and provides menu to connect/disconnect

VPN_CONFIG_DIR="$HOME/Documents/vpn"
ICON_CONNECTED="󰒓"
ICON_DISCONNECTED=""

# Check if wg is available
if ! command -v wg &> /dev/null; then
    case "${1:-status}" in
        status)
            exit 0
            ;;
        tooltip)
            echo "WireGuard not installed"
            ;;
        menu)
            notify-send "VPN" "WireGuard is not installed"
            ;;
    esac
    exit 0
fi

# Get list of active WireGuard interfaces
get_active_vpns() {
    if command -v wg &> /dev/null; then
        sudo wg show interfaces 2>/dev/null | tr -d '\n' | sed 's/ /\n/g' | grep -v '^$'
    fi
}

# Show current status
show_status() {
    local active=$(get_active_vpns)
    
    if [ -z "$active" ]; then
        # Return empty or a space to avoid waybar errors
        echo ""
    else
        echo "$ICON_CONNECTED $(echo "$active" | head -1)"
    fi
}

# Show tooltip with all active connections
show_tooltip() {
    local active=$(get_active_vpns)
    
    if [ -z "$active" ]; then
        echo "VPN: Disconnected"
    else
        echo "VPN: $(echo "$active" | tr '\n' ', ' | sed 's/,$//')"
    fi
}

# Menu for VPN selection
show_menu() {
    # Create menu options
    local options=""
    
    # Add disconnect option if VPN is active
    if [ -n "$(get_active_vpns)" ]; then
        options="Disconnect\n"
    fi
    
    # Add available VPN configs
    if [ -d "$VPN_CONFIG_DIR" ]; then
        for conf in "$VPN_CONFIG_DIR"/*.conf; do
            if [ -f "$conf" ]; then
                options+="$(basename "$conf" .conf)\n"
            fi
        done
    fi
    
    if [ -z "$options" ]; then
        notify-send "VPN" "No VPN configs found in $VPN_CONFIG_DIR"
        return
    fi
    
    # Show menu in wofi
    local choice=$(echo -e "$options" | wofi --style "$HOME/.config/wofi/style.css" --allow-images --dmenu -p "Select VPN:")
    
    if [ -z "$choice" ]; then
        return
    fi
    
    # Handle selection
    if [ "$choice" = "Disconnect" ]; then
        # Disconnect all WireGuard interfaces
        for iface in $(get_active_vpns); do
            sudo wg-quick down "$iface" 2>/dev/null
        done
        notify-send "VPN" "Disconnected"
    else
        # Connect to selected VPN
        local conf_file="$VPN_CONFIG_DIR/$choice.conf"
        if [ -f "$conf_file" ]; then
            sudo wg-quick up "$conf_file" 2>&1 | tail -1
            notify-send "VPN" "Connecting to $choice..."
        fi
    fi
}

# Main logic
case "${1:-status}" in
    status)
        show_status
        ;;
    tooltip)
        show_tooltip
        ;;
    menu)
        show_menu
        ;;
    *)
        show_status
        ;;
esac

