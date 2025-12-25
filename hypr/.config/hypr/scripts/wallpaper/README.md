# Hyprland Wallpaper Manager

A modular, centralized wallpaper management system using `swww`. 
Designed to be portable, state-persistent, and redundant-aware.

## Directory Structure & Architecture

This system uses a **Hub-and-Spoke** architecture:
* **Hub (`swww-config.sh`):** Centralizes all paths, variables, and the `swww` execution logic. It detects its own location to resolve paths dynamically.
* **Satellites (`change`, `load`, `reset`):** Lightweight scripts that source the Hub to perform specific actions.

```text
~/.config/hypr/
├── hyprland.conf
├── .last_wallpaper          # State file (Current wallpaper path)
└── Wallpaper/               # Image directory
    └── ...
└── scripts/
    └── wallpaper/
        ├── swww-config.sh   # The "Brain"
        ├── change...sh      # Rotates images
        ├── load...sh        # Restores state on boot
        └── reset...sh       # Resets index to 0

```


## Features

    Dynamic Pathing: Scripts calculate the root hypr directory relative to their own location. Moving the folder structure won't break the logic.

    Smart Rotation: changeWallpaper.sh uses natural sorting (sort -V) to handle numbered files correctly (e.g., img2 comes before img10).

    Redundancy Check: The rotation script checks the currently displayed wallpaper against the next target. If they match (common on boot), it automatically skips to the next image.

    State Persistence: load-wallpaper.sh restores the last used wallpaper after a reboot.

## Installation

Add the following to your hyprland.conf:
```Ini, TOML

# Initialize wallpaper daemon and restore previous state
exec-once = swww-daemon
exec-once = ~/.config/hypr/scripts/wallpaper/load-wallpaper.sh

# Keybinding to cycle wallpapers
bind = $mainMod, W, exec, ~/.config/hypr/scripts/wallpaper/changeWallpaper.sh

# Keybind to change for Default Wallpaper
bind = $mainMod SHIFT, W, exec, ~/.config/hypr/scripts/wallpaper/reset-wallpaper.sh

```




