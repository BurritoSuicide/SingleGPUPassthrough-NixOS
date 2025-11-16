#!/bin/bash
WALLPAPER=$(find ~/Pictures/Wallpapers -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mov" -o -name "*.webm" \) | shuf -n 1)
if [ -n "$WALLPAPER" ]; then
    mpvpaper -vs -o "no-audio loop" DP-3 "$WALLPAPER"
fi
