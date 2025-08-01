#!/bin/bash

# OneClick for Arch - Enhanced Standalone Update Manager
# Version 1.0 - Complete system/shell detection with automatic alias refresh
# Author: No1Really
# License: GPL-3.0

set -e

# ===== CONFIGURATION =====
CONFIG_DIR="$HOME/.config/oneclick-arch"
CONFIG_FILE="$CONFIG_DIR/config.json"
LOG_FILE="$CONFIG_DIR/updates.log"
UPDATE_HISTORY="$CONFIG_DIR/update_history.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SYSTEM_TYPE=""
PACKAGE_MANAGER=""
SYSTEM_NAME=""
SHELL_TYPE=""
SHELL_CONFIG=""
SHELL_PROFILE=""
SHELL_FUNCTIONS_DIR=""
OH_MY_ZSH=false
MULTI_SHELL_SETUP=false
DETECTED_SHELLS=()

# Update tracking variables
SECURITY_UPDATES=0
ESSENTIAL_UPDATES=0
OPTIONAL_UPDATES=0
AUR_UPDATES=0
FLATPAK_UPDATES=0
PACKAGES_AVAILABLE=()

# ===== HELPER FUNCTIONS =====

# Check if OneClick is properly initialized
is_initialized() {
    [ -f "$CONFIG_FILE" ] && [ -d "$CONFIG_DIR" ]
}

# Silent system and shell detection (no prompts)
detect_system_silent() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYSTEM_NAME="$NAME"
        case "${ID,,}" in
            arch*|manjaro*|endeavour*|artix*|garuda*|archcraft*|arcolinux*)
                SYSTEM_TYPE="arch-based"
                PACKAGE_MANAGER="pacman"
                ;;
            ubuntu*|debian*|linuxmint*|pop*|elementary*|zorin*|deepin*)
                SYSTEM_TYPE="debian-based"
                PACKAGE_MANAGER="apt"
                ;;
            fedora*|rhel*|centos*|rocky*|almalinux*)
                SYSTEM_TYPE="rhel-based"
                PACKAGE_MANAGER="dnf"
                ;;
            opensuse*|sled*|sles*)
                SYSTEM_TYPE="suse-based"
                PACKAGE_MANAGER="zypper"
                ;;
            void*)
                SYSTEM_TYPE="void"
                PACKAGE_MANAGER="xbps"
                ;;
            *)
                SYSTEM_TYPE="unknown"
                PACKAGE_MANAGER="unknown"
                ;;
        esac
    elif [ -f /etc/arch-release ]; then
        SYSTEM_TYPE="arch-based"
        PACKAGE_MANAGER="pacman"
        SYSTEM_NAME="Arch Linux"
    else
        SYSTEM_TYPE="arch-based"  # Default assumption
        PACKAGE_MANAGER="pacman"
        SYSTEM_NAME="Arch Linux"
    fi

    # Set shell info without prompts
    SHELL_TYPE=$(basename "$SHELL")
    case "$SHELL_TYPE" in
        "bash")
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_PROFILE="$HOME/.bash_profile"
            ;;
        "zsh")
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_PROFILE="$HOME/.zprofile"
            ;;
        "fish")
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            SHELL_FUNCTIONS_DIR="$HOME/.config/fish/functions"
            ;;
        "dash")
            SHELL_CONFIG="$HOME/.profile"
            SHELL_PROFILE="$HOME/.profile"
            ;;
        *)
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_PROFILE="$HOME/.bash_profile"
            ;;
    esac
}

# ===== SYSTEM DETECTION =====

# Detect system type and package manager (interactive)
detect_system() {
    echo -e "${BLUE}🔍 Detecting system type...${NC}"
    
    # Initialize system variables
    SYSTEM_TYPE=""
    PACKAGE_MANAGER=""
    SYSTEM_NAME=""
    
    # Check for various Linux distributions
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYSTEM_NAME="$NAME"
        
        case "$ID" in
            "arch"|"manjaro"|"endeavouros"|"artix"|"garuda"|"archcraft"|"arcolinux")
                SYSTEM_TYPE="arch-based"
                PACKAGE_MANAGER="pacman"
                echo -e "${GREEN}✅ Detected: $SYSTEM_NAME (Arch-based)${NC}"
                ;;
            "ubuntu"|"debian"|"linuxmint"|"pop"|"elementary"|"zorin"|"deepin")
                SYSTEM_TYPE="debian-based"
                PACKAGE_MANAGER="apt"
                echo -e "${YELLOW}⚠️  Detected: $SYSTEM_NAME (Debian-based) - Limited compatibility${NC}"
                ;;
            "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"nobara")
                SYSTEM_TYPE="rhel-based"
                PACKAGE_MANAGER="dnf"
                echo -e "${YELLOW}⚠️  Detected: $SYSTEM_NAME (RHEL-based) - Limited compatibility${NC}"
                ;;
            "opensuse"|"sled"|"sles"|"opensuse-tumbleweed"|"opensuse-leap")
                SYSTEM_TYPE="suse-based"
                PACKAGE_MANAGER="zypper"
                echo -e "${YELLOW}⚠️  Detected: $SYSTEM_NAME (SUSE-based) - Limited compatibility${NC}"
                ;;
            "void")
                SYSTEM_TYPE="void"
                PACKAGE_MANAGER="xbps"
                echo -e "${YELLOW}⚠️  Detected: $SYSTEM_NAME (Void Linux) - Limited compatibility${NC}"
                ;;
            *)
                SYSTEM_TYPE="unknown"
                PACKAGE_MANAGER="unknown"
                echo -e "${RED}❌ Unknown system: $SYSTEM_NAME${NC}"
                ;;
        esac
    elif [ -f /etc/arch-release ]; then
        SYSTEM_TYPE="arch-based"
        PACKAGE_MANAGER="pacman"
        SYSTEM_NAME="Arch Linux"
        echo -e "${GREEN}✅ Detected: Arch Linux${NC}"
    else
        echo -e "${RED}❌ Could not detect system type${NC}"
        SYSTEM_TYPE="unknown"
        PACKAGE_MANAGER="unknown"
        SYSTEM_NAME="Unknown"
    fi
    
    # Warn if not Arch-based
    if [ "$SYSTEM_TYPE" != "arch-based" ]; then
        echo -e "${YELLOW}⚠️  Warning: This script is optimized for Arch Linux${NC}"
        echo -e "${YELLOW}   Some features may not work on $SYSTEM_NAME${NC}"
        read -p "Continue anyway? [y/N]: " continue_choice
        case $continue_choice in
            [Yy]*)
                echo -e "${BLUE}Continuing with limited functionality...${NC}"
                ;;
            *)
                echo -e "${RED}Exiting...${NC}"
                exit 1
                ;;
        esac
    fi
}

