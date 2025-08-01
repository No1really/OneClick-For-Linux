#!/usr/bin/env bash

# ============== OneClick System Configuration Module ==============
# Pac-Man themed system configuration with consistent styling
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
config_header=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                ⚙️  SYSTEM CONFIGURATION ⚙️                   ║"
    "║                   Tune Your System!                         ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

config_menu=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                   CONFIGURATION OPTIONS                      ║"
    "╠══════════════════════════════════════════════════════════════╣"
    "║                                                              ║"
    "║       🟡  1. Pacman Configuration & Mirrors  🍒             ║"
    "║                                                              ║"
    "║       🟡  2. Install/Configure AUR Helper    🟡             ║"
    "║                                                              ║"
    "║       👻  3. Network Configuration           🍒             ║"
    "║                                                              ║"
    "║       👻  4. Audio System (PulseAudio/Pipewire) 🟡         ║"
    "║                                                              ║"
    "║       🟡  5. System Services Management      👻             ║"
    "║                                                              ║"
    "║       🟡  6. Performance Tuning             🍒             ║"
    "║                                                              ║"
    "║       🍒  7. Return to Main Menu            🟡             ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Animation frames
config_frames=("⚙️" "🔧" "🛠️" "⚡")

# Show configuration animation
show_config_animation() {
    local duration="$1"
    local message="$2"
    local end_time=$((SECONDS + duration))
    local frame_index=0
    
    while [[ $SECONDS -lt $end_time ]]; do
        local frame=${config_frames[$frame_index]}
        center_box "$box_width" "$frame $message"
        frame_index=$(((frame_index + 1) % ${#config_frames[@]}))
        sleep 0.4
        tput cup $(($(tput lines) / 2)) 0
        tput el
    done
}

# Configure Pacman and mirrors
configure_pacman() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                 PACMAN CONFIGURATION                        ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 Optimizing Pacman configuration 🟡"
    echo
    center_box "$box_width" "This will:"
    center_box "$box_width" "• Enable parallel downloads"
    center_box "$box_width" "• Add color output"
    center_box "$box_width" "• Optimize mirror list"
    echo
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        # Backup pacman.conf
        sudo cp /etc/pacman.conf /etc/pacman.conf.backup
        
        show_config_animation 2 "Configuring Pacman..."
        echo
        
        # Enable parallel downloads and other optimizations
        sudo sed -i 's/#Color/Color/' /etc/pacman.conf
        sudo sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
        sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
        
        # Add ILoveCandy for Pac-Man progress bar
        if ! grep -q "ILoveCandy" /etc/pacman.conf; then
            sudo sed -i '/^#Color/a ILoveCandy' /etc/pacman.conf
        fi
        
        center_box "$box_width" "✅ Pacman configuration updated!"
        echo
        
        # Ask about mirror optimization
        center_box "$box_width" "Optimize mirror list with reflector? [Y/n]: "
        read -n 1 -s mirror_confirm
        echo
        
        if [[ "${mirror_confirm,,}" != "n" ]]; then
            if ! command -v reflector &>/dev/null; then
                center_box "$box_width" "Installing reflector..."
                sudo pacman -S --noconfirm reflector
            fi
            
            # Backup current mirrorlist
            sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
            
            show_config_animation 3 "Optimizing mirrors..."
            echo
            center_box "$box_width" "Generating optimized mirrorlist..."
            
            # Generate new mirrorlist
            sudo reflector --save /etc/pacman.d/mirrorlist \
                --protocol https \
                --country "United States,Germany,France,Netherlands,Canada" \
                --latest 20 \
                --sort rate \
                --age 12
            
            center_box "$box_width" "✅ Mirror list optimized!"
        fi
        
    else
        center_box "$box_width" "Pacman configuration cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Install and configure AUR helper
configure_aur_helper() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                   AUR HELPER SETUP                          ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    # Check for existing AUR helpers
    local existing_helper=""
    if command -v yay &>/dev/null; then
        existing_helper="yay"
    elif command -v paru &>/dev/null; then
        existing_helper="paru"
    elif command -v trizen &>/dev/null; then
        existing_helper="trizen"
    fi
    
    if [[ -n "$existing_helper" ]]; then
        center_box "$box_width" "✅ AUR helper already installed: $existing_helper"
        echo
        center_box "$box_width" "Configure $existing_helper? [Y/n]: "
        read -n 1 -s config_confirm
        echo
        
        if [[ "${config_confirm,,}" != "n" ]]; then
            case "$existing_helper" in
                "yay")
                    center_box "$box_width" "Configuring yay..."
                    yay --save --answerclean All --answerdiff None --answeredit None --answerupgrade None
                    center_box "$box_width" "✅ Yay configured for automatic operation"
                    ;;
                "paru")
                    center_box "$box_width" "Configuring paru..."
                    # Create paru config if it doesn't exist
                    mkdir -p ~/.config/paru
                    cat > ~/.config/paru/paru.conf << 'EOF'
[options]
BottomUp
SudoLoop
NewsOnUpgrade
EOF
                    center_box "$box_width" "✅ Paru configured"
                    ;;
            esac
        fi
    else
        center_box "$box_width" "🟡 Installing AUR helper 🟡"
        echo
        center_box "$box_width" "Choose AUR helper:"
        center_box "$box_width" "1. yay (recommended)"
        center_box "$box_width" "2. paru (rust-based)"
        center_box "$box_width" "3. Cancel"
        echo
        center_box "$box_width" "Choice [1-3]: "
        read -n 1 -s choice
        echo
        
        case $choice in
            1)
                show_config_animation 3 "Installing yay..."
                echo
                
                # Install prerequisites
                sudo pacman -S --needed --noconfirm base-devel git
                
                # Clone and install yay
                cd /tmp
                git clone https://aur.archlinux.org/yay.git
                cd yay
                makepkg -si --noconfirm
                cd ~
                
                # Configure yay
                yay --save --answerclean All --answerdiff None --answeredit None --answerupgrade None
                
                center_box "$box_width" "✅ Yay installed and configured! 🟡"
                ;;
            2)
                show_config_animation 3 "Installing paru..."
                echo
                
                # Install prerequisites
                sudo pacman -S --needed --noconfirm base-devel git
                
                # Clone and install paru
                cd /tmp
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si --noconfirm
                cd ~
                
                # Configure paru
                mkdir -p ~/.config/paru
                cat > ~/.config/paru/paru.conf << 'EOF'
