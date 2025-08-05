#!/usr/bin/env bash

# HEADER
VERSION="1.0"
BOX_WIDTH=66

center_box() {
    local w=$1; shift
    local termw
    termw=$(tput cols 2>/dev/null || echo 80)
    local left=$(( (termw - w) / 2 ))
    [[ $left -lt 0 ]] && left=0
    for line in "$@"; do
        printf "%*s%s\n" "$left" "" "$line"
    done
}

log_info() { printf "[%s] INFO: %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }
log_error() { printf "[%s] ERROR: %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }
log_success() { printf "[%s] SUCCESS: %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }

# DEP CHECK
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v apt >/dev/null 2>&1; then echo "apt"
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then echo "zypper"
    elif command -v brew >/dev/null 2>&1; then echo "brew"
    else echo "none"; fi
}

detect_fetch_tool() {
    if command -v fastfetch >/dev/null 2>&1; then
        echo "fastfetch"
    elif command -v neofetch >/dev/null 2>&1; then
        echo "neofetch"
    elif command -v zeitfetch >/dev/null 2>&1; then
        echo "zeitfetch"
    else
        echo "none"
    fi
}

detect_terminal() {
    local term_program="${TERM_PROGRAM:-}"
    local term="${TERM:-}"
    local kitty_window_id="${KITTY_WINDOW_ID:-}"
    [[ -n "$kitty_window_id" ]] && { echo "kitty"; return; }
    [[ "$term_program" == "kitty" ]] && { echo "kitty"; return; }
    [[ "$term_program" == "Alacritty" ]] && { echo "alacritty"; return; }
    [[ "$COLORTERM" == "gnome-terminal" ]] && { echo "gnome-terminal"; return; }
    echo "generic"
}

# CONFIG GENERATION - BASH (unchanged from previous version)
configure_bash() {
    [[ -f ~/.bashrc ]] && cp ~/.bashrc ~/.bashrc.backup.$(date +%s)
    
    cat > ~/.bashrc << 'BASH_EOF'
# Disable blinking cursor immediately
echo -ne '\e[2 q'
clear
# Display banner
printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🟡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "          ONECLICK FOR LINUX — THE TERMINAL'S ARCADE\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

# Bash configuration
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend checkwinsize cdspell autocd
export HISTCONTROL=ignoredups:erasedups

# Prompt with Tokyo Night theme
PS1='\[\e[34m\]\u@\h\[\e[0m\] \[\e[36m\]\w\[\e[0m\] \[\e[33m\]❯\[\e[0m\] '

# Color support
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ALIAS DEFINITIONS
alias chomp='_package_install'
alias hungry='_system_update'
alias ghost='_remove_orphans'
alias pellets='_package_count'
alias powerup='_full_system_maintenance'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias proj='cd ~/Projects 2>/dev/null || mkdir -p ~/Projects && cd ~/Projects'
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias desk='cd ~/Desktop'
alias code='cd ~/Code 2>/dev/null || mkdir -p ~/Code && cd ~/Code'
alias home='cd ~'
alias -- -='cd -'
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -alFh'
alias la='ls -A'
alias lt='ls -lth'
alias l='ls -CF'
alias lsize='ls -lSrh'
alias ldot='ls -ld .*'
alias sizes='du -sh * 2>/dev/null | sort -hr | head -15'
alias tree='command -v tree >/dev/null && tree -C || find . -type d | head -20'
alias hunt='_find_files'
alias nuke='_secure_delete'
alias backup='_create_backup'
alias extract='_extract_archive'
alias pack='_create_archive'
alias clone='_git_clone_cd'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git stash'
alias gfp='git fetch --prune'
alias gb='git branch'
alias gm='git merge'
alias gr='git remote -v'
alias sysinfo='_system_info'
alias myip='_network_info'
alias topcpu='ps aux --sort=-%cpu | head -15'
alias topmem='ps aux --sort=-%mem | head -15'
alias ports='ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null'
alias ping-test='ping -c 4 8.8.8.8'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias weather='curl -s wttr.in 2>/dev/null || echo "Weather service unavailable"'
alias cheat='_cheat_sheet'
alias help='_show_help'
alias oc-help='_show_help'
alias och='_show_help'
alias aliases='_show_help'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias mount='mount | column -t'
alias path='echo $PATH | tr ":" "\n" | nl'
alias now='date +"%T"'
alias nowtime='now'
alias nowdate='date +"%d-%m-%Y"'
alias h='history | tail -20'
alias hgrep='history | grep'
alias j='jobs -l'
alias vi='vim'
alias edit='${EDITOR:-vi}'
alias c='clear'
alias cls='clear'
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ln='ln -iv'
alias wget='wget -c'
alias curl='curl -L'
alias df='df -h'
alias du='du -ch'
alias free='free -h'
alias meminfo='cat /proc/meminfo | head -10'
alias cpuinfo='lscpu'
alias diskinfo='lsblk'
alias netinfo='ip addr show'
alias ps='ps aux'
alias psg='ps aux | grep -v grep | grep -i'
alias top='command -v htop >/dev/null && htop || top'
alias process='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20'
alias myprocess='ps -f -u $USER'
alias cpu='cat /proc/cpuinfo | head -20'
alias temp='sensors 2>/dev/null || echo "lm-sensors not installed"'
alias battery='acpi 2>/dev/null || upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null || echo "Battery info unavailable"'
alias left='ls -t -1 | head -10'
alias right='ls -t -1 | tail -10'
alias count='find . -type f | wc -l'
alias usage='du -h --max-depth=1 2>/dev/null | sort -hr'
alias biggest='find . -type f -exec ls -lS {} + 2>/dev/null | head -10'
alias oldest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | head -10'
alias newest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -10'
alias emptydirs='find . -type d -empty 2>/dev/null'
alias brokenlinks='find . -type l ! -exec test -e {} \; -print 2>/dev/null'
alias runlevel='systemctl get-default'
alias services='systemctl list-units --type=service --state=running'
alias failed='systemctl --failed'
alias logs='journalctl -f'

# CUSTOM FUNCTIONS (same as before)
waka() { 
    echo "WAKA-WAKA-WAKA! OneClick CLI - Your terminal arcade is ready!"
    echo "Type 'help' or 'och' to see all 70+ power-ups available!"
}

_package_install() {
    [[ $# -eq 0 ]] && { echo "Usage: chomp <package1> [package2]..."; return 1; }
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman) sudo pacman -S --needed "$@" ;;
        apt) sudo apt update && sudo apt install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
        brew) brew install "$@" ;;
        *) echo "❌ No supported package manager found!"; return 1 ;;
    esac
}

_system_update() {
    local pm=$(detect_package_manager)
    echo "🔄 Updating system packages..."
    case "$pm" in
        pacman) sudo pacman -Syu ;;
        apt) sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y ;;
        dnf) sudo dnf upgrade -y && sudo dnf autoremove -y ;;
        zypper) sudo zypper update -y && sudo zypper clean -a ;;
        brew) brew update && brew upgrade && brew cleanup ;;
        *) echo "❌ No supported package manager found!"; return 1 ;;
    esac
    echo "✅ System updated successfully!"
}

_remove_orphans() {
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman)
            local orphans=$(pacman -Qtdq 2>/dev/null)
            if [[ -n "$orphans" ]]; then
                echo "🗑️ Removing orphaned packages..."
                sudo pacman -Rns --noconfirm $orphans
                echo "✅ Orphans removed!"
            else
                echo "✨ No orphaned packages found!"
            fi
            ;;
        apt)
            echo "🗑️ Cleaning system packages..."
            sudo apt autoremove -y && sudo apt autoclean
            echo "✅ System cleaned!"
            ;;
        dnf|zypper)
            echo "🗑️ Cleaning system packages..."
            [[ "$pm" == "dnf" ]] && sudo dnf autoremove -y && sudo dnf clean all
            [[ "$pm" == "zypper" ]] && sudo zypper clean -a
            echo "✅ System cleaned!"
            ;;
        *) echo "❌ No supported package manager found!" ;;
    esac
}

_package_count() {
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman) pacman -Q | wc -l ;;
        apt) dpkg -l | grep -c '^ii' ;;
        dnf|zypper) rpm -qa | wc -l ;;
        brew) brew list | wc -l ;;
        *) echo "Unable to count packages" ;;
    esac
}

