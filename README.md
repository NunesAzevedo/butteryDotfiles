

# Buttery Dotfiles 🧈

> My personal, modular configuration files for **Arch Linux (Hyprland)**.
> Automates the setup of a fully functional environment from a fresh install to a polished desktop.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00A4CC?style=for-the-badge&logo=hyprland&logoColor=white)
![GNU Stow](https://img.shields.io/badge/GNU_Stow-D02020?style=for-the-badge&logo=gnu&logoColor=white)

## 📦 What's Inside?

This repository manages configurations for:
* **Window Manager:** Hyprland (Waybar, nwg-bar, nwg-look)
* **Shell:** Zsh + Oh My Zsh + Oh My Posh
* **Terminal:** Kitty
* **Editor:** Neovim (NvChad base)
* **Tools:** Tmux, Git, Yay, Btop, Cava, Lazygit
* **System:** Pacman, Makepkg, GRUB, Keyd (root configs)

## 🚀 Installation (One-Command Setup)

The installation process is fully scripted and idempotent. It handles system packages, root configurations, and user dotfiles automatically.

### Prerequisites
* A fresh Arch Linux installation.
* `git` installed (`sudo pacman -S git`).
* An active internet connection.

### Quick Start
Run the following command in your terminal:

```bash
git clone https://github.com/NunesAzevedo/butteryDotfiles.git ~/butteryDotfiles
cd ~/butteryDotfiles
./install.sh

```
(Note: If you prefer SSH, clone using ```git@github.com:NunesAzevedo/butteryDotfiles.git```)

---

## 🛠️ Under the Hood

The setup is orchestrated by `install.sh`, which executes three distinct phases:

### 1. System Configuration (Root)

**Script:** `system/install_system.sh`

* Backs up and replaces system-wide configs in `/etc/`.
* Optimizes **Pacman** (Parallel downloads, colors, multilib).
* Optimizes **Makepkg** (Uses all CPU cores for compilation).
* Configures **GRUB** (Boot timeout and visuals).
* Sets up **Keyd** (Remaps CapsLock to Esc/Ctrl).

### 2. Package Installation

**Script:** `install_packages.sh`

* Installs base tools (`base-devel`, `stow`, `git`).
* Bootstraps **Yay** (AUR Helper) if missing.
* Installs official packages from `pkglist_native.txt`.
* Installs AUR packages from `pkglist_aur.txt`.
* Sets up Zsh plugins and Oh My Posh themes.

### 3. Dotfiles Linking (Stow)

**Script:** `install_dotfiles.sh`

* Uses **GNU Stow** to symlink configurations from this repo to `~/.config/` and `~/`.
* Automatically ignores system folders and scripts.
* Modular structure: `hypr/` maps to `~/.config/hypr/`, `zsh/` maps to `~/`, etc.

---

## 🧪 Testing (Docker)

You can verify the installation scripts safely inside a Docker container before running them on real hardware.

```bash
# 1. Create a clean Arch Linux container (Privileged is required for Pacman sandbox)
sudo docker run -it --rm --privileged --name arch_test archlinux:latest bash

# 2. Inside the container, setup the environment:
pacman -Sy --noconfirm git base-devel sudo
useradd -m -G wheel -s /bin/bash tester
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
su - tester

# 3. Clone and Run
git clone [https://github.com/NunesAzevedo/butteryDotfiles.git](https://github.com/NunesAzevedo/butteryDotfiles.git) ~/butteryDotfiles
cd ~/butteryDotfiles
./install.sh

```

---

## 🔄 Maintenance

### Keeping the repo updated

When you install new programs or change settings, keep the repository in sync:

1. **Backup Package Lists:**
```bash
./backup_packages.sh

```


2. **Commit Changes:**
```bash
git add .
git commit -m "feat: updated configs and package lists"
git push

```
Or use the alias ```updot``` in this dotfiles.



### Updating Symlinks

If you add new configuration folders, simply run:

```bash
./install_dotfiles.sh

```

---

## 📂 Structure

```text
butteryDotfiles/
├── install.sh             # Master orchestrator
├── install_packages.sh    # Package installer
├── install_dotfiles.sh    # Stow linker
├── system/                # Root configurations (/etc)
│   └── install_system.sh  # Root config installer
├── pkglist_native.txt     # Official packages list
├── pkglist_aur.txt        # AUR packages list
├── hypr/                  # Hyprland configs (.config/hypr)
├── nvim/                  # Neovim configs (.config/nvim)
└── ...

```