# ===== SHELL DETECTION =====

# Detect shell type and set appropriate config files (interactive)
detect_shell() {
    local SILENT_MODE=${1:-false}
    
    if [ "$SILENT_MODE" = "true" ]; then
        # Silent detection - no prompts
        SHELL_TYPE=$(basename "$SHELL")
        DETECTED_SHELLS=("$SHELL_TYPE")
        case "$SHELL_TYPE" in
            "bash")
                SHELL_CONFIG="$HOME/.bashrc"
                SHELL_PROFILE="$HOME/.bash_profile"
                ;;
            "zsh")
                SHELL_CONFIG="$HOME/.zshrc"
                SHELL_PROFILE="$HOME/.zprofile"
                ;;
            "fish")
                SHELL_CONFIG="$HOME/.config/fish/config.fish"
                SHELL_FUNCTIONS_DIR="$HOME/.config/fish/functions"
                ;;
            "dash")
                SHELL_CONFIG="$HOME/.profile"
                SHELL_PROFILE="$HOME/.profile"
                ;;
            *)
                SHELL_CONFIG="$HOME/.bashrc"
                SHELL_PROFILE="$HOME/.bash_profile"
                ;;
        esac
        return
    fi
    
    echo -e "${BLUE}🐚 Detecting shell type...${NC}"
    
    # Get current shell
    local CURRENT_SHELL=$(basename "$SHELL")
    DETECTED_SHELLS=()
    
    # Primary shell (currently running)
    SHELL_TYPE="$CURRENT_SHELL"
    
    echo -e "${GREEN}✅ Primary shell: $SHELL_TYPE${NC}"
    
    # Detect all available shells and their config files
    case "$SHELL_TYPE" in
        "bash")
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_PROFILE="$HOME/.bash_profile"
            DETECTED_SHELLS+=("bash")
            echo -e "   Config file: $SHELL_CONFIG"
            ;;
        "zsh")
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_PROFILE="$HOME/.zprofile"
            DETECTED_SHELLS+=("zsh")
            echo -e "   Config file: $SHELL_CONFIG"
            
            # Check for Oh My Zsh
            if [ -d "$HOME/.oh-my-zsh" ]; then
                echo -e "   ${CYAN}📦 Oh My Zsh detected${NC}"
                OH_MY_ZSH=true
            fi
            ;;
        "fish")
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            SHELL_FUNCTIONS_DIR="$HOME/.config/fish/functions"
            DETECTED_SHELLS+=("fish")
            echo -e "   Config file: $SHELL_CONFIG"
            echo -e "   Functions dir: $SHELL_FUNCTIONS_DIR"
            
            # Create fish directories if they don't exist
            mkdir -p "$HOME/.config/fish/functions"
            ;;
        "dash")
            SHELL_CONFIG="$HOME/.profile"
            SHELL_PROFILE="$HOME/.profile"
            DETECTED_SHELLS+=("dash")
            echo -e "   Config file: $SHELL_CONFIG"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown shell: $SHELL_TYPE${NC}"
            echo -e "${YELLOW}   Falling back to bash compatibility${NC}"
            SHELL_TYPE="bash"
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_PROFILE="$HOME/.bash_profile"
            DETECTED_SHELLS+=("bash")
            ;;
    esac
    
    # Check for additional shells installed
    echo -e "${BLUE}🔍 Checking for other installed shells...${NC}"
    
    local OTHER_SHELLS=()
    
    # Check common shell locations
    for shell_path in /bin/bash /usr/bin/bash /bin/zsh /usr/bin/zsh /usr/bin/fish /bin/fish /bin/dash /usr/bin/dash; do
        if [ -x "$shell_path" ]; then
            local shell_name=$(basename "$shell_path")
            if [[ ! " ${DETECTED_SHELLS[@]} " =~ " ${shell_name} " ]]; then
                OTHER_SHELLS+=("$shell_name")
            fi
        fi
    done
    
    if [ ${#OTHER_SHELLS[@]} -gt 0 ]; then
        echo -e "   ${CYAN}Additional shells found: ${OTHER_SHELLS[*]}${NC}"
        
        read -p "Create aliases for all detected shells? [Y/n]: " multi_shell
        case $multi_shell in
            [Nn]*)
                MULTI_SHELL_SETUP=false
                ;;
            *)
                MULTI_SHELL_SETUP=true
                DETECTED_SHELLS+=("${OTHER_SHELLS[@]}")
                ;;
        esac
    fi
    
    echo -e "${GREEN}✅ Shell detection complete${NC}"
}

# ===== INITIALIZATION =====

# Set default editor if not defined
setup_editor() {
    if [ -z "$EDITOR" ]; then
        if command -v nano >/dev/null 2>&1; then
            export EDITOR="nano"
        elif command -v vim >/dev/null 2>&1; then
            export EDITOR="vim"
        elif command -v vi >/dev/null 2>&1; then
            export EDITOR="vi"
        else
            export EDITOR="nano"
        fi
    fi
}

