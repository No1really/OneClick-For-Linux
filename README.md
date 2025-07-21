# OneClick for Linux – GNOME Extension

**OneClick for Linux** is a GNOME Shell extension that makes updating your Linux system effortless.  
Currently optimized for **Arch Linux**, it provides a **top-bar updater icon** that monitors for available updates, notifies you, and lets you perform **one-click updates** with a **Pac-Man-themed progress bar**.

**Future releases will add support for Fedora, Debian, and other major distros.**

---

## ✨ Features

✅ **Background Update Checks**  
- Actively monitors available updates for Arch Linux  
- Detects Flatpak updates via `flatpak remote-ls --updates`  
- Displays notifications when updates are available  

✅ **Custom Update Modes**  
- **Security-only updates** (minimal risk)  
- **Essential updates** (core system & libraries)  
- **Optional updates** (apps, utilities)  
- **Full system update** (everything + Flatpaks)  

✅ **Reflector & Mirror Control (Arch)**  
- Run Reflector before updates  
- Configure mirror **protocol**, **sort order**, **country**, and **latest count**  

✅ **Package Manager Behavior Control**  
- Adjust **parallel downloads**  
- Enable/disable **colored output**  
- Enable/disable **space checking**  
- Toggle **verbose mode**  

✅ **Self-contained Installer**  
- Dynamically generates the GNOME extension (`metadata.json`, `extension.js`, schemas, icons)  
- Installs required dependencies if missing  

✅ **Fun Pac-Man Progress Bar**  
- Watch a Pac-Man animation while updates run in the terminal  

---

## 🛠 Current Requirements

- Arch Linux or an Arch-based distro  
- GNOME Shell **42–48**  
- `pacman` + `pacman-contrib` (for `checkupdates`)  
- `flatpak` (optional, for Flatpak support)  
- `reflector` (optional, for mirror updates)  
- `curl` or `wget` for installation  

---

## 🚀 Future Plans

- **Fedora support** (DNF update checks, mirror refresh)  
- **Debian/Ubuntu support** (`apt` integration with security/essential/optional categories)  
- Unified updater logic for multiple distros  

---

## 🔧 Available Options in Settings

### Update Modes
- **Security Updates** – Only critical security patches  
- **Essential Updates** – Core components & system libraries  
- **Optional Updates** – User apps, utilities  
- **Full Updates** – Everything including Flatpaks  

### Flatpak Support
- Toggle Flatpak update detection  

### Reflector & Mirrors (Arch-specific)
- Run Reflector before updates  
- Configure:
  - Mirror protocol (`https`, `http`)
  - Sorting (`rate`, `score`, `age`)
  - Latest mirrors count
  - Preferred country  

### Package Manager Configuration
- Parallel Downloads (e.g. `5`, `10`)  
- Colored Pacman Output toggle  
- Verbose Mode toggle  
- Space Checking toggle  

---

## 🚀 Installation (Arch Only for Now)

### Quick Install via `curl`
```bash
curl -fsSL https://raw.githubusercontent.com/No1really/OneClick-For-Linux/refs/heads/main/OneClick.sh | bash
```

### Quick Install via `wget`
```bash
wget -qO- https://raw.githubusercontent.com/No1really/OneClick-For-Linux/refs/heads/main/OneClick.sh | bash
```

### Manual Install via Git
```bash
git clone [https://github.com/<your-username>/oneclick-linux-updater.git](https://github.com/No1really/OneClick-For-Linux.git)
cd oneclick-linux-updater
bash oneclick_installer.sh
```

---

## ✅ Post-Install Steps

1. **Restart GNOME Shell**

   a. Shortcut (For X11):
   
   ```bash
   Alt + F2, then type: r
   ```

   b. Log back in if on Wayland.

3. **Enable the Extension**  
   Open **GNOME Extensions** → Toggle *OneClick for Linux*.  

4. **Configure Settings**  
   Open the extension’s settings dialog and adjust behavior as needed.  

---

## 🔄 How It Works

- A background loop runs:
  - `checkupdates` for Arch repo updates (Fedora/Debian support coming soon)  
  - `flatpak remote-ls --updates` for Flatpak updates  
- The **top-bar icon** reflects available updates  
- Clicking it shows update details and lets you:
  - Run **Security**, **Essential**, **Optional**, or **Full** updates  
- Updates execute in a **Kitty (or preferred) terminal** with a Pac-Man progress animation  

---

## 🖥️ Removal Process

To remove OneClick for Linux completely:
```bash
rm -rf ~/.local/share/gnome-shell/extensions/oneclick-linux@local
```

Then restart GNOME Shell:
```bash
Alt + F2, then type: r
```

If you also want to remove related GNOME settings:
```bash
gsettings reset-recursively org.gnome.shell.extensions.oneclick-linux || true
```

---

## 🏗 Roadmap

- ✅ Arch Linux support  
- ⏳ Fedora support (DNF integration)  
- ⏳ Debian/Ubuntu support (APT integration)  
- [ ] Configurable update check intervals  
- [ ] Notification snooze option  
- [ ] GUI for update history  

---

## 🤝 Contributing

Want to add Fedora or Debian support?  

```bash
git fork https://github.com/<your-username>/oneclick-linux-updater.git
git checkout -b feature/new-distro-support
# make your changes
git commit -m "Add Fedora/Debian support"
git push origin feature/new-distro-support
```

Then open a Pull Request.  

Bug reports & feature requests:  
[GitHub Issues](https://github.com/<your-username>/oneclick-linux-updater/issues)

---

---

## ❤️ Credits

- Built for Linux users who love **less typing, more clicking**  
- Currently Arch-focused but designed to scale to Fedora & Debian  
