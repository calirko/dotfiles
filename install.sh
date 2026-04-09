#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SKIP_PACKAGES=false
ICON_THEME_NAME="Adwaita"
CONFIGS=("hypr" "kitty" "mako" "eww" "wofi" "zed")

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

# Configure fontconfig to use Inter as default font
echo -e "${YELLOW}Configuring Inter as default system font...${NC}"
FONTCONFIG_DIR="$HOME/.config/fontconfig"
mkdir -p "$FONTCONFIG_DIR"

cat > "$FONTCONFIG_DIR/fonts.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <!-- Set Inter as default sans-serif font -->
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Inter</family>
        </prefer>
    </alias>

    <!-- Enable font antialias and hinting for better rendering -->
    <match target="font">
        <edit name="antialias" mode="assign">
            <bool>true</bool>
        </edit>
        <edit name="hinting" mode="assign">
            <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
        </edit>
        <edit name="rgba" mode="assign">
            <const>rgb</const>
        </edit>
    </match>
</fontconfig>
EOF

echo -e "${GREEN}✓ Inter configured as default system font${NC}"
echo ""

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

# Create zen symlink (non-standard path: maps repo/zen -> Zen profile chrome dir)
ZEN_SOURCE="$REPO_DIR/zen"
ZEN_TARGET="/home/calirko/.zen/7310cqpp.Default (release)/chrome"

echo -e "${YELLOW}→ Linking zen chrome...${NC}"
if [ ! -d "$ZEN_SOURCE" ]; then
    echo -e "${YELLOW}⊘ Skipping zen (not found in repo)${NC}"
elif [ -L "$ZEN_TARGET" ]; then
    if [ "$(readlink "$ZEN_TARGET")" = "$ZEN_SOURCE" ]; then
        echo -e "${GREEN}✓ zen already linked${NC}"
    else
        echo -e "${RED}✗ zen symlink points elsewhere${NC}"
        echo "  Points to: $(readlink "$ZEN_TARGET")"
        echo "  Should point to: $ZEN_SOURCE"
    fi
elif [ -d "$ZEN_TARGET" ] || [ -e "$ZEN_TARGET" ]; then
    backup="$ZEN_TARGET.backup.$(date +%s)"
    echo -e "${YELLOW}→ Backing up existing zen chrome dir to $backup${NC}"
    mv "$ZEN_TARGET" "$backup"
    ln -s "$ZEN_SOURCE" "$ZEN_TARGET"
    echo -e "${GREEN}✓ Linked zen${NC}"
else
    mkdir -p "$(dirname "$ZEN_TARGET")"
    ln -s "$ZEN_SOURCE" "$ZEN_TARGET"
    echo -e "${GREEN}✓ Linked zen${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Your config files are now managed by the dotfiles repo."
echo "To update: git pull && source ~/.bashrc (or reload your shell)"