_find_files() {
    [[ $# -eq 0 ]] && { echo "Usage: hunt <pattern>"; return 1; }
    echo "🔍 Searching for: $1"
    if command -v fd >/dev/null; then
        fd -H -I "$1" 2>/dev/null | head -25
    elif command -v find >/dev/null; then
        find . -type f -iname "*$1*" 2>/dev/null | head -25
    else
        echo "❌ No search tool available"
    fi
}

_secure_delete() {
    [[ $# -eq 0 ]] && { echo "Usage: nuke <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    echo "💥 Securely deleting: $1"
    read -r -p "Are you sure? [y/N] " confirm
    [[ "${confirm,,}" =~ ^y ]] || { echo "🛡️ Deletion cancelled"; return; }
    if command -v shred >/dev/null; then
        shred -vfz -n 3 "$1" && echo "✅ File obliterated!"
    else
        rm -f "$1" && echo "✅ File deleted!"
    fi
}

_create_backup() {
    [[ $# -eq 0 ]] && { echo "Usage: backup <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    local backup_name="$1.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$backup_name" && echo "💾 Backup created: $backup_name"
}

_extract_archive() {
    [[ $# -eq 0 ]] && { echo "Usage: extract <archive>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    local file="$1"
    local ext="${file##*.}"
    case "${ext,,}" in
        tar.bz2|tbz2) tar xjf "$file" ;;
        tar.gz|tgz) tar xzf "$file" ;;
        tar.xz|txz) tar xJf "$file" ;;
        tar) tar xf "$file" ;;
        bz2) bunzip2 "$file" ;;
        gz) gunzip "$file" ;;
        zip) unzip "$file" ;;
        7z) command -v 7z >/dev/null && 7z x "$file" || echo "7z not installed" ;;
        rar) command -v unrar >/dev/null && unrar x "$file" || echo "unrar not installed" ;;
        *) echo "❌ Unsupported archive format: $ext" ;;
    esac && echo "✅ Extracted: $file"
}

_system_info() {
    if command -v fastfetch >/dev/null; then
        fastfetch
    elif command -v neofetch >/dev/null; then
        neofetch
    elif command -v zeitfetch >/dev/null; then
        zeitfetch
    else
        echo "╭─ System Information ─────────────────────────────────────╮"
        echo "│ System: $(uname -srm)"
        echo "│ Shell:  $(basename "$SHELL") ($BASH_VERSION)"
        echo "│ User:   $USER@$(hostname)"
        echo "│ Date:   $(date '+%Y-%m-%d %H:%M:%S')"
        if command -v free >/dev/null; then
            echo "│ Memory: $(free -h | awk '/^Mem:/{print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
        fi
        if command -v df >/dev/null; then
            echo "│ Disk:   $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
        fi
        echo "╰──────────────────────────────────────────────────────────╯"
    fi
}

_network_info() {
    echo "╭─ Network Information ────────────────────────────────────╮"
    local local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A')
    local public_ip=$(timeout 3 curl -s ifconfig.me 2>/dev/null || echo 'N/A')
    echo "│ Local IP:  $local_ip"
    echo "│ Public IP: $public_ip"
    echo "│ Hostname:  $(hostname)"
    if command -v nmcli >/dev/null 2>&1; then
        local wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        [[ -n "$wifi" ]] && echo "│ WiFi:      $wifi"
    fi
    echo "╰──────────────────────────────────────────────────────────╯"
}

_show_help() {
    local help_content='
ONECLICK CLI - COMPREHENSIVE HELP SYSTEM
========================================

PACKAGE MANAGEMENT
------------------
chomp <pkg>      Install packages across all distros
hungry           Update entire system + cleanup  
ghost            Remove orphaned/unused packages
pellets          Count installed packages
powerup          Full system maintenance routine

NAVIGATION & DIRECTORIES
------------------------
..               Go up one directory
...              Go up two directories  
....             Go up three directories
.....            Go up four directories
proj             Go to ~/Projects (create if needed)
dl               Go to ~/Downloads
docs             Go to ~/Documents  
desk             Go to ~/Desktop
code             Go to ~/Code (create if needed)
home             Go to home directory
-                Go to previous directory

FILE OPERATIONS & LISTING
-------------------------
ls               Colorized directory listing
ll               Detailed list with human sizes
la               Show all files including hidden
lt               List by modification time
lsize            List by file size
ldot             List only dotfiles
sizes            Show largest files/dirs (top 15)
tree             Directory tree or fallback listing
hunt <pattern>   Find files by name pattern
count            Count files in current directory
usage            Directory disk usage summary
biggest          Find largest files
oldest           Find oldest files  
newest           Find newest files
emptydirs        Find empty directories
brokenlinks      Find broken symbolic links

FILE MANAGEMENT
---------------
nuke <file>      Securely delete file with confirmation
backup <file>    Create timestamped backup
extract <arch>   Extract any archive format
pack <files>     Create archive (future feature)
cp               Copy with confirmation
mv               Move with confirmation  
rm               Remove with confirmation
mkdir            Create directory with parents
rmdir            Remove directory verbosely

GIT VERSION CONTROL
-------------------
clone <url>      Git clone and cd into directory
gs               git status  
ga               git add
gaa              git add --all
gc               git commit
gcm <msg>        git commit with message
gp               git push
gl               git pull
gd               git diff
glog             git log with graph
gco <branch>     git checkout
gcb <branch>     git checkout new branch
gst              git stash
gfp              git fetch --prune
gb               git branch
gm               git merge
gr               git remote -v

SYSTEM MONITORING & INFO
------------------------
sysinfo          System info (fastfetch/neofetch/basic)
myip             Network information with IPs
topcpu           Top CPU consuming processes
topmem           Top memory consuming processes  
process          Detailed process information
myprocess        Current user processes
ports            Show listening network ports
temp             CPU/system temperatures
battery          Battery status information
meminfo          Detailed memory information
cpuinfo          CPU information
diskinfo         Disk/storage information
netinfo          Network interfaces
df               Disk space usage
du               Directory usage
free             Memory usage summary

SYSTEM SERVICES & LOGS
----------------------
runlevel         Current system target/runlevel
services         Running system services
failed           Failed system services
logs             Follow system journal logs

NETWORK & CONNECTIVITY
----------------------
ping-test        Test internet connectivity
speedtest        Internet speed test
weather          Weather information
wget             Resume-capable download
curl             HTTP client with redirects

UTILITIES & SHORTCUTS
--------------------
waka             OneClick welcome message
help             This comprehensive help (VIM)
oc-help          Alias for help
och              Short alias for help  
aliases          Alias for help
h                Recent command history
hgrep <term>     Search command history
j                List active jobs
c/cls            Clear screen
now              Current time
nowtime          Current time
nowdate          Current date
path             Show PATH variable formatted
vi               Vim editor
edit             Default editor
cheat <topic>    Quick reference (future feature)
left             Newest files (top 10)
right            Oldest files (top 10)

SEARCH & FILTERS
----------------
grep             Colorized pattern matching
fgrep            Fixed string grep
egrep            Extended regex grep  
psg <term>       Search running processes
hgrep <term>     Search command history

POWER USER FEATURES
-------------------
mount            Show mounted filesystems formatted
Usage Examples:
  chomp firefox vim git     # Install multiple packages
  hunt "*.log"              # Find all log files
  backup important.txt      # Create timestamped backup
  extract archive.tar.gz    # Extract any archive
  glog --since="1 week"     # Git log from last week
  topcpu | head -5          # Top 5 CPU processes

TIPS & TRICKS
-------------
• All commands work across Bash, Zsh, and Fish shells
• Package management works on Arch, Debian, Fedora, openSUSE
• Use Tab completion with most commands
• Commands gracefully fall back when tools are missing
• Type any help trigger (help/oc-help/och) to see this guide
• Most aliases have built-in error handling and confirmations

VERSION: OneClick CLI v1.0 - 70+ productivity boosters active!
'

    if command -v vim >/dev/null; then
        echo "$help_content" | vim -R -c 'set ft=help' -c 'set nomodifiable' -c 'noremap q :q!' -c 'noremap <Space> <C-f>' -c 'noremap b <C-b>' -
    elif command -v less >/dev/null; then
        echo "$help_content" | less
    else
        echo "$help_content" | more
    fi
}

