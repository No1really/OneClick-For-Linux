#!/usr/bin/env bash

# =====================================================================
# 🟡 ONECLICK CLI v1.0: UPDATE CHECKER MODULE 🟡
# "Hunt those pellets! Check for system updates!"
# =====================================================================

VERSION="1.0"
box_width=66

# Center text function - STANDARDIZED
center_box() {
    local w=$1; shift
    local termw=$(tput cols 2>/dev/null || echo 80)
    local left=$(( (termw - w) / 2 ))
    [[ $left -lt 0 ]] && left=0
    for line in "$@"; do
        printf "%*s%s\n" "$left" "" "$line"
    done
}

# Pac-Man themed UI components
header_lines=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                                                              ║"
    "║               🟡 UPDATE CHECKER: PELLET HUNT 🟡              ║"
    "║                 Scanning for available updates               ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Detect package manager
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Scanning animation
show_scanning_animation() {
    local pm="$1"
    local pellets=("🟡" "🍒" "🟡" "🍒" "🟡" "👻" "🟡" "🍒")
    
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    
    center_box "$box_width" "Package Manager: $pm"
    echo
    
    for i in {0..15}; do
        local pellet=${pellets[$((i % 8))]}
        center_box "$box_width" "$pellet Chomping through repositories... $pellet"
        sleep 0.3
        tput cup $(($(tput lines) / 2 + 4)) 0
        tput el
    done
}

# Check for updates - Arch Linux (pacman)
check_pacman_updates() {
    center_box "$box_width" "🟡 Syncing package databases..."
    
    # Update package database
    if sudo pacman -Sy --noconfirm >/dev/null 2>&1; then
        center_box "$box_width" "✅ Database sync successful!"
    else
        center_box "$box_width" "⚠️ Database sync failed, proceeding with cached data..."
    fi
    echo
    
    # Check for updates
    local updates=$(pacman -Qu 2>/dev/null)
    local update_count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "🍒 Found $update_count pellets (updates) to chomp!"
        echo
        center_box "$box_width" "Available updates:"
        echo
        
        # Show first 10 updates with Pac-Man styling
        echo "$updates" | head -10 | while read -r pkg; do
            center_box "$box_width" "  🟡 $pkg"
        done
        
        if [[ $update_count -gt 10 ]]; then
            center_box "$box_width" "  ... and $((update_count - 10)) more packages"
        fi
    else
        center_box "$box_width" "👻 No pellets found! System is up to date!"
    fi
    
    return $update_count
}

# Check for updates - Debian/Ubuntu (apt)
check_apt_updates() {
    center_box "$box_width" "🟡 Updating package lists..."
    
    if sudo apt update >/dev/null 2>&1; then
        center_box "$box_width" "✅ Package lists updated!"
    else
        center_box "$box_width" "⚠️ Update failed, checking with cached data..."
    fi
    echo
    
    local updates=$(apt list --upgradable 2>/dev/null | grep -v "WARNING\|Listing")
    local update_count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "🍒 Found $update_count pellets (updates) to chomp!"
        echo
        center_box "$box_width" "Available updates:"
        echo
        
        echo "$updates" | head -10 | while read -r pkg; do
            local pkg_name=$(echo "$pkg" | cut -d'/' -f1)
            center_box "$box_width" "  🟡 $pkg_name"
        done
        
        if [[ $update_count -gt 10 ]]; then
            center_box "$box_width" "  ... and $((update_count - 10)) more packages"
        fi
    else
        center_box "$box_width" "👻 No pellets found! System is up to date!"
    fi
    
    return $update_count
}

# Check for updates - Fedora (dnf)
check_dnf_updates() {
    center_box "$box_width" "🟡 Checking for updates..."
    
    local updates=$(dnf list updates 2>/dev/null | grep -v "Available Upgrades\|Last metadata")
    local update_count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "🍒 Found $update_count pellets (updates) to chomp!"
        echo
        center_box "$box_width" "Available updates:"
        echo
        
        echo "$updates" | head -10 | while read -r pkg; do
            local pkg_name=$(echo "$pkg" | awk '{print $1}')
            center_box "$box_width" "  🟡 $pkg_name"
        done
        
        if [[ $update_count -gt 10 ]]; then
            center_box "$box_width" "  ... and $((update_count - 10)) more packages"
        fi
    else
        center_box "$box_width" "👻 No pellets found! System is up to date!"
    fi
    
    return $update_count
}

