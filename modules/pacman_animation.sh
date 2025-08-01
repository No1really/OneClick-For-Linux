#!/usr/bin/env bash

# ============== OneClick Pac-Man Animation Module ==============
# Interactive Pac-Man game with full controls - FIXED VERSION
# Author: OCD Arch User (Kolkata, India)

# Box styling configuration
box_width=66

# Game variables
game_running=false
score=0
lives=3
level=1
pacman_x=10
pacman_y=10
ghost_x=50
ghost_y=10
pellets_eaten=0
power_pellet_active=false
power_pellet_timer=0

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

# Game UI Components
game_header=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                🟡 PAC-MAN ARCADE GAME 🟡                     ║"
    "║                   Ready Player One!                         ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

game_menu=(
    "╔══════════════════════════════════════════════════════════════╗"
    "║                      GAME OPTIONS                            ║"
    "╠══════════════════════════════════════════════════════════════╣"
    "║                                                              ║"
    "║       🟡  1. Start New Game              🍒                  ║"
    "║                                                              ║"
    "║       🟡  2. Watch Classic Animation     🟡                  ║"
    "║                                                              ║"
    "║       👻  3. High Scores                 🍒                  ║"
    "║                                                              ║"
    "║       👻  4. Game Instructions           🟡                  ║"
    "║                                                              ║"
    "║       🍒  5. Return to Main Menu         👻                  ║"
    "║                                                              ║"
    "╚══════════════════════════════════════════════════════════════╝"
)

# Initialize terminal for game - FIXED
init_game_terminal() {
    # Save terminal state
    stty -g > /tmp/terminal_state_backup
    
    # Configure terminal for game
    stty -icanon -echo min 0 time 1
    tput civis  # Hide cursor
    tput clear
}

# Restore terminal - FIXED
restore_terminal() {
    # Restore saved terminal state
    if [[ -f /tmp/terminal_state_backup ]]; then
        stty $(cat /tmp/terminal_state_backup)
        rm -f /tmp/terminal_state_backup
    else
        stty sane
    fi
    tput cnorm  # Show cursor
    tput clear
}

# Handle input - FIXED for better responsiveness
handle_input() {
    local input
    # Use timeout read for non-blocking input
    if read -t 0.05 -n 1 input 2>/dev/null; then
        case "$input" in
            'w'|'W'|$'\x1b[A') # Up arrow or W
                if [[ $pacman_y -gt 4 ]]; then
                    tput cup $pacman_y $pacman_x; printf " "
                    ((pacman_y--))
                fi
                ;;
            's'|'S'|$'\x1b[B') # Down arrow or S
                if [[ $pacman_y -lt 20 ]]; then
                    tput cup $pacman_y $pacman_x; printf " "
                    ((pacman_y++))
                fi
                ;;
            'a'|'A'|$'\x1b[D') # Left arrow or A
                if [[ $pacman_x -gt 7 ]]; then
                    tput cup $pacman_y $pacman_x; printf " "
                    ((pacman_x--))
                fi
                ;;
            'd'|'D'|$'\x1b[C') # Right arrow or D
                if [[ $pacman_x -lt 60 ]]; then
                    tput cup $pacman_y $pacman_x; printf " "
                    ((pacman_x++))
                fi
                ;;
            'q'|'Q'|$'\x03') # Quit or Ctrl+C
                game_running=false
                ;;
            'p'|'P') # Pause
                tput cup 25 5
                printf "🟡 PAUSED - Press any key to continue 🟡"
                read -n 1 -s
                tput cup 25 5
                printf "                                         "
                ;;
        esac
    fi
}

# Draw game border - FIXED positioning
draw_game_border() {
    local width=58
    local height=18
    local start_row=3
    local start_col=6
    
    # Top border
    tput cup $start_row $start_col
    printf "╔"
    for ((i=1; i<width-1; i++)); do printf "═"; done
    printf "╗"
    
    # Side borders
    for ((i=1; i<height-1; i++)); do
        tput cup $((start_row + i)) $start_col
        printf "║"
        tput cup $((start_row + i)) $((start_col + width - 1))
        printf "║"
    done
    
    # Bottom border
    tput cup $((start_row + height - 1)) $start_col
    printf "╚"
    for ((i=1; i<width-1; i++)); do printf "═"; done
    printf "╝"
}

