#!/usr/bin/env bash
# NixOS Management Menu
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║     NixOS Management Menu              ║"
    echo "╠════════════════════════════════════════╣"
    echo "║ 1. Update System & Flakes              ║"
    echo "║ 2. Push to GitHub                      ║"
    echo "║ 3. Garbage Collection                  ║"
    echo "║ 4. Update + Push (combo)               ║"
    echo "║ 5. Full Maintenance (all three)        ║"
    echo "║ 0. Exit                                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
}

# Spinner animation for background tasks
spinner() {
    local pid=$1
    local task=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    echo -n "$task "
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r$task ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r$task ✓\n"
}

# Progress bar for multi-step operations
show_progress() {
    local current=$1
    local total=$2
    local task=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r[$current/$total] $task ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${percent}%%"
}

run_with_spinner() {
    local script=$1
    local task=$2
    shift 2
    
    "$script" "$@" > /tmp/nix-script.log 2>&1 &
    local pid=$!
    spinner $pid "$task"
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "❌ Error occurred. Log:"
        tail -20 /tmp/nix-script.log
        return $exit_code
    fi
    return 0
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

while true; do
    show_menu
    read -p "Select an option: " choice
    echo ""
    
    case $choice in
        1)
            run_with_spinner "$SCRIPT_DIR/update.sh" "Updating system..."
            press_enter
            ;;
        2)
            read -p "Enter commit message (or press Enter for default): " msg
            if [ -z "$msg" ]; then
                run_with_spinner "$SCRIPT_DIR/push.sh" "Pushing to GitHub..."
            else
                run_with_spinner "$SCRIPT_DIR/push.sh" "Pushing to GitHub..." "$msg"
            fi
            press_enter
            ;;
        3)
            run_with_spinner "$SCRIPT_DIR/gc.sh" "Running garbage collection..."
            press_enter
            ;;
        4)
            echo ""
            show_progress 1 2 "Updating system"
            run_with_spinner "$SCRIPT_DIR/update.sh" "Updating system..." || { press_enter; continue; }
            echo ""
            show_progress 2 2 "Pushing to GitHub"
            run_with_spinner "$SCRIPT_DIR/push.sh" "Pushing to GitHub..." "System update $(date '+%Y-%m-%d')"
            echo ""
            echo "✅ Complete!"
            press_enter
            ;;
        5)
            echo ""
            show_progress 1 3 "Updating system"
            run_with_spinner "$SCRIPT_DIR/update.sh" "Updating system..." || { press_enter; continue; }
            echo ""
            show_progress 2 3 "Pushing to GitHub"
            run_with_spinner "$SCRIPT_DIR/push.sh" "Pushing to GitHub..." "System update $(date '+%Y-%m-%d')" || { press_enter; continue; }
            echo ""
            show_progress 3 3 "Garbage collection"
            run_with_spinner "$SCRIPT_DIR/gc.sh" "Running garbage collection..."
            echo ""
            echo "✅ Full maintenance complete!"
            press_enter
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            press_enter
            ;;
    esac
done
