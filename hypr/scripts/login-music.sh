#!/usr/bin/env bash

MUSIC_PATH="/home/scryv/Music/Culmination - Picayune Dreams Vol. 2.mp3"
PID_FILE="/tmp/login-music.pid"

# Apps that won't trigger a fade-out
IGNORE_CLASSES=("wofi" "kando")

# Get current volume level
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' '/Front Left/ {gsub(/ /,"",$2); print $2}' | tr -d '%'
}

# Fade volume to target
fade_volume() {
    local from=$1
    local to=$2
    local step=$(( (from > to) ? -2 : 2 ))
    for vol in $(seq "$from" "$step" "$to"); do
        pactl set-sink-volume @DEFAULT_SINK@ "${vol}%" >/dev/null 2>&1
        sleep 0.05
    done
}

# Check for active windows excluding ignored ones
is_real_app_open() {
    hyprctl clients -j | jq -r '.[].class' | grep -v -E "$(IFS='|'; echo "${IGNORE_CLASSES[*]}")" | grep -q .
}

# Kill any previous music
if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
fi

# Start MPV at current volume
mpv --no-video --ao=pulse "$MUSIC_PATH" &
echo $! > "$PID_FILE"

faded_out=false
current_vol=$(get_volume)

while true; do
    sleep 1
    if is_real_app_open; then
        if [ "$faded_out" = false ]; then
            fade_volume "$current_vol" 0
            faded_out=true
            kill "$(cat "$PID_FILE")" 2>/dev/null
        fi
    else
        if [ "$faded_out" = true ]; then
            # Music stopped, restart and fade in
            mpv --no-video --ao=pulse --volume=0 "$MUSIC_PATH" &
            echo $! > "$PID_FILE"
            fade_volume 0 "$current_vol"
            faded_out=false
        fi
    fi
done