# Draw game status - FIXED
draw_status() {
    tput cup 2 6
    printf "Score: %-6d Lives: %d Level: %d Pellets: %-3d" "$score" "$lives" "$level" "$pellets_eaten"
    
    if [[ $power_pellet_active == true ]]; then
        tput cup 2 50
        printf "POWER! ⚡ (%d)" "$power_pellet_timer"
    fi
}

# Draw pellets - SIMPLIFIED
draw_pellets() {
    local start_y=5
    local start_x=8
    
    for ((row=0; row<12; row++)); do
        for ((col=0; col<20; col++)); do
            if [[ $((row % 2)) -eq 0 && $((col % 3)) -eq 0 ]]; then
                tput cup $((start_y + row)) $((start_x + col * 2))
                printf "·"
            fi
        done
    done
    
    # Power pellets
    tput cup 7 15; printf "🍒"
    tput cup 7 45; printf "🍒"
    tput cup 15 15; printf "🍒"
    tput cup 15 45; printf "🍒"
}

# Draw Pac-Man
draw_pacman() {
    tput cup $pacman_y $pacman_x
    printf "🟡"
}

# Draw Ghost
draw_ghost() {
    tput cup $ghost_y $ghost_x
    if [[ $power_pellet_active == true ]]; then
        printf "🫣"
    else
        printf "👻"
    fi
}

# Move ghost - SIMPLIFIED AI
move_ghost() {
    # Clear old position first
    tput cup $ghost_y $ghost_x
    printf " "
    
    # Simple movement towards Pac-Man
    if [[ $((RANDOM % 3)) -eq 0 ]]; then  # Add randomness
        if [[ $ghost_x -lt $pacman_x && $ghost_x -lt 58 ]]; then
            ((ghost_x++))
        elif [[ $ghost_x -gt $pacman_x && $ghost_x -gt 8 ]]; then
            ((ghost_x--))
        fi
        
        if [[ $ghost_y -lt $pacman_y && $ghost_y -lt 19 ]]; then
            ((ghost_y++))
        elif [[ $ghost_y -gt $pacman_y && $ghost_y -gt 5 ]]; then
            ((ghost_y--))
        fi
    fi
}

# Check collisions - FIXED
check_collisions() {
    # Check if Pac-Man and Ghost are at same position
    if [[ $((pacman_x - ghost_x)) -lt 2 && $((pacman_x - ghost_x)) -gt -2 ]] && 
       [[ $((pacman_y - ghost_y)) -lt 2 && $((pacman_y - ghost_y)) -gt -2 ]]; then
        
        if [[ $power_pellet_active == true ]]; then
            # Pac-Man eats ghost
            score=$((score + 200))
            ghost_x=50
            ghost_y=10
            tput cup 22 6
            printf "🟡 GHOST EATEN! +200 points! 🟡"
            sleep 0.5
            tput cup 22 6
            printf "                                "
        else
            # Ghost catches Pac-Man
            ((lives--))
            tput cup 22 6
            printf "👻 OUCH! Life lost! 👻"
            sleep 1
            tput cup 22 6
            printf "                      "
            
            if [[ $lives -eq 0 ]]; then
                game_running=false
                return
            fi
            
            # Reset positions
            pacman_x=10
            pacman_y=10
            ghost_x=50
            ghost_y=10
        fi
    fi
    
    # Power pellet timer countdown
    if [[ $power_pellet_active == true ]]; then
        ((power_pellet_timer--))
        if [[ $power_pellet_timer -le 0 ]]; then
            power_pellet_active=false
        fi
    fi
    
    # Check for pellet eating (simplified)
    if [[ $((pacman_x % 6)) -eq 2 && $((pacman_y % 2)) -eq 1 ]]; then
        score=$((score + 10))
        ((pellets_eaten++))
    fi
    
    # Check for power pellet
    local power_positions=("7:15" "7:45" "15:15" "15:45")
    local current_pos="$pacman_y:$pacman_x"
    for pos in "${power_positions[@]}"; do
        if [[ "$pos" == "$current_pos" ]]; then
            power_pellet_active=true
            power_pellet_timer=30
            score=$((score + 50))
            tput cup $pacman_y $pacman_x
            printf " "  # Clear the power pellet
        fi
    done
}

