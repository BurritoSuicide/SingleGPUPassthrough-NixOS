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

# Reload Hyprland configuration as the actual user
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    # Home Manager activation should have run during nixos-rebuild switch
    # But we'll wait a moment and verify the config file exists
    HYPR_CONFIG="/home/$ACTUAL_USER/.config/hypr/hyprland.conf"
    
    # Wait a bit longer for Home Manager activation to complete
    sleep 3
    
    # Reload Hyprland config
    if sudo -u "$ACTUAL_USER" command -v hyprctl >/dev/null 2>&1; then
        echo "  → Reloading Hyprland configuration..."
        # Check if config file exists and is readable
        if sudo -u "$ACTUAL_USER" test -f "$HYPR_CONFIG"; then
            # First, try to reload the entire config
            # Use 'hyprctl reload' which should reload everything including keybinds
            sudo -u "$ACTUAL_USER" hyprctl reload 2>/dev/null || echo "    ⚠️  Initial reload failed"
            
            # Wait a moment for reload to process
            sleep 1
            
            # Force reload keybinds specifically by reloading the config again
            # Sometimes a single reload doesn't catch all changes
            echo "  → Forcing keybind reload..."
            sudo -u "$ACTUAL_USER" hyprctl reload 2>/dev/null || true
            
            # Verify Hyprland is responding
            if sudo -u "$ACTUAL_USER" hyprctl version >/dev/null 2>&1; then
                echo "    ✓ Hyprland is running and config reloaded"
            else
                echo "    ⚠️  Hyprland may not be running"
            fi
        else
            echo "    ⚠️  Hyprland config not found at $HYPR_CONFIG"
            echo "    → Trying reload anyway (config may be in different location)..."
            sudo -u "$ACTUAL_USER" hyprctl reload 2>/dev/null || echo "    ⚠️  Could not reload Hyprland"
        fi
        
        # Run the animatedborders script to update borders
        echo "  → Updating Hyprland borders..."
        ANIMATED_BORDERS_SCRIPT="/home/$ACTUAL_USER/.config/hypr/scripts/animatedborders.sh"
        if sudo -u "$ACTUAL_USER" test -f "$ANIMATED_BORDERS_SCRIPT"; then
            sudo -u "$ACTUAL_USER" bash "$ANIMATED_BORDERS_SCRIPT" 2>/dev/null || echo "    ⚠️  Could not update borders"
        else
            echo "    ⚠️  Animatedborders script not found at $ANIMATED_BORDERS_SCRIPT"
        fi
        
        # Force a final reload to ensure everything is applied
        echo "  → Final Hyprland config reload..."
        sudo -u "$ACTUAL_USER" hyprctl reload 2>/dev/null || true
        
        # Reload systemd user daemon to pick up any new service files
        echo "  → Reloading systemd user daemon..."
        sudo -u "$ACTUAL_USER" systemctl --user daemon-reload 2>/dev/null || true
        
        # Restart Hyprland-related user services to ensure everything is in sync
        echo "  → Restarting Hyprland-related services..."
        sudo -u "$ACTUAL_USER" systemctl --user restart hypr-border-sync.service 2>/dev/null || true
        sudo -u "$ACTUAL_USER" systemctl --user restart hypr-border-sync.path 2>/dev/null || true
        
        # Also try to restart any shell services that might need it
        sudo -u "$ACTUAL_USER" systemctl --user restart caelestia.service 2>/dev/null || true
        sudo -u "$ACTUAL_USER" systemctl --user restart noctalia-shell.service 2>/dev/null || true
        sudo -u "$ACTUAL_USER" systemctl --user restart quickshell-dms.service 2>/dev/null || true
    else
        echo "  ⚠️  hyprctl not found for user $ACTUAL_USER, skipping Hyprland reload"
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
