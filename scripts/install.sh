#!/usr/bin/env bash
# Install package to NixOS configuration
set -e

CONFIG_DIR="/etc/nixos"
CONFIG_FILE="$CONFIG_DIR/configuration.nix"
HOME_FILE="$CONFIG_DIR/home.nix"

if [ -n "$1" ]; then
    PACKAGE="$1"
    CHANNEL="${2:-unstable}"
    LOCATION="${3:-system}"
else
    read -p "Enter package name to install: " PACKAGE
    if [ -z "$PACKAGE" ]; then
        echo "Error: Package name cannot be empty"
        exit 1
    fi

    read -p "Enter channel (25.05/unstable) [unstable]: " CHANNEL
    CHANNEL="${CHANNEL:-unstable}"

    read -p "Install to (system/home) [system]: " LOCATION
    LOCATION="${LOCATION:-system}"
fi

# Validate inputs
case "$CHANNEL" in
    25.05|unstable) ;;
    *)
        echo "Error: Invalid channel '$CHANNEL'"
        exit 1
        ;;
esac

case "$LOCATION" in
    system|home) ;;
    *)
        echo "Error: Invalid location '$LOCATION'. Use 'system' or 'home'"
        exit 1
        ;;
esac

# Determine which file to edit
if [ "$LOCATION" = "home" ]; then
    TARGET_FILE="$HOME_FILE"
    MARKER="home.packages = with pkgs; ["
else
    TARGET_FILE="$CONFIG_FILE"
    if [ "$CHANNEL" = "unstable" ]; then
        MARKER="# Unstable packages"
        PACKAGE_LINE="    unstablePkgs.$PACKAGE"
    else
        MARKER="# System utilities"
        PACKAGE_LINE="    $PACKAGE"
    fi
fi

# Check if file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: $TARGET_FILE not found"
    exit 1
fi

# For home.nix, simple append
if [ "$LOCATION" = "home" ]; then
    # Check if package already exists
    if grep -q "^\s*$PACKAGE\s*$" "$HOME_FILE"; then
        echo "⚠️  Package '$PACKAGE' already exists in home.nix"
        exit 1
    fi

    # Find the closing bracket and add before it
    sudo sed -i "/home.packages = with pkgs; \[/,/\];/ {
        /\];/ i\    $PACKAGE
    }" "$HOME_FILE"

    echo "✓ Added '$PACKAGE' to home.nix"
else
    # For configuration.nix
    if [ "$CHANNEL" = "unstable" ]; then
        # Check if already exists
        if grep -q "unstablePkgs\.$PACKAGE" "$CONFIG_FILE"; then
            echo "⚠️  Package 'unstablePkgs.$PACKAGE' already exists in configuration.nix"
            exit 1
        fi

        # Add after "# Unstable packages" marker, before the closing bracket
        sudo sed -i "/# Unstable packages/,/\] ++ \[/ {
            /unstablePkgs\./ {
                :a
                n
                /\] ++ \[/ {
                    i\    unstablePkgs.$PACKAGE
                    b
                }
                ba
            }
            /\] ++ \[/ i\    unstablePkgs.$PACKAGE
        }" "$CONFIG_FILE"

        echo "✓ Added 'unstablePkgs.$PACKAGE' to configuration.nix"
    else
        # Check if already exists
        if grep -q "^\s*$PACKAGE\s*$" "$CONFIG_FILE"; then
            echo "⚠️  Package '$PACKAGE' already exists in configuration.nix"
            exit 1
        fi

        # Add in system utilities section, before the closing bracket
        sudo sed -i "/# System utilities/,/\] ++ \[/ {
            /\] ++ \[/ i\    $PACKAGE
        }" "$CONFIG_FILE"

        echo "✓ Added '$PACKAGE' to configuration.nix"
    fi
fi

# Ask to rebuild
echo ""
read -p "Rebuild NixOS now? (y/n) [y]: " REBUILD
REBUILD="${REBUILD:-y}"

if [ "$REBUILD" = "y" ] || [ "$REBUILD" = "Y" ]; then
    echo ""
    echo "🔨 Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake "$CONFIG_DIR#"
    echo ""
    echo "✅ System rebuilt successfully!"
else
    echo "⚠️  Remember to run: sudo nixos-rebuild switch"
fi