# ROTATOR - Welcome message with rotating tips
_oneclick_welcome() {
    local tips=(
        "💡 Pro tip: Use 'help/och' to browse all 70+ power-ups in VIM!"
        "🚀 Speed tip: 'proj' creates & enters ~/Projects instantly"  
        "🎯 Power tip: 'ghost' removes orphaned packages automatically"
        "🔍 Search tip: 'hunt pattern' finds files across your system"
        "🆘 Help tip: All help triggers open full guide in VIM"
        "📦 Package tip: 'chomp' works on ALL Linux distributions"
        "🧹 Clean tip: 'hungry' does full system update + cleanup"
        "⚡ Git tip: 'glog' shows beautiful commit graph"
        "📊 Info tip: 'sysinfo' auto-detects best system info tool"
        "🌐 Network tip: 'myip' shows local + public IP with details"
        "🗂️ File tip: 'sizes' shows largest files sorted by size"
        "⏰ Time tip: 'now/nowdate' for quick timestamps"
        "🔧 System tip: 'services' shows all running system services"
        "💾 Backup tip: 'backup file.txt' creates timestamped copies"
        "🎮 Fun tip: 'waka' for OneClick CLI welcome message!"
    )
    local tip_index=$((RANDOM % ${#tips[@]}))
    printf "%s\n\n" "${tips[$tip_index]}"
}

# WELCOME - System info and welcome
_system_startup() {
    _system_info
    echo
    _oneclick_welcome
}

# Execute welcome sequence
_system_startup

detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v apt >/dev/null 2>&1; then echo "apt"  
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then echo "zypper"
    elif command -v brew >/dev/null 2>&1; then echo "brew"
    else echo "none"; fi
}
BASH_EOF

    log_success "Bash configuration with 70+ aliases created"
}

# ZSH CONFIG (same as before - unchanged)
configure_zsh() {
    [[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.backup.$(date +%s)
    
    cat > ~/.zshrc << 'ZSH_EOF'
# Disable blinking cursor immediately
echo -ne '\e[2 q'
clear
# Display banner
printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🟡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "          ONECLICK FOR LINUX — THE TERMINAL'S ARCADE\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

# Zsh configuration
autoload -Uz compinit colors
compinit -d ~/.zcompdump
colors

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=100000
setopt appendhistory sharehistory incappendhistory hist_ignore_dups
setopt hist_ignore_space hist_verify auto_cd correct_all

# Prompt with Tokyo Night theme  
PROMPT='%F{blue}%n@%m%f %F{cyan}%~%f %F{yellow}❯%f '
RPROMPT='%F{green}%*%f'

# Key bindings
bindkey -e
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^R' history-incremental-search-backward

# Load plugins if available
for plugin_file in \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
    [[ -f "$plugin_file" ]] && { source "$plugin_file"; break; }
done

for suggest_file in \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    [[ -f "$suggest_file" ]] && { source "$suggest_file"; break; }
done

# ALIAS DEFINITIONS - Identical to Bash
alias chomp='_package_install'
alias hungry='_system_update'
alias ghost='_remove_orphans'
alias pellets='_package_count'
alias powerup='_full_system_maintenance'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias proj='cd ~/Projects 2>/dev/null || { mkdir -p ~/Projects && cd ~/Projects }'
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias desk='cd ~/Desktop'
alias code='cd ~/Code 2>/dev/null || { mkdir -p ~/Code && cd ~/Code }'
alias home='cd ~'
alias -- -='cd -'
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -alFh'
alias la='ls -A'
alias lt='ls -lth'
alias l='ls -CF'
alias lsize='ls -lSrh'
alias ldot='ls -ld .*'
alias sizes='du -sh * 2>/dev/null | sort -hr | head -15'
alias tree='command -v tree >/dev/null && tree -C || find . -type d | head -20'
alias hunt='_find_files'
alias nuke='_secure_delete'
alias backup='_create_backup'
alias extract='_extract_archive'
alias pack='_create_archive'
alias clone='_git_clone_cd'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git stash'
alias gfp='git fetch --prune'
alias gb='git branch'
alias gm='git merge'
alias gr='git remote -v'
alias sysinfo='_system_info'
alias myip='_network_info'
alias topcpu='ps aux --sort=-%cpu | head -15'
alias topmem='ps aux --sort=-%mem | head -15'
alias ports='ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null'
alias ping-test='ping -c 4 8.8.8.8'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias weather='curl -s wttr.in 2>/dev/null || echo "Weather service unavailable"'
alias cheat='_cheat_sheet'
alias help='_show_help'
alias oc-help='_show_help'
alias och='_show_help'
alias aliases='_show_help'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias mount='mount | column -t'
alias path='echo $PATH | tr ":" "\n" | nl'
alias now='date +"%T"'
alias nowtime='now'
alias nowdate='date +"%d-%m-%Y"'
alias h='history | tail -20'
alias hgrep='history | grep'
alias j='jobs -l'
alias vi='vim'
alias edit='${EDITOR:-vi}'
alias c='clear'
alias cls='clear'
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ln='ln -iv'
alias wget='wget -c'
alias curl='curl -L'
alias df='df -h'
alias du='du -ch'
alias free='free -h'
alias meminfo='cat /proc/meminfo | head -10'
alias cpuinfo='lscpu'
alias diskinfo='lsblk'
alias netinfo='ip addr show'
alias ps='ps aux'
alias psg='ps aux | grep -v grep | grep -i'
alias top='command -v htop >/dev/null && htop || top'
alias process='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20'
alias myprocess='ps -f -u $USER'
alias cpu='cat /proc/cpuinfo | head -20'
alias temp='sensors 2>/dev/null || echo "lm-sensors not installed"'
alias battery='acpi 2>/dev/null || upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null || echo "Battery info unavailable"'
alias left='ls -t -1 | head -10'
alias right='ls -t -1 | tail -10'
alias count='find . -type f | wc -l'
alias usage='du -h --max-depth=1 2>/dev/null | sort -hr'
alias biggest='find . -type f -exec ls -lS {} + 2>/dev/null | head -10'
alias oldest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | head -10'
alias newest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -10'
alias emptydirs='find . -type d -empty 2>/dev/null'
alias brokenlinks='find . -type l ! -exec test -e {} \; -print 2>/dev/null'
alias runlevel='systemctl get-default'
alias services='systemctl list-units --type=service --state=running'
alias failed='systemctl --failed'
alias logs='journalctl -f'

# CUSTOM FUNCTIONS - Same as Bash functions
waka() { 
    echo "WAKA-WAKA-WAKA! OneClick CLI - Your terminal arcade is ready!"
    echo "Type 'help' or 'och' to see all 70+ power-ups available!"
}

_package_install() {
    [[ $# -eq 0 ]] && { echo "Usage: chomp <package1> [package2]..."; return 1; }
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman) sudo pacman -S --needed "$@" ;;
        apt) sudo apt update && sudo apt install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
        brew) brew install "$@" ;;
        *) echo "❌ No supported package manager found!"; return 1 ;;
    esac
}

_system_update() {
    local pm=$(detect_package_manager)
    echo "🔄 Updating system packages..."
    case "$pm" in
        pacman) sudo pacman -Syu ;;
        apt) sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y ;;
        dnf) sudo dnf upgrade -y && sudo dnf autoremove -y ;;
        zypper) sudo zypper update -y && sudo zypper clean -a ;;
        brew) brew update && brew upgrade && brew cleanup ;;
        *) echo "❌ No supported package manager found!"; return 1 ;;
    esac
    echo "✅ System updated successfully!"
}

_remove_orphans() {
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman)
            local orphans=$(pacman -Qtdq 2>/dev/null)
            if [[ -n "$orphans" ]]; then
                echo "🗑️ Removing orphaned packages..."
                sudo pacman -Rns --noconfirm $orphans
                echo "✅ Orphans removed!"
            else
                echo "✨ No orphaned packages found!"
            fi
            ;;
        apt)
            echo "🗑️ Cleaning system packages..."
            sudo apt autoremove -y && sudo apt autoclean
            echo "✅ System cleaned!"
            ;;
        dnf|zypper)
            echo "🗑️ Cleaning system packages..."
            [[ "$pm" == "dnf" ]] && sudo dnf autoremove -y && sudo dnf clean all
            [[ "$pm" == "zypper" ]] && sudo zypper clean -a
            echo "✅ System cleaned!"
            ;;
        *) echo "❌ No supported package manager found!" ;;
    esac
}

_package_count() {
    local pm=$(detect_package_manager)
    case "$pm" in
        pacman) pacman -Q | wc -l ;;
        apt) dpkg -l | grep -c '^ii' ;;
        dnf|zypper) rpm -qa | wc -l ;;
        brew) brew list | wc -l ;;
        *) echo "Unable to count packages" ;;
    esac
}

