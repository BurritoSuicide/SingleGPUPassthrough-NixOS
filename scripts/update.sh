#!/usr/bin/env bash
# Update NixOS system and flakes
set -e

echo "🔄 Updating flake inputs..."
cd /etc/nixos
sudo nix flake update

echo "🔨 Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake /etc/nixos

echo "🔄 Reloading Hyprland and related services..."
# Wait a moment for system to settle after rebuild
sleep 2

# Get the current user (who invoked sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
    # If no SUDO_USER, try to get the user from the display session
    ACTUAL_USER=$(who | awk '/tty[0-9]|pts\/[0-9]/ {print $1; exit}' || echo "")
fi

run_as_actual_user() {
    if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
        return 1
    fi

    if [ "$EUID" -eq 0 ]; then
        sudo -u "$ACTUAL_USER" "$@"
    else
        "$@"
    fi
}

HYPR_ENV_ARGS=()

gather_hypr_env() {
    local hypr_pid="${1:-}"
    HYPR_ENV_ARGS=()

    if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
        return 1
    fi

    local user_uid runtime_dir wayland_display hypr_sig
    user_uid=$(id -u "$ACTUAL_USER" 2>/dev/null || echo "")
    [ -n "$user_uid" ] || return 1

    runtime_dir="/run/user/$user_uid"
    if [ -d "$runtime_dir" ]; then
        HYPR_ENV_ARGS+=(XDG_RUNTIME_DIR="$runtime_dir")
    fi

    wayland_display="${WAYLAND_DISPLAY:-}"
    hypr_sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"

    if [ -z "$wayland_display" ] || [ -z "$hypr_sig" ]; then
        if [ -z "$hypr_pid" ]; then
            hypr_pid=$(pgrep -u "$ACTUAL_USER" -x Hyprland 2>/dev/null | head -1)
        fi

        if [ -n "$hypr_pid" ]; then
            if [ -z "$hypr_sig" ]; then
                hypr_sig=$(grep -z "^HYPRLAND_INSTANCE_SIGNATURE=" "/proc/$hypr_pid/environ" 2>/dev/null | cut -d= -f2- | tr -d '\0')
            fi
            if [ -z "$wayland_display" ]; then
                wayland_display=$(grep -z "^WAYLAND_DISPLAY=" "/proc/$hypr_pid/environ" 2>/dev/null | cut -d= -f2- | tr -d '\0')
            fi
        fi
    fi

    if [ -n "$wayland_display" ]; then
        HYPR_ENV_ARGS+=(WAYLAND_DISPLAY="$wayland_display")
    fi
    if [ -n "$hypr_sig" ]; then
        HYPR_ENV_ARGS+=(HYPRLAND_INSTANCE_SIGNATURE="$hypr_sig")
    fi

    if [ -z "$wayland_display" ] && [ -z "$hypr_sig" ]; then
        return 1
    fi

    return 0
}

run_user_with_env() {
    if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
        return 1
    fi

    if [ "${#HYPR_ENV_ARGS[@]}" -gt 0 ]; then
        run_as_actual_user env "${HYPR_ENV_ARGS[@]}" "$@"
    else
        run_as_actual_user "$@"
    fi
}

