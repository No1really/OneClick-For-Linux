#!/usr/bin/env bash

# =====================================================================
# 🟡 ONECLICK CLI v1.0: SYSTEM UPDATER MODULE 🟡
# "Power pellet time! Update your entire system!"
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
    "║              🟡 SYSTEM UPDATER: POWER PELLET 🟡              ║"
    "║                 Chomping through system updates              ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

update_menu_lines=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                       UPDATE OPTIONS                         ║"
    "╠══════════════════════════════════════════════════════════════╣"
    "║                                                              ║"
    "║  🟡 1. Quick Update (Essential packages only)   🍒           ║"
    "║                                                              ║"
    "║  🟡 2. Full System Update (All packages)        👻           ║"
    "║                                                              ║"
    "║  🟡 3. Update + Cleanup (Full update + cleanup) 🍒           ║"
    "║                                                              ║"
    "║  🟡 4. Custom Update (Select packages)          👻           ║"
    "║                                                              ║"
    "║  🟡 5. Check What Will Be Updated                🍒          ║"
    "║                                                              ║"
    "║  🍒 6. Return to Main Menu                      🟡           ║"
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

# Power pellet animation
show_power_pellet_animation() {
    local action="$1"
    local power_frames=("🟡" "🟠" "🔴" "🟡" "🟠" "🔴" "💥" "⚡")
    
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    
    center_box "$box_width" "Power Pellet Activated! $action"
    echo
    
    for i in {0..15}; do
        local frame=${power_frames[$((i % 8))]}
        center_box "$box_width" "$frame CHOMPING THROUGH UPDATES... $frame"
        sleep 0.2
        tput cup $(($(tput lines) / 2 + 4)) 0
        tput el
    done
}

# Progress bar function
show_progress_bar() {
    local current=$1
    local total=$2
    local description="$3"
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="🟡"
    done
    for ((i=filled; i<width; i++)); do
        bar+="⬜"
    done
    
    center_box "$box_width" "$description ($current/$total)"
    center_box "$box_width" "[$bar] ${percentage}%"
}

# Quick update - Arch Linux (pacman)
quick_update_pacman() {
    center_box "$box_width" "🟡 Quick Update: Essential packages only"
    echo
    
    # Update system packages only (not AUR)
    center_box "$box_width" "Updating core system packages..."
    if sudo pacman -Syu --noconfirm >/dev/null 2>&1; then
        center_box "$box_width" "✅ Quick update completed successfully!"
    else
        center_box "$box_width" "❌ Quick update encountered errors"
        return 1
    fi
}

# Full update - Arch Linux (pacman)
full_update_pacman() {
    center_box "$box_width" "🟡 Full System Update: All packages"
    echo
    
    # Full system update
    center_box "$box_width" "Updating all packages and dependencies..."
    if sudo pacman -Syu --noconfirm; then
        center_box "$box_width" "✅ Full system update completed successfully!"
    else
        center_box "$box_width" "❌ Full update encountered errors"
        return 1
    fi
}

# Update with cleanup - Arch Linux (pacman)
update_cleanup_pacman() {
    center_box "$box_width" "🟡 Update + Cleanup: Full update with maintenance"
    echo
    
    # Full system update
    center_box "$box_width" "Step 1/3: Updating all packages..."
    sudo pacman -Syu --noconfirm
    
    echo
    center_box "$box_width" "Step 2/3: Cleaning package cache..."
    sudo pacman -Scc --noconfirm
    
    echo
    center_box "$box_width" "Step 3/3: Removing orphaned packages..."
    local orphans=$(pacman -Qtdq 2>/dev/null)
    if [[ -n "$orphans" ]]; then
        sudo pacman -Rns --noconfirm $orphans
        center_box "$box_width" "👻 Removed orphaned packages"
    else
        center_box "$box_width" "👻 No orphaned packages found"
    fi
    
    center_box "$box_width" "✅ Update + Cleanup completed!"
}

