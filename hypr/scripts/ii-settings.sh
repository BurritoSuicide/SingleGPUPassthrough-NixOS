#!/usr/bin/env bash
# Launch illogical-impulse settings
# This script finds and launches the illogical-impulse settings window
# It uses the same approach as the original illogical-impulse config

# Set environment variables
export qsConfig=ii
export QT_QPA_PLATFORM=wayland
export QML_DISABLE_DISK_CACHE=1

# Try to find qs in PATH first
if command -v qs >/dev/null 2>&1; then
    exec qs -p ~/.config/quickshell/$qsConfig/settings.qml
fi

# If not in PATH, try common locations
for path in /run/current-system/sw/bin/qs ~/.nix-profile/bin/qs; do
    if [ -x "$path" ] 2>/dev/null; then
        exec "$path" -p ~/.config/quickshell/$qsConfig/settings.qml
    fi
done

# Last resort: find in nix store
FOUND=$(find /nix/store -name "qs" -type f -executable 2>/dev/null | grep -E "quickshell|qs" | head -1)
if [ -n "$FOUND" ]; then
    exec "$FOUND" -p ~/.config/quickshell/$qsConfig/settings.qml
fi

# If we get here, qs wasn't found
notify-send -t 5000 "Error" "Could not find quickshell (qs) binary. Make sure quickshell is installed."
exit 1

