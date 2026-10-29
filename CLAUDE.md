# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Arch Linux + Hyprland dotfiles. The installer symlinks `configs/<name>/` → `~/.config/<name>/`, so edits in the repo take effect immediately on the live system.

## Key commands

```bash
# Install: symlink all configs and install packages from woof.json
bash install.sh

# Install without package installation
bash install.sh --skip-packages

# Remove symlinks (restores originals)
bash uninstall.sh

# Reload eww bar after changes
eww reload

# Restart eww bar from scratch
eww kill && eww daemon && ~/.config/hypr/scripts/bar.sh
```

## Architecture

### Hyprland config (`configs/hypr/hyprland.lua`)
The Hyprland config is written in **Lua** using the `hl` global API (from `hypr-lua` / hyprland's Lua bindings). The `.luarc.json` at the root configures the Lua LSP to recognize `hl` as a global and points stubs to `/usr/share/hypr/stubs`.

The file is host-aware: it branches on `/etc/hostname` to apply machine-specific monitor layouts. Shared config (keybinds, animations, window rules, env vars, autostart) lives after the hostname block.

**Workspaces** aren't pinned to monitors: each monitor keeps its own stack, ordered by id and shown as dots on the bar (bar's monitor only). `SUPER + Left/Right` switches monitors and `SUPER + Up/Down` cycles the focused monitor's stack (add `SHIFT` to take the window along, `ALT` + arrows moves focus between windows); Down past the last opens a new workspace at the bottom (`configs/hypr/scripts/workspace-cycle.sh`). Workspace switches slide vertically.

**Machines:**
- `raccoon` — triple monitor desktop (DP-1 primary, HDMI-A-1 secondary, laptop panel)
- `shark` — single HDMI monitor desktop

### Bar (`configs/eww/`)
The bar is built with **eww** (Elkowar's Wacky Widgets). It's a floating 48px glass rail on the left edge (8px margin), with the quick menu as a glass card beside it.

- `eww.yuck` — main widget definitions and bar window declaration
- `menu.yuck` — popup menu panel (toggled by `SUPER + /`)
- `osd.yuck` — on-screen display for volume/brightness/etc.
- `eww.scss` — all bar styles
- `scripts/` — shell scripts polled or listened to by eww widgets (workspace watcher, audio, network, brightness, weather, etc.)

The bar is spawned by `~/.config/hypr/scripts/bar.sh` on Hyprland start.

### Notification daemon: mako (`configs/mako/`)
### Launcher: wofi (`configs/wofi/`)
### Terminal: kitty (`configs/kitty/`)
### Lock screen: hyprlock + hypridle (`configs/hypr/hyprlock.conf`, `hypridle.conf`)
### Media Discord RPC: `configs/hypr/media-rpc` binary + `configs/hypr/config.json`

### Package management (`woof.json`)
Lists all packages installed via `yay`. The installer reads this with `jq` and runs `yay -S --noconfirm`.

## Theme system

Glass, grayscale. The tokens live at the top of `configs/eww/eww.scss`; wofi (`style.css`), mako (`config`, `#RRGGBBAA`) and hyprlock use the same values. Each glass layer needs a Hyprland `blur` + `ignore_alpha` layer rule. Note `configs/gtk-3.0/gtk.css` loads above wofi's own stylesheet, so wofi's search field is also styled there.

- **Glass panels:** bar, quick menu and OSD are translucent black (`rgba(…, 0.74–0.78)`) over Hyprland blur (`blur` + `ignore_alpha` layer rules). The wallpaper decides the tint; the UI itself adds no color.
- **White-alpha foreground:** text, icons and fills are white at fixed alphas (`$fg` .95, `$fg-2` .68, `$fg-3` .46; fills .08/.13/.19). Don't use dark grays for text on glass.
- **"On" = inverted:** active tiles and buttons turn near-white with dark text. They use the dark icon copies in `icons/dark/`.
- **Icons:** Phosphor SVGs baked white (`icons/set-color.sh "#ffffff"`), dimmed with CSS `opacity`. When adding an icon, also put a `#161616` copy in `icons/dark/`.
- **Spacing, not lines:** no dividers between groups.
- **Shapes:** rounded rectangles (6/8/12/16/20px). No full circles except the workspace and status dots. Hyprland window rounding is 16px (same as the rail), gaps 4/8.
- **Fonts:** Geist for UI, Geist Mono for numbers (clock, values).