_find_files() {
    [[ $# -eq 0 ]] && { echo "Usage: hunt <pattern>"; return 1; }
    echo "🔍 Searching for: $1"
    if command -v fd >/dev/null; then
        fd -H -I "$1" 2>/dev/null | head -25
    elif command -v find >/dev/null; then
        find . -type f -iname "*$1*" 2>/dev/null | head -25
    else
        echo "❌ No search tool available"
    fi
}

_secure_delete() {
    [[ $# -eq 0 ]] && { echo "Usage: nuke <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    echo "💥 Securely deleting: $1"
    read -q "confirm?Are you sure? [y/N] "
    echo
    [[ "${confirm,,}" == "y" ]] || { echo "🛡️ Deletion cancelled"; return; }
    if command -v shred >/dev/null; then
        shred -vfz -n 3 "$1" && echo "✅ File obliterated!"
    else
        rm -f "$1" && echo "✅ File deleted!"
    fi
}

_create_backup() {
    [[ $# -eq 0 ]] && { echo "Usage: backup <file>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    local backup_name="$1.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$backup_name" && echo "💾 Backup created: $backup_name"
}

_extract_archive() {
    [[ $# -eq 0 ]] && { echo "Usage: extract <archive>"; return 1; }
    [[ ! -f "$1" ]] && { echo "❌ File not found: $1"; return 1; }
    local file="$1"
    local ext="${file##*.}"
    case "${ext:l}" in
        tar.bz2|tbz2) tar xjf "$file" ;;
        tar.gz|tgz) tar xzf "$file" ;;
        tar.xz|txz) tar xJf "$file" ;;
        tar) tar xf "$file" ;;
        bz2) bunzip2 "$file" ;;
        gz) gunzip "$file" ;;
        zip) unzip "$file" ;;
        7z) command -v 7z >/dev/null && 7z x "$file" || echo "7z not installed" ;;
        rar) command -v unrar >/dev/null && unrar x "$file" || echo "unrar not installed" ;;
        *) echo "❌ Unsupported archive format: $ext" ;;
    esac && echo "✅ Extracted: $file"
}

_system_info() {
    if command -v fastfetch >/dev/null; then
        fastfetch
    elif command -v neofetch >/dev/null; then
        neofetch
    elif command -v zeitfetch >/dev/null; then
        zeitfetch
    else
        echo "╭─ System Information ─────────────────────────────────────╮"
        echo "│ System: $(uname -srm)"
        echo "│ Shell:  $(basename "$SHELL") ($ZSH_VERSION)"
        echo "│ User:   $USER@$(hostname)"
        echo "│ Date:   $(date '+%Y-%m-%d %H:%M:%S')"
        if command -v free >/dev/null; then
            echo "│ Memory: $(free -h | awk '/^Mem:/{print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
        fi
        if command -v df >/dev/null; then
            echo "│ Disk:   $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
        fi
        echo "╰──────────────────────────────────────────────────────────╯"
    fi
}

_network_info() {
    echo "╭─ Network Information ────────────────────────────────────╮"
    local local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A')
    local public_ip=$(timeout 3 curl -s ifconfig.me 2>/dev/null || echo 'N/A')
    echo "│ Local IP:  $local_ip"
    echo "│ Public IP: $public_ip"
    echo "│ Hostname:  $(hostname)"
    if command -v nmcli >/dev/null 2>&1; then
        local wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        [[ -n "$wifi" ]] && echo "│ WiFi:      $wifi"
    fi
    echo "╰──────────────────────────────────────────────────────────╯"
}

_show_help() {
    local help_content='
ONECLICK CLI - COMPREHENSIVE HELP SYSTEM
========================================

PACKAGE MANAGEMENT
------------------
chomp <pkg>      Install packages across all distros
hungry           Update entire system + cleanup  
ghost            Remove orphaned/unused packages
pellets          Count installed packages
powerup          Full system maintenance routine

NAVIGATION & DIRECTORIES
------------------------
..               Go up one directory
...              Go up two directories  
....             Go up three directories
.....            Go up four directories
proj             Go to ~/Projects (create if needed)
dl               Go to ~/Downloads
docs             Go to ~/Documents  
desk             Go to ~/Desktop
code             Go to ~/Code (create if needed)
home             Go to home directory
-                Go to previous directory

FILE OPERATIONS & LISTING
-------------------------
ls               Colorized directory listing
ll               Detailed list with human sizes
la               Show all files including hidden
lt               List by modification time
lsize            List by file size
ldot             List only dotfiles
sizes            Show largest files/dirs (top 15)
tree             Directory tree or fallback listing
hunt <pattern>   Find files by name pattern
count            Count files in current directory
usage            Directory disk usage summary
biggest          Find largest files
oldest           Find oldest files  
newest           Find newest files
emptydirs        Find empty directories
brokenlinks      Find broken symbolic links

FILE MANAGEMENT
---------------
nuke <file>      Securely delete file with confirmation
backup <file>    Create timestamped backup
extract <arch>   Extract any archive format
pack <files>     Create archive (future feature)
cp               Copy with confirmation
mv               Move with confirmation  
rm               Remove with confirmation
mkdir            Create directory with parents
rmdir            Remove directory verbosely

GIT VERSION CONTROL
-------------------
clone <url>      Git clone and cd into directory
gs               git status  
ga               git add
gaa              git add --all
gc               git commit
gcm <msg>        git commit with message
gp               git push
gl               git pull
gd               git diff
glog             git log with graph
gco <branch>     git checkout
gcb <branch>     git checkout new branch
gst              git stash
gfp              git fetch --prune
gb               git branch
gm               git merge
gr               git remote -v

SYSTEM MONITORING & INFO
------------------------
sysinfo          System info (fastfetch/neofetch/basic)
myip             Network information with IPs
topcpu           Top CPU consuming processes
topmem           Top memory consuming processes  
process          Detailed process information
myprocess        Current user processes
ports            Show listening network ports
temp             CPU/system temperatures
battery          Battery status information
meminfo          Detailed memory information
cpuinfo          CPU information
diskinfo         Disk/storage information
netinfo          Network interfaces
df               Disk space usage
du               Directory usage
free             Memory usage summary

SYSTEM SERVICES & LOGS
----------------------
runlevel         Current system target/runlevel
services         Running system services
failed           Failed system services
logs             Follow system journal logs

NETWORK & CONNECTIVITY
----------------------
ping-test        Test internet connectivity
speedtest        Internet speed test
weather          Weather information
wget             Resume-capable download
curl             HTTP client with redirects

UTILITIES & SHORTCUTS
--------------------
waka             OneClick welcome message
help             This comprehensive help (VIM)
oc-help          Alias for help
och              Short alias for help  
aliases          Alias for help
h                Recent command history
hgrep <term>     Search command history
j                List active jobs
c/cls            Clear screen
now              Current time
nowtime          Current time
nowdate          Current date
path             Show PATH variable formatted
vi               Vim editor
edit             Default editor
cheat <topic>    Quick reference (future feature)
left             Newest files (top 10)
right            Oldest files (top 10)

SEARCH & FILTERS
----------------
grep             Colorized pattern matching
fgrep            Fixed string grep
egrep            Extended regex grep  
psg <term>       Search running processes
hgrep <term>     Search command history

POWER USER FEATURES
-------------------
mount            Show mounted filesystems formatted
Usage Examples:
  chomp firefox vim git     # Install multiple packages
  hunt "*.log"              # Find all log files
  backup important.txt      # Create timestamped backup
  extract archive.tar.gz    # Extract any archive
  glog --since="1 week"     # Git log from last week
  topcpu | head -5          # Top 5 CPU processes

TIPS & TRICKS
-------------
• All commands work across Bash, Zsh, and Fish shells
• Package management works on Arch, Debian, Fedora, openSUSE
• Use Tab completion with most commands
• Commands gracefully fall back when tools are missing
• Type any help trigger (help/oc-help/och) to see this guide
• Most aliases have built-in error handling and confirmations

VERSION: OneClick CLI v1.0 - 70+ productivity boosters active!
'

    if command -v vim >/dev/null; then
        echo "$help_content" | vim -R -c 'set ft=help' -c 'set nomodifiable' -c 'noremap q :q!' -c 'noremap <Space> <C-f>' -c 'noremap b <C-b>' -
    elif command -v less >/dev/null; then
        echo "$help_content" | less
    else
        echo "$help_content" | more
    fi
}