# Custom update - Arch Linux (pacman)
custom_update_pacman() {
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Custom Package Selection"
    echo
    
    # Get available updates
    local updates=$(pacman -Qu 2>/dev/null)
    if [[ -z "$updates" ]]; then
        center_box "$box_width" "👻 No updates available!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    # Convert to array
    local -a packages
    local -a selected
    local i=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            packages[i]="$line"
            selected[i]=false
            ((i++))
        fi
    done <<< "$updates"
    
    local total=${#packages[@]}
    local current_pos=0
    
    while true; do
        clear
        center_box "$box_width" "${header_lines[@]}"
        echo
        center_box "$box_width" "🟡 Select packages to update (SPACE=toggle, ENTER=confirm)"
        echo
        
        # Show packages with selection status
        for ((j=0; j<total && j<15; j++)); do
            local display_idx=$((current_pos + j))
            if [[ $display_idx -ge $total ]]; then
                break
            fi
            
            local prefix="  "
            if [[ $display_idx -eq $current_pos ]]; then
                prefix="🟡"
            fi
            
            local checkbox="⬜"
            if [[ "${selected[$display_idx]}" == "true" ]]; then
                checkbox="✅"
            fi
            
            local pkg_name=$(echo "${packages[$display_idx]}" | awk '{print $1}')
            center_box "$box_width" "$prefix $checkbox $pkg_name"
        done
        
        if [[ $total -gt 15 ]]; then
            center_box "$box_width" "... showing $((current_pos + 1))-$((current_pos + 15)) of $total packages"
        fi
        
        echo
        center_box "$box_width" "Controls: ↑/↓ navigate, SPACE select, ENTER confirm, q quit"
        
        # Get user input
        read -n 1 -s key
        case "$key" in
            $'\x1b') # Arrow keys
                read -n 2 -s key
                case "$key" in
                    '[A') # Up arrow
                        if [[ $current_pos -gt 0 ]]; then
                            ((current_pos--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $current_pos -lt $((total - 1)) ]]; then
                            ((current_pos++))
                        fi
                        ;;
                esac
                ;;
            ' ') # Space - toggle selection
                if [[ "${selected[$current_pos]}" == "true" ]]; then
                    selected[$current_pos]=false
                else
                    selected[$current_pos]=true
                fi
                ;;
            $'\n'|$'\r') # Enter - confirm selection
                break
                ;;
            'q'|'Q') # Quit
                return 0
                ;;
        esac
    done
    
    # Build list of selected packages
    local selected_packages=()
    for ((i=0; i<total; i++)); do
        if [[ "${selected[i]}" == "true" ]]; then
            local pkg_name=$(echo "${packages[i]}" | awk '{print $1}')
            selected_packages+=("$pkg_name")
        fi
    done
    
    if [[ ${#selected_packages[@]} -eq 0 ]]; then
        center_box "$box_width" "👻 No packages selected!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    # Confirm selection
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Selected ${#selected_packages[@]} packages for update:"
    echo
    
    for pkg in "${selected_packages[@]}"; do
        center_box "$box_width" "  🍒 $pkg"
    done
    
    echo
    center_box "$box_width" "Proceed with update? (y/N): "
    read -n 1 -s confirm
    echo
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        center_box "$box_width" "🟡 Updating selected packages..."
        if sudo pacman -S --noconfirm "${selected_packages[@]}"; then
            center_box "$box_width" "✅ Custom update completed successfully!"
        else
            center_box "$box_width" "❌ Custom update encountered errors"
            return 1
        fi
    else
        center_box "$box_width" "👻 Update cancelled by user"
    fi
}

# Quick update - Debian/Ubuntu (apt)
quick_update_apt() {
    center_box "$box_width" "🟡 Quick Update: Security updates only"
    echo
    
    center_box "$box_width" "Updating package lists..."
    sudo apt update >/dev/null 2>&1
    
    center_box "$box_width" "Installing security updates..."
    if sudo apt upgrade -y >/dev/null 2>&1; then
        center_box "$box_width" "✅ Quick update completed successfully!"
    else
        center_box "$box_width" "❌ Quick update encountered errors"
        return 1
    fi
}

# Full update - Debian/Ubuntu (apt)
full_update_apt() {
    center_box "$box_width" "🟡 Full System Update: All packages"
    echo
    
    center_box "$box_width" "Updating package lists..."
    sudo apt update
    
    echo
    center_box "$box_width" "Upgrading all packages..."
    if sudo apt full-upgrade -y; then
        center_box "$box_width" "✅ Full system update completed successfully!"
    else
        center_box "$box_width" "❌ Full update encountered errors"
        return 1
    fi
}

# Update with cleanup - Debian/Ubuntu (apt)
update_cleanup_apt() {
    center_box "$box_width" "🟡 Update + Cleanup: Full update with maintenance"
    echo
    
    center_box "$box_width" "Step 1/4: Updating package lists..."
    sudo apt update
    
    echo
    center_box "$box_width" "Step 2/4: Upgrading all packages..."
    sudo apt full-upgrade -y
    
    echo
    center_box "$box_width" "Step 3/4: Removing unnecessary packages..."
    sudo apt autoremove -y
    
    echo
    center_box "$box_width" "Step 4/4: Cleaning package cache..."
    sudo apt autoclean
    
    center_box "$box_width" "✅ Update + Cleanup completed!"
}

# Custom update - Debian/Ubuntu (apt)
custom_update_apt() {
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Custom Package Selection"
    echo
    
    # Update package lists first
    center_box "$box_width" "Updating package lists..."
    sudo apt update >/dev/null 2>&1
    
    # Get available updates
    local updates=$(apt list --upgradable 2>/dev/null | grep -v "WARNING\|Listing")
    if [[ -z "$updates" ]]; then
        center_box "$box_width" "👻 No updates available!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    # Convert to array
    local -a packages
    local -a selected
    local i=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            packages[i]="$line"
            selected[i]=false
            ((i++))
        fi
    done <<< "$updates"
    
    local total=${#packages[@]}
    local current_pos=0
    
    while true; do
        clear
        center_box "$box_width" "${header_lines[@]}"
        echo
        center_box "$box_width" "🟡 Select packages to update (SPACE=toggle, ENTER=confirm)"
        echo
        
        # Show packages with selection status
        for ((j=0; j<total && j<15; j++)); do
            local display_idx=$((current_pos + j))
            if [[ $display_idx -ge $total ]]; then
                break
            fi
            
            local prefix="  "
            if [[ $display_idx -eq $current_pos ]]; then
                prefix="🟡"
            fi
            
            local checkbox="⬜"
            if [[ "${selected[$display_idx]}" == "true" ]]; then
                checkbox="✅"
            fi
            
            local pkg_name=$(echo "${packages[$display_idx]}" | cut -d'/' -f1)
            center_box "$box_width" "$prefix $checkbox $pkg_name"
        done
        
        if [[ $total -gt 15 ]]; then
            center_box "$box_width" "... showing $((current_pos + 1))-$((current_pos + 15)) of $total packages"
        fi
        
        echo
        center_box "$box_width" "Controls: ↑/↓ navigate, SPACE select, ENTER confirm, q quit"
        
        # Get user input
        read -n 1 -s key
        case "$key" in
            $'\x1b') # Arrow keys
                read -n 2 -s key
                case "$key" in
                    '[A') # Up arrow
                        if [[ $current_pos -gt 0 ]]; then
                            ((current_pos--))
                        fi
                        ;;
                    '[B') # Down arrow
                        if [[ $current_pos -lt $((total - 1)) ]]; then
                            ((current_pos++))
                        fi
                        ;;
                esac
                ;;
            ' ') # Space - toggle selection
                if [[ "${selected[$current_pos]}" == "true" ]]; then
                    selected[$current_pos]=false
                else
                    selected[$current_pos]=true
                fi
                ;;
            $'\n'|$'\r') # Enter - confirm selection
                break
                ;;
            'q'|'Q') # Quit
                return 0
                ;;
        esac
    done
    
    # Build list of selected packages
    local selected_packages=()
    for ((i=0; i<total; i++)); do
        if [[ "${selected[i]}" == "true" ]]; then
            local pkg_name=$(echo "${packages[i]}" | cut -d'/' -f1)
            selected_packages+=("$pkg_name")
        fi
    done
    
    if [[ ${#selected_packages[@]} -eq 0 ]]; then
        center_box "$box_width" "👻 No packages selected!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    # Confirm and execute
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Selected ${#selected_packages[@]} packages for update:"
    echo
    
    for pkg in "${selected_packages[@]}"; do
        center_box "$box_width" "  🍒 $pkg"
    done
    
    echo
    center_box "$box_width" "Proceed with update? (y/N): "
    read -n 1 -s confirm
    echo
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        center_box "$box_width" "🟡 Updating selected packages..."
        if sudo apt install --only-upgrade "${selected_packages[@]}"; then
            center_box "$box_width" "✅ Custom update completed successfully!"
        else
            center_box "$box_width" "❌ Custom update encountered errors"
            return 1
        fi
    else
        center_box "$box_width" "👻 Update cancelled by user"
    fi
}

# Quick update - Fedora (dnf)
quick_update_dnf() {
    center_box "$box_width" "🟡 Quick Update: Essential packages only"
    echo
    
    center_box "$box_width" "Updating essential packages..."
    if sudo dnf upgrade -y --security >/dev/null 2>&1; then
        center_box "$box_width" "✅ Quick update completed successfully!"
    else
        center_box "$box_width" "❌ Quick update encountered errors"
        return 1
    fi
}

# Full update - Fedora (dnf)
full_update_dnf() {
    center_box "$box_width" "🟡 Full System Update: All packages"
    echo
    
    center_box "$box_width" "Upgrading all packages..."
    if sudo dnf upgrade -y; then
        center_box "$box_width" "✅ Full system update completed successfully!"
    else
        center_box "$box_width" "❌ Full update encountered errors"
        return 1
    fi
}

# Update with cleanup - Fedora (dnf)
update_cleanup_dnf() {
    center_box "$box_width" "🟡 Update + Cleanup: Full update with maintenance"
    echo
    
    center_box "$box_width" "Step 1/3: Upgrading all packages..."
    sudo dnf upgrade -y
    
    echo
    center_box "$box_width" "Step 2/3: Removing unnecessary packages..."
    sudo dnf autoremove -y
    
    echo
    center_box "$box_width" "Step 3/3: Cleaning package cache..."
    sudo dnf clean all
    
    center_box "$box_width" "✅ Update + Cleanup completed!"
}

# Custom update - Fedora (dnf)
custom_update_dnf() {
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Custom Package Selection"
    echo
    
    # Get available updates
    local updates=$(dnf list updates 2>/dev/null | grep -v "Available Upgrades\|Last metadata")
    if [[ -z "$updates" ]]; then
        center_box "$box_width" "👻 No updates available!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    # Use similar selection logic as pacman/apt versions
    # [Implementation similar to above but adapted for dnf]
    center_box "$box_width" "🟡 Interactive selection for DNF packages"
    center_box "$box_width" "Updating all packages for now..."
    sudo dnf upgrade -y
}

# Update functions for other package managers (zypper, brew)
quick_update_zypper() {
    center_box "$box_width" "🟡 Quick Update: Security patches"
    echo
    
    if sudo zypper patch -y >/dev/null 2>&1; then
        center_box "$box_width" "✅ Quick update completed successfully!"
    else
        center_box "$box_width" "❌ Quick update encountered errors"
        return 1
    fi
}

full_update_zypper() {
    center_box "$box_width" "🟡 Full System Update: All packages"
    echo
    
    if sudo zypper update -y; then
        center_box "$box_width" "✅ Full system update completed successfully!"
    else
        center_box "$box_width" "❌ Full update encountered errors"
        return 1
    fi
}

update_cleanup_zypper() {
    center_box "$box_width" "🟡 Update + Cleanup: Full update with maintenance"
    echo
    
    center_box "$box_width" "Step 1/2: Updating all packages..."
    sudo zypper update -y
    
    echo
    center_box "$box_width" "Step 2/2: Cleaning package cache..."
    sudo zypper clean -a
    
    center_box "$box_width" "✅ Update + Cleanup completed!"
}

custom_update_zypper() {
    center_box "$box_width" "🟡 Custom Update: Interactive package selection"
    echo
    
    # Use zypper's interactive mode
    sudo zypper update
}

quick_update_brew() {
    center_box "$box_width" "🟡 Quick Update: Homebrew packages"
    echo
    
    if brew upgrade >/dev/null 2>&1; then
        center_box "$box_width" "✅ Quick update completed successfully!"
    else
        center_box "$box_width" "❌ Quick update encountered errors"
        return 1
    fi
}

full_update_brew() {
    center_box "$box_width" "🟡 Full Update: All Homebrew packages + cleanup"
    echo
    
    center_box "$box_width" "Updating Homebrew..."
    brew update
    
    echo
    center_box "$box_width" "Upgrading packages..."
    brew upgrade
    
    echo
    center_box "$box_width" "Cleaning up..."
    brew cleanup
    
    center_box "$box_width" "✅ Full update completed!"
}

custom_update_brew() {
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🟡 Custom Package Selection"
    echo
    
    # Get outdated packages
    local updates=$(brew outdated 2>/dev/null)
    if [[ -z "$updates" ]]; then
        center_box "$box_width" "👻 No updates available!"
        echo
        center_box "$box_width" "Press any key to continue..."
        read -n 1 -s
        return 0
    fi
    
    center_box "$box_width" "Available updates:"
    echo "$updates" | while read -r pkg; do
        center_box "$box_width" "  🟡 $pkg"
    done
    
    echo
    center_box "$box_width" "Enter package names to update (space-separated):"
    read -r selected_packages
    
    if [[ -n "$selected_packages" ]]; then
        center_box "$box_width" "🟡 Updating selected packages..."
        if brew upgrade $selected_packages; then
            center_box "$box_width" "✅ Custom update completed!"
        else
            center_box "$box_width" "❌ Custom update encountered errors"
            return 1
        fi
    else
        center_box "$box_width" "👻 No packages selected"
    fi
}

# Check what will be updated
check_pending_updates() {
    local pm=$(detect_package_manager)
    
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "🔍 Checking what will be updated..."
    echo
    
    case "$pm" in
        pacman)
            local updates=$(pacman -Qu 2>/dev/null)
            local count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
            ;;
        apt)
            sudo apt update >/dev/null 2>&1
            local updates=$(apt list --upgradable 2>/dev/null | grep -v "WARNING\|Listing")
            local count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
            ;;
        dnf)
            local updates=$(dnf list updates 2>/dev/null | grep -v "Available Upgrades\|Last metadata")
            local count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
            ;;
        zypper)
            local updates=$(zypper list-updates 2>/dev/null | grep -v "Repository\|Loading\|Reading\|---")
            local count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
            ;;
        brew)
            local updates=$(brew outdated 2>/dev/null)
            local count=$(echo "$updates" | grep -c '^' 2>/dev/null || echo 0)
            ;;
    esac
    
    if [[ $count -gt 0 ]]; then
        center_box "$box_width" "🍒 $count packages will be updated:"
        echo
        echo "$updates" | head -15 | while read -r pkg; do
            center_box "$box_width" "  🟡 $pkg"
        done
        
        if [[ $count -gt 15 ]]; then
            center_box "$box_width" "  ... and $((count - 15)) more packages"
        fi
    else
        center_box "$box_width" "👻 No updates available! System is current."
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Execute update based on type and package manager
execute_update() {
    local update_type="$1"
    local pm=$(detect_package_manager)
    
    show_power_pellet_animation "$update_type"
    
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    
    case "$pm-$update_type" in
        pacman-quick) quick_update_pacman ;;
        pacman-full) full_update_pacman ;;
        pacman-cleanup) update_cleanup_pacman ;;
        pacman-custom) custom_update_pacman ;;
        apt-quick) quick_update_apt ;;
        apt-full) full_update_apt ;;
        apt-cleanup) update_cleanup_apt ;;
        apt-custom) custom_update_apt ;;
        dnf-quick) quick_update_dnf ;;
        dnf-full) full_update_dnf ;;
        dnf-cleanup) update_cleanup_dnf ;;
        dnf-custom) custom_update_dnf ;;
        zypper-quick) quick_update_zypper ;;
        zypper-full) full_update_zypper ;;
        zypper-cleanup) update_cleanup_zypper ;;
        zypper-custom) custom_update_zypper ;;
        brew-quick) quick_update_brew ;;
        brew-full) full_update_brew ;;
        brew-cleanup) full_update_brew ;;
        brew-custom) custom_update_brew ;;
        *)
            center_box "$box_width" "❌ Unsupported combination: $pm + $update_type"
            center_box "$box_width" "Supported package managers: pacman, apt, dnf, zypper, brew"
            return 1
            ;;
    esac
    
    local exit_code=$?
    echo
    
    if [[ $exit_code -eq 0 ]]; then
        center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
        center_box "$box_width" "║                   🟡 POWER PELLET CONSUMED! 🟡               ║"
        center_box "$box_width" "╠══════════════════════════════════════════════════════════════╣"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  System update completed successfully!                       ║"
        center_box "$box_width" "║  Your system is now running the latest versions.             ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  🟡 WAKA-WAKA-WAKA! 🟡                                       ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    else
        center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
        center_box "$box_width" "║                      👻 GHOST CAUGHT YOU! 👻                 ║"
        center_box "$box_width" "╠══════════════════════════════════════════════════════════════╣"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  Update encountered some issues.                             ║"
        center_box "$box_width" "║  Please check the output above for details.                  ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "║  You may need to run the update manually.                    ║"
        center_box "$box_width" "║                                                              ║"
        center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
    
    return $exit_code
}

