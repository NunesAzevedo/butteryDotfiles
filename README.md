# Buttery Dotfiles 🧈

> My personal, modular configuration files for **Arch Linux** and **Fedora Workstation**.
> Automates the setup of a fully functional environment, adapting intelligently to the underlying distribution.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00A4CC?style=for-the-badge&logo=hyprland&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![KDE](https://img.shields.io/badge/KDE_Plasma-1D99F3?style=for-the-badge&logo=kde&logoColor=white)
![GNU Stow](https://img.shields.io/badge/GNU_Stow-D02020?style=for-the-badge&logo=gnu&logoColor=white)

## ✨ Features

- 🔄 **Multi-Distro Support** - Single codebase for Arch and Fedora
- ⚡ **Fast Installation** - Two-phase batch strategy (~20 min)
- 🔗 **Symlink Management** - GNU Stow for clean dotfile linking
- 📝 **Detailed Logging** - Timestamped logs with error tracking
- 🐳 **Docker Testing** - Test scripts safely before real installation
- 🎨 **Complete Environment** - Shell, terminal, editor, and DE configs

## 📦 What's Inside?

This repository manages configurations for:

| Category | Tools |
|----------|-------|
| **Desktop Environment** | Hyprland (Arch), KDE Plasma (Fedora/Arch) |
| **Shell** | Zsh + Oh My Zsh + Oh My Posh + Plugins |
| **Terminal** | Kitty |
| **Editor** | Neovim (NvChad base) |
| **Tools** | Tmux, Git, Btop, Cava, Lazygit, Ranger |
| **System (Arch)** | Pacman, Makepkg, Yay |
| **System (Fedora)** | DNF5, COPR, Flatpak |
| **Shared** | Keyd (key remapping), Fonts |

## 🚀 Installation (One-Command Setup)

The installation process is orchestrated by a master script that detects your distribution and applies the correct strategies.

### Prerequisites

| Requirement | Details |
|-------------|--------|
| **OS** | Fresh installation of Arch Linux or Fedora |
| **Git** | `sudo pacman -S git` or `sudo dnf install git` |
| **Internet** | Active connection for downloading packages |
| **User** | Run as normal user (not root) |

### Quick Start

```bash
git clone https://github.com/NunesAzevedo/butteryDotfiles.git ~/butteryDotfiles
cd ~/butteryDotfiles
./install.sh
```

> ⚠️ **Important:** Do not run `install.sh` as root. The script will request sudo permissions when needed.

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

Uses a **two-phase installation strategy** for speed and reliability:
1. **Phase 1:** Batch install all packages at once (fast)
2. **Phase 2:** Verify and retry any missing packages individually

* **Arch:** Bootstraps **Yay**, installs Native & AUR packages.
* **Fedora:** Configures **COPR**, installs Native, COPR & Flatpak packages.
* **Both:** Sets up Zsh, Oh My Zsh, Oh My Posh, and Zsh plugins.

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
├── docker/                     # Docker Test Environment
│   ├── Dockerfile.arch         # Arch Linux test image
│   ├── Dockerfile.fedora       # Fedora test image
│   └── start_test.sh           # Test runner script
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
├── assets/                     # Fonts and other assets
├── hypr/                       # User Configs (.config/hypr)
├── nvim/                       # User Configs (.config/nvim)
├── zsh/                        # Zsh configuration
└── ...                         # Other app configs (stow packages)

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
git commit -m "chore: update package lists"
git push
```



### Updating Symlinks

If you add new configuration folders (e.g., adding a `waybar` folder), simply run the installer again or the specific submodule:

```bash
./scripts/install_dotfiles.sh

```

---

## 🧪 Testing (Docker)

The repository includes Docker configurations to safely test installation scripts without affecting your real system.

### Quick Start

```bash
# Test Arch Linux installation
./docker/start_test.sh arch

# Test Fedora installation
./docker/start_test.sh fedora

# Force a clean rebuild (no cache)
./docker/start_test.sh arch clean
./docker/start_test.sh fedora clean
```

The script will:
1. Build a Docker image with a pre-configured test user (`tester`)
2. Mount the repository inside the container
3. Drop you into an interactive shell ready to run `./install.sh`

### Inside the Container

```bash
# Run the full installation
./install.sh

# Or test individual scripts
./scripts/install_packages.sh
./scripts/install_dotfiles.sh
```

### Expected Results

| Distro | Approx. Time | Expected Errors |
|--------|--------------|-----------------|
| Arch   | ~20 min      | `vconsole.conf` not found (no real console), some Flatpaks may fail |
| Fedora | ~20 min      | ~200+ packages fail (systemd, NetworkManager, hardware drivers - no real hardware in Docker) |

> **Note:** These errors are expected in Docker and do not indicate problems with the scripts. On a real system, all packages install correctly.

---

## 📝 Installation Logs

Every installation generates a detailed log file in the repository root:

```
.install_arch_2026-01-02_08-40-59.log
.install_fedora_2026-01-02_08-41-00.log
```

### Log Features

- **Timestamped filename** includes distro and date/time
- **Complete output** of all installation steps
- **Error tracking** - errors are collected and shown in a summary at the end
- **Execution time** displayed at completion

### Log Structure

```
====================================================================
 START: Fri Jan  2 08:00:00 -03 2026
 HOST: arch
====================================================================

 STEP 1: SYSTEM CONFIGURATION (Root/Sudo)
 ...

 STEP 2: PACKAGES & SHELL SETUP
 ...

 STEP 3: DOTFILES LINKING (Stow)
 ...

====================================================================
 INSTALLATION SUMMARY
====================================================================
✅ SUCCESS! No errors reported.
⏱️  Total execution time: 19m 51s
```

### Analyzing Logs

```bash
# View errors only
grep "ERROR\|FAIL" .install_arch_*.log

# Count failed packages
grep -c "ERROR: Failed to install package" .install_fedora_*.log

# Check if oh-my-posh installed
grep "oh-my-posh" .install_*.log
```

> **Tip:** Log files are hidden (start with `.`) to keep the repo clean. Use `ls -la` to see them.

---

## 📄 License

This project is for personal use. Feel free to fork and adapt to your needs.

---

<p align="center">
  Made with 🧈 by <a href="https://github.com/NunesAzevedo">NunesAzevedo</a>
</p>