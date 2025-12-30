# Buttery Dotfiles 🧈

> My personal, modular configuration files for **Arch Linux** and **Fedora Workstation**.
> Automates the setup of a fully functional environment, adapting intelligently to the underlying distribution.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00A4CC?style=for-the-badge&logo=hyprland&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![GNU Stow](https://img.shields.io/badge/GNU_Stow-D02020?style=for-the-badge&logo=gnu&logoColor=white)

## 📦 What's Inside?

This repository manages configurations for:
* **Window Managers/DE:** Hyprland (Arch) & KDE Plasma (Fedora/Arch)
* **Shell:** Zsh + Oh My Zsh + Oh My Posh
* **Terminal:** Kitty
* **Editor:** Neovim (NvChad base)
* **Tools:** Tmux, Git, Btop, Cava, Lazygit
* **System Internals:**
    * **Arch:** Pacman, Makepkg, Yay
    * **Fedora:** DNF5, COPR
    * **Shared:** Keyd (Remaps), Fonts

## 🚀 Installation (One-Command Setup)

The installation process is orchestrated by a master script that detects your distribution and applies the correct strategies.

### Prerequisites
* A fresh installation of **Arch Linux** or **Fedora**.
* `git` installed (`sudo pacman -S git` or `sudo dnf install git`).
* An active internet connection.

### Quick Start
Run the following command in your terminal:

```bash
git clone [https://github.com/NunesAzevedo/butteryDotfiles.git](https://github.com/NunesAzevedo/butteryDotfiles.git) ~/butteryDotfiles
cd ~/butteryDotfiles
./install.sh

```

---

## 🛠️ Under the Hood

The setup follows a **Facade Pattern**. The root `install.sh` acts as the orchestrator, detecting the OS and delegating tasks to modular scripts in `scripts/` and `os/`.

### 1. System Configuration (Root)

**Script:** `os/$DISTRO/system/install_system.sh`

Depending on the detected distro, it applies specific optimizations:

* **Arch Linux:**
* Optimizes `pacman.conf` (Parallel downloads, colors).
* Configures `makepkg.conf` (Multicore compilation).


* **Fedora:**
* Optimizes `dnf.conf` (Max parallel downloads, fastest mirror).
* Updates `grub` defaults (Boot timeout, hidden menu).


* **Common (`os/common`):**
* Installs and configures **Keyd** (System-wide keyboard remapping).



### 2. Package Installation

**Script:** `scripts/install_packages.sh`

* **Arch:** Bootstraps **Yay**, installs Native & AUR packages.
* **Fedora:** Configures **COPR**, installs Native, COPR & Flatpak packages.
* **Shell:** Sets up Zsh, Oh My Zsh, and Oh My Posh for both.

### 3. Dotfiles Linking (Stow)

**Script:** `scripts/install_dotfiles.sh`

* Uses **GNU Stow** to symlink configurations from this repo to `~/.config/`.
* Automatically installs fonts from `assets/fonts`.
* Ignores system infrastructure folders (`os/`, `scripts/`) to keep `$HOME` clean.

---

## 📂 Structure

The repository is organized to separate logic (scripts) from data (configs).

```text
butteryDotfiles/
├── install.sh                  # Master Orchestrator (Entry Point)
├── scripts/                    # Automation Logic
│   ├── install_packages.sh     # Package Manager Wrapper
│   ├── install_dotfiles.sh     # Stow & Assets Linker
│   ├── backup_packages.sh      # Backup Tool
│   └── lib/utils.sh            # Shared Library (Colors, Helpers)
├── os/                         # OS-Specific Data
│   ├── arch/
│   │   ├── system/             # Arch Root Configs
│   │   ├── pkglist_native.txt  # Arch Packages
│   │   └── pkglist_aur.txt     # AUR Packages
│   ├── fedora/
│   │   ├── system/             # Fedora Root Configs
│   │   ├── pkglist_dnf.txt     # DNF Packages
│   │   └── pkglist_copr.txt    # COPR Packages
│   └── common/                 # Shared Root Configs (e.g., Keyd)
├── hypr/                       # User Configs (.config/hypr)
├── nvim/                       # User Configs (.config/nvim)
└── ...

```

---

## 🔄 Maintenance

### Keeping the repo updated

When you install new programs, use the included backup script. It intelligently detects your distro and updates the correct package lists.

1. **Backup Package Lists:**
```bash
./scripts/backup_packages.sh

```


2. **Commit Changes:**
```bash
git add .
git commit -m "chore: update package lists for $(lsb_release -si)"
git push

```



### Updating Symlinks

If you add new configuration folders (e.g., adding a `waybar` folder), simply run the installer again or the specific submodule:

```bash
./scripts/install_dotfiles.sh

```

---

## 🧪 Testing (Docker)

You can verify the installation scripts safely inside a Docker container.

**Arch Linux Test:**

```bash
# 1. Start Container
docker run -it --rm --privileged --name arch_test archlinux:base-devel bash

# 2. Setup User & Sudo (simulate real env)
pacman -Sy --noconfirm git sudo
useradd -m -G wheel -s /bin/bash tester
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopasswd
su - tester

# 3. Clone & Run
git clone [https://github.com/NunesAzevedo/butteryDotfiles.git](https://github.com/NunesAzevedo/butteryDotfiles.git) ~/butteryDotfiles
cd ~/butteryDotfiles
./install.sh

```