# Create config directory with proper permissions
setup_directories() {
    echo -e "${BLUE}🔧 Setting up OneClick directories...${NC}"
    
    # Create directory and set permissions
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    
    # Ensure user owns the directory
    chown "$USER:$USER" "$CONFIG_DIR" 2>/dev/null || true
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    echo -e "${GREEN}✅ Directories created successfully${NC}"
}

# System-aware dependency installation
install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies for $SYSTEM_NAME...${NC}"
    
    local missing_deps=()
    
    case "$SYSTEM_TYPE" in
        "arch-based")
            # Check for Arch-specific dependencies
            if ! command -v jq >/dev/null 2>&1; then
                missing_deps+=("jq")
            fi
            if ! command -v checkupdates >/dev/null 2>&1; then
                missing_deps+=("pacman-contrib")
            fi
            if ! command -v reflector >/dev/null 2>&1; then
                missing_deps+=("reflector")
            fi
            
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Installing: ${missing_deps[*]}${NC}"
                sudo pacman -S --needed --noconfirm "${missing_deps[@]}"
            fi
            ;;
        "debian-based")
            if ! command -v jq >/dev/null 2>&1; then
                missing_deps+=("jq")
            fi
            
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Installing: ${missing_deps[*]}${NC}"
                sudo apt update && sudo apt install -y "${missing_deps[@]}"
            fi
            
            echo -e "${YELLOW}⚠️  Note: Some features limited on Debian-based systems${NC}"
            ;;
        "rhel-based")
            if ! command -v jq >/dev/null 2>&1; then
                missing_deps+=("jq")
            fi
            
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Installing: ${missing_deps[*]}${NC}"
                sudo dnf install -y "${missing_deps[@]}"
            fi
            
            echo -e "${YELLOW}⚠️  Note: Some features limited on RHEL-based systems${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown system type - manual dependency installation required${NC}"
            echo "Required packages: jq, checkupdates (pacman-contrib), reflector"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
}

# Function to read JSON config
config() {
    if [ -f "$CONFIG_FILE" ]; then
        jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Create default configuration
create_default_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}🔧 Creating default configuration...${NC}"
        cat > "$CONFIG_FILE" << 'EOF'
{
  "check_interval": 3600,
  "parallel_downloads": 5,
  "run_reflector": false,
  "reflector_protocol": "https",
  "reflector_sort": "rate",
  "reflector_latest": 10,
  "reflector_country": "all",
  "essential_packages": [
    "linux",
    "linux-headers",
    "systemd",
    "pacman",
    "glibc",
    "base",
    "base-devel"
  ],
  "default_update_type": "full",
  "enable_aur": true,
  "aur_helper": "yay",
  "enable_flatpak": true,
  "flatpak_auto_update": false,
  "pacman_style": true,
  "show_on_terminal_launch": true,
  "auto_clean_cache": true,
  "backup_config": true
}
EOF
        chmod 644 "$CONFIG_FILE"
        echo -e "${GREEN}✅ Configuration created${NC}"
    fi
}

# Enable Pacman game-style progress bar
enable_pacman_style() {
    if [ "$SYSTEM_TYPE" != "arch-based" ]; then
        return
    fi
    
    echo -e "${BLUE}🎮 Enabling Pacman-style progress bar...${NC}"
    
    # Add ILoveCandy to pacman.conf if not present
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        echo "Adding ILoveCandy option to pacman.conf..."
        sudo sed -i '/^#Color/a ILoveCandy' /etc/pacman.conf
    fi
    
    # Enable Color if not enabled
    if grep -q "^#Color" /etc/pacman.conf; then
        echo "Enabling color output in pacman..."
        sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    fi
    
    echo -e "${GREEN}🎮 Pacman-style progress enabled!${NC}"
}

# ===== UPDATE CHECKING =====

