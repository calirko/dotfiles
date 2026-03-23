#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Dotfiles Installer${NC}"
echo "Repo: $REPO_DIR"
echo "Target: $CONFIG_DIR"
echo ""

# Array of config directories to link
CONFIGS=("hypr" "kitty" "mako" "waybar" "wofi")

# Create symlinks
for config in "${CONFIGS[@]}"; do
    source="$REPO_DIR/$config"
    target="$CONFIG_DIR/$config"
    
    if [ ! -d "$source" ]; then
        echo -e "${YELLOW}⊘ Skipping $config (not found in repo)${NC}"
        continue
    fi
    
    if [ -L "$target" ]; then
        # Already a symlink
        if [ "$(readlink "$target")" = "$source" ]; then
            echo -e "${GREEN}✓ $config already linked${NC}"
        else
            echo -e "${RED}✗ $config symlink points elsewhere${NC}"
            echo "  Points to: $(readlink "$target")"
            echo "  Should point to: $source"
        fi
    elif [ -d "$target" ]; then
        # Directory exists, backup it
        backup="$target.backup.$(date +%s)"
        echo -e "${YELLOW}→ Backing up existing $config to $backup${NC}"
        mv "$target" "$backup"
        ln -s "$source" "$target"
        echo -e "${GREEN}✓ Linked $config${NC}"
    elif [ -e "$target" ]; then
        # File exists
        backup="$target.backup.$(date +%s)"
        echo -e "${YELLOW}→ Backing up existing $config to $backup${NC}"
        mv "$target" "$backup"
        ln -s "$source" "$target"
        echo -e "${GREEN}✓ Linked $config${NC}"
    else
        # Doesn't exist, create symlink
        ln -s "$source" "$target"
        echo -e "${GREEN}✓ Linked $config${NC}"
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Your config files are now managed by the dotfiles repo."
echo "To update: git pull && source ~/.bashrc (or reload your shell)"
