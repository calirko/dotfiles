#!/usr/bin/env bash
# Tweak systemd-boot + mkinitcpio for a faster, silent boot on this machine:
#   - drop the UKI splash bitmap baked in by mkinitcpio's ukify options
#   - zero out the systemd-boot menu timeout and disable its editor prompt
#   - disable NetworkManager-wait-online.service, a common multi-second stall
#
# Safe to re-run (idempotent). Requires sudo for anything touching /boot or
# /etc, and rebuilds the UKI at the end so changes take effect immediately.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v sudo &>/dev/null; then
    echo -e "${RED}sudo not available — run this as root manually.${NC}"
    exit 1
fi

changed=0

# ── Remove the UKI splash image ──────────────────────────────────────────
echo -e "${YELLOW}Checking mkinitcpio presets for a baked-in splash...${NC}"
for preset in /etc/mkinitcpio.d/*.preset; do
    [ -f "$preset" ] || continue
    if grep -qE -- '--splash[[:space:]]+[^"]*"' "$preset"; then
        sudo sed -i -E 's/[[:space:]]*--splash[[:space:]]+[^"]*//' "$preset"
        echo -e "${GREEN}✓ Removed --splash from $(basename "$preset")${NC}"
        changed=1
    fi
done
(( changed )) || echo -e "${GREEN}✓ No splash option found in mkinitcpio presets${NC}"

# ── systemd-boot: no timeout, no editor prompt ───────────────────────────
LOADER_CONF="/boot/loader/loader.conf"
if [ -d /boot/loader ]; then
    echo -e "${YELLOW}Configuring systemd-boot loader.conf...${NC}"
    sudo touch "$LOADER_CONF"

    set_loader_key() {
        local key="$1" val="$2"
        if sudo grep -qE "^${key}[[:space:]]" "$LOADER_CONF"; then
            sudo sed -i -E "s/^${key}[[:space:]].*/${key} ${val}/" "$LOADER_CONF"
        else
            echo "${key} ${val}" | sudo tee -a "$LOADER_CONF" >/dev/null
        fi
    }

    set_loader_key "timeout" "0"
    set_loader_key "editor" "no"
    echo -e "${GREEN}✓ loader.conf: timeout 0, editor disabled${NC}"
else
    echo -e "${YELLOW}⊘ /boot/loader not found — not using systemd-boot, skipping${NC}"
fi

# ── Disable NetworkManager-wait-online (known multi-second boot stall) ──
if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
    echo -e "${YELLOW}Disabling NetworkManager-wait-online.service...${NC}"
    sudo systemctl disable NetworkManager-wait-online.service
    echo -e "${GREEN}✓ NetworkManager-wait-online disabled${NC}"
else
    echo -e "${GREEN}✓ NetworkManager-wait-online already disabled${NC}"
fi

# ── Rebuild the UKI so the splash removal takes effect now ──────────────
echo -e "${YELLOW}Rebuilding initramfs/UKI...${NC}"
sudo mkinitcpio -P
echo -e "${GREEN}✓ UKI rebuilt${NC}"

echo ""
echo -e "${GREEN}Done. Reboot to see the faster, splashless boot.${NC}"
echo -e "  Run ${YELLOW}scripts/boot-analyze.sh${NC} after rebooting to check for further slow units."