# Start interactive game - FIXED
start_game() {
    # Setup trap to restore terminal on exit
    trap 'restore_terminal; exit' EXIT INT TERM
    
    init_game_terminal
    
    # Initialize game state
    game_running=true
    score=0
    lives=3
    level=1
    pacman_x=10
    pacman_y=10
    ghost_x=50
    ghost_y=10
    pellets_eaten=0
    power_pellet_active=false
    power_pellet_timer=0
    
    # Draw initial game state
    tput clear
    draw_game_border
    draw_pellets
    
    # Game instructions
    tput cup 1 6
    printf "🟡 Use WASD or Arrow Keys to move | P=Pause | Q=Quit 🟡"
    
    local frame_count=0
    
    # Main game loop
    while [[ $game_running == true ]]; do
        # Handle input
        handle_input
        
        # Move ghost every few frames
        if [[ $((frame_count % 4)) -eq 0 ]]; then
            move_ghost
        fi
        
        # Check for collisions
        check_collisions
        
        # Update display
        draw_pacman
        draw_ghost
        draw_status
        
        # Check win condition
        if [[ $pellets_eaten -ge 30 ]]; then
            tput cup 22 6
            printf "🟡 LEVEL COMPLETE! Moving to level $((level + 1)) 🟡"
            sleep 2
            ((level++))
            pellets_eaten=0
            draw_pellets
            tput cup 22 6
            printf "                                              "
        fi
        
        ((frame_count++))
        sleep 0.1
    done
    
    # Game over screen
    tput clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                     🟡 GAME OVER 🟡                          ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    center_box "$box_width" "Final Score: $score"
    center_box "$box_width" "Levels Reached: $level"
    center_box "$box_width" "Pellets Eaten: $pellets_eaten"
    echo
    center_box "$box_width" "Thanks for playing! WAKA-WAKA! 🟡"
    echo
    center_box "$box_width" "Press any key to return to menu..."
    read -n 1 -s
    
    restore_terminal
}

# Watch classic animation - FIXED to prevent going crazy
watch_classic_animation() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                🟡 CLASSIC PAC-MAN ANIMATION 🟡               ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "Press 'q' to stop animation or Ctrl+C to exit..."
    echo
    
    # Set up non-blocking input for stopping animation
    stty -icanon -echo min 0 time 1
    
    # Animation frames
    local frames=(
        "ᗧ  . . .  🍒  . . .  👻"
        "ᗤ . . .  🍒  . . .  👻 "
        "ᗧ. . .  🍒  . . .  👻  "
        "ᗤ . .  🍒  . . .  👻   "
        "ᗧ. .  🍒  . . .  👻    "
        "ᗤ .  🍒  . . .  👻     "
        "ᗧ.  🍒  . . .  👻      "
        "ᗤ  🍒. . .  👻        "
        "ᗧ  🟡👻  CHOMP!        "
    )
    
    local score=0
    local cycles=0
    
    while [[ $cycles -lt 5 ]]; do  # Limit animation cycles
        for frame in "${frames[@]}"; do
            # Check for quit input
            local input
            if read -t 0 -n 1 input 2>/dev/null; then
                if [[ "$input" == "q" || "$input" == "Q" ]]; then
                    stty sane
                    return
                fi
            fi
            
            tput cup 10 0
            center_box "$box_width" "$frame"
            center_box "$box_width" "Score: $((score += 10)) | Cycle: $((cycles + 1))/5"
            sleep 0.4
        done
        ((cycles++))
        
        # Power pellet sequence
        center_box "$box_width" "🟡 POWER PELLET! ⚡"
        sleep 0.8
        center_box "$box_width" "ᗧ . . . 😱 . . . 🫣"
        sleep 0.6
        center_box "$box_width" "💀 GHOST EATEN! +200 🟡"
        sleep 1
    done
    
    stty sane
    center_box "$box_width" "Animation complete! Press any key to continue..."
    read -n 1 -s
}