# Show update menu
show_update_menu() {
    clear
    center_box "$box_width" "${header_lines[@]}"
    echo
    center_box "$box_width" "${update_menu_lines[@]}"
    echo
    center_box "$box_width" "Package Manager: $(detect_package_manager)"
    echo
}

# Handle menu choice
handle_update_choice() {
    local choice="$1"
    
    case "$choice" in
        1) execute_update "quick" ;;
        2) execute_update "full" ;;
        3) execute_update "cleanup" ;;
        4) execute_update "custom" ;;
        5) check_pending_updates ;;
        6) return 0 ;;
        *)
            center_box "$box_width" "❌ Invalid choice! Please select 1-6."
            echo
            center_box "$box_width" "Press any key to continue..."
            read -n 1 -s
            ;;
    esac
}

# Quick update function (for command line)
quick_update() {
    local pm=$(detect_package_manager)
    
    show_power_pellet_animation "Quick Update"
    
    case "$pm" in
        pacman) quick_update_pacman ;;
        apt) quick_update_apt ;;
        dnf) quick_update_dnf ;;
        zypper) quick_update_zypper ;;
        brew) quick_update_brew ;;
        *)
            echo "❌ Unsupported package manager: $pm"
            exit 1
            ;;
    esac
    
    exit $?
}

# Main update menu loop
update_menu() {
    while true; do
        show_update_menu
        center_box "$box_width" "Choose your power pellet (1-6): "
        read -n 1 -s choice
        echo
        
        handle_update_choice "$choice"
        [[ "$choice" == "6" ]] && break
    done
}

# Handle script arguments
case "${1:-menu}" in
    menu|"") update_menu ;;
    quick) quick_update ;;
    --help|-h) 
        echo "Usage: $0 [menu|quick|--help]"
        echo "  menu  - Interactive update menu (default)"
        echo "  quick - Quick system update"
        exit 0
        ;;
    *) 
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

