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
echo ""

# Array of config directories to unlink
CONFIGS=("hypr" "kitty" "mako" "eww" "wofi" "zed" "fastfetch")

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

# Remove zen symlink
ZEN_TARGET="/home/calirko/.zen/7310cqpp.Default (release)/chrome"
ZEN_SOURCE="$REPO_DIR/zen"

echo -e "${YELLOW}→ Removing zen symlink...${NC}"
if [ -L "$ZEN_TARGET" ]; then
    if [ "$(readlink "$ZEN_TARGET")" = "$ZEN_SOURCE" ]; then
        rm "$ZEN_TARGET"
        echo -e "${GREEN}✓ Removed symlink for zen${NC}"
    else
        echo -e "${YELLOW}⊘ zen symlink points elsewhere, skipping${NC}"
    fi
elif [ -e "$ZEN_TARGET" ]; then
    echo -e "${YELLOW}⊘ zen chrome dir exists but is not a symlink, skipping${NC}"
else
    echo -e "${YELLOW}⊘ zen chrome dir not found${NC}"
fi

# Remove GTK symlinks
GTK_SOURCE="$REPO_DIR/gtk/gtk.css"
GTK3_TARGET="$HOME/.config/gtk-3.0/gtk.css"
GTK4_TARGET="$HOME/.config/gtk-4.0/gtk.css"

echo -e "${YELLOW}→ Removing GTK symlinks...${NC}"

# GTK 3
if [ -L "$GTK3_TARGET" ]; then
    if [ "$(readlink "$GTK3_TARGET")" = "$GTK_SOURCE" ]; then
        rm "$GTK3_TARGET"
        echo -e "${GREEN}✓ Removed GTK 3 gtk.css symlink${NC}"
    else
        echo -e "${YELLOW}⊘ GTK 3 gtk.css symlink points elsewhere, skipping${NC}"
    fi
elif [ -e "$GTK3_TARGET" ]; then
    echo -e "${YELLOW}⊘ GTK 3 gtk.css exists but is not a symlink, skipping${NC}"
fi

# GTK 4
if [ -L "$GTK4_TARGET" ]; then
    if [ "$(readlink "$GTK4_TARGET")" = "$GTK_SOURCE" ]; then
        rm "$GTK4_TARGET"
        echo -e "${GREEN}✓ Removed GTK 4 gtk.css symlink${NC}"
    else
        echo -e "${YELLOW}⊘ GTK 4 gtk.css symlink points elsewhere, skipping${NC}"
    fi
elif [ -e "$GTK4_TARGET" ]; then
    echo -e "${YELLOW}⊘ GTK 4 gtk.css exists but is not a symlink, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Symlinks removed. Your configs are still available in:"
echo "  $REPO_DIR/"
