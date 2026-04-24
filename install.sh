#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SKIP_PACKAGES=true
ICON_THEME_NAME="WhiteSur-grey-dark"
CONFIGS=("btop" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "eww" "wofi" "fastfetch" "fontconfig")

# Color output
RED='\033[0;31m'
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


# Configure PS1 prompt color in ~/.bashrc (managed block)
BASHRC_FILE="$HOME/.bashrc"
PS1_VALUE="PS1='\\[\\e[1;37m\\]\\u@\\h\\[\\e[0m\\] \\[\\e[2;37m\\]\\w\\[\\e[0m\\]\\\\$ '"
PS1_BEGIN="# >>> dotfiles managed ps1 >>>"
PS1_END="# <<< dotfiles managed ps1 <<<"

echo -e "${YELLOW}Configuring PS1 prompt in $BASHRC_FILE...${NC}"

# Ensure file exists
touch "$BASHRC_FILE"

# Remove existing managed block if present (replace behavior)
tmp_file="$(mktemp)"
awk -v begin="$PS1_BEGIN" -v end="$PS1_END" '
    $0 == begin {skip=1; next}
    $0 == end   {skip=0; next}
    !skip
' "$BASHRC_FILE" > "$tmp_file"
mv "$tmp_file" "$BASHRC_FILE"

# Append managed PS1 block
{
    echo ""
    echo "$PS1_BEGIN"
    echo "$PS1_VALUE"
    echo "$PS1_END"
} >> "$BASHRC_FILE"

echo -e "${GREEN}✓ PS1 prompt configured${NC}"
echo ""

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Your config files are now managed by the dotfiles repo."
echo "To update: git pull && source ~/.bashrc (or reload your shell)"
