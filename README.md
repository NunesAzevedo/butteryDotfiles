# Buttery Dotfiles 🧈

My personal dotfiles for Arch Linux with Hyprland, Fedora with KDE and Windows 11, in multiboot., managed with **GNU Stow**.

## 📦 Contents

This repository contains configurations for:

* **Window Manager:** Hyprland (including Waybar, nwg-bar, nwg-look)
* **Terminal:** Kitty and Konsole
* **Shell:** Zsh (with Oh My Zsh and Oh My Posh)
* **Editor:** Neovim (NvChad/Custom)
* **Tools:** Tmux, Git, Yay, Btop, Cava, Ranger, Lazygit
* **Design:** GTK Themes, Icons, GIMP (PhotoGIMP setup)

## 🚀 Prerequisites

Ensure you have `git` and `stow` installed:

```bash
sudo pacman -S git stow

```

## 🛠️ Installation

1. **Clone the repository** to your Home directory:

```bash
git clone https://github.com/NunesAzevedo/butteryDotfiles.git ~/butteryDotfiles
cd ~/butteryDotfiles

```

2. **Apply configurations (Stow)**
For most packages, simply use Stow. This will automatically create symbolic links in `~/.config/` or `~/`.

```bash
# Example: install everything (except special folders like fonts)
stow .

# Or install package by package (recommended for testing)
stow zsh
stow nvim
stow kitty
stow hypr

```

---

## ⚠️ Special Configuration: Fonts

Due to directory structure conflicts caused by **PhotoGIMP** (which creates a nested `.local` folder), fonts **must not** be installed via Stow.

**Install fonts manually using the following commands:**

```bash
# 1. Ensure the target directory exists and is clean
rm -rf ~/.local/share/fonts
mkdir -p ~/.local/share/fonts

# 2. Create the direct symbolic link
ln -s ~/butteryDotfiles/fonts/.local/share/fonts ~/.local/share/fonts

# 3. Update the font cache
fc-cache -fv

```

---

## 🎨 GIMP (PhotoGIMP)

GIMP configurations have been cleaned to avoid "noise" from temporary files (`sessionrc`, `tool-options`, etc.). The repository tracks only essential settings, shortcuts, and preferences.

When launching GIMP for the first time, it will automatically recreate the necessary cache folders.

## 🔄 Updates

To make local changes and save them to the repository:

```bash
cd ~/butteryDotfiles
git add .
git commit -m "update: description of changes"
git push

```


