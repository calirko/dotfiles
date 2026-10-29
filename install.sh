#!/bin/bash

# Dotfiles installer - creates symlinks from repo to ~/.config/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SKIP_PACKAGES=false
ICON_THEME_NAME="WhiteSur-grey-dark"
CONFIGS=("zed" "btop" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "eww" "wofi" "fastfetch" "fontconfig" "easyeffects" "zsh")

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
    # packages woof.json lists, so bootstrap it directly via pacman so a
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

# zen-browser: userChrome.css must live inside the active profile's chrome/
# dir, not at ~/.config/zen itself -- that root is the whole browser profile
# (cookies, logins, history), so symlinking over it like the CONFIGS loop
# above would destroy it. Only touch the one file, inside whichever profile
# the browser actually launches by default.
ZEN_CONFIG_DIR="$CONFIG_DIR/zen"
ZEN_SOURCE="$REPO_DIR/configs/zen/userChrome.css"
if [ -f "$ZEN_SOURCE" ] && [ -d "$ZEN_CONFIG_DIR" ]; then
    ZEN_PROFILE=$(grep -m1 '^Default=' "$ZEN_CONFIG_DIR/installs.ini" 2>/dev/null | cut -d= -f2-)
    if [ -z "$ZEN_PROFILE" ]; then
        ZEN_PROFILE=$(awk -F= '/^Path=/{print $2; exit}' "$ZEN_CONFIG_DIR/profiles.ini" 2>/dev/null)
    fi

    if [ -n "$ZEN_PROFILE" ] && [ -d "$ZEN_CONFIG_DIR/$ZEN_PROFILE" ]; then
        mkdir -p "$ZEN_CONFIG_DIR/$ZEN_PROFILE/chrome"
        ZEN_TARGET="$ZEN_CONFIG_DIR/$ZEN_PROFILE/chrome/userChrome.css"
        if [ -L "$ZEN_TARGET" ] && [ "$(readlink "$ZEN_TARGET")" = "$ZEN_SOURCE" ]; then
            echo -e "${GREEN}✓ zen userChrome.css already linked${NC}"
        else
            rm -f "$ZEN_TARGET"
            ln -s "$ZEN_SOURCE" "$ZEN_TARGET"
            echo -e "${GREEN}✓ Linked zen userChrome.css${NC}"
        fi
    else
        echo -e "${YELLOW}⊘ Could not determine zen-browser's default profile, skipping userChrome.css${NC}"
    fi
else
    echo -e "${YELLOW}⊘ zen-browser has no profile yet (launch it once first), skipping userChrome.css${NC}"
fi

# Switch default shell to zsh (the .zprofile autostart block below is only
# read on login by zsh -- bash never sources .zprofile).
echo ""
ZSH_PATH="$(command -v zsh || true)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ -z "$ZSH_PATH" ]; then
    echo -e "${YELLOW}⊘ zsh not installed, skipping default shell switch${NC}"