# ROTATOR - Welcome message with rotating tips
_oneclick_welcome() {
    local tips=(
        "💡 Pro tip: Use 'help/och' to browse all 70+ power-ups in VIM!"
        "🚀 Speed tip: 'proj' creates & enters ~/Projects instantly"  
        "🎯 Power tip: 'ghost' removes orphaned packages automatically"
        "🔍 Search tip: 'hunt pattern' finds files across your system"
        "🆘 Help tip: All help triggers open full guide in VIM"
        "📦 Package tip: 'chomp' works on ALL Linux distributions"
        "🧹 Clean tip: 'hungry' does full system update + cleanup"
        "⚡ Git tip: 'glog' shows beautiful commit graph"
        "📊 Info tip: 'sysinfo' auto-detects best system info tool"
        "🌐 Network tip: 'myip' shows local + public IP with details"
        "🗂️ File tip: 'sizes' shows largest files sorted by size"
        "⏰ Time tip: 'now/nowdate' for quick timestamps"
        "🔧 System tip: 'services' shows all running system services"
        "💾 Backup tip: 'backup file.txt' creates timestamped copies"
        "🎮 Fun tip: 'waka' for OneClick CLI welcome message!"
    )
    local tip_index=$((RANDOM % ${#tips[@]}))
    printf "%s\n\n" "${tips[$tip_index]}"
}

# WELCOME - System info and welcome
_system_startup() {
    _system_info
    echo
    _oneclick_welcome
}

# Execute welcome sequence
_system_startup

detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v apt >/dev/null 2>&1; then echo "apt"  
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then echo "zypper"
    elif command -v brew >/dev/null 2>&1; then echo "brew"
    else echo "none"; fi
}
ZSH_EOF

    log_success "Zsh configuration with 70+ aliases created"
}

# FISH CONFIG - FIXED FOR PROPER RANDOM TIP SELECTION
configure_fish() {
    mkdir -p ~/.config/fish
    [[ -f ~/.config/fish/config.fish ]] && cp ~/.config/fish/config.fish ~/.config/fish/config.fish.backup.$(date +%s)

    cat > ~/.config/fish/config.fish << 'FISH_EOF'
# Disable blinking cursor immediately
printf '\e[2 q'
clear
# Display banner
printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🟡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "          ONECLICK FOR LINUX — THE TERMINAL'S ARCADE\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

# Fish configuration
set fish_greeting ""
set -g fish_color_command blue
set -g fish_color_param cyan
set -g fish_color_error red
set -g fish_color_end green

# Custom prompt with Tokyo Night theme
function fish_prompt
    set -l user (set_color blue)"$USER"(set_color normal)
    set -l host_name
    if type -q hostname
        set host_name (hostname -s 2>/dev/null)
    else if test -f /etc/hostname
        set host_name (cat /etc/hostname | string trim)
    else
        set host_name "localhost"
    end
    set -l host (set_color blue)"$host_name"(set_color normal)
    set -l dir (set_color cyan)(prompt_pwd)(set_color normal)
    set -l time (set_color green)(date +%T)(set_color normal)
    set -l prompt_symbol "❯"
    if test $status -eq 0
        set prompt_symbol (set_color yellow)"$prompt_symbol"
    else
        set prompt_symbol (set_color red)"$prompt_symbol"
    end
    echo -e "$user@$host $dir $time"
    echo -e -n "$prompt_symbol "(set_color normal)
end

# ALIAS DEFINITIONS - Fish syntax
alias chomp='_package_install'
alias hungry='_system_update'
alias ghost='_remove_orphans'
alias pellets='_package_count'
alias powerup='_full_system_maintenance'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias desk='cd ~/Desktop'
alias home='cd ~'
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -alFh'
alias la='ls -A'
alias lt='ls -lth'
alias l='ls -CF'
alias lsize='ls -lSrh'
alias ldot='ls -ld .*'
alias sizes='du -sh * 2>/dev/null | sort -hr | head -15'
alias tree='command -v tree >/dev/null; and tree -C; or find . -type d | head -20'
alias hunt='_find_files'
alias nuke='_secure_delete'
alias backup='_create_backup'
alias extract='_extract_archive'
alias pack='_create_archive'
alias clone='_git_clone_cd'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git stash'
alias gfp='git fetch --prune'
alias gb='git branch'
alias gm='git merge'
alias gr='git remote -v'
alias sysinfo='_system_info'
alias myip='_network_info'
alias topcpu='ps aux --sort=-%cpu | head -15'
alias topmem='ps aux --sort=-%mem | head -15'
alias ports='ss -tuln 2>/dev/null; or netstat -tuln 2>/dev/null'
alias ping-test='ping -c 4 8.8.8.8'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias weather='curl -s wttr.in 2>/dev/null; or echo "Weather service unavailable"'
alias cheat='_cheat_sheet'
alias help='_show_help'
alias oc-help='_show_help'
alias och='_show_help'
alias aliases='_show_help'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias mount='mount | column -t'
alias path='echo $PATH | tr ":" "\n" | nl'
alias now='date +"%T"'
alias nowtime='now'
alias nowdate='date +"%d-%m-%Y"'
alias h='history | tail -20'
alias hgrep='history | grep'
alias j='jobs'
alias vi='vim'
alias edit='$EDITOR'
alias c='clear'
alias cls='clear'
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias ln='ln -iv'
alias wget='wget -c'
alias curl='curl -L'
alias df='df -h'
alias du='du -ch'
alias free='free -h'
alias meminfo='cat /proc/meminfo | head -10'
alias cpuinfo='lscpu'
alias diskinfo='lsblk'
alias netinfo='ip addr show'
alias ps='ps aux'
alias psg='ps aux | grep -v grep | grep -i'
alias top='command -v htop >/dev/null; and htop; or top' 
alias process='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20'
alias myprocess='ps -f -u $USER'
alias cpu='cat /proc/cpuinfo | head -20'
alias temp='sensors 2>/dev/null; or echo "lm-sensors not installed"'
alias battery='acpi 2>/dev/null; or upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null; or echo "Battery info unavailable"'
alias left='ls -t -1 | head -10'
alias right='ls -t -1 | tail -10'
alias count='find . -type f | wc -l'
alias usage='du -h --max-depth=1 2>/dev/null | sort -hr'
alias biggest='find . -type f -exec ls -lS {} + 2>/dev/null | head -10'
alias oldest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | head -10'
alias newest='find . -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -10'
alias emptydirs='find . -type d -empty 2>/dev/null'
alias brokenlinks='find . -type l ! -exec test -e {} \; -print 2>/dev/null'
alias runlevel='systemctl get-default'
alias services='systemctl list-units --type=service --state=running'
alias failed='systemctl --failed'
alias logs='journalctl -f'

# FUNCTIONS - Fixed for Fish shell
function waka
    echo "WAKA-WAKA-WAKA! OneClick CLI - Your terminal arcade is ready!"
    echo "Type 'help' or 'och' to see all 70+ power-ups available!"
end

function proj
    if test -d ~/Projects
        cd ~/Projects
    else
        mkdir -p ~/Projects
        cd ~/Projects
    end
end

function code
    if test -d ~/Code
        cd ~/Code
    else
        mkdir -p ~/Code
        cd ~/Code
    end
end

function _package_install
    if test (count $argv) -eq 0
        echo "Usage: chomp <package1> [package2]..."
        return 1
    end
    set pm (detect_package_manager)
    switch $pm
        case pacman
            sudo pacman -S --needed $argv
        case apt
            sudo apt update; and sudo apt install -y $argv
        case dnf
            sudo dnf install -y $argv
        case zypper
            sudo zypper install -y $argv
        case brew
            brew install $argv
        case '*'
            echo "❌ No supported package manager found!"
            return 1
    end
end

function _system_update
    set pm (detect_package_manager)
    echo "🔄 Updating system packages..."
    switch $pm
        case pacman
            sudo pacman -Syu
        case apt
            sudo apt update; and sudo apt upgrade -y; and sudo apt autoremove -y
        case dnf
            sudo dnf upgrade -y; and sudo dnf autoremove -y
        case zypper
            sudo zypper update -y; and sudo zypper clean -a
        case brew
            brew update; and brew upgrade; and brew cleanup
        case '*'
            echo "❌ No supported package manager found!"
            return 1
    end
    echo "✅ System updated successfully!"
end

function _remove_orphans
    set pm (detect_package_manager)
    switch $pm
        case pacman
            set orphans (pacman -Qtdq 2>/dev/null)
            if test -n "$orphans"
                echo "🗑️ Removing orphaned packages..."
                sudo pacman -Rns --noconfirm $orphans
                echo "✅ Orphans removed!"
            else
                echo "✨ No orphaned packages found!"
            end
        case apt
            echo "🗑️ Cleaning system packages..."
            sudo apt autoremove -y; and sudo apt autoclean
            echo "✅ System cleaned!"
        case dnf
            echo "🗑️ Cleaning system packages..."
            sudo dnf autoremove -y; and sudo dnf clean all
            echo "✅ System cleaned!"
        case zypper
            echo "🗑️ Cleaning system packages..."
            sudo zypper clean -a
            echo "✅ System cleaned!"
        case '*'
            echo "❌ No supported package manager found!"
    end
end

function _package_count
    set pm (detect_package_manager)
    switch $pm
        case pacman
            pacman -Q | wc -l
        case apt
            dpkg -l | grep -c '^ii'
        case dnf
            rpm -qa | wc -l
        case zypper
            rpm -qa | wc -l
        case brew
            brew list | wc -l
        case '*'
            echo "Unable to count packages"
    end
end

function _find_files
    if test (count $argv) -eq 0
        echo "Usage: hunt <pattern>"
        return 1
    end
    echo "🔍 Searching for: $argv[1]"
    if command -v fd >/dev/null
        fd -H -I "$argv[1]" 2>/dev/null | head -25
    else if command -v find >/dev/null
        find . -type f -iname "*$argv[1]*" 2>/dev/null | head -25
    else
        echo "❌ No search tool available"
    end
end

function _secure_delete
    if test (count $argv) -eq 0
        echo "Usage: nuke <file>"
        return 1
    end
    if not test -f "$argv[1]"
        echo "❌ File not found: $argv[1]"
        return 1
    end
    echo "💥 Securely deleting: $argv[1]"
    read -P "Are you sure? [y/N] " confirm
    if test "$confirm" = "y"; or test "$confirm" = "Y"
        if command -v shred >/dev/null
            shred -vfz -n 3 "$argv[1]"; and echo "✅ File obliterated!"
        else
            rm -f "$argv[1]"; and echo "✅ File deleted!"
        end
    else
        echo "🛡️ Deletion cancelled"
    end
end

function _create_backup
    if test (count $argv) -eq 0
        echo "Usage: backup <file>"
        return 1
    end
    if not test -f "$argv[1]"
        echo "❌ File not found: $argv[1]"
        return 1
    end
    set backup_name "$argv[1].backup."(date +%Y%m%d_%H%M%S)
    cp "$argv[1]" "$backup_name"; and echo "💾 Backup created: $backup_name"
end

function _extract_archive
    if test (count $argv) -eq 0
        echo "Usage: extract <archive>"
        return 1
    end
    if not test -f "$argv[1]"
        echo "❌ File not found: $argv[1]"
        return 1
    end
    set file "$argv[1]"
    set ext (echo $file | awk -F. '{print $NF}')
    switch (string lower $ext)
        case tar.bz2 tbz2
            tar xjf "$file"
        case tar.gz tgz
            tar xzf "$file"
        case tar.xz txz
            tar xJf "$file"
        case tar
            tar xf "$file"
        case bz2
            bunzip2 "$file"
        case gz
            gunzip "$file"
        case zip
            unzip "$file"
        case 7z
            if command -v 7z >/dev/null
                7z x "$file"
            else
                echo "7z not installed"
            end
        case rar
            if command -v unrar >/dev/null
                unrar x "$file"
            else
                echo "unrar not installed"
            end
        case '*'
            echo "❌ Unsupported archive format: $ext"
    end
    and echo "✅ Extracted: $file"
end

function _system_info
    if command -v fastfetch >/dev/null
        fastfetch
    else if command -v neofetch >/dev/null
        neofetch
    else if command -v zeitfetch >/dev/null
        zeitfetch
    else
        echo "╭─ System Information ─────────────────────────────────────╮"
        echo "│ System: "(uname -srm)
        echo "│ Shell:  "(basename $SHELL)" ("$FISH_VERSION")"
        echo "│ User:   $USER@"(hostname)
        echo "│ Date:   "(date '+%Y-%m-%d %H:%M:%S')
        if command -v free >/dev/null
            echo "│ Memory: "(free -h | awk '/^Mem:/{print $3 "/" $2 " (" int($3/$2*100) "%)"}')
        end
        if command -v df >/dev/null
            echo "│ Disk:   "(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')
        end
        echo "╰──────────────────────────────────────────────────────────╯"
    end
end

function _network_info
    echo "╭─ Network Information ────────────────────────────────────╮"
    set local_ip (hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A')
    set public_ip (timeout 3 curl -s ifconfig.me 2>/dev/null || echo 'N/A')
    echo "│ Local IP:  $local_ip"
    echo "│ Public IP: $public_ip"
    echo "│ Hostname:  "(hostname)
    if command -v nmcli >/dev/null
        set wifi (nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        if test -n "$wifi"
            echo "│ WiFi:      $wifi"
        end
    end
    echo "╰──────────────────────────────────────────────────────────╯"
end

function _show_help
    set help_content '
ONECLICK CLI - COMPREHENSIVE HELP SYSTEM
========================================

PACKAGE MANAGEMENT
------------------
chomp <pkg>      Install packages across all distros
hungry           Update entire system + cleanup  
ghost            Remove orphaned/unused packages
pellets          Count installed packages
powerup          Full system maintenance routine

NAVIGATION & DIRECTORIES
------------------------
..               Go up one directory
...              Go up two directories  
....             Go up three directories
.....            Go up four directories
proj             Go to ~/Projects (create if needed)
dl               Go to ~/Downloads
docs             Go to ~/Documents  
desk             Go to ~/Desktop
code             Go to ~/Code (create if needed)
home             Go to home directory
-                Go to previous directory

FILE OPERATIONS & LISTING
-------------------------
ls               Colorized directory listing
ll               Detailed list with human sizes
la               Show all files including hidden
lt               List by modification time
lsize            List by file size
ldot             List only dotfiles
sizes            Show largest files/dirs (top 15)
tree             Directory tree or fallback listing
hunt <pattern>   Find files by name pattern
count            Count files in current directory
usage            Directory disk usage summary
biggest          Find largest files
oldest           Find oldest files  
newest           Find newest files
emptydirs        Find empty directories
brokenlinks      Find broken symbolic links

FILE MANAGEMENT
---------------
nuke <file>      Securely delete file with confirmation
backup <file>    Create timestamped backup
extract <arch>   Extract any archive format
pack <files>     Create archive (future feature)
cp               Copy with confirmation
mv               Move with confirmation  
rm               Remove with confirmation
mkdir            Create directory with parents
rmdir            Remove directory verbosely

GIT VERSION CONTROL
-------------------
clone <url>      Git clone and cd into directory
gs               git status  
ga               git add
gaa              git add --all
gc               git commit
gcm <msg>        git commit with message
gp               git push
gl               git pull
gd               git diff
glog             git log with graph
gco <branch>     git checkout
gcb <branch>     git checkout new branch
gst              git stash
gfp              git fetch --prune
gb               git branch
gm               git merge
gr               git remote -v

SYSTEM MONITORING & INFO
------------------------
sysinfo          System info (fastfetch/neofetch/basic)
myip             Network information with IPs
topcpu           Top CPU consuming processes
topmem           Top memory consuming processes  
process          Detailed process information
myprocess        Current user processes
ports            Show listening network ports
temp             CPU/system temperatures
battery          Battery status information
meminfo          Detailed memory information
cpuinfo          CPU information
diskinfo         Disk/storage information
netinfo          Network interfaces
df               Disk space usage
du               Directory usage
free             Memory usage summary

SYSTEM SERVICES & LOGS
----------------------
runlevel         Current system target/runlevel
services         Running system services
failed           Failed system services
logs             Follow system journal logs

NETWORK & CONNECTIVITY
----------------------
ping-test        Test internet connectivity
speedtest        Internet speed test
weather          Weather information
wget             Resume-capable download
curl             HTTP client with redirects

UTILITIES & SHORTCUTS
--------------------
waka             OneClick welcome message
help             This comprehensive help (VIM)
oc-help          Alias for help
och              Short alias for help  
aliases          Alias for help
h                Recent command history
hgrep <term>     Search command history
j                List active jobs
c/cls            Clear screen
now              Current time
nowtime          Current time
nowdate          Current date
path             Show PATH variable formatted
vi               Vim editor
edit             Default editor
cheat <topic>    Quick reference (future feature)
left             Newest files (top 10)
right            Oldest files (top 10)

SEARCH & FILTERS
----------------
grep             Colorized pattern matching
fgrep            Fixed string grep
egrep            Extended regex grep  
psg <term>       Search running processes
hgrep <term>     Search command history

POWER USER FEATURES
-------------------
mount            Show mounted filesystems formatted
Usage Examples:
  chomp firefox vim git     # Install multiple packages
  hunt "*.log"              # Find all log files
  backup important.txt      # Create timestamped backup
  extract archive.tar.gz    # Extract any archive
  glog --since="1 week"     # Git log from last week
  topcpu | head -5          # Top 5 CPU processes

TIPS & TRICKS
-------------
• All commands work across Bash, Zsh, and Fish shells
• Package management works on Arch, Debian, Fedora, openSUSE
• Use Tab completion with most commands
• Commands gracefully fall back when tools are missing
• Type any help trigger (help/oc-help/och) to see this guide
• Most aliases have built-in error handling and confirmations

VERSION: OneClick CLI v1.0 - 70+ productivity boosters active!
'

    if command -v vim >/dev/null
        echo $help_content | vim -R -c 'set ft=help' -c 'set nomodifiable' -c 'noremap q :q!' -c 'noremap <Space> <C-f>' -c 'noremap b <C-b>' -
    else if command -v less >/dev/null
        echo $help_content | less
    else
        echo $help_content | more
    end
end

# ROTATOR - Welcome message with rotating tips - FIXED FOR FISH
function _oneclick_welcome
    # Define tips as individual variables to avoid array counting issues
    set tip1 "💡 Pro tip: Use 'help/och' to browse all 70+ power-ups in VIM!"
    set tip2 "🚀 Speed tip: 'proj' creates & enters ~/Projects instantly" 
    set tip3 "🎯 Power tip: 'ghost' removes orphaned packages automatically"
    set tip4 "🔍 Search tip: 'hunt pattern' finds files across your system"
    set tip5 "🆘 Help tip: All help triggers open full guide in VIM"
    set tip6 "📦 Package tip: 'chomp' works on ALL Linux distributions"
    set tip7 "🧹 Clean tip: 'hungry' does full system update + cleanup"
    set tip8 "⚡ Git tip: 'glog' shows beautiful commit graph"
    set tip9 "📊 Info tip: 'sysinfo' auto-detects best system info tool"
    set tip10 "🌐 Network tip: 'myip' shows local + public IP with details"
    set tip11 "🗂️ File tip: 'sizes' shows largest files sorted by size"
    set tip12 "⏰ Time tip: 'now/nowdate' for quick timestamps"
    set tip13 "🔧 System tip: 'services' shows all running system services"
    set tip14 "💾 Backup tip: 'backup file.txt' creates timestamped copies"
    set tip15 "🎮 Fun tip: 'waka' for OneClick CLI welcome message!"
    
    # Generate random number between 1-15 using fish's random function
    set random_num (random 1 15)
    
    # Display the selected tip
    switch $random_num
        case 1
            echo $tip1
        case 2
            echo $tip2
        case 3
            echo $tip3
        case 4
            echo $tip4
        case 5
            echo $tip5
        case 6
            echo $tip6
        case 7
            echo $tip7
        case 8
            echo $tip8
        case 9
            echo $tip9
        case 10
            echo $tip10
        case 11
            echo $tip11
        case 12
            echo $tip12
        case 13
            echo $tip13
        case 14
            echo $tip14
        case 15
            echo $tip15
    end
    echo
end

# WELCOME - System info and welcome
function _system_startup
    _system_info
    echo
    _oneclick_welcome
end

# Execute welcome sequence
_system_startup

function detect_package_manager
    if command -v pacman >/dev/null
        echo "pacman"
    else if command -v apt >/dev/null
        echo "apt"
    else if command -v dnf >/dev/null
        echo "dnf"
    else if command -v zypper >/dev/null
        echo "zypper"
    else if command -v brew >/dev/null
        echo "brew"
    else
        echo "none"
    end
end
FISH_EOF

    log_success "Fish configuration with 70+ aliases created"
}

# REST OF SCRIPT (unchanged - terminal theme, animations, menus, etc.)
apply_terminal_theme() {
    local terminal=$(detect_terminal)
    case "$terminal" in
        kitty)
            mkdir -p ~/.config/kitty
            cat > ~/.config/kitty/kitty.conf << 'KITTY_EOF'
# Tokyo Night Theme for Kitty - OneClick CLI
foreground #c0caf5
background #1a1b26
cursor #c0caf5
cursor_shape block
cursor_blink_interval 0

# Black
color0 #15161E
color8 #414868

# Red  
color1 #f7768e
color9 #f7768e

# Green
color2 #9ece6a
color10 #9ece6a

# Yellow
color3 #e0af68
color11 #e0af68

# Blue
color4 #7aa2f7
color12 #7aa2f7

# Magenta
color5 #bb9af7
color13 #bb9af7

# Cyan
color6 #7dcfff
color14 #7dcfff

# White
color7 #a9b1d6
color15 #c0caf5

# Font
font_family JetBrains Mono
font_size 11.0
disable_ligatures never
KITTY_EOF
            log_success "Kitty terminal theme configured"
            ;;
        alacritty)
            mkdir -p ~/.config/alacritty
            cat > ~/.config/alacritty/alacritty.yml << 'ALACRITTY_EOF'
# Tokyo Night Theme for Alacritty - OneClick CLI
colors:
  primary:
    background: '0x1a1b26'
    foreground: '0xc0caf5'
  cursor:
    text: '0x1a1b26'
    cursor: '0xc0caf5'
  normal:
    black: '0x15161e'
    red: '0xf7768e'
    green: '0x9ece6a'
    yellow: '0xe0af68'
    blue: '0x7aa2f7'
    magenta: '0xbb9af7'
    cyan: '0x7dcfff'
    white: '0xa9b1d6'
  bright:
    black: '0x414868'
    red: '0xf7768e'
    green: '0x9ece6a'
    yellow: '0xe0af68'
    blue: '0x7aa2f7'
    magenta: '0xbb9af7'
    cyan: '0x7dcfff'
    white: '0xc0caf5'

cursor:
  style: Block
  blinking: Never

font:
  normal:
    family: JetBrains Mono
    style: Regular
  size: 11.0
ALACRITTY_EOF
            log_success "Alacritty terminal theme configured"
            ;;
        gnome-terminal)
            if command -v gsettings >/dev/null; then
                local profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
                if [[ -n "$profile_id" ]]; then
                    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/ foreground-color '#c0caf5' 2>/dev/null
                    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/ background-color '#1a1b26' 2>/dev/null
                    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/ cursor-blink-mode 'off' 2>/dev/null
                    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/ font 'JetBrains Mono 11' 2>/dev/null
                    log_success "GNOME terminal theme configured"
                fi
            fi
            ;;
        *)
            log_info "Generic terminal detected - basic theming applied in shell configs"
            ;;
    esac
}

