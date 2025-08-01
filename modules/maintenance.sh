#!/usr/bin/env bash

# ============== OneClick System Maintenance Module ==============
# Pac-Man themed system maintenance with consistent styling - FIXED VERSION
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
maintenance_header=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                🧹 SYSTEM MAINTENANCE 🧹                      ║"
    "║                 Keep Your System Clean!                      ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

maintenance_menu=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                   MAINTENANCE OPTIONS                        ║"
    "╠══════════════════════════════════════════════════════════════╣"
    "║                                                              ║"
    "║       🟡  1. Quick System Cleanup        🍒                  ║"
    "║                                                              ║"
    "║       🟡  2. Package Cache Management     🟡                 ║"
    "║                                                              ║"
    "║       👻  3. Orphaned Packages Removal   🍒                  ║"
    "║                                                              ║"
    "║       👻  4. Log Files Cleanup           🟡                  ║"
    "║                                                              ║"
    "║       🟡  5. Disk Usage Analysis         👻                  ║"
    "║                                                              ║"
    "║       🟡  6. System Health Check         🍒                  ║"
    "║                                                              ║"
    "║       🟡  7. Complete System Maintenance  🟡                 ║"
    "║                                                              ║"
    "║       🍒  8. Return to Main Menu         👻                  ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Animation frames
maintenance_frames=("🧹" "✨" "🧽" "💫")

# FIXED: Show maintenance animation without cursor jumping
show_maintenance_animation() {
    local duration="$1"
    local message="$2"
    local end_time=$((SECONDS + duration))
    local frame_index=0
    
    # Save cursor position
    tput sc
    
    # Show initial message
    echo
    center_box "$box_width" "$message"
    
    # Animation loop with proper positioning
    local start_line=$(tput lines)
    ((start_line = start_line / 2 + 2))
    
    while [[ $SECONDS -lt $end_time ]]; do
        local frame=${maintenance_frames[$frame_index]}
        
        # Use saved position and clear line
        tput rc
        tput el
        center_box "$box_width" "$frame Working..."
        
        frame_index=$(((frame_index + 1) % ${#maintenance_frames[@]}))
        sleep 0.5
    done
    
    # Clear animation line and move to next line
    tput rc
    tput el
    echo
}

# Simple progress indicator without animation
show_progress() {
    local message="$1"
    echo
    center_box "$box_width" "🔄 $message"
    echo
}

# Quick system cleanup
quick_cleanup() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                  QUICK SYSTEM CLEANUP                        ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🧹 Starting quick system cleanup 🧹"
    echo
    center_box "$box_width" "This will clean temporary files, cache, and logs"
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        local cleaned_space=0
        
        show_progress "Cleaning temporary files..."
        
        # Clean /tmp
        center_box "$box_width" "🧽 Cleaning /tmp directory..."
        local tmp_before=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
        sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
        local tmp_after=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
        cleaned_space=$((cleaned_space + tmp_before - tmp_after))
        
        # Clean user cache
        center_box "$box_width" "🧽 Cleaning user cache..."
        if [[ -d "$HOME/.cache" ]]; then
            local cache_before=$(du -sm "$HOME/.cache" 2>/dev/null | awk '{print $1}' || echo 0)
            find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null || true
            local cache_after=$(du -sm "$HOME/.cache" 2>/dev/null | awk '{print $1}' || echo 0)
            cleaned_space=$((cleaned_space + cache_before - cache_after))
        fi
        
        # Clean package cache (if pacman)
        if command -v pacman &>/dev/null; then
            center_box "$box_width" "🧽 Cleaning package cache..."
            local cache_before=$(du -sm /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}' || echo 0)
            sudo pacman -Sc --noconfirm >/dev/null 2>&1
            local cache_after=$(du -sm /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}' || echo 0)
            cleaned_space=$((cleaned_space + cache_before - cache_after))
        fi
        
        # Clean journal logs
        center_box "$box_width" "🧽 Cleaning old journal logs..."
        sudo journalctl --vacuum-time=2weeks >/dev/null 2>&1 || true
        
        # Clean thumbnail cache
        if [[ -d "$HOME/.thumbnails" ]]; then
            center_box "$box_width" "🧽 Cleaning thumbnail cache..."
            find "$HOME/.thumbnails" -type f -atime +30 -delete 2>/dev/null || true
        fi
        
        echo
        center_box "$box_width" "✅ Quick cleanup completed! 🟡"
        center_box "$box_width" "Approximate space freed: ${cleaned_space}MB"
        
    else
        center_box "$box_width" "Cleanup cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Package cache management
manage_package_cache() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                PACKAGE CACHE MANAGEMENT                      ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    if command -v pacman &>/dev/null; then
        # Show cache information
        show_progress "Analyzing package cache..."
        
        local cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}' || echo "Unknown")
        local cache_files=$(find /var/cache/pacman/pkg -name "*.pkg.tar.*" 2>/dev/null | wc -l || echo 0)
        
        center_box "$box_width" "📦 Package Cache Information 📦"
        echo
        center_box "$box_width" "Cache location: /var/cache/pacman/pkg"
        center_box "$box_width" "Cache size: $cache_size"
        center_box "$box_width" "Cached packages: $cache_files"
        echo
        
        center_box "$box_width" "Cache management options:"
        center_box "$box_width" "1. Remove all cached packages"
        center_box "$box_width" "2. Remove old cached packages"
        center_box "$box_width" "3. Keep only current versions"
        center_box "$box_width" "4. Return to menu"
        echo
        center_box "$box_width" "Choice [1-4]: "
        read -n 1 -s choice
        echo
        
        case $choice in
            1)
                show_progress "Removing all cached packages..."
                sudo pacman -Scc --noconfirm >/dev/null 2>&1
                center_box "$box_width" "✅ All cached packages removed!"
                ;;
            2)
                show_progress "Removing old cached packages..."
                sudo pacman -Sc --noconfirm >/dev/null 2>&1
                center_box "$box_width" "✅ Old cached packages removed!"
                ;;
            3)
                if command -v paccache &>/dev/null; then
                    show_progress "Keeping only current versions..."
                    sudo paccache -r >/dev/null 2>&1
                    center_box "$box_width" "✅ Cache optimized!"
                else
                    center_box "$box_width" "Install 'pacman-contrib' for advanced cache management"
                fi
                ;;
            *)
                return
                ;;
        esac
    else
        center_box "$box_width" "Package cache management is specific to Arch Linux"
        center_box "$box_width" "For other distributions:"
        center_box "$box_width" "• Debian/Ubuntu: apt clean"
        center_box "$box_width" "• Fedora: dnf clean all"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Remove orphaned packages