# Check for available updates
check_updates() {
    echo -e "${BLUE}🔍 Checking for updates...${NC}"
    
    # Reset counters
    SECURITY_UPDATES=0
    ESSENTIAL_UPDATES=0
    OPTIONAL_UPDATES=0
    AUR_UPDATES=0
    FLATPAK_UPDATES=0
    PACKAGES_AVAILABLE=()
    
    # Check official repo updates (Arch-based systems only)
    if [ "$SYSTEM_TYPE" = "arch-based" ]; then
        if command -v checkupdates >/dev/null 2>&1; then
            PACKAGES_AVAILABLE=($(checkupdates 2>/dev/null | awk '{print $1}' || true))
        fi
        
        # Check AUR updates if enabled
        if [ "$(config '.enable_aur')" = "true" ]; then
            local AUR_HELPER="$(config '.aur_helper')"
            if command -v "$AUR_HELPER" >/dev/null 2>&1; then
                AUR_UPDATES=$("$AUR_HELPER" -Qua 2>/dev/null | wc -l || echo 0)
            fi
        fi
    fi
    
    # Check Flatpak updates if enabled
    if [ "$(config '.enable_flatpak')" = "true" ] && command -v flatpak >/dev/null 2>&1; then
        FLATPAK_UPDATES=$(flatpak remote-ls --updates 2>/dev/null | wc -l || echo 0)
    fi
    
    # Classify updates
    if [ ${#PACKAGES_AVAILABLE[@]} -gt 0 ]; then
        classify_updates "${PACKAGES_AVAILABLE[@]}"
    fi
    
    local TOTAL_UPDATES=$((SECURITY_UPDATES + ESSENTIAL_UPDATES + OPTIONAL_UPDATES + FLATPAK_UPDATES + AUR_UPDATES))
    
    if [ $TOTAL_UPDATES -gt 0 ]; then
        echo -e "${YELLOW}📦 Updates available:${NC}"
        echo -e "   ${RED}🔴 $SECURITY_UPDATES security${NC}"
        echo -e "   ${YELLOW}🟠 $ESSENTIAL_UPDATES essential${NC}"
        echo -e "   ${BLUE}🔵 $OPTIONAL_UPDATES optional${NC}"
        echo -e "   ${PURPLE}📱 $FLATPAK_UPDATES Flatpaks${NC}"
        echo -e "   ${CYAN}🏗️ $AUR_UPDATES AUR${NC}"
        return 0
    else
        echo -e "${GREEN}✅ System is up to date!${NC}"
        return 1
    fi
}

# Classify updates into security, essential, optional
classify_updates() {
    local ESSENTIAL_PKGS=($(config '.essential_packages[]' | tr '\n' ' '))
    local SECURITY_KEYWORDS=("security" "cve" "vulnerability" "exploit" "patch")
    
    for pkg in "$@"; do
        local pkg_lower=${pkg,,}
        local classified=false
        
        # Check for security updates
        for keyword in "${SECURITY_KEYWORDS[@]}"; do
            if [[ "$pkg_lower" == *"$keyword"* ]]; then
                ((SECURITY_UPDATES++))
                classified=true
                break
            fi
        done
        
        if [ "$classified" = true ]; then
            continue
        fi
        
        # Check for essential packages
        for essential in "${ESSENTIAL_PKGS[@]}"; do
            if [[ "$pkg" == "$essential" ]]; then
                ((ESSENTIAL_UPDATES++))
                classified=true
                break
            fi
        done
        
        if [ "$classified" = false ]; then
            ((OPTIONAL_UPDATES++))
        fi
    done
}

# ===== UPDATE EXECUTION =====

# Error handling
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    echo "$(date): ERROR - $1" >> "$LOG_FILE"
    read -p "Press any key to continue..." -n 1
    exit 1
}

# Check internet connectivity
check_internet() {
    echo -e "${BLUE}🌐 Checking internet connectivity...${NC}"
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1 && ! ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        handle_error "No internet connection"
    fi
    echo -e "${GREEN}✅ Internet connection verified${NC}"
}

# Check and handle pacman lock
check_pacman_lock() {
    if [ "$SYSTEM_TYPE" != "arch-based" ]; then
        return
    fi
    
    if [ -f /var/lib/pacman/db.lck ]; then
        echo -e "${YELLOW}⚠️  Pacman database is locked${NC}"
        local blocking_pid=$(lsof /var/lib/pacman/db.lck 2>/dev/null | awk 'NR==2 {print $2}')
        
        if [ -n "$blocking_pid" ]; then
            local blocking_cmd=$(ps -p $blocking_pid -o comm= 2>/dev/null)
            echo "Blocking process: $blocking_cmd (PID: $blocking_pid)"
            echo
            read -p "Kill process and continue? [y/N]: " choice
            case $choice in
                [Yy]*)
                    sudo kill -9 $blocking_pid
                    sudo rm -f /var/lib/pacman/db.lck
                    echo -e "${GREEN}✅ Lock removed, continuing...${NC}"
                    ;;
                *)
                    handle_error "Update stopped by user"
                    ;;
            esac
        else
            echo "Removing stale lock file..."
            sudo rm -f /var/lib/pacman/db.lck
        fi
    fi
}

# Run reflector to optimize mirrors
run_reflector() {
    if [ "$SYSTEM_TYPE" != "arch-based" ] || [ "$(config '.run_reflector')" != "true" ]; then
        return
    fi
    
    echo -e "${BLUE}🪞 Optimizing mirrors with reflector...${NC}"
    
    local PROTOCOL=$(config '.reflector_protocol')
    local SORT=$(config '.reflector_sort')
    local LATEST=$(config '.reflector_latest')
    local COUNTRY=$(config '.reflector_country')
    
    local ARGS=("--protocol" "$PROTOCOL" "--sort" "$SORT" "--latest" "$LATEST")
    
    if [ "$COUNTRY" != "all" ]; then
        ARGS+=("--country" "$COUNTRY")
    fi
    
    echo "Running: reflector ${ARGS[*]} --save /etc/pacman.d/mirrorlist"
    sudo reflector "${ARGS[@]}" --save /etc/pacman.d/mirrorlist || echo -e "${YELLOW}⚠️ Reflector failed, continuing...${NC}"
    echo -e "${GREEN}✅ Mirror optimization complete${NC}"
}

# Log update activity
log_update() {
    local update_type="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp: $update_type update - Security: $SECURITY_UPDATES, Essential: $ESSENTIAL_UPDATES, Optional: $OPTIONAL_UPDATES, Flatpak: $FLATPAK_UPDATES, AUR: $AUR_UPDATES" >> "$LOG_FILE"
    
    # Update JSON history if jq is available
    if command -v jq >/dev/null 2>&1; then
        local history_entry=$(jq -n \
            --arg date "$(date '+%Y-%m-%d')" \
            --arg time "$(date '+%H:%M:%S')" \
            --arg type "$update_type" \
            --argjson security "$SECURITY_UPDATES" \
            --argjson essential "$ESSENTIAL_UPDATES" \
            --argjson optional "$OPTIONAL_UPDATES" \
            --argjson flatpak "$FLATPAK_UPDATES" \
            --argjson aur "$AUR_UPDATES" \
            '{date: $date, time: $time, type: $type, security: $security, essential: $essential, optional: $optional, flatpak: $flatpak, aur: $aur}')
        
        if [ -f "$UPDATE_HISTORY" ]; then
            jq ". + [$history_entry]" "$UPDATE_HISTORY" > "${UPDATE_HISTORY}.tmp" && mv "${UPDATE_HISTORY}.tmp" "$UPDATE_HISTORY"
        else
            echo "[$history_entry]" > "$UPDATE_HISTORY"
        fi
    fi
}