show_powerup_animation() {
    local shell_type="$1"
    local frames=("🟡" "⚡" "💥" "🌟" "✨" "🟡")
    clear
    center_box $BOX_WIDTH "Power-up activated! Installing $shell_type"
    echo
    for i in {0..18}; do
        local frame=${frames[$((i % 6))]}
        center_box $BOX_WIDTH "$frame CHOMPING THROUGH DEPENDENCIES... $frame"
        sleep 0.1
        tput cup $(($(tput lines) / 2 + 4)) 0 2>/dev/null
        tput el 2>/dev/null
    done
}

execute_shell_setup() {
    local shell_type="$1"
    show_powerup_animation "$shell_type"
    clear
    center_box $BOX_WIDTH "╔══════════════════════════════════════════════════════════════╗"
    center_box $BOX_WIDTH "║            Setting up $shell_type configuration              ║"
    center_box $BOX_WIDTH "╚══════════════════════════════════════════════════════════════╝"
    echo

    case "$shell_type" in
        "Bash") 
            configure_bash
            apply_terminal_theme
            ;;
        "Zsh") 
            configure_zsh
            apply_terminal_theme
            ;;
        "Fish") 
            configure_fish
            apply_terminal_theme
            ;;
        "All")
            configure_bash
            configure_zsh
            configure_fish
            apply_terminal_theme
            ;;
    esac

    echo
    center_box $BOX_WIDTH "╔══════════════════════════════════════════════════════════════╗"
    center_box $BOX_WIDTH "║                🟡 POWER-UP COMPLETE! 🟡                      ║"
    center_box $BOX_WIDTH "╠══════════════════════════════════════════════════════════════╣"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║     $shell_type configuration completed successfully!        ║"
    center_box $BOX_WIDTH "║         Terminal themed with Tokyo Night colors              ║"
    center_box $BOX_WIDTH "║          70+ productivity aliases ready to use               ║"
    center_box $BOX_WIDTH "║     Welcome message with rotating tips configured            ║"
    center_box $BOX_WIDTH "║           VIM-based help system activated                    ║"
    center_box $BOX_WIDTH "║               No blinking cursor enabled                     ║"
    center_box $BOX_WIDTH "║         Auto-detected system info tool integration           ║"
    center_box $BOX_WIDTH "║         Cross-distribution package management ready          ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║               🟡 WAKA-WAKA-WAKA! LEVEL UP! 🟡                ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "╚══════════════════════════════════════════════════════════════╝"
    echo
    center_box $BOX_WIDTH "🔥 RESTART TERMINAL TO ACTIVATE ALL POWER-UPS! 🔥"
    center_box $BOX_WIDTH "🔥 Type 'help', 'och', or 'oc-help' for full guide! 🔥"
    echo
    center_box $BOX_WIDTH "Press any key to continue..."
    read -n 1 -s
}