remove_orphans() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                ORPHANED PACKAGES REMOVAL                     ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    if command -v pacman &>/dev/null; then
        show_progress "Searching for orphaned packages..."
        
        # Find orphaned packages
        local orphans=$(pacman -Qtdq 2>/dev/null)
        
        if [[ -n "$orphans" ]]; then
            local orphan_count=$(echo "$orphans" | wc -l)
            center_box "$box_width" "👻 Found $orphan_count orphaned packages:"
            echo
            
            # Show orphaned packages (limit to 10 for display)
            echo "$orphans" | head -10 | while read -r pkg; do
                center_box "$box_width" "• $pkg"
            done
            
            if [[ $orphan_count -gt 10 ]]; then
                center_box "$box_width" "... and $((orphan_count - 10)) more"
            fi
            
            echo
            center_box "$box_width" "Remove these orphaned packages? [Y/n]: "
            read -n 1 -s confirm
            echo
            
            if [[ "${confirm,,}" != "n" ]]; then
                show_progress "Removing orphaned packages..."
                
                if sudo pacman -Rns $orphans --noconfirm >/dev/null 2>&1; then
                    center_box "$box_width" "✅ Orphaned packages removed! 🟡"
                else
                    center_box "$box_width" "⚠️  Some packages couldn't be removed (dependencies)"
                fi
            else
                center_box "$box_width" "Orphan removal cancelled"
            fi
        else
            center_box "$box_width" "✅ No orphaned packages found! 🟡"
            center_box "$box_width" "Your system is clean!"
        fi
    else
        center_box "$box_width" "Orphan removal is specific to Arch Linux"
        center_box "$box_width" "For other distributions:"
        center_box "$box_width" "• Debian/Ubuntu: apt autoremove"
        center_box "$box_width" "• Fedora: dnf autoremove"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Clean log files
