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

The file is host-aware: it branches on `/etc/hostname` to apply machine-specific monitor layouts and workspace rules. Shared config (keybinds, animations, window rules, env vars, autostart) lives after the hostname block.

**Machines:**
- `raccoon` — triple monitor desktop (DP-1 primary, HDMI-A-1 secondary, laptop panel)
- `shark` — single HDMI monitor desktop

### Bar (`configs/eww/`)
The bar is built with **eww** (Elkowar's Wacky Widgets). It's a 36px vertical bar pinned to the left edge.

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

All visual configs follow the **grayscale-only** design system documented in `THEME.md`. The key rules:

- **Zero color.** Every value is `R=G=B` — no blue tints, no warm tones, no accent colors.
- **16-step gray ladder:** `g-000` (#000000) through `g-999` (#f5f5f5). Always use the nearest step; don't invent intermediates.
- **Surface stacking:** surfaces get lighter as they nest deeper (desktop → app shell → sidebar → panel → elevated panel).
- **Hover = one step up; active = two steps up** on the ladder.
- **Borders:** 1px only, using `rgba(255,255,255,0.06/0.10/0.16)` — never solid color borders on dark surfaces.
- **Fonts:** Geist (sans) for UI, Geist Mono for terminal/bar/timestamps.
- **Radii:** 4px (r-sm), 6px (r-md), 10px (r-lg max). Hyprland window rounding is 6px.
- **No shadows** on windows (`drop_shadow = false`). Shadows only on truly floating layers (launcher, notifications).

When editing any config file's colors, cross-reference `THEME.md` section 14 ("Quick Cross-App Mapping") for the canonical per-app values.