# Reload Hyprland configuration as the actual user
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    HYPR_CONFIG="/home/$ACTUAL_USER/.config/hypr/hyprland.conf"
    ANIMATED_BORDERS_SCRIPT="/home/$ACTUAL_USER/.config/hypr/scripts/animatedborders.sh"
    
    sleep 3
    
    echo "  → Reloading systemd user daemon..."
    run_as_actual_user systemctl --user daemon-reload 2>/dev/null || true
    
    echo "  → Restarting Hyprland-related services..."
    run_as_actual_user systemctl --user restart hypr-border-sync.service 2>/dev/null || true
    run_as_actual_user systemctl --user restart hypr-border-sync.path 2>/dev/null || true
    
    # Restart Illogical Impulse shell service
    echo "  → Restarting Illogical Impulse shell service..."
    run_as_actual_user systemctl --user stop quickshell-ii.service 2>/dev/null || true
    run_as_actual_user systemctl --user restart quickshell-ii.service 2>/dev/null || true
    
    sleep 2
    
    if ! run_as_actual_user test -f "$HYPR_CONFIG"; then
        echo "    ⚠️  Hyprland config not found at $HYPR_CONFIG (continuing with reload anyway)"
    fi
    
    # Try to reload Hyprland - check multiple ways to find the process
    if ! command -v hyprctl >/dev/null 2>&1; then
        echo "    ⚠️  hyprctl not found, skipping Hyprland reload"
    else
        # Try multiple methods to find Hyprland process
        HYPR_PID=""
        
        # Method 1: Check by username
        if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
            HYPR_PID=$(pgrep -u "$ACTUAL_USER" -x Hyprland 2>/dev/null | head -1)
        fi
        
        # Method 2: Check all Hyprland processes (might be running under different user context)
        if [ -z "$HYPR_PID" ]; then
            HYPR_PID=$(pgrep -x Hyprland 2>/dev/null | head -1)
        fi
        
        # Method 3: Check via process list for any hyprland-related process
        if [ -z "$HYPR_PID" ]; then
            HYPR_PID=$(ps aux | grep -i '[h]yprland' | awk '{print $2}' | head -1)
        fi
        
        # Always try to reload if hyprctl is available - even if we can't find the PID
        # The reload command itself will fail gracefully if Hyprland isn't running
        echo "  → Reloading Hyprland configuration..."
        
        # First, gather environment if we found a PID
        if [ -n "$HYPR_PID" ]; then
            gather_hypr_env "$HYPR_PID" || true
            echo "    → Found Hyprland process (PID: $HYPR_PID)"
        else
            # Try to build environment from runtime directory even without PID
            USER_UID=$(id -u "$ACTUAL_USER" 2>/dev/null || echo "")
            if [ -n "$USER_UID" ]; then
                RUNTIME_DIR="/run/user/$USER_UID"
                if [ -d "$RUNTIME_DIR" ]; then
                    HYPR_ENV_ARGS=()
                    HYPR_ENV_ARGS+=(XDG_RUNTIME_DIR="$RUNTIME_DIR")
                    # Try to find wayland socket
                    WAYLAND_SOCKET=$(find "$RUNTIME_DIR" -maxdepth 1 -name "wayland-*" -type s 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "wayland-0")
                    HYPR_ENV_ARGS+=(WAYLAND_DISPLAY="$WAYLAND_SOCKET")
                    echo "    → Using runtime directory: $RUNTIME_DIR"
                fi
            fi
        fi
        
        # Attempt reload with environment
        RELOAD_SUCCESS=false
        if [ "${#HYPR_ENV_ARGS[@]}" -gt 0 ]; then
            if run_user_with_env hyprctl reload 2>/dev/null; then
                echo "    ✓ Hyprland reloaded successfully"
                RELOAD_SUCCESS=true
            fi
        fi
        
        # Fallback: try without environment variables
        if [ "$RELOAD_SUCCESS" = false ]; then
            if run_as_actual_user hyprctl reload 2>/dev/null; then
                echo "    ✓ Hyprland reloaded successfully (fallback method)"
                RELOAD_SUCCESS=true
            else
                echo "    ⚠️  Could not reload Hyprland (Hyprland may not be running or not accessible)"
            fi
        fi
        
        if [ "$RELOAD_SUCCESS" = true ]; then
            sleep 2  # Give Hyprland time to process the reload
            
            # Update borders
            if run_as_actual_user test -f "$ANIMATED_BORDERS_SCRIPT"; then
                echo "  → Updating Hyprland borders..."
                if [ "${#HYPR_ENV_ARGS[@]}" -gt 0 ]; then
                    run_user_with_env bash "$ANIMATED_BORDERS_SCRIPT" 2>/dev/null || echo "    ⚠️  Could not update borders"
                else
                    run_as_actual_user bash "$ANIMATED_BORDERS_SCRIPT" 2>/dev/null || echo "    ⚠️  Could not update borders"
                fi
            fi
            
            # Final reload to ensure everything is applied
            echo "  → Final Hyprland config reload..."
            sleep 1
            if [ "${#HYPR_ENV_ARGS[@]}" -gt 0 ]; then
                run_user_with_env hyprctl reload 2>/dev/null || true
            else
                run_as_actual_user hyprctl reload 2>/dev/null || true
            fi
        fi
    fi
else
    # Fallback: try without sudo if already running as user
    if command -v hyprctl >/dev/null 2>&1; then
        echo "  → Activating Home Manager configuration (fallback)..."
        home-manager switch --flake /etc/nixos#scryv 2>/dev/null || true
        sleep 1
        
        echo "  → Reloading Hyprland configuration (fallback)..."
        hyprctl reload 2>/dev/null || echo "    ⚠️  Could not reload Hyprland (may not be running)"
        
        # Run animatedborders script
        if [ -f "$HOME/.config/hypr/scripts/animatedborders.sh" ]; then
            bash "$HOME/.config/hypr/scripts/animatedborders.sh" 2>/dev/null || true
        fi
        
        systemctl --user daemon-reload 2>/dev/null || true
    else
        echo "  ⚠️  hyprctl not found, skipping Hyprland reload"
    fi
fi

echo "✅ System updated successfully!"