# Clean package cache
clean_cache() {
    if [ "$(config '.auto_clean_cache')" != "true" ]; then
        return
    fi
    
    echo -e "${BLUE}🧹 Cleaning package cache...${NC}"
    
    case "$SYSTEM_TYPE" in
        "arch-based")
            # Clean pacman cache
            sudo pacman -Sc --noconfirm
            
            # Clean AUR helper cache if available
            local AUR_HELPER="$(config '.aur_helper')"
            if command -v "$AUR_HELPER" >/dev/null 2>&1; then
                case "$AUR_HELPER" in
                    "yay")
                        yay -Sc --noconfirm 2>/dev/null || true
                        ;;
                    "paru")
                        paru -Sc --noconfirm 2>/dev/null || true
                        ;;
                esac
            fi
            ;;
        "debian-based")
            sudo apt autoremove -y
            sudo apt autoclean
            ;;
        "rhel-based")
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
    esac
    
    echo -e "${GREEN}✅ Cache cleaned${NC}"
}

# Perform system update
perform_update() {
    local UPDATE_TYPE=${1:-$(config '.default_update_type')}
    local PARALLEL_DOWNLOADS=$(config '.parallel_downloads')
    
    echo -e "${CYAN}🚀 Starting $UPDATE_TYPE update...${NC}"
    
    check_internet
    check_pacman_lock
    run_reflector
    
    # Configure pacman for Arch-based systems
    if [ "$SYSTEM_TYPE" = "arch-based" ]; then
        echo -e "${BLUE}📦 Configuring pacman...${NC}"
        sudo sed -i "s/^#ParallelDownloads = .*/ParallelDownloads = $PARALLEL_DOWNLOADS/" /etc/pacman.conf
        sudo sed -i "s/^ParallelDownloads = .*/ParallelDownloads = $PARALLEL_DOWNLOADS/" /etc/pacman.conf
        
        # Enable Pacman-style progress if configured
        if [ "$(config '.pacman_style')" = "true" ]; then
            enable_pacman_style
        fi
        
        # Update package database
        echo -e "${BLUE}🔄 Updating package database...${NC}"
        sudo pacman -Sy || handle_error "Failed to sync package database"
    fi
    
    case "$UPDATE_TYPE" in
        "security")
            echo -e "${RED}🔴 Updating security packages...${NC}"
            if [ "$SYSTEM_TYPE" = "arch-based" ]; then
                sudo pacman -Su --noconfirm || handle_error "Security update failed"
            fi
            ;;
        "essential")
            echo -e "${YELLOW}🟠 Updating essential packages...${NC}"
            if [ "$SYSTEM_TYPE" = "arch-based" ]; then
                local ESSENTIAL_PKGS=($(config '.essential_packages[]' | tr '\n' ' '))
                if [ ${#ESSENTIAL_PKGS[@]} -gt 0 ]; then
                    sudo pacman -S --needed --noconfirm "${ESSENTIAL_PKGS[@]}" || handle_error "Essential update failed"
                fi
                
                read -p "Continue with optional updates? [Y/n]: " choice
                case $choice in
                    [Nn]*)
                        echo -e "${GREEN}✅ Essential updates completed!${NC}"
                        log_update "essential"
                        clean_cache
                        return 0
                        ;;
                    *)
                        echo -e "${BLUE}🔵 Continuing with optional updates...${NC}"
                        sudo pacman -Su --noconfirm || handle_error "Optional update failed"
                        ;;
                esac
            fi
            ;;
        "full")
            echo -e "${GREEN}🌈 Performing full system update...${NC}"
            case "$SYSTEM_TYPE" in
                "arch-based")
                    sudo pacman -Su --noconfirm || handle_error "Full update failed"
                    ;;
                "debian-based")
                    sudo apt update && sudo apt upgrade -y || handle_error "Full update failed"
                    ;;
                "rhel-based")
                    sudo dnf upgrade -y || handle_error "Full update failed"
                    ;;
            esac
            ;;
    esac
    
    # AUR updates if enabled and on Arch-based system
    if [ "$SYSTEM_TYPE" = "arch-based" ] && [ "$(config '.enable_aur')" = "true" ]; then
        local AUR_HELPER="$(config '.aur_helper')"
        if command -v "$AUR_HELPER" >/dev/null 2>&1; then
            echo -e "${CYAN}🏗️ Updating AUR packages...${NC}"
            $AUR_HELPER -Syu --noconfirm || echo -e "${YELLOW}⚠️ Some AUR updates failed${NC}"
        fi
    fi
    
    # Flatpak updates if enabled
    if [ "$(config '.enable_flatpak')" = "true" ] && command -v flatpak >/dev/null 2>&1; then
        echo -e "${PURPLE}📱 Updating Flatpaks...${NC}"
        flatpak update -y || echo -e "${YELLOW}⚠️ Some Flatpak updates failed${NC}"
    fi
    
    # Clean cache and log update
    clean_cache
    log_update "$UPDATE_TYPE"
    
    echo
    echo -e "${GREEN}✅ All updates completed successfully!${NC}"
    echo -e "${CYAN}📊 Update Summary:${NC}"
    echo -e "   ${RED}🔴 Security: $SECURITY_UPDATES${NC}"
    echo -e "   ${YELLOW}🟠 Essential: $ESSENTIAL_UPDATES${NC}"
    echo -e "   ${BLUE}🔵 Optional: $OPTIONAL_UPDATES${NC}"
    echo -e "   ${PURPLE}📱 Flatpak: $FLATPAK_UPDATES${NC}"
    echo -e "   ${CYAN}🏗️ AUR: $AUR_UPDATES${NC}"
    echo
    read -p "Press any key to close..." -n 1
}

# ===== ALIAS MANAGEMENT =====

