#!/bin/bash

# Dotfiles reload script - restarts all services to load latest config files

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
ZEN_CHROME_DIR="/home/calirko/.zen/7310cqpp.Default (release)/chrome"

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

# Verify Zed symlink
echo -e "${YELLOW}→ Checking Zed symlink...${NC}"
if [ -L "$CONFIG_DIR/zed" ] && [ "$(readlink "$CONFIG_DIR/zed")" = "$REPO_DIR/zed" ]; then
    echo -e "${GREEN}✓ Zed symlink OK${NC}"
else
    echo -e "${YELLOW}⊘ Zed symlink missing or stale, re-linking...${NC}"
    rm -f "$CONFIG_DIR/zed"
    ln -s "$REPO_DIR/zed" "$CONFIG_DIR/zed"
    echo -e "${GREEN}✓ Zed symlink restored${NC}"
fi
echo ""

# Verify Zen chrome symlink
echo -e "${YELLOW}→ Checking Zen chrome symlink...${NC}"
if [ -L "$ZEN_CHROME_DIR" ] && [ "$(readlink "$ZEN_CHROME_DIR")" = "$REPO_DIR/zen" ]; then
    echo -e "${GREEN}✓ Zen chrome symlink OK${NC}"
else
    echo -e "${YELLOW}⊘ Zen chrome symlink missing or stale, re-linking...${NC}"
    rm -rf "$ZEN_CHROME_DIR"
    ln -s "$REPO_DIR/zen" "$ZEN_CHROME_DIR"
    echo -e "${GREEN}✓ Zen chrome symlink restored${NC}"
fi
echo ""

# Reload shell configuration (useful to add to ~/.bashrc or ~/.zshrc)
echo -e "${YELLOW}→ Reloading shell...${NC}"
echo -e "${GREEN}✓ Reload shell with: ${YELLOW}exec \$SHELL${NC}${GREEN} or reload your terminal${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done! All configs have been reloaded.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
