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

# Array of config directories to unlink (must match install.sh)
CONFIGS=("zed" "btop" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "eww" "wofi" "fastfetch" "fontconfig" "easyeffects")

# Confirm before proceeding
echo -e "${YELLOW}This will remove symlinks to dotfiles from ~/.config/${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# raccoon: restore logind lid handling (mirror of install.sh)
if [[ "$(uname -n)" == "raccoon" ]]; then
    echo -e "${YELLOW}raccoon: restoring logind lid handling...${NC}"

    if command -v sudo >/dev/null 2>&1; then
        sudo rm -f /etc/systemd/logind.conf.d/raccoon-lid.conf
        sudo systemctl kill -s HUP systemd-logind 2>/dev/null || true
        echo -e "${GREEN}✓ logind lid drop-in removed${NC}"
    else
        echo -e "${YELLOW}⊘ sudo not available — remove /etc/systemd/logind.conf.d/raccoon-lid.conf manually${NC}"
    fi
    echo ""
fi

# Remove Hyprland autostart block from ~/.zprofile (mirror of install.sh)
ZPROFILE="$HOME/.zprofile"
START_HYPR_MARKER="# start-hyprland (dotfiles-managed)"
if [ -f "$ZPROFILE" ] && grep -qF "$START_HYPR_MARKER" "$ZPROFILE"; then
    sed -i "/^${START_HYPR_MARKER}\$/,/^fi\$/d" "$ZPROFILE"
    echo -e "${GREEN}✓ Removed Hyprland autostart from ~/.zprofile${NC}"
fi

# Remove PATH block from ~/.zshenv (mirror of install.sh)
ZSHENV="$HOME/.zshenv"
LOCAL_BIN_MARKER="# local-bin-path (dotfiles-managed)"
if [ -f "$ZSHENV" ] && grep -qF "$LOCAL_BIN_MARKER" "$ZSHENV"; then
    sed -i "/^${LOCAL_BIN_MARKER}\$/d;\@^export PATH=\"\$HOME/.local/bin:\$PATH\"\$@d" "$ZSHENV"
    echo -e "${GREEN}✓ Removed PATH block from ~/.zshenv${NC}"
fi

# Remove oh-my-zsh block from ~/.zshrc (mirror of install.sh)
ZSHRC="$HOME/.zshrc"
OMZ_MARKER="# oh-my-zsh (dotfiles-managed)"
if [ -f "$ZSHRC" ] && grep -qF "$OMZ_MARKER" "$ZSHRC"; then
    sed -i "/^${OMZ_MARKER}\$/,/^source \$ZSH\/oh-my-zsh.sh\$/d" "$ZSHRC"
    echo -e "${GREEN}✓ Removed oh-my-zsh block from ~/.zshrc${NC}"
fi

# Remove symlinks
for config in "${CONFIGS[@]}"; do
    target="$CONFIG_DIR/$config"
    source="$REPO_DIR/configs/$config"

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
