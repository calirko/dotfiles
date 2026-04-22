# dotfiles

my setup for arch linux + hyprland

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/yourusername/dotfiles ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

The installer creates symlinks from your repo to `~/.config/`, so changes in the repo apply immediately to your system.

## Managing Your Configs

### After Making Changes

1. Edit config files normally (they're now in your repo)
2. Test the changes
3. Commit and push: `git add . && git commit -m "message" && git push`

### On Another Computer

1. Clone: `git clone <your-repo> ~/.dotfiles`
2. Run installer: `cd ~/.dotfiles && bash install.sh`
3. Pull updates anytime: `cd ~/.dotfiles && git pull`

## What's Included

- **hypr/** - Hyprland window manager config
- **kitty/** - Kitty terminal config
- **mako/** - Mako notification daemon config
- **eww/** - Eww status bar + top-right quick menu
- **wofi/** - Wofi app launcher config

Hyprland extras in this setup:

- `hyprlock` with a sharp-corner dark theme matching the rest of the UI
- `hypridle` auto-lock after 20 minutes of inactivity
- `Super + L` to lock immediately

## Updating Specific Systems

Edit files in the repo and they'll automatically sync to `~/.config/`. Reload apps as needed:

- Hyprland: `Super+Shift+R` or reload manually
- Kitty: Settings reload automatically on config change
- Others: Usually require app restart

## Uninstalling

To remove symlinks and restore your original config files:

```bash
cd ~/.dotfiles
bash uninstall.sh
```

The script will ask whether to restore backups (if they exist) for each config.

sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal pipewire pipewire-pulse wireplumber

#### Misc

foreground - #eaeaea
background - #141414
/usr/share/xdg-desktop-portal/hyprland-portals.conf

#### Bash Profile

```bash
#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec start-hyprland -- -c ~/.config/hypr/hosts/$HOSTNAME.conf
fi
```

#### Pallete

$bg-0:    #0e0e0e;   // deepest — titlebars, inactive borders
$bg-1: #141414; // main window background
$bg-2:    #1c1c1c;   // panels, sidebars
$bg-3: #252525; // hover states, selections
$bg-4: #2e2e2e; // active/focused elements

$border-inactive: #1a1a1a;
$border-active: #3a3a3a;

$text-dim:    #4a4a4a;   // disabled, placeholder
$text-muted: #6e6e6e; // secondary labels
$text-normal: #b0b0b0;   // body text
$text-bright: #d8d8d8; // headings, active items
