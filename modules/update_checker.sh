#!/usr/bin/env bash

# ============== OneClick Update Checker Module ==============
# Pac-Man themed update checker with consistent styling
# Author: OCD Arch User (Kolkata, India)

# Box styling configuration
box_width=66

# Center text function
center_box() {
    local w=$1; shift
    local termw=$(tput cols)
    local left=$(( (termw - w) / 2 ))
    [ $left -lt 0 ] && left=0
    for line in "$@"; do
        printf "%*s%s\n" "$left" "" "$line"
    done
}

# UI Components
check_update_lines=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                🔍 SYSTEM UPDATE CHECKER 🔍                   ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

result_lines_ok=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║           Your system is fully up to date! 🟡🍒             ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

result_lines_updates=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║         Updates available! Chomp those packets! 👻          ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Show update checker animation
show_update_checker_box() {
    clear
    center_box "$box_width" "${check_update_lines[@]}"
    echo
    center_box "$box_width" "Pac-Man is scanning for pellets (updates)..."
    echo
    
    # Animation frames
    local frames=("◐" "◓" "◑" "◒")
    for i in {1..8}; do
        local frame=${frames[$((i % 4))]}
        center_box "$box_width" "$frame Chomping through package databases..."
        sleep 0.3
        tput cup $(($(tput lines) / 2 + 2)) 0
        tput el
    done
}

# Show update results
show_update_result_box() {
    local updates="$1"
    
    if [[ "$updates" -eq 0 ]]; then
        center_box "$box_width" "${result_lines_ok[@]}"
        echo
        center_box "$box_width" "You're ready to WAKA-WAKA! 🟡"
    else
        center_box "$box_width" "${result_lines_updates[@]}"
        echo
        center_box "$box_width" "Run your system update to power up!"
        center_box "$box_width" "Total updates available: $updates"
        echo
        center_box "$box_width" "🟡 Packages waiting to be chomped! 🟡"
    fi
}

# Get update count based on system
get_update_count() {
    local updates=0
    
    # Arch Linux
    if command -v checkupdates &>/dev/null; then
        updates=$(checkupdates 2>/dev/null | wc -l)
    # Debian/Ubuntu
    elif command -v apt &>/dev/null; then
        updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    # Fedora/RHEL
    elif command -v dnf &>/dev/null; then
        updates=$(dnf check-update -q 2>/dev/null | grep -cE '^[a-zA-Z0-9]' || echo 0)
    # Fallback
    else
        updates=0
    fi
    
    echo "$updates"
}

# Main update checker function
update_checker_main() {
    show_update_checker_box
    
    local updates
    updates=$(get_update_count)
    
    show_update_result_box "$updates"
    echo
    center_box "$box_width" "Press any key to return to main menu..."
    read -n 1 -s
}

# Handle execution mode
case "$1" in
    "menu"|"")
        update_checker_main
        ;;
    *)
        echo "Update Checker Module"
        echo "Usage: $0 [menu]"
        ;;
esac