cleanup_logs() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                   LOG FILES CLEANUP                          ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    show_progress "Analyzing log files..."
    
    # Show log information
    local journal_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $7}' || echo "Unknown")
    
    center_box "$box_width" "📋 System Log Information 📋"
    echo
    center_box "$box_width" "Journal size: $journal_size"
    center_box "$box_width" "Log location: /var/log/"
    echo
    
    center_box "$box_width" "Log cleanup options:"
    center_box "$box_width" "1. Clean old journal logs (2 weeks)"
    center_box "$box_width" "2. Limit journal size (100MB)"
    center_box "$box_width" "3. Clean all old logs"
    center_box "$box_width" "4. Return to menu"
    echo
    center_box "$box_width" "Choice [1-4]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            show_progress "Cleaning old journal logs..."
            sudo journalctl --vacuum-time=2weeks >/dev/null 2>&1
            center_box "$box_width" "✅ Old journal logs cleaned!"
            ;;
        2)
            show_progress "Limiting journal size..."
            sudo journalctl --vacuum-size=100M >/dev/null 2>&1
            center_box "$box_width" "✅ Journal size limited to 100MB!"
            ;;
        3)
            show_progress "Cleaning all old logs..."
            
            # Clean various log files
            sudo find /var/log -name "*.log" -type f -mtime +30 -exec truncate -s 0 {} \; 2>/dev/null || true
            sudo find /var/log -name "*.1" -type f -delete 2>/dev/null || true
            sudo find /var/log -name "*.gz" -type f -delete 2>/dev/null || true
            
            center_box "$box_width" "✅ Old log files cleaned!"
            ;;
        *)
            return
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Disk usage analysis
analyze_disk_usage() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                  DISK USAGE ANALYSIS                         ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    show_progress "Analyzing disk usage..."
    
    center_box "$box_width" "💾 Disk Usage Report 💾"
    echo
    
    # Overall disk usage
    center_box "$box_width" "📊 Filesystem Usage:"
    df -h | head -5 | while read -r line; do
        center_box "$box_width" "$line"
    done
    echo
    
    # Largest directories in home
    center_box "$box_width" "📂 Largest directories in $HOME:"
    if [[ -d "$HOME" ]]; then
        du -sh "$HOME"/* 2>/dev/null | sort -hr | head -5 | while read -r size dir; do
            dir_name=$(basename "$dir")
            center_box "$box_width" "$size - $dir_name"
        done
    fi
    echo
    
    # System directories
    center_box "$box_width" "🗂️  System directory sizes:"
    local dirs=("/var" "/usr" "/opt" "/tmp")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            center_box "$box_width" "$size - $dir"
        fi
    done
    echo
    
    # Cache directories
    center_box "$box_width" "🗃️  Cache directory sizes:"
    local cache_dirs=(
        "/var/cache"
        "$HOME/.cache"
        "/var/cache/pacman/pkg"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            local size=$(du -sh "$cache_dir" 2>/dev/null | awk '{print $1}')
            center_box "$box_width" "$size - $cache_dir"
        fi
    done
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# System health check
system_health_check() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                  SYSTEM HEALTH CHECK                         ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    show_progress "Performing system health check..."
    
    center_box "$box_width" "🏥 System Health Report 🏥"
    echo
    
    # Memory usage
    local mem_info=$(free -h | awk 'NR==2{printf "%.1f%% used", $3/$2*100}')
    center_box "$box_width" "💾 Memory: $mem_info"
    
    # CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    center_box "$box_width" "🔥 CPU Load: $cpu_load"
    
    # Disk usage
    local disk_usage=$(df / | awk 'NR==2{printf "%.1f%% used", $3/$2*100}')
    center_box "$box_width" "💿 Root Disk: $disk_usage"
    
    # Uptime
    local uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    center_box "$box_width" "⏰ Uptime: $uptime_info"
    
    echo
    
    # System services status
    center_box "$box_width" "🔧 Critical Services Status:"
    local services=("NetworkManager" "systemd-resolved" "bluetooth")
    for service in "${services[@]}"; do
        if systemctl is-active "$service" &>/dev/null; then
            center_box "$box_width" "✅ $service: Active"
        else
            center_box "$box_width" "❌ $service: Inactive"
        fi
    done
    
    echo
    
    # Failed services
    local failed_services=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    if [[ $failed_services -gt 0 ]]; then
        center_box "$box_width" "⚠️  $failed_services failed services detected"
        center_box "$box_width" "Run 'systemctl --failed' for details"
    else
        center_box "$box_width" "✅ No failed services"
    fi
    
    # Check for system errors
    local recent_errors=$(journalctl -p 3 --since "1 hour ago" --no-pager --quiet 2>/dev/null | wc -l)
    if [[ $recent_errors -gt 0 ]]; then
        center_box "$box_width" "⚠️  $recent_errors recent system errors"
    else
        center_box "$box_width" "✅ No recent system errors"
    fi
    
    # Package system integrity
    if command -v pacman &>/dev/null; then
        center_box "$box_width" "📦 Checking package database integrity..."
        if sudo pacman -Dk >/dev/null 2>&1; then
            center_box "$box_width" "✅ Package database: OK"
        else
            center_box "$box_width" "⚠️  Package database issues detected"
        fi
    fi
    
    echo
    center_box "$box_width" "Health check completed!"
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Complete system maintenance
complete_maintenance() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║              COMPLETE SYSTEM MAINTENANCE                     ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🧹 Complete System Maintenance 🧹"
    echo
    center_box "$box_width" "This will perform all maintenance tasks:"
    center_box "$box_width" "• Clean temporary files and cache"
    center_box "$box_width" "• Remove orphaned packages"
    center_box "$box_width" "• Clean log files"
    center_box "$box_width" "• System health check"
    echo
    center_box "$box_width" "This may take several minutes. Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        local start_time=$(date +%s)
        
        # Step 1: Clean temporary files
        center_box "$box_width" "Step 1/5: Cleaning temporary files..."
        center_box "$box_width" "🧽 Cleaning /tmp and cache directories..."
        sudo find /tmp -type f -atime +3 -delete 2>/dev/null || true
        find "$HOME/.cache" -type f -atime +7 -delete 2>/dev/null || true
        sleep 1
        
        # Step 2: Package cache cleanup
        center_box "$box_width" "Step 2/5: Managing package cache..."
        if command -v pacman &>/dev/null; then
            center_box "$box_width" "🗂️  Cleaning old cached packages..."
            sudo pacman -Sc --noconfirm >/dev/null 2>&1
        fi
        sleep 1
        
        # Step 3: Remove orphans
        center_box "$box_width" "Step 3/5: Removing orphaned packages..."
        if command -v pacman &>/dev/null; then
            local orphans=$(pacman -Qtdq 2>/dev/null)
            if [[ -n "$orphans" ]]; then
                center_box "$box_width" "👻 Removing orphaned packages..."
                sudo pacman -Rns $orphans --noconfirm >/dev/null 2>&1 || true
            else
                center_box "$box_width" "✅ No orphaned packages found"
            fi
        fi
        sleep 1
        
        # Step 4: Clean logs
        center_box "$box_width" "Step 4/5: Cleaning system logs..."
        center_box "$box_width" "📋 Cleaning journal logs..."
        sudo journalctl --vacuum-time=1week >/dev/null 2>&1 || true
        sleep 1
        
        # Step 5: Final system check
        center_box "$box_width" "Step 5/5: Final system verification..."
        center_box "$box_width" "🔍 Running final checks..."
        sleep 1
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo
        center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
        center_box "$box_width" "║                  ✅ MAINTENANCE COMPLETE! ✅                 ║"
        center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
        echo
        center_box "$box_width" "🟡 All maintenance tasks completed successfully! 🟡"
        center_box "$box_width" "Time taken: ${duration} seconds"
        echo
        center_box "$box_width" "Your system is now optimized and clean!"
        center_box "$box_width" "WAKA-WAKA-WAKA! 🟡👻🍒"
        
    else
        center_box "$box_width" "Complete maintenance cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Main system maintenance menu
maintenance_main() {
    while true; do
        clear
        center_box "$box_width" "${maintenance_header[@]}"
        echo
        
        # Maintenance ASCII art
        center_box "$box_width" "    🧹 → ✨ → 🟡"
        center_box "$box_width" " System Cleaning Station"
        echo
        
        center_box "$box_width" "${maintenance_menu[@]}"
        echo
        
        # Show system stats
        local mem_usage=$(free 2>/dev/null | awk 'NR==2{printf "%.0f%%", $3/$2*100}' || echo "N/A")
        local disk_usage=$(df / 2>/dev/null | awk 'NR==2{printf "%.0f%%", $3/$2*100}' || echo "N/A")
        local uptime_info=$(uptime -p 2>/dev/null | cut -d' ' -f2-4 || echo "N/A")
        center_box "$box_width" "Memory: ${mem_usage} | Disk: ${disk_usage} | Uptime: ${uptime_info}"
        echo
        center_box "$box_width" "Choose your maintenance task (1-8): "
        read -n 1 -s choice
        echo
        
        case $choice in
            1) quick_cleanup ;;
            2) manage_package_cache ;;
            3) remove_orphans ;;
            4) cleanup_logs ;;
            5) analyze_disk_usage ;;
            6) system_health_check ;;
            7) complete_maintenance ;;
            8) return 0 ;;
            *)
                center_box "$box_width" "❌ Invalid choice! Please select 1-8."
                echo
                center_box "$box_width" "Press any key to continue..."
                read -n 1 -s
                ;;
        esac
    done
}

# Handle execution modes
case "$1" in
    "menu"|"") maintenance_main ;;
    "quick") quick_cleanup ;;
    "cache") manage_package_cache ;;
    "orphans") remove_orphans ;;
    "logs") cleanup_logs ;;
    "disk") analyze_disk_usage ;;
    "health") system_health_check ;;
    "complete") complete_maintenance ;;
    *) echo "Maintenance Module - Usage: $0 [menu|quick|cache|orphans|logs|disk|health|complete]" ;;
esac

