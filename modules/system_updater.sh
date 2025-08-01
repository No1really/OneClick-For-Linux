#!/usr/bin/env bash

box_width=66

center_box() {
    local w=$1; shift
    local termw=$(tput cols)
    local left=$(( (termw - w) / 2 ))
    [ $left -lt 0 ] && left=0
    for line in "$@"; do
        printf "%*s%s\n" "$left" "" "$line"
    done
}

system_updater_main() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                    SYSTEM UPDATER                            ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 System Updater Module Running! 🟡"
    center_box "$box_width" "Ready to chomp those updates!"
    echo
    
    if command -v pacman &>/dev/null; then
        center_box "$box_width" "Would you like to run 'sudo pacman -Syu'? [Y/n]:"
        read -n 1 -s confirm
        echo
        if [[ "${confirm,,}" != "n" ]]; then
            echo
            center_box "$box_width" "Running system update..."
            sudo pacman -Syu
        fi
    else
        center_box "$box_width" "Non-Arch system detected"
        center_box "$box_width" "Manual update commands may be needed"
    fi
    
    echo
    center_box "$box_width" "Press any key to return..."
    read -n 1 -s
}

case "$1" in
    "menu"|"quick"|"") system_updater_main ;;
esac

