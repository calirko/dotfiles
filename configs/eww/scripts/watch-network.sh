#!/usr/bin/env bash

emit() {
    local connection ssid vpn_active vpn_name

    local vpn_name_raw
    vpn_name_raw=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | awk -F: '$2 == "wireguard" { print $1 }' | head -n1 || true)
    if [[ -n "$vpn_name_raw" ]]; then
        vpn_active="true"
        vpn_name="$vpn_name_raw"
    else
        vpn_active="false"
        vpn_name=""
    fi

    local wifi_line
    wifi_line=$(nmcli -t -f IN-USE,SIGNAL dev wifi list 2>/dev/null | grep '^\*' | head -1 || true)
    if [[ -n "$wifi_line" ]]; then
        local signal
        signal=$(cut -d: -f2 <<< "$wifi_line")
        if   [[ $signal -ge 80 ]]; then connection="wifi-strength-4"
        elif [[ $signal -ge 60 ]]; then connection="wifi-strength-3"
        elif [[ $signal -ge 40 ]]; then connection="wifi-strength-2"
        elif [[ $signal -ge 20 ]]; then connection="wifi-strength-1"
        else                             connection="wifi-strength-0"
        fi
        ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1 || true)
    elif nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | grep -qE 'ethernet:connected'; then
        connection="ethernet-connected"
        ssid=""
    else
        connection="wifi-offline"
        ssid=""
    fi

    jq -cn \
        --arg connection "$connection" \
        --arg ssid "$ssid" \
        --argjson vpn_active "$vpn_active" \
        --arg vpn_name "$vpn_name" \
        '{connection:$connection,ssid:$ssid,vpn_active:$vpn_active,vpn_name:$vpn_name}'
}

emit

nmcli monitor 2>/dev/null | while read -r _; do
    emit
done