elif [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo -e "${GREEN}✓ Default shell already zsh${NC}"
else
    echo -e "${YELLOW}Switching default shell to zsh...${NC}"
    if chsh -s "$ZSH_PATH"; then
        echo -e "${GREEN}✓ Default shell set to zsh (takes effect next login)${NC}"
    else
        echo -e "${YELLOW}⊘ Failed to switch shell, run 'chsh -s $ZSH_PATH' manually${NC}"
    fi
fi

# raccoon: lid switch handling (laptop-only, requires sudo for logind drop-in)
# Lid close/open itself is handled natively inside hyprland.lua via switch
# bindings. This just stops systemd-logind from also acting on the lid
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
        echo -e "${YELLOW}⊘ sudo not available, copy configs/hypr/logind-lid.conf to /etc/systemd/logind.conf.d/raccoon-lid.conf manually${NC}"
    fi
fi

# raccoon: power-mode tile in the quick menu (eww/scripts/power-mode.sh).
# A sudoers rule for the three `auto-cpufreq --force=…` commands, and a boot
# unit that drops any forced mode so every boot starts on Auto.
if [[ "$(uname -n)" == "raccoon" ]] && command -v auto-cpufreq >/dev/null 2>&1; then
    echo ""
    echo -e "${YELLOW}raccoon: installing power-mode sudoers rule and boot reset...${NC}"

    if command -v sudo >/dev/null 2>&1; then
        tmp=$(mktemp)
        sed "s/^USERNAME /$USER /" "$REPO_DIR/configs/hypr/power-mode.sudoers" > "$tmp"
        if sudo visudo -cf "$tmp" >/dev/null; then
            sudo install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/power-mode
            echo -e "${GREEN}✓ sudoers rule installed${NC}"
        else
            echo -e "${YELLOW}⊘ sudoers rule failed visudo check, not installed${NC}"
        fi
        rm -f "$tmp"

        sudo install -m 0644 "$REPO_DIR/configs/hypr/power-mode-reset.service" /etc/systemd/system/power-mode-reset.service
        sudo systemctl daemon-reload
        sudo systemctl enable power-mode-reset.service >/dev/null 2>&1
        echo -e "${GREEN}✓ power mode resets to Auto on boot${NC}"
    else
        echo -e "${YELLOW}⊘ sudo not available, install configs/hypr/power-mode.sudoers and power-mode-reset.service manually${NC}"
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

# Put ~/.local/bin on PATH for zsh. .zprofile above only runs on the tty1
# login shell (which immediately execs into Hyprland), so every other zsh
# instance -- kitty, etc. -- is a non-login shell that reads .zshenv, not
# .zprofile. Without this, tools installed to ~/.local/bin (like the claude
# CLI) are invisible outside of bash.
ZSHENV="$HOME/.zshenv"
LOCAL_BIN_MARKER="# local-bin-path (dotfiles-managed)"
if ! grep -qF "$LOCAL_BIN_MARKER" "$ZSHENV" 2>/dev/null; then
    {
        echo "$LOCAL_BIN_MARKER"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$ZSHENV"
    echo -e "${GREEN}✓ Added ~/.local/bin to PATH in ~/.zshenv${NC}"
else
    echo -e "${GREEN}✓ ~/.zshenv already configured for PATH${NC}"
fi

# Shared zsh config (configs/zsh/zshrc, linked to ~/.config/zsh above) loads
# oh-my-zsh and nvm -- wire it up from ~/.zshrc.
#
# Any oh-my-zsh or nvm loading already in ~/.zshrc gets commented out first:
# the oh-my-zsh curl installer's template sources omz itself, and the old
# version of this block appended a second copy on top, so every shell loaded
# omz twice plus an eager nvm (~1.7s startup instead of ~0.1s).
ZSHRC="$HOME/.zshrc"
ZSHRC_MARKER="# dotfiles zshrc (dotfiles-managed)"
LEGACY_OMZ_MARKER="# oh-my-zsh (dotfiles-managed)"
SLOW_LOAD_RE='^[^#]*(oh-my-zsh\.sh|/nvm\.sh|NVM_DIR/bash_completion)'
touch "$ZSHRC"
if grep -qF "$LEGACY_OMZ_MARKER" "$ZSHRC" || grep -qE "$SLOW_LOAD_RE" "$ZSHRC"; then
    cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
    sed -i "/^${LEGACY_OMZ_MARKER}\$/,/^source \$ZSH\/oh-my-zsh.sh\$/d" "$ZSHRC"
    sed -i -E "s@${SLOW_LOAD_RE}.*\$@# & # disabled by dotfiles install.sh@" "$ZSHRC"
    echo -e "${GREEN}✓ Disabled duplicate oh-my-zsh/nvm loading in ~/.zshrc (backup saved)${NC}"
fi
if ! grep -qF "$ZSHRC_MARKER" "$ZSHRC"; then
    {
        echo "$ZSHRC_MARKER"
        echo '[ -r "$HOME/.config/zsh/zshrc" ] && source "$HOME/.config/zsh/zshrc"'
    } >> "$ZSHRC"
    echo -e "${GREEN}✓ Added shared zsh config to ~/.zshrc${NC}"
else
    echo -e "${GREEN}✓ ~/.zshrc already sources shared zsh config${NC}"
fi

# xdg-user-dirs: (re)generate ~/.config/user-dirs.dirs so GIO/Nautilus know
# which folders are Documents/Downloads/Pictures/etc. and give them themed
# icons instead of the generic folder icon. Missing this file is what causes
# bookmarked/home folders to show the wrong icons in Nautilus.
echo ""
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
    echo -e "${GREEN}✓ Updated ~/.config/user-dirs.dirs${NC}"
    if pgrep -x nautilus >/dev/null 2>&1; then
        killall nautilus
        echo -e "${GREEN}✓ Restarted Nautilus to pick up folder icons${NC}"
    fi
else
    echo -e "${YELLOW}⊘ xdg-user-dirs-update not found, skipping${NC}"
fi

echo -e "${GREEN}Done!${NC}"
