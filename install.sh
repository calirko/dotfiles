#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SKIP_PACKAGES=true
ICON_THEME_NAME="WhiteSur-grey-dark"
CONFIGS=("zed" "btop" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "eww" "wofi" "fastfetch" "fontconfig")

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

# Zen Browser userChrome.css
ZEN_PROFILES="$HOME/.config/zen/profiles.ini"
ZEN_SOURCE="$REPO_DIR/zen/userChrome.css"

if [ ! -f "$ZEN_SOURCE" ]; then
    echo -e "${YELLOW}⊘ zen/userChrome.css not found in repo, skipping${NC}"
elif [ ! -f "$ZEN_PROFILES" ]; then
    echo -e "${YELLOW}⊘ Zen profiles.ini not found, skipping${NC}"
else
    ZEN_PROFILE_PATH=$(awk -F= '
        /^\[Profile/ { in_profile=1; path=""; is_default=0 }
        in_profile && /^Path=/ { path=$2 }
        in_profile && /^Default=1/ { is_default=1 }
        in_profile && /^$/ {
            if (is_default && path) { print path; found=1; exit }
        }
        END { if (!found && is_default && path) print path }
    ' "$ZEN_PROFILES" | tr -d '\r')

    if [ -z "$ZEN_PROFILE_PATH" ]; then
        echo -e "${RED}✗ Could not find default Zen profile${NC}"
    else
        ZEN_CHROME_DIR="$HOME/.config/zen/$ZEN_PROFILE_PATH/chrome"
        ZEN_TARGET="$ZEN_CHROME_DIR/userChrome.css"

        mkdir -p "$ZEN_CHROME_DIR"

        if [ -L "$ZEN_TARGET" ] && [ "$(readlink "$ZEN_TARGET")" = "$ZEN_SOURCE" ]; then
            echo -e "${GREEN}✓ Zen userChrome.css already linked${NC}"
        elif [ -e "$ZEN_TARGET" ]; then
            backup="$ZEN_TARGET.backup.$(date +%s)"
            echo -e "${YELLOW}→ Backing up existing Zen userChrome.css to $backup${NC}"
            mv "$ZEN_TARGET" "$backup"
            ln -s "$ZEN_SOURCE" "$ZEN_TARGET"
            echo -e "${GREEN}✓ Linked Zen userChrome.css${NC}"
        else
            ln -s "$ZEN_SOURCE" "$ZEN_TARGET"
            echo -e "${GREEN}✓ Linked Zen userChrome.css${NC}"
        fi
    fi
fi

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
