#!/bin/bash

# Dotfiles uninstaller - removes symlinks and optionally restores backups

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Dotfiles Uninstaller${NC}"
echo "Repo: $REPO_DIR"
echo "Target: $CONFIG_DIR"
echo ""

# Array of config directories to unlink
CONFIGS=("hypr" "kitty" "mako" "waybar" "wofi")

# Confirm before proceeding
echo -e "${YELLOW}This will remove symlinks to dotfiles from ~/.config/${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Remove symlinks
for config in "${CONFIGS[@]}"; do
    target="$CONFIG_DIR/$config"
    source="$REPO_DIR/$config"
    
    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$source" ]; then
            rm "$target"
            echo -e "${GREEN}✓ Removed symlink for $config${NC}"
            
            # Check for backups and ask to restore
            backup=$(ls -t "$CONFIG_DIR/${config}.backup."* 2>/dev/null | head -1)
            if [ -n "$backup" ]; then
                read -p "  Restore backup from $(basename $backup)? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    mv "$backup" "$target"
                    echo -e "${GREEN}  ✓ Restored backup${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⊘ $config symlink points elsewhere, skipping${NC}"
        fi
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}⊘ $config exists but is not a symlink, skipping${NC}"
    else
        echo -e "${YELLOW}⊘ $config not found${NC}"
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Symlinks removed. Your configs are still available in:"
echo "  $REPO_DIR/"