# Refresh shell configuration after alias creation
refresh_shell() {
    local shell="$1"
    local alias_name="$2"
    
    echo -e "${BLUE}🔄 Refreshing shell configuration...${NC}"
    
    case "$shell" in
        "bash")
            if [ -f "$HOME/.bashrc" ]; then
                echo -e "${BLUE}   Reloading .bashrc to apply alias...${NC}"
                # Source the bashrc file and test the alias
                source "$HOME/.bashrc" && echo -e "${GREEN}   ✅ Bash alias '$alias_name' is now active!${NC}"
            fi
            ;;
        "zsh")
            if [ -f "$HOME/.zshrc" ]; then
                echo -e "${BLUE}   Reloading .zshrc to apply alias...${NC}"
                # For zsh, we need to handle this differently since we're in bash
                echo -e "${GREEN}   ✅ Zsh alias '$alias_name' will be active in new zsh sessions!${NC}"
                echo -e "${CYAN}   💡 Run 'exec zsh' or open a new terminal to use the alias immediately${NC}"
            fi
            ;;
        "fish")
            echo -e "${GREEN}   ✅ Fish function '$alias_name' is now available!${NC}"
            echo -e "${CYAN}   💡 Open a new fish shell or run 'exec fish' to use the function${NC}"
            ;;
        "dash")
            if [ -f "$HOME/.profile" ]; then
                echo -e "${BLUE}   Reloading .profile to apply alias...${NC}"
                source "$HOME/.profile" && echo -e "${GREEN}   ✅ Dash alias '$alias_name' is now active!${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}   ⚠️ Unknown shell type. Please restart your shell to use the alias.${NC}"
            ;;
    esac
}

# Helper functions for each shell type
setup_bash_alias() {
    local alias_name="$1"
    local script_path="$2"
    local config_file="$3"
    
    # Create config file if it doesn't exist
    touch "$config_file"
    
    # Remove existing alias
    sed -i "/alias $alias_name=/d" "$config_file" 2>/dev/null || true
    
    # Add new alias
    echo "# OneClick Arch alias" >> "$config_file"
    echo "alias $alias_name='$script_path --menu'" >> "$config_file"
    echo -e "   ${GREEN}✅ Bash alias added to $config_file${NC}"
}

setup_zsh_alias() {
    local alias_name="$1"
    local script_path="$2"
    local config_file="$3"
    
    # Create config file if it doesn't exist
    touch "$config_file"
    
    # Remove existing alias
    sed -i "/alias $alias_name=/d" "$config_file" 2>/dev/null || true
    
    # Add new alias with zsh-specific optimizations
    {
        echo "# OneClick Arch alias"
        echo "alias $alias_name='$script_path --menu'"
    } >> "$config_file"
    
    echo -e "   ${GREEN}✅ Zsh alias added to $config_file${NC}"
}

setup_fish_function() {
    local alias_name="$1"
    local script_path="$2"
    local functions_dir="$HOME/.config/fish/functions"
    
    # Create functions directory
    mkdir -p "$functions_dir"
    
    # Create function file
    cat > "$functions_dir/$alias_name.fish" << EOF
function $alias_name --description 'OneClick Arch update manager'
    $script_path --menu \$argv
end
EOF
    
    echo -e "   ${GREEN}✅ Fish function created: $functions_dir/$alias_name.fish${NC}"
}

setup_dash_alias() {
    local alias_name="$1"
    local script_path="$2"
    local config_file="$3"
    
    # Create config file if it doesn't exist
    touch "$config_file"
    
    # Remove existing alias
    sed -i "/alias $alias_name=/d" "$config_file" 2>/dev/null || true
    
    # Add POSIX-compliant alias
    echo "# OneClick Arch alias" >> "$config_file"
    echo "alias $alias_name='$script_path --menu'" >> "$config_file"
    echo -e "   ${GREEN}✅ Dash alias added to $config_file${NC}"
}

# Multi-shell alias creation with automatic refresh
create_alias() {
    echo -e "${BLUE}🔗 Setting up OneClick alias...${NC}"
    echo
    
    # Run detection functions
    detect_shell
    
    # Get alias name
    read -p "Enter alias name [default: oc]: " alias_name
    alias_name=${alias_name:-oc}
    
    local script_path=$(realpath "$0")
    local success_count=0
    
    # Create aliases for all detected shells
    for shell in "${DETECTED_SHELLS[@]}"; do
        echo -e "${BLUE}📝 Setting up alias for $shell...${NC}"
        
        case "$shell" in
            "bash")
                local bash_config="$HOME/.bashrc"
                setup_bash_alias "$alias_name" "$script_path" "$bash_config"
                refresh_shell "bash" "$alias_name"
                ((success_count++))
                ;;
            "zsh")
                local zsh_config="$HOME/.zshrc"
                setup_zsh_alias "$alias_name" "$script_path" "$zsh_config"
                refresh_shell "zsh" "$alias_name"
                ((success_count++))
                ;;
            "fish")
                setup_fish_function "$alias_name" "$script_path"
                refresh_shell "fish" "$alias_name"
                ((success_count++))
                ;;
            "dash")
                local dash_config="$HOME/.profile"
                setup_dash_alias "$alias_name" "$script_path" "$dash_config"
                refresh_shell "dash" "$alias_name"
                ((success_count++))
                ;;
        esac
        echo
    done
    
    echo -e "${GREEN}🎉 Alias setup complete!${NC}"
    echo -e "   ${GREEN}$success_count shell(s) configured${NC}"
    echo -e "   ${CYAN}Alias name: $alias_name${NC}"
    echo
    
    # Special message for current shell
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" == "bash" ]] && [[ " ${DETECTED_SHELLS[@]} " =~ " bash " ]]; then
        echo -e "${GREEN}🚀 You can now use: $alias_name${NC}"
    else
        echo -e "${YELLOW}💡 For immediate use in your current shell:${NC}"
        case "$current_shell" in
            "bash") echo "   source ~/.bashrc && $alias_name" ;;
            "zsh") echo "   source ~/.zshrc && $alias_name" ;;
            "fish") echo "   exec fish" ;;
            *) echo "   Restart your terminal or run: $alias_name" ;;
        esac
    fi
    echo
}