[options]
BottomUp
SudoLoop
NewsOnUpgrade
EOF
                
                center_box "$box_width" "✅ Paru installed and configured! 🟡"
                ;;
            *)
                center_box "$box_width" "Installation cancelled"
                ;;
        esac
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Configure network
configure_network() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                NETWORK CONFIGURATION                        ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🌐 Network Configuration Options 🌐"
    echo
    center_box "$box_width" "1. Configure NetworkManager"
    center_box "$box_width" "2. Install and configure UFW firewall"
    center_box "$box_width" "3. Network diagnostics"
    center_box "$box_width" "4. Return to previous menu"
    echo
    center_box "$box_width" "Choice [1-4]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            show_config_animation 2 "Configuring NetworkManager..."
            echo
            
            # Install NetworkManager if not present
            if ! command -v nmcli &>/dev/null; then
                center_box "$box_width" "Installing NetworkManager..."
                sudo pacman -S --noconfirm networkmanager
            fi
            
            # Enable and start NetworkManager
            sudo systemctl enable NetworkManager
            sudo systemctl start NetworkManager
            
            center_box "$box_width" "✅ NetworkManager enabled and started!"
            center_box "$box_width" "Use 'nmtui' for text interface or 'nmcli' for CLI"
            ;;
        2)
            show_config_animation 2 "Setting up UFW firewall..."
            echo
            
            # Install UFW
            if ! command -v ufw &>/dev/null; then
                center_box "$box_width" "Installing UFW..."
                sudo pacman -S --noconfirm ufw
            fi
            
            # Configure UFW
            center_box "$box_width" "Configuring UFW with safe defaults..."
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw enable
            
            center_box "$box_width" "✅ UFW firewall enabled with secure defaults!"
            ;;
        3)
            center_box "$box_width" "🔍 Network Diagnostics 🔍"
            echo
            center_box "$box_width" "Interface information:"
            ip addr show | grep -E "(inet |inet6 )" | head -5
            echo
            center_box "$box_width" "Testing connectivity..."
            if ping -c 3 8.8.8.8 &>/dev/null; then
                center_box "$box_width" "✅ Internet connectivity: OK"
            else
                center_box "$box_width" "❌ Internet connectivity: FAILED"
            fi
            ;;
        *)
            return
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Configure audio system
configure_audio() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                 AUDIO CONFIGURATION                         ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🔊 Audio System Configuration 🔊"
    echo
    center_box "$box_width" "1. Install and configure PipeWire"
    center_box "$box_width" "2. Configure PulseAudio (legacy)"
    center_box "$box_width" "3. Audio troubleshooting"
    center_box "$box_width" "4. Return to previous menu"
    echo
    center_box "$box_width" "Choice [1-4]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            show_config_animation 3 "Installing PipeWire..."
            echo
            
            center_box "$box_width" "Installing PipeWire audio system..."
            sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
            
            # Enable PipeWire services
            systemctl --user enable pipewire.service
            systemctl --user enable pipewire-pulse.service
            systemctl --user enable wireplumber.service
            
            center_box "$box_width" "✅ PipeWire installed and configured!"
            center_box "$box_width" "Reboot or restart session to activate"
            ;;
        2)
            show_config_animation 2 "Configuring PulseAudio..."
            echo
            
            if ! command -v pulseaudio &>/dev/null; then
                center_box "$box_width" "Installing PulseAudio..."
                sudo pacman -S --noconfirm pulseaudio pulseaudio-alsa
            fi
            
            center_box "$box_width" "✅ PulseAudio configured!"
            ;;
        3)
            center_box "$box_width" "🔍 Audio Diagnostics 🔍"
            echo
            center_box "$box_width" "Audio system information:"
            if command -v pactl &>/dev/null; then
                center_box "$box_width" "PulseAudio/PipeWire status:"
                pactl info | head -3
            else
                center_box "$box_width" "No PulseAudio/PipeWire detected"
            fi
            echo
            center_box "$box_width" "Audio devices:"
            aplay -l 2>/dev/null | head -5 || center_box "$box_width" "No audio devices found"
            ;;
        *)
            return
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Manage system services
manage_services() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                 SERVICES MANAGEMENT                         ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "⚡ System Services Management ⚡"
    echo
    center_box "$box_width" "1. View running services"
    center_box "$box_width" "2. Enable common services"
    center_box "$box_width" "3. Disable unnecessary services"
    center_box "$box_width" "4. Service diagnostics"
    center_box "$box_width" "5. Return to previous menu"
    echo
    center_box "$box_width" "Choice [1-5]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            center_box "$box_width" "🔍 Running Services 🔍"
            echo
            systemctl list-units --type=service --state=running | head -20
            ;;
        2)
            show_config_animation 2 "Enabling common services..."
            echo
            
            local services=("NetworkManager" "bluetooth" "cups" "firewalld")
            for service in "${services[@]}"; do
                if systemctl list-unit-files | grep -q "$service"; then
                    center_box "$box_width" "Enabling $service..."
                    sudo systemctl enable "$service" 2>/dev/null || true
                fi
            done
            center_box "$box_width" "✅ Common services enabled!"
            ;;
        3)
            center_box "$box_width" "⚠️  Service cleanup requires manual review"
            center_box "$box_width" "Use 'systemctl list-unit-files --state=enabled' to review"
            ;;
        4)
            center_box "$box_width" "🔍 Service Diagnostics 🔍"
            echo
            center_box "$box_width" "Failed services:"
            systemctl list-units --failed | head -10
            ;;
        *)
            return
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Performance tuning
performance_tuning() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                PERFORMANCE TUNING                           ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🚀 System Performance Tuning 🚀"
    echo
    center_box "$box_width" "1. Optimize system swappiness"
    center_box "$box_width" "2. Configure CPU governor"
    center_box "$box_width" "3. Setup zram compression"
    center_box "$box_width" "4. Disk I/O optimizations"
    center_box "$box_width" "5. Return to previous menu"
    echo
    center_box "$box_width" "Choice [1-5]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            show_config_animation 2 "Optimizing swappiness..."
            echo
            
            center_box "$box_width" "Current swappiness: $(cat /proc/sys/vm/swappiness)"
            center_box "$box_width" "Setting swappiness to 10 (recommended for desktop)..."
            
            echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
            sudo sysctl vm.swappiness=10
            
            center_box "$box_width" "✅ Swappiness optimized!"
            ;;
        2)
            center_box "$box_width" "CPU governor configuration:"
            echo
            if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
                center_box "$box_width" "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
                center_box "$box_width" "Available governors:"
                cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
            else
                center_box "$box_width" "CPU frequency scaling not available"
            fi
            ;;
        3)
            show_config_animation 2 "Setting up zram..."
            echo
            
            if ! command -v zramctl &>/dev/null; then
                center_box "$box_width" "Installing zram-generator..."
                sudo pacman -S --noconfirm zram-generator
            fi
            
            center_box "$box_width" "✅ Zram compression configured!"
            ;;
        4)
            center_box "$box_width" "🔍 Disk I/O Information 🔍"
            echo
            center_box "$box_width" "Current I/O schedulers:"
            for disk in /sys/block/sd*; do
                if [[ -f "$disk/queue/scheduler" ]]; then
                    echo "$(basename $disk): $(cat $disk/queue/scheduler)"
                fi
            done 2>/dev/null | head -5
            ;;
        *)
            return
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Main system configuration menu
system_config_main() {
    while true; do
        clear
        center_box "$box_width" "${config_header[@]}"
        echo
        
        # System ASCII art
        center_box "$box_width" "    ⚙️ → 🟡 → 🚀"
        center_box "$box_width" " System Tuning Station"
        echo
        
        center_box "$box_width" "${config_menu[@]}"
        echo
        center_box "$box_width" "System: $(uname -r) | Load: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')"
        echo
        center_box "$box_width" "Choose your configuration (1-7): "
        read -n 1 -s choice
        echo
        
        case $choice in
            1) configure_pacman ;;
            2) configure_aur_helper ;;
            3) configure_network ;;
            4) configure_audio ;;
            5) manage_services ;;
            6) performance_tuning ;;
            7) return 0 ;;
            *)
                center_box "$box_width" "❌ Invalid choice! Please select 1-7."
                echo
                center_box "$box_width" "Press any key to continue..."
                read -n 1 -s
                ;;
        esac
    done
}

# Handle execution modes
case "$1" in
    "menu"|"") system_config_main ;;
    "pacman") configure_pacman ;;
    "aur") configure_aur_helper ;;
    "network") configure_network ;;
    "audio") configure_audio ;;
    "services") manage_services ;;
    "performance") performance_tuning ;;
    *) echo "System Configuration Module - Usage: $0 [menu|pacman|aur|network|audio|services|performance]" ;;
esac

