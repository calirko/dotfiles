#!/bin/bash

# Dotfiles reload script - restarts all services to load latest config files

set -e

CONFIG_DIR="$HOME/.config"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Dotfiles Config Reload${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Reload Eww
echo -e "${YELLOW}→ Reloading Eww...${NC}"
if command -v eww &> /dev/null; then
    eww close-all || true
    pkill -f "eww daemon" || true
    sleep 1
    eww daemon
    eww open bar
    echo -e "${GREEN}✓ Eww reloaded${NC}"
else
    echo -e "${RED}✗ Eww not found${NC}"
fi
echo ""

# Reload Mako (notifications)
echo -e "${YELLOW}→ Reloading Mako...${NC}"
if command -v mako &> /dev/null; then
    pkill -f mako || true
    sleep 1
    mako &
    echo -e "${GREEN}✓ Mako reloaded${NC}"
else
    echo -e "${RED}✗ Mako not found${NC}"
fi
echo ""

# Reload Hyprland config (if running under Hyprland)
if [ "$XDG_SESSION_TYPE" = "wayland" ] && command -v hyprctl &> /dev/null; then
    echo -e "${YELLOW}→ Reloading Hyprland config...${NC}"
    hyprctl reload
    echo -e "${GREEN}✓ Hyprland config reloaded${NC}"
    echo ""
fi

# Kill and restart Wofi if running
if pgrep -f wofi > /dev/null; then
    echo -e "${YELLOW}→ Restarting Wofi...${NC}"
    pkill -f wofi || true
    sleep 1
    echo -e "${GREEN}✓ Wofi cleared${NC}"
    echo ""
fi

# Reload shell configuration (useful to add to ~/.bashrc or ~/.zshrc)
echo -e "${YELLOW}→ Reloading shell...${NC}"
echo -e "${GREEN}✓ Reload shell with: ${YELLOW}exec \$SHELL${NC}${GREEN} or reload your terminal${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done! All configs have been reloaded.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