# ===== TERMINAL LAUNCH INTEGRATION =====

# Setup terminal launch check
setup_terminal_integration() {
    if [ "$(config '.show_on_terminal_launch')" != "true" ]; then
        echo -e "${YELLOW}⚠️  Terminal integration is disabled in config${NC}"
        read -p "Enable terminal integration? [Y/n]: " enable_choice
        case $enable_choice in
            [Nn]*)
                return
                ;;
            *)
                # Enable in config
                if command -v jq >/dev/null 2>&1; then
                    jq '.show_on_terminal_launch = true' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                fi
                ;;
        esac
    fi
    
    local script_path=$(realpath "$0")
    
    # Use current shell config for integration
    detect_shell true  # Silent mode
    
    # Add update check to shell config if not present
    local check_line="# OneClick update check"
    if ! grep -q "$check_line" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "$check_line" >> "$SHELL_CONFIG"
        echo "$script_path --terminal-check" >> "$SHELL_CONFIG"
        echo -e "${GREEN}✅ Terminal integration added to $SHELL_CONFIG${NC}"
    else
        echo -e "${CYAN}ℹ️  Terminal integration already enabled${NC}"
    fi
}

# Quick update check for terminal launch
terminal_update_check() {
    # Only run if configured to do so
    if [ "$(config '.show_on_terminal_launch')" != "true" ]; then
        return
    fi
    
    # Silent detection
    detect_system_silent >/dev/null 2>&1
    
    # Only check for Arch-based systems
    if [ "$SYSTEM_TYPE" != "arch-based" ]; then
        return
    fi
    
    # Check for updates silently
    if command -v checkupdates >/dev/null 2>&1; then
        PACKAGES_AVAILABLE=($(checkupdates 2>/dev/null | awk '{print $1}' || true))
        if [ ${#PACKAGES_AVAILABLE[@]} -gt 0 ]; then
            classify_updates "${PACKAGES_AVAILABLE[@]}"
            
            local TOTAL_UPDATES=$((SECURITY_UPDATES + ESSENTIAL_UPDATES + OPTIONAL_UPDATES))
            
            if [ $TOTAL_UPDATES -gt 0 ]; then
                echo -e "${YELLOW}⚡ $TOTAL_UPDATES updates available${NC} ${BLUE}(run 'oc --menu' to update)${NC}"
                
                # Show breakdown if significant updates
                if [ $SECURITY_UPDATES -gt 0 ] || [ $ESSENTIAL_UPDATES -gt 0 ]; then
                    echo -e "   ${RED}$SECURITY_UPDATES security${NC} ${YELLOW}$ESSENTIAL_UPDATES essential${NC} ${BLUE}$OPTIONAL_UPDATES optional${NC}"
                fi
            fi
        fi
    fi
}

# ===== HISTORY AND REPORTING =====

# Show update history
show_history() {
    echo -e "${BLUE}📜 Update History:${NC}"
    echo
    
    if [ -f "$UPDATE_HISTORY" ] && command -v jq >/dev/null 2>&1; then
        # Show last 10 updates in a formatted way
        jq -r 'reverse | .[:10] | .[] | "\(.date) \(.time) - \(.type | ascii_upcase) update: Security: \(.security), Essential: \(.essential), Optional: \(.optional), Flatpak: \(.flatpak), AUR: \(.aur)"' "$UPDATE_HISTORY" 2>/dev/null || echo "No valid history found"
    elif [ -f "$LOG_FILE" ]; then
        echo "Recent log entries:"
        tail -10 "$LOG_FILE"
    else
        echo "No update history available"
    fi
    
    echo
}

# Show system information
show_system_info() {
    echo -e "${CYAN}🖥️  System Information:${NC}"
    echo -e "   ${WHITE}OS:${NC} $SYSTEM_NAME"
    echo -e "   ${WHITE}Type:${NC} $SYSTEM_TYPE"
    echo -e "   ${WHITE}Package Manager:${NC} $PACKAGE_MANAGER"
    echo -e "   ${WHITE}Shell:${NC} $SHELL_TYPE"
    echo -e "   ${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "   ${WHITE}Architecture:${NC} $(uname -m)"
    
    if [ "$SYSTEM_TYPE" = "arch-based" ]; then
        if command -v pacman >/dev/null 2>&1; then
            local installed_pkgs=$(pacman -Q | wc -l)
            echo -e "   ${WHITE}Installed packages:${NC} $installed_pkgs"
        fi
        
        if [ "$(config '.enable_aur')" = "true" ]; then
            local aur_helper="$(config '.aur_helper')"
            echo -e "   ${WHITE}AUR helper:${NC} $aur_helper"
        fi
    fi
    
    echo
}

# ===== MENU SYSTEM =====

# Main menu
show_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║          OneClick for Arch - v1.0            ║${NC}"
        echo -e "${CYAN}║        Enhanced Standalone Edition           ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${WHITE}System: ${GREEN}$SYSTEM_NAME${NC} | ${WHITE}Shell: ${GREEN}$SHELL_TYPE${NC}"
        echo
        echo -e "${GREEN}📦 Update Options:${NC}"
        echo "1. Check for updates"
        echo "2. Update now (default type)"
        echo "3. Full system update"
        echo "4. Essential updates only"
        echo "5. Security updates only"
        echo
        echo -e "${BLUE}⚙️  Configuration:${NC}"
        echo "6. Configure settings"
        echo "7. Setup alias"
        echo "8. Setup terminal integration"
        echo
        echo -e "${PURPLE}📊 Information:${NC}"
        echo "9. View update history"
        echo "10. System information"
        echo
        echo -e "${RED}🚪 Exit:${NC}"
        echo "11. Exit"
        echo
        read -p "Choose an option [1-11]: " choice
        
        case $choice in
            1)
                if check_updates; then
                    echo
                    read -p "Updates available. Update now? [Y/n]: " update_choice
                    case $update_choice in
                        [Nn]*) ;;
                        *) perform_update ;;
                    esac
                fi
                read -p "Press any key to continue..." -n 1
                ;;
            2)
                perform_update
                ;;
            3)
                perform_update "full"
                ;;
            4)
                perform_update "essential"
                ;;
            5)
                perform_update "security"
                ;;
            6)
                setup_editor
                $EDITOR "$CONFIG_FILE"
                ;;
            7)
                create_alias
                read -p "Press any key to continue..." -n 1
                ;;
            8)
                setup_terminal_integration
                read -p "Press any key to continue..." -n 1
                ;;
            9)
                show_history
                read -p "Press any key to continue..." -n 1
                ;;
            10)
                show_system_info
                read -p "Press any key to continue..." -n 1
                ;;
            11)
                echo -e "${GREEN}Thank you for using OneClick! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 1-11.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ===== MAIN EXECUTION =====