show_shell_menu() {
    clear
    center_box $BOX_WIDTH "╔══════════════════════════════════════════════════════════════╗"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║             🟡 SHELL POWER-UP CONFIGURATION 🟡               ║"
    center_box $BOX_WIDTH "║             Transform your terminal experience               ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "╚══════════════════════════════════════════════════════════════╝"
    echo
    center_box $BOX_WIDTH "╔══════════════════════════════════════════════════════════════╗"
    center_box $BOX_WIDTH "║                       SHELL POWER-UPS                        ║"
    center_box $BOX_WIDTH "╠══════════════════════════════════════════════════════════════╣"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🟡 1. Custom Bash + Terminal Theme (STABLE) ⚡         ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🟡 2. Custom Zsh + Terminal Theme (ADVANCED) 🍒        ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🟡 3. Custom Fish + Terminal Theme (MODERN) 👻         ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🟡 4. ALL Shells + Complete Setup (RECOMMENDED) 🍒     ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🟡 5. Show Current Status 👻                           ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "║       🍒 6. Exit 🟡                                          ║"
    center_box $BOX_WIDTH "║                                                              ║"
    center_box $BOX_WIDTH "╚══════════════════════════════════════════════════════════════╝"
    echo
    center_box $BOX_WIDTH "Current Shell: $(basename "$SHELL")"
    center_box $BOX_WIDTH "Terminal: $(detect_terminal)"
    echo
}

