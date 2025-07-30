# OneClick for Arch – Enhanced Standalone Update Manager

![License](https://img.shields.io/badge/License-GPL--3.0-blue)

**OneClick for Arch** is a zero-fluff shell script that transforms system maintenance into a painless experience. Currently supporting **Arch Linux** (both pacman and AUR helpers), with **Debian and Fedora support coming later**.

## What It Does

- **Auto-detects your system** and configures itself accordingly
- **Installs missing dependencies** automatically (`jq`, `pacman-contrib`, `reflector`)
- **Enables Pacman's game-style progress bar** (`ILoveCandy`) for visual feedback
- **Provides one-click updates** for full system, essential packages, or security-only
- **Supports AUR updates** via your preferred helper (default: `yay`)
- **Handles Flatpak updates** when enabled
- **Creates a global `oc` alias** across all your shells (bash, zsh, fish, dash)
- **Logs update history** for tracking and troubleshooting
- **Outputs JSON data** for Waybar integration
- **Offers interactive menu** for keyboard-driven system management
- **Provides terminal-launch reminders** for pending updates

## ⚙️ Key Features

**System Integration**
- Detects OS & package manager automatically
- Configures shell aliases across bash, zsh, fish, and dash
- Refreshes shell configurations automatically

**Smart Updates**
- Full system updates
- Essential packages only
- Security-focused updates
- AUR package management
- Flatpak application updates

**User Experience**
- Interactive, keyboard-driven menu
- Pacman's playful progress animations
- Optional terminal-launch update notifications
- Waybar status bar integration

**Configuration & Logging**
- Stores preferences in `~/.config/oneclick-arch/config.json`
- Maintains update history and logs
- Configurable update intervals and behaviors

## 🚀 Installation

```
curl -fsSL https://raw.githubusercontent.com/No1really/OneClick-For-Linux/main/OneClick-Arch-Standalone.sh | bash
```

*or*

```
wget -qO- https://raw.githubusercontent.com/No1really/OneClick-For-Linux/main/OneClick-Arch-Standalone.sh | bash
```

*or clone & run locally:*

```
git clone https://github.com/No1really/OneClick-For-Linux.git
cd OneClick-For-Linux
bash OneClick-Arch-Standalone.sh --init
```

## 🛡 License

Released under **GPL-3.0-only**. See `LICENSE` for details.

---



**Made with 🖤 by [Kō](https://github.com/No1really)**  

*OneClick for Arch* • *Minimal* • *Efficient* • *Perfect*

**Because even perfectionists deserve one click.**

---

**Connect:**  
[GitHub](https://github.com/No1really) • [Issues](https://github.com/No1really/OneClick-For-Linux/issues) • [Contribute](https://github.com/No1really/OneClick-For-Linux/pulls)
