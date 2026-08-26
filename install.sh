#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SKIP_PACKAGES=false
ICON_THEME_NAME="WhiteSur-grey-dark"
CONFIGS=("zed" "btop" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "eww" "wofi" "fastfetch" "fontconfig" "easyeffects")

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-packages)
            SKIP_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-packages    Skip package installation from woof.json"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}Dotfiles Installer${NC}"
echo "Repo: $REPO_DIR"
echo "Target: $CONFIG_DIR"
echo ""

# Install packages from woof.json
if [ "$SKIP_PACKAGES" = false ]; then
    # jq is required to parse woof.json below, and is itself one of the
    # packages woof.json lists — bootstrap it directly via pacman so a
    # jq-less machine isn't stuck permanently skipping package installation.
    if ! command -v jq &> /dev/null && command -v sudo &> /dev/null; then
        echo -e "${YELLOW}Bootstrapping jq (required to read woof.json)...${NC}"
        sudo pacman -S --noconfirm jq
        echo ""
    fi

    if [ ! -f "$REPO_DIR/woof.json" ]; then
        echo -e "${YELLOW}⊘ woof.json not found, skipping package installation${NC}"
        echo ""
    elif ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⊘ jq not found, skipping package installation${NC}"
        echo ""
    elif ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}⊘ yay not found, skipping package installation${NC}"
        echo ""
    else
        echo -e "${YELLOW}Installing packages from woof.json...${NC}"
        PACKAGES=$(jq -r '.packages[]' "$REPO_DIR/woof.json")
        if [ -n "$PACKAGES" ]; then
            yay -S --noconfirm $(echo "$PACKAGES" | tr '\n' ' ')
            echo -e "${GREEN}✓ Packages installed${NC}"
        fi
        echo ""
    fi
else
    echo -e "${YELLOW}⊘ Skipping package installation (--skip-packages)${NC}"
    echo ""
fi

# Create symlinks
for config in "${CONFIGS[@]}"; do
    source="$REPO_DIR/configs/$config"
    target="$CONFIG_DIR/$config"

    if [ ! -d "$source" ]; then
        echo -e "${YELLOW}⊘ Skipping $config (not found in repo)${NC}"
        continue
    fi

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo -e "${GREEN}✓ $config already linked${NC}"
    else
        rm -rf "$target"
        ln -s "$source" "$target"
        echo -e "${GREEN}✓ Linked $config${NC}"
    fi
done

# raccoon: lid switch handling (laptop-only, requires sudo for logind drop-in)
# Lid close/open itself is handled natively inside hyprland.lua via switch
# bindings — this just stops systemd-logind from also acting on the lid
# (suspending, etc.) so Hyprland is the sole owner of the event.
if [[ "$(uname -n)" == "raccoon" ]]; then
    echo ""
    echo -e "${YELLOW}raccoon: disabling logind lid handling (Hyprland owns it natively)...${NC}"

    if command -v sudo >/dev/null 2>&1; then
        sudo mkdir -p /etc/systemd/logind.conf.d
        sudo cp "$REPO_DIR/configs/hypr/logind-lid.conf" /etc/systemd/logind.conf.d/raccoon-lid.conf
        sudo systemctl kill -s HUP systemd-logind
        echo -e "${GREEN}✓ logind lid switch handling disabled${NC}"
    else
        echo -e "${YELLOW}⊘ sudo not available — copy configs/hypr/logind-lid.conf to /etc/systemd/logind.conf.d/raccoon-lid.conf manually${NC}"
    fi
fi

# Auto-start Hyprland on tty1 login
echo ""
ZPROFILE="$HOME/.zprofile"
START_HYPR_MARKER="# start-hyprland (dotfiles-managed)"
if ! grep -qF "$START_HYPR_MARKER" "$ZPROFILE" 2>/dev/null; then
    {
        echo "$START_HYPR_MARKER"
        echo 'if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then'
        echo "    exec start-hyprland"
        echo "fi"
    } >> "$ZPROFILE"
    echo -e "${GREEN}✓ Added Hyprland autostart to ~/.zprofile${NC}"
else
    echo -e "${GREEN}✓ ~/.zprofile already configured for Hyprland autostart${NC}"
fi

echo -e "${GREEN}Done!${NC}"
