#!/usr/bin/env bash

# ============== OneClick Shell Configuration Module ==============
# Pac-Man themed shell configuration with consistent styling
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
shell_header=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                🐚 SHELL CONFIGURATION 🐚                     ║"
    "║                  Power-Up Your Shell!                       ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

shell_menu=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                     SHELL OPTIONS                            ║"
    "╠══════════════════════════════════════════════════════════════╣"
    "║                                                              ║"
    "║       🟡  1. Install/Setup Zsh + Oh My Zsh   🍒             ║"
    "║                                                              ║"
    "║       🟡  2. Configure Bash with Enhancements 🟡            ║"
    "║                                                              ║"
    "║       👻  3. Install Fish Shell              🍒             ║"
    "║                                                              ║"
    "║       👻  4. Setup Shell Aliases & Functions 🟡             ║"
    "║                                                              ║"
    "║       🟡  5. Install Powerline/Starship      👻             ║"
    "║                                                              ║"
    "║       🍒  6. Return to Main Menu             🟡             ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Animation frames
shell_frames=("🐚" "🟡" "👻" "🍒")

# Show shell animation
show_shell_animation() {
    local duration="$1"
    local message="$2"
    local end_time=$((SECONDS + duration))
    local frame_index=0
    
    while [[ $SECONDS -lt $end_time ]]; do
        local frame=${shell_frames[$frame_index]}
        center_box "$box_width" "$frame $message"
        frame_index=$(((frame_index + 1) % ${#shell_frames[@]}))
        sleep 0.4
        tput cup $(($(tput lines) / 2)) 0
        tput el
    done
}

# Install Zsh and Oh My Zsh
install_zsh_setup() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                  ZSH INSTALLATION                           ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 Installing Zsh + Oh My Zsh + plugins 🟡"
    echo
    center_box "$box_width" "This will install and configure a powerful Zsh setup"
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        # Install Zsh
        if ! command -v zsh &>/dev/null; then
            center_box "$box_width" "Installing Zsh..."
            if command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm zsh
            elif command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y zsh
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y zsh
            fi
        else
            center_box "$box_width" "✅ Zsh already installed"
        fi
        
        # Install Oh My Zsh
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            show_shell_animation 3 "Installing Oh My Zsh..."
            echo
            center_box "$box_width" "Downloading Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            center_box "$box_width" "✅ Oh My Zsh already installed"
        fi
        
        # Install popular plugins
        local zsh_custom="$HOME/.oh-my-zsh/custom"
        
        # zsh-autosuggestions
        if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
            center_box "$box_width" "Installing zsh-autosuggestions..."
            git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
        fi
        
        # zsh-syntax-highlighting
        if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
            center_box "$box_width" "Installing zsh-syntax-highlighting..."
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/plugins/zsh-syntax-highlighting"
        fi
        
        # Configure .zshrc
        center_box "$box_width" "Configuring .zshrc with optimizations..."
        
        # Backup existing .zshrc
        [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        
        # Create optimized .zshrc
        cat > "$HOME/.zshrc" << 'EOF'
# OneClick CLI Optimized Zsh Configuration
# Pac-Man Edition 🟡

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# Plugins
plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    command-not-found
    colored-man-pages
    extract
    z
)

source $ZSH/oh-my-zsh.sh

# OneClick CLI Configuration
export PATH="$HOME/OneClick:$PATH"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Pac-Man themed aliases
alias chomp='sudo pacman -S'
alias nom='sudo pacman -R'
alias hungry='sudo pacman -Syu'
alias waka='echo "🟡 WAKA-WAKA-WAKA! 🟡"'

# System aliases
alias sysinfo='neofetch 2>/dev/null || screenfetch 2>/dev/null || echo "System: $(uname -a)"'
alias ports='netstat -tuln'
alias meminfo='free -m -l -t'

# Custom functions
pac-search() {
    pacman -Ss "$1"
}

extract-here() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted!" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# Enable autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,underline"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS

# Welcome message
echo "🟡 Zsh powered by OneClick CLI! Ready to WAKA-WAKA! 🟡"
EOF
        
        echo
        center_box "$box_width" "✅ Zsh setup completed successfully! 🟡"
        center_box "$box_width" "Run 'chsh -s /bin/zsh' to make it default"
        
    else
        center_box "$box_width" "Zsh setup cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Configure Bash with enhancements
configure_bash() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                 BASH ENHANCEMENT                            ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 Enhancing Bash with useful configurations 🟡"
    echo
    center_box "$box_width" "This will add aliases, functions, and optimizations"
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        # Backup existing .bashrc
        [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
        
        show_shell_animation 2 "Configuring Bash..."
        echo
        
        # Add enhancements to .bashrc
        cat >> "$HOME/.bashrc" << 'EOF'

# ==================================================
# OneClick CLI Bash Enhancements - Pac-Man Edition
# ==================================================

# Better history
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Better completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Colored prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enhanced aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Pac-Man themed aliases
alias chomp='sudo pacman -S'
alias nom='sudo pacman -R'
alias hungry='sudo pacman -Syu'
alias pellets='pacman -Q | wc -l'
alias waka='echo "🟡 WAKA-WAKA-WAKA! 🟡"'

# Useful functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

weather() {
    curl -s "wttr.in/$1"
}

sysinfo() {
    echo "🟡 System Information 🟡"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
}

# Welcome message
echo "🟡 Bash enhanced by OneClick CLI! 🟡"

# ==================================================
EOF
        
        # Source the new configuration
        source "$HOME/.bashrc"
        
        center_box "$box_width" "✅ Bash enhancement completed! 🟡"
        
    else
        center_box "$box_width" "Bash enhancement cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Install Fish Shell
install_fish_shell() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                  FISH SHELL SETUP                           ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🐟 Installing Fish Shell - The friendly shell 🐟"
    echo
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        # Install Fish
        if ! command -v fish &>/dev/null; then
            show_shell_animation 3 "Installing Fish Shell..."
            echo
            if command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm fish
            elif command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y fish
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y fish
            fi
        else
            center_box "$box_width" "✅ Fish shell already installed"
        fi
        
        # Configure Fish
        mkdir -p "$HOME/.config/fish"
        
        cat > "$HOME/.config/fish/config.fish" << 'EOF'
# OneClick CLI Fish Configuration
# Pac-Man Edition 🟡

# Set PATH
set -gx PATH $HOME/OneClick $PATH

# Aliases
alias ll 'ls -alF'
alias la 'ls -A'
alias l 'ls -CF'
alias .. 'cd ..'
alias ... 'cd ../..'
alias grep 'grep --color=auto'

# Pac-Man themed aliases
alias chomp 'sudo pacman -S'
alias nom 'sudo pacman -R'
alias hungry 'sudo pacman -Syu'
alias waka 'echo "🟡 WAKA-WAKA-WAKA! 🟡"'

# Functions
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

function backup
    cp $argv[1] $argv[1].backup.(date +%Y%m%d_%H%M%S)
end

# Welcome message
echo "🐟 Fish shell powered by OneClick CLI! 🟡"
EOF
        
        center_box "$box_width" "✅ Fish shell setup completed! 🐟"
        center_box "$box_width" "Run 'chsh -s /usr/bin/fish' to make it default"
        
    else
        center_box "$box_width" "Fish installation cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Setup shell aliases and functions
setup_aliases_functions() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║              ALIASES & FUNCTIONS SETUP                      ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 Setting up useful aliases and functions 🟡"
    echo
    center_box "$box_width" "This will create ~/.shell_aliases for all shells"
    center_box "$box_width" "Continue? [Y/n]: "
    read -n 1 -s confirm
    echo
    
    if [[ "${confirm,,}" != "n" ]]; then
        show_shell_animation 2 "Creating alias collection..."
        echo
        
        cat > "$HOME/.shell_aliases" << 'EOF'
#!/bin/bash
# OneClick CLI Universal Aliases and Functions
# Compatible with Bash, Zsh, and Fish

# System navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# List files
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lh='ls -lah --color=auto'
alias tree='tree -C'

# System monitoring
alias htop='htop -C'
alias iotop='sudo iotop'
alias iftop='sudo iftop'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -E'

# Network
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias ports='netstat -tuln'
alias openports='ss -tuln'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Archive operations
alias tarxz='tar -xf'
alias tarcz='tar -czf'
alias tarxzv='tar -xzf'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Pac-Man themed system management
alias chomp='sudo pacman -S'
alias nom='sudo pacman -R'
alias hungry='sudo pacman -Syu'
alias pellets='pacman -Q | wc -l'
alias ghost='sudo pacman -Rns'
alias power-pellet='sudo pacman -Scc'
alias waka='echo "🟡 WAKA-WAKA-WAKA! 🟡"'

# OneClick CLI shortcuts
alias oc='oneclick-cli'
alias ochelp='oneclick-cli --help'
alias occheck='oneclick-cli --check'
alias ocupdate='oneclick-cli --update'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backup created: $1.backup.$(date +%Y%m%d_%H%M%S)"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted!" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

sysinfo() {
    echo "🟡 System Information 🟡"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}' 2>/dev/null || echo 'N/A')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}' 2>/dev/null || echo 'N/A')"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}' 2>/dev/null || echo 'N/A')"
}

weather() {
    curl -s "wttr.in/$1" 2>/dev/null || echo "Weather service unavailable"
}

myip() {
    echo "Local IP: $(hostname -I | awk '{print $1}' 2>/dev/null || echo 'N/A')"
    echo "Public IP: $(curl -s ifconfig.me 2>/dev/null || echo 'N/A')"
}

# Directory shortcuts
alias projects='cd ~/Projects 2>/dev/null || cd ~'
alias downloads='cd ~/Downloads 2>/dev/null || cd ~'
alias documents='cd ~/Documents 2>/dev/null || cd ~'

echo "🟡 OneClick CLI aliases loaded! Use 'waka' for fun! 🟡"
EOF
        
        # Add sourcing to shell configs
        for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [[ -f "$shell_config" ]]; then
                if ! grep -q "\.shell_aliases" "$shell_config"; then
                    echo "" >> "$shell_config"
                    echo "# Source OneClick CLI aliases" >> "$shell_config"
                    echo "[[ -f ~/.shell_aliases ]] && source ~/.shell_aliases" >> "$shell_config"
                fi
            fi
        done
        
        center_box "$box_width" "✅ Aliases and functions setup completed! 🟡"
        center_box "$box_width" "Source your shell config or restart terminal"
        
    else
        center_box "$box_width" "Aliases setup cancelled"
    fi
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Install Powerline/Starship
install_powerline_starship() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║              POWERLINE/STARSHIP SETUP                       ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "Choose your shell prompt enhancement:"
    echo
    center_box "$box_width" "1. Starship (Rust-based, fast, modern)"
    center_box "$box_width" "2. Powerline (Python-based, classic)"
    center_box "$box_width" "3. Cancel"
    echo
    center_box "$box_width" "Choice [1-3]: "
    read -n 1 -s choice
    echo
    
    case $choice in
        1)
            # Install Starship
            show_shell_animation 3 "Installing Starship prompt..."
            echo
            
            if ! command -v starship &>/dev/null; then
                center_box "$box_width" "Downloading Starship..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            else
                center_box "$box_width" "✅ Starship already installed"
            fi
            
            # Configure Starship
            mkdir -p "$HOME/.config"
            cat > "$HOME/.config/starship.toml" << 'EOF'
# OneClick CLI Starship Configuration
# Pac-Man Edition 🟡

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$package\
$nodejs\
$python\
$rust\
$java\
$character"""

[character]
success_symbol = "[🟡](bold green)"
error_symbol = "[👻](bold red)"

[directory]
style = "bold blue"
truncation_length = 3

[git_branch]
symbol = "🍒 "
style = "bold purple"

[package]
symbol = "📦 "

[nodejs]
symbol = "⬢ "

[python]
symbol = "🐍 "

[rust]
symbol = "🦀 "

[java]
symbol = "☕ "
EOF
            
            # Add to shell configs
            for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
                if [[ -f "$shell_config" ]]; then
                    if ! grep -q "starship init" "$shell_config"; then
                        echo 'eval "$(starship init bash)"' >> "$shell_config"
                    fi
                fi
            done
            
            center_box "$box_width" "✅ Starship setup completed! 🟡"
            ;;
        2)
            # Install Powerline
            show_shell_animation 3 "Installing Powerline..."
            echo
            
            if command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm python-pip powerline powerline-fonts
            elif command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y python3-pip powerline fonts-powerline
            fi
            
            pip3 install --user powerline-status
            
            center_box "$box_width" "✅ Powerline setup completed! 🟡"
            ;;
        *)
            center_box "$box_width" "Setup cancelled"
            ;;
    esac
    
    echo
    center_box "$box_width" "Press any key to continue..."
    read -n 1 -s
}

# Main shell configuration menu
shell_config_main() {
    while true; do
        clear
        center_box "$box_width" "${shell_header[@]}"
        echo
        
        # Shell ASCII art
        center_box "$box_width" "    🐚 → 🟡 → 💻"
        center_box "$box_width" " Shell Power-Up Station"
        echo
        
        center_box "$box_width" "${shell_menu[@]}"
        echo
        center_box "$box_width" "Current shell: $SHELL"
        echo
        center_box "$box_width" "Choose your power-up (1-6): "
        read -n 1 -s choice
        echo
        
        case $choice in
            1) install_zsh_setup ;;
            2) configure_bash ;;
            3) install_fish_shell ;;
            4) setup_aliases_functions ;;
            5) install_powerline_starship ;;
            6) return 0 ;;
            *)
                center_box "$box_width" "❌ Invalid choice! Please select 1-6."
                echo
                center_box "$box_width" "Press any key to continue..."
                read -n 1 -s
                ;;
        esac
    done
}

# Handle execution modes
case "$1" in
    "menu"|"") shell_config_main ;;
    "zsh") install_zsh_setup ;;
    "bash") configure_bash ;;
    "fish") install_fish_shell ;;
    "aliases") setup_aliases_functions ;;
    "prompt") install_powerline_starship ;;
    *) echo "Shell Configuration Module - Usage: $0 [menu|zsh|bash|fish|aliases|prompt]" ;;
esac

