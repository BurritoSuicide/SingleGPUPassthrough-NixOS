#!/usr/bin/env bash
# Search NixOS packages
set -e

# If arguments provided, use them (for script/menu usage)
if [ -n "$1" ]; then
    PACKAGE="$1"
    CHANNEL="${2:-unstable}"
else
    # Interactive mode
    read -p "Enter package name to search: " PACKAGE
    if [ -z "$PACKAGE" ]; then
        echo "Error: Package name cannot be empty"
        exit 1
    fi

    read -p "Enter channel (25.05/unstable) [unstable]: " CHANNEL
    CHANNEL="${CHANNEL:-unstable}"
fi

# Validate channel
case "$CHANNEL" in
    25.05|unstable)
        ;;
    *)
        echo "Error: Invalid channel '$CHANNEL'"
        echo "Valid channels: 25.05, unstable"
        exit 1
        ;;
esac

echo "🔍 Searching for '$PACKAGE' in NixOS $CHANNEL..."
echo ""

# Check if package is currently installed
INSTALLED=false
INSTALL_LOCATION=""

# Check nix-env
if nix-env -q | grep -q "^${PACKAGE}"; then
    INSTALLED=true
    INSTALLED_VERSION=$(nix-env -q | grep "^${PACKAGE}" | head -1)
    echo "✓ Package '$PACKAGE' is INSTALLED (nix-env)"
    echo "  Current version: $INSTALLED_VERSION"
    INSTALL_LOCATION="user profile"
# Check configuration.nix
elif grep -q "^\s*$PACKAGE\s*$" /etc/nixos/configuration.nix 2>/dev/null; then
    INSTALLED=true
    echo "✓ Package '$PACKAGE' is INSTALLED (configuration.nix - stable)"
    INSTALL_LOCATION="configuration.nix (stable channel)"
elif grep -q "unstablePkgs\.$PACKAGE" /etc/nixos/configuration.nix 2>/dev/null; then
    INSTALLED=true
    echo "✓ Package '$PACKAGE' is INSTALLED (configuration.nix - unstable)"
    INSTALL_LOCATION="configuration.nix (unstable channel)"
elif grep -q "gitPkgs\.$PACKAGE" /etc/nixos/configuration.nix 2>/dev/null; then
    INSTALLED=true
    echo "✓ Package '$PACKAGE' is INSTALLED (configuration.nix - git)"
    INSTALL_LOCATION="configuration.nix (git source)"
# Check home.nix
elif grep -q "^\s*$PACKAGE\s*$" /etc/nixos/home.nix 2>/dev/null; then
    INSTALLED=true
    echo "✓ Package '$PACKAGE' is INSTALLED (home.nix)"
    INSTALL_LOCATION="home.nix"
else
    echo "✗ Package '$PACKAGE' is NOT installed on your system"
fi

if [ "$INSTALLED" = true ] && [ -n "$INSTALL_LOCATION" ]; then
    echo "  Location: $INSTALL_LOCATION"
fi
echo ""

# Search for available packages
# Use the correct flake reference for the channel
if [ "$CHANNEL" = "unstable" ]; then
    FLAKE_REF="nixpkgs"
else
    FLAKE_REF="nixpkgs/nixos-${CHANNEL}"
fi

RESULTS=$(nix search "$FLAKE_REF" "$PACKAGE" --json 2>/dev/null)

if [ -z "$RESULTS" ] || [ "$RESULTS" = "{}" ]; then
    echo "❌ No packages found matching '$PACKAGE' in $CHANNEL channel"
    echo ""
    echo "Try:"
    echo "  - Check spelling"
    echo "  - Try a different channel"
    if [ "$CHANNEL" = "unstable" ]; then
        echo "  - Search online: https://search.nixos.org/packages?channel=unstable&query=$PACKAGE"
    else
        echo "  - Search online: https://search.nixos.org/packages?channel=${CHANNEL}&query=$PACKAGE"
    fi
    exit 1
fi

echo "📦 Available packages:"
echo ""

echo "$RESULTS" | jq -r '
    to_entries[] |
    "Package: \(.key | sub("legacyPackages\\.[^.]+\\."; ""))
Version: \(.value.version // "N/A")
Description: \(.value.description // "No description")
---"
'

echo ""
echo "💡 To install: nix-env -iA nixos.$PACKAGE"
echo "💡 Or add to configuration.nix: environment.systemPackages = [ pkgs.$PACKAGE ];"
