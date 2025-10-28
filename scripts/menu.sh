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
            echo "Running system update..."
            "$SCRIPT_DIR/update.sh"
            press_enter
            ;;
        2)
            read -p "Enter commit message (or press Enter for default): " msg
            if [ -z "$msg" ]; then
                "$SCRIPT_DIR/push.sh"
            else
                "$SCRIPT_DIR/push.sh" "$msg"
            fi
            press_enter
            ;;
        3)
            echo "Running garbage collection..."
            "$SCRIPT_DIR/gc.sh"
            press_enter
            ;;
        4)
            echo "Running update + push..."
            "$SCRIPT_DIR/update.sh"
            echo ""
            "$SCRIPT_DIR/push.sh" "System update $(date '+%Y-%m-%d')"
            press_enter
            ;;
        5)
            echo "Running full maintenance..."
            "$SCRIPT_DIR/update.sh"
            echo ""
            "$SCRIPT_DIR/push.sh" "System update $(date '+%Y-%m-%d')"
            echo ""
            "$SCRIPT_DIR/gc.sh"
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
