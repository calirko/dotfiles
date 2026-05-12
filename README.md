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

To remove symlinks and restore your original config files:

```bash
cd ~/.dotfiles
bash uninstall.sh
```