# Check for updates - openSUSE (zypper)
check_zypper_updates() {
    center_box "$box_width" "🟡 Refreshing repositories..."
    
    if sudo zypper ref >/dev/null 2>&1; then
        center_box "$box_width" "✅ Repositories refreshed!"
    else
        center_box "$box_width" "⚠️ Refresh failed, checking with cached data..."
    fi
    echo
    
    local updates=$(zypper list-updates 2>/dev/null | grep -v "Repository\|Loading\|Reading\|---")
    local update_count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "🍒 Found $update_count pellets (updates) to chomp!"
        echo
        center_box "$box_width" "Available updates:"
        echo
        
        echo "$updates" | head -10 | while read -r pkg; do
            local pkg_name=$(echo "$pkg" | awk '{print $3}')
            center_box "$box_width" "  🟡 $pkg_name"
        done
        
        if [[ $update_count -gt 10 ]]; then
            center_box "$box_width" "  ... and $((update_count - 10)) more packages"
        fi
    else
        center_box "$box_width" "👻 No pellets found! System is up to date!"
    fi
    
    return $update_count
}

# Check for updates - macOS (brew)
check_brew_updates() {
    center_box "$box_width" "🟡 Updating Homebrew..."
    
    if brew update >/dev/null 2>&1; then
        center_box "$box_width" "✅ Homebrew updated!"
    else
        center_box "$box_width" "⚠️ Update failed, checking with cached data..."
    fi
    echo
    
    local updates=$(brew outdated 2>/dev/null)
    local update_count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "🍒 Found $update_count pellets (updates) to chomp!"
        echo
        center_box "$box_width" "Available updates:"
        echo
        
        echo "$updates" | head -10 | while read -r pkg; do
            center_box "$box_width" "  🟡 $pkg"
        done
        
        if [[ $update_count -gt 10 ]]; then
            center_box "$box_width" "  ... and $((update_count - 10)) more packages"
        fi
    else
        center_box "$box_width" "👻 No pellets found! System is up to date!"
    fi
    
    return $update_count
}

# Main update checking function
check_for_updates() {
    local pm=$(detect_package_manager)
    
    show_scanning_animation "$pm"
    
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    
    case "$pm" in
        pacman)
            check_pacman_updates
            local update_count=$?
            ;;
        apt)
            check_apt_updates
            local update_count=$?
            ;;
        dnf)
            check_dnf_updates
            local update_count=$?
            ;;
        zypper)
            check_zypper_updates
            local update_count=$?
            ;;
        brew)
            check_brew_updates
            local update_count=$?
            ;;
        *)
            center_box "$box_width" "❌ Unsupported package manager!"
            center_box "$box_width" "Supported: pacman, apt, dnf, zypper, brew"
            return 1
            ;;
    esac
    
    echo
    
    if [[ $update_count -gt 0 ]]; then
        center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
        center_box "$box_width" "║                     🟡 PELLET HUNT RESULTS 🟡                ║"
        center_box "$box_width" "╠══════════════════════════════════════════════════════════════╣"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  🍒 $update_count package updates available!                 ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  Next steps:                                                 ║"
        center_box "$box_width" "║  • Return to main menu and select 'Update System'            ║"
        center_box "$box_width" "║  • Or run: ./oneclick-cli --update                           ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    else
        center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
        center_box "$box_width" "║                    👻 MAZE CLEARED! 👻                       ║"
        center_box "$box_width" "╠══════════════════════════════════════════════════════════════╣"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  All packages up to date!                                    ║"
        center_box "$box_width" "║  Your system is running the latest versions.                 ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  🟡 WAKA-WAKA-WAKA! 🟡                                       ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    fi
    
    echo
    center_box "$box_width" "Press any key to return to main menu..."
    read -n 1 -s
    
    return $update_count
}

# Quick check function (for command line usage)
quick_check() {
    local pm=$(detect_package_manager)
    
    case "$pm" in
        pacman)
            local update_count=$(pacman -Qu 2>/dev/null | wc -l)
            ;;
        apt)
            local update_count=$(apt list --upgradable 2>/dev/null | grep -v "WARNING\|Listing" | wc -l)
            ;;
        dnf)
            local update_count=$(dnf list updates 2>/dev/null | grep -v "Available Upgrades\|Last metadata" | wc -l)
            ;;
        zypper)
            local update_count=$(zypper list-updates 2>/dev/null | grep -v "Repository\|Loading\|Reading\|---" | wc -l)
            ;;
        brew)
            local update_count=$(brew outdated 2>/dev/null | wc -l)
            ;;
        *)
            echo "❌ Unsupported package manager: $pm"
            exit 1
            ;;
    esac
    
    if [[ $update_count -gt 0 ]]; then
        echo "🍒 $update_count updates available"
    else
        echo "👻 System up to date"
    fi
    
    exit $update_count
}

# Handle script arguments
case "${1:-menu}" in
    menu|"") check_for_updates ;;
    quick) quick_check ;;
    --help|-h) 
        echo "Usage: $0 [menu|quick|--help]"
        echo "  menu  - Interactive update checker (default)"
        echo "  quick - Quick check, returns count"
        exit 0
        ;;
    *) 
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