# Enhanced initialization with system detection
initialize_oneclick() {
    echo -e "${CYAN}🚀 Initializing OneClick for Arch...${NC}"
    echo
    
    # Detect system and shell (interactive mode)
    detect_system
    detect_shell
    
    # Continue with setup
    setup_editor
    setup_directories
    install_dependencies
    create_default_config
    
    # Enable Pacman-style progress if on Arch-based system
    if [ "$SYSTEM_TYPE" = "arch-based" ] && [ "$(config '.pacman_style')" = "true" ]; then
        enable_pacman_style
    fi
    
    echo
    echo -e "${GREEN}✅ OneClick initialized successfully!${NC}"
    echo -e "   ${CYAN}System: $SYSTEM_NAME${NC}"
    echo -e "   ${CYAN}Shell: $SHELL_TYPE${NC}"
    echo -e "   ${CYAN}Package Manager: $PACKAGE_MANAGER${NC}"
    echo
}

# ===== COMMAND LINE ARGUMENT HANDLING =====

# Waybar integration and command modes
case "$1" in
    --init)
        initialize_oneclick
        ;;
    --check)
        # Quick detection for Waybar
        if is_initialized; then
            detect_system_silent >/dev/null 2>&1
            if check_updates >/dev/null 2>&1; then
                local TOTAL_UPDATES=$((SECURITY_UPDATES + ESSENTIAL_UPDATES + OPTIONAL_UPDATES + FLATPAK_UPDATES + AUR_UPDATES))
                echo "{\"text\":\"$TOTAL_UPDATES\", \"tooltip\":\"$SECURITY_UPDATES security\\n$ESSENTIAL_UPDATES essential\\n$OPTIONAL_UPDATES optional\\n$FLATPAK_UPDATES flatpak\\n$AUR_UPDATES AUR\", \"class\":\"updates-available\"}"
                exit 0
            else
                echo "{\"text\":\"0\", \"tooltip\":\"System up to date\", \"class\":\"no-updates\"}"
                exit 1
            fi
        else
            echo "{\"text\":\"!\", \"tooltip\":\"OneClick not initialized\", \"class\":\"error\"}"
            exit 1
        fi
        ;;
    --terminal-check)
        if is_initialized; then
            terminal_update_check
        fi
        ;;
    --update)
        if ! is_initialized; then
            echo -e "${YELLOW}⚠️  OneClick not initialized. Running initialization...${NC}"
            initialize_oneclick
        else
            detect_system_silent
            detect_shell true
        fi
        perform_update
        ;;
    --menu)
        # Only initialize if not already done
        if ! is_initialized; then
            echo -e "${YELLOW}⚠️  OneClick not initialized. Running initialization...${NC}"
            initialize_oneclick
        else
            # Silent detection - no prompts for menu access
            detect_system_silent
            detect_shell true
        fi
        show_menu
        ;;
    --setup-alias)
        if ! is_initialized; then
            initialize_oneclick
        else
            detect_system_silent
        fi
        create_alias
        ;;
    --version)
        echo "OneClick for Arch - Enhanced Standalone Edition v1.0"
        echo "System & Shell Auto-Detection | Multi-Distribution Support"
        echo "Features: Alias setup + Automatic shell refresh + Pacman game style"
        echo "Author: Enhanced by AI Assistant"
        exit 0
        ;;
    --help|-h)
        echo -e "${CYAN}OneClick for Arch - Enhanced Standalone Edition v1.0${NC}"
        echo
        echo "A comprehensive system update manager with automatic detection"
        echo
        echo -e "${WHITE}Usage:${NC} $0 [OPTION]"
        echo
        echo -e "${WHITE}Options:${NC}"
        echo "  --init              Initialize OneClick (run this first)"
        echo "  --check             Check for updates (JSON output for Waybar)"
        echo "  --update            Perform default update"
        echo "  --menu              Show interactive menu"
        echo "  --setup-alias       Create shell alias interactively"
        echo "  --terminal-check    Quick update check for terminal launch"
        echo "  --version           Show version information"
        echo "  --help, -h          Show this help message"
        echo
        echo -e "${WHITE}First time setup:${NC}"
        echo "  1. Run: $0 --init"
        echo "  2. Run: $0 --setup-alias"
        echo "  3. Shell will refresh automatically!"
        echo "  4. Use your alias to access the menu"
        echo
        echo -e "${WHITE}Examples:${NC}"
        echo "  $0 --init                    # Initialize OneClick"
        echo "  $0 --menu                    # Open interactive menu"
        echo "  $0 --setup-alias             # Create shell alias"
        echo
        exit 0
        ;;
    *)
        if [ $# -eq 0 ]; then
            # No arguments - show help
            "$0" --help
        else
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use '$0 --help' for usage information."
            exit 1
        fi
        ;;
esac