show_shell_status() {
    clear
    center_box $BOX_WIDTH "╔══════════════════════════════════════════════════════════════╗"
    center_box $BOX_WIDTH "║                🔍 CURRENT SHELL STATUS 🔍                    ║"
    center_box $BOX_WIDTH "╚══════════════════════════════════════════════════════════════╝"
    echo
    center_box $BOX_WIDTH "Current Shell: $(basename "$SHELL")"
    center_box $BOX_WIDTH "Shell Version: $("$SHELL" --version 2>/dev/null | head -1 || echo 'Unknown')"
    center_box $BOX_WIDTH "Terminal: $(detect_terminal)"
    echo
    
    # Check shell configurations
    if [[ -f ~/.bashrc ]]; then
        if grep -q "ONECLICK FOR LINUX" ~/.bashrc 2>/dev/null; then
            center_box $BOX_WIDTH "✅ Bash configuration: CONFIGURED"
        else
            center_box $BOX_WIDTH "⚠️ Bash configuration: DEFAULT"
        fi
    else
        center_box $BOX_WIDTH "❌ Bash configuration: MISSING"
    fi
    
    if [[ -f ~/.zshrc ]]; then
        if grep -q "ONECLICK FOR LINUX" ~/.zshrc 2>/dev/null; then
            center_box $BOX_WIDTH "✅ Zsh configuration: CONFIGURED"
        else
            center_box $BOX_WIDTH "⚠️ Zsh configuration: DEFAULT"
        fi
    else
        center_box $BOX_WIDTH "❌ Zsh configuration: MISSING"
    fi
    
    if [[ -f ~/.config/fish/config.fish ]]; then
        if grep -q "ONECLICK FOR LINUX" ~/.config/fish/config.fish 2>/dev/null; then
            center_box $BOX_WIDTH "✅ Fish configuration: CONFIGURED"
        else
            center_box $BOX_WIDTH "⚠️ Fish configuration: DEFAULT"
        fi
    else
        center_box $BOX_WIDTH "❌ Fish configuration: MISSING"
    fi
    
    # Check terminal theme
    local terminal=$(detect_terminal)
    case "$terminal" in
        kitty)
            if [[ -f ~/.config/kitty/kitty.conf ]]; then
                if grep -q "Tokyo Night Theme" ~/.config/kitty/kitty.conf 2>/dev/null; then
                    center_box $BOX_WIDTH "✅ Kitty theme: CONFIGURED"
                else
                    center_box $BOX_WIDTH "⚠️ Kitty theme: DEFAULT"
                fi
            else
                center_box $BOX_WIDTH "❌ Kitty theme: NOT CONFIGURED"
            fi
            ;;
        alacritty)
            if [[ -f ~/.config/alacritty/alacritty.yml ]]; then
                if grep -q "Tokyo Night Theme" ~/.config/alacritty/alacritty.yml 2>/dev/null; then
                    center_box $BOX_WIDTH "✅ Alacritty theme: CONFIGURED"
                else
                    center_box $BOX_WIDTH "⚠️ Alacritty theme: DEFAULT"
                fi
            else
                center_box $BOX_WIDTH "❌ Alacritty theme: NOT CONFIGURED"
            fi
            ;;
        gnome-terminal)
            center_box $BOX_WIDTH "✅ GNOME terminal theme: AUTO-CONFIGURED"
            ;;
        *)
            center_box $BOX_WIDTH "⚠️ Terminal theming: Basic support for $terminal"
            ;;
    esac
    
    echo
    center_box $BOX_WIDTH "Available system tools:"
    local fetch_tool=$(detect_fetch_tool)
    if [[ "$fetch_tool" != "none" ]]; then
        center_box $BOX_WIDTH "✅ System info: $fetch_tool"
    else
        center_box $BOX_WIDTH "⚠️ System info: Basic fallback"
    fi
    
    local pm=$(detect_package_manager)
    if [[ "$pm" != "none" ]]; then
        center_box $BOX_WIDTH "✅ Package manager: $pm"
    else
        center_box $BOX_WIDTH "❌ Package manager: Not detected"
    fi
    
    echo
    center_box $BOX_WIDTH "Press any key to return to menu..."
    read -n 1 -s
}

handle_shell_choice() {
    local choice="$1"
    case "$choice" in
        1) execute_shell_setup "Bash" ;;
        2) execute_shell_setup "Zsh" ;;
        3) execute_shell_setup "Fish" ;;
        4) execute_shell_setup "All" ;;
        5) show_shell_status ;;
        6) return 1 ;;
        *)
            center_box $BOX_WIDTH "❌ Invalid choice! Please select 1-6."
            echo
            center_box $BOX_WIDTH "Press any key to continue..."
            read -n 1 -s
            ;;
    esac
}

shell_config_menu() {
    while true; do
        show_shell_menu
        center_box $BOX_WIDTH "Choose your power-up (1-6): "
        read -n 1 -s choice 2>/dev/null
        echo
        handle_shell_choice "$choice"
        [[ "$choice" == "6" ]] && break
    done
}

# HELP HANDLER
show_script_help() {
    cat << 'SCRIPT_HELP_EOF'
OneClick CLI Shell Configuration Script
======================================

USAGE:
  ./shell_config.sh [OPTION]

OPTIONS:
  menu, ""         Interactive shell configuration menu (default)
  bash             Setup Bash configuration only  
  zsh              Setup Zsh configuration only
  fish             Setup Fish configuration only
  all              Setup all shells + terminal theming
  status           Show current shell configuration status
  --help, -h       Show this help message

FEATURES:
✓ 70+ cross-shell productivity aliases
✓ Tokyo Night terminal theming
✓ Auto-detection of system tools (fastfetch/neofetch/zeitfetch)
✓ Cross-distribution package management
✓ VIM-based comprehensive help system
✓ Rotating startup tips
✓ No blinking cursor configuration
✓ Comprehensive error handling
✓ Backup of existing configurations

SUPPORTED SHELLS:
  • Bash (all distributions)
  • Zsh (with optional plugins)
  • Fish (modern shell with advanced features)

SUPPORTED TERMINALS:
  • Kitty (full theming)
  • Alacritty (full theming)  
  • GNOME Terminal (automatic theming)
  • Generic terminals (basic support)

SUPPORTED PACKAGE MANAGERS:
  • pacman (Arch Linux)
  • apt (Debian/Ubuntu)
  • dnf (Fedora)
  • zypper (openSUSE)
  • brew (macOS/Linux)

All configurations are idempotent and safe to run multiple times.
Original configurations are automatically backed up with timestamps.

VERSION: OneClick CLI v1.0
SCRIPT_HELP_EOF
}

# Main execution logic
case "${1:-}" in
    menu|"") shell_config_menu ;;
    bash) execute_shell_setup "Bash" ;;
    zsh) execute_shell_setup "Zsh" ;;
    fish) execute_shell_setup "Fish" ;;
    all) execute_shell_setup "All" ;;
    status) show_shell_status ;;
    --help|-h) show_script_help ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

exit 0