# Show high scores - WORKING
show_high_scores() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                   🏆 HIGH SCORES 🏆                          ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    local scores_file="$HOME/.oneclick_highscores"
    if [[ ! -f "$scores_file" ]]; then
        cat > "$scores_file" << 'EOF'
PAC-MAN:9999:Level 10
GHOST:8888:Level 9
CHOMP:7777:Level 8
WAKA:6666:Level 7
PELLET:5555:Level 6
EOF
    fi
    
    center_box "$box_width" "🟡 OneClick CLI Pac-Man High Scores 🟡"
    echo
    
    local rank=1
    while IFS=':' read -r name score level; do
        center_box "$box_width" "$rank. $name - $score points ($level)"
        ((rank++))
        [[ $rank -gt 10 ]] && break  # Limit to top 10
    done < "$scores_file"
    
    echo
    center_box "$box_width" "Press any key to return..."
    read -n 1 -s
}

# Show game instructions - WORKING
show_instructions() {
    clear
    center_box "$box_width" "╔══════════════════════════════════════════════════════════════╗"
    center_box "$box_width" "║                🎮 GAME INSTRUCTIONS 🎮                       ║"
    center_box "$box_width" "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    center_box "$box_width" "🟡 How to Play OneClick Pac-Man 🟡"
    echo
    center_box "$box_width" "CONTROLS:"
    center_box "$box_width" "WASD Keys or Arrow Keys - Move Pac-Man"
    center_box "$box_width" "P - Pause Game"
    center_box "$box_width" "Q - Quit Game"
    echo
    center_box "$box_width" "OBJECTIVE:"
    center_box "$box_width" "• Eat pellets (·) to score points"
    center_box "$box_width" "• Avoid ghosts 👻 or lose a life"
    center_box "$box_width" "• Eat power pellets 🍒 to turn ghosts vulnerable"
    center_box "$box_width" "• Eat vulnerable ghosts for bonus points"
    echo
    center_box "$box_width" "SCORING:"
    center_box "$box_width" "• Pellet: 10 points"
    center_box "$box_width" "• Power pellet: 50 points"
    center_box "$box_width" "• Vulnerable ghost: 200 points"
    echo
    center_box "$box_width" "Press any key to return..."
    read -n 1 -s
}

# Main Pac-Man menu
pacman_animation_main() {
    while true; do
        clear
        center_box "$box_width" "${game_header[@]}"
        echo
        
        center_box "$box_width" "    🟡 ᗧ"
        center_box "$box_width" "   ╱ ◯ ╲   . . . 🍒 . . . 👻"
        center_box "$box_width" "   │   │    WAKA-WAKA-WAKA!"
        center_box "$box_width" "   ╲   ╱"
        center_box "$box_width" "    ╰───╯"
        echo
        
        center_box "$box_width" "${game_menu[@]}"
        echo
        center_box "$box_width" "Choose your adventure (1-5): "
        read -n 1 -s choice
        echo
        
        case $choice in
            1) start_game ;;
            2) watch_classic_animation ;;
            3) show_high_scores ;;
            4) show_instructions ;;
            5) return 0 ;;
            *)
                center_box "$box_width" "❌ Invalid choice! Please select 1-5."
                echo
                center_box "$box_width" "Press any key to continue..."
                read -n 1 -s
                ;;
        esac
    done
}

# Handle execution modes
case "$1" in
    "menu"|"") pacman_animation_main ;;
    "play") start_game ;;
    "watch") watch_classic_animation ;;
    "scores") show_high_scores ;;
    "help") show_instructions ;;
    *) echo "Pac-Man Animation Module - Usage: $0 [menu|play|watch|scores|help]" ;;
esac

