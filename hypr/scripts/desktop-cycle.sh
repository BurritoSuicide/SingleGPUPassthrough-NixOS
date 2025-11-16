#!/usr/bin/env bash
set -euo pipefail

SYSTEMCTL="$(command -v systemctl || echo '/run/current-system/sw/bin/systemctl')"
NOTIFY_SEND="$(command -v notify-send || echo '/run/current-system/sw/bin/notify-send')"
STATE_ROOT="${HOME}/.local/state/quickshell"
STATE_FILE="${STATE_ROOT}/active-shell"

mkdir -p "${STATE_ROOT}"

sessions=(caelestia noctalia dms)
services=("caelestia.service" "noctalia-shell.service" "quickshell-dms.service")
labels=("Caelestia Shell" "Noctalia" "DankMaterialShell")

current="$(cat "$STATE_FILE" 2>/dev/null || echo "caelestia")"

index=0
idx=0
for session in "${sessions[@]}"; do
  if [[ "$session" == "$current" ]]; then
    index=$idx
    break
  fi
  idx=$((idx + 1))
done

length="${#sessions[@]}"
next_index=$(( (index + 1) % length ))
next="${sessions[$next_index]}"

for svc in "${services[@]}"; do
  "$SYSTEMCTL" --user stop "$svc" >/dev/null 2>&1 || true
done

case "$next" in
  caelestia)
    if ! "$SYSTEMCTL" --user start caelestia.service; then
      [ -x "$NOTIFY_SEND" ] && "$NOTIFY_SEND" -t 5000 "Failed to start Caelestia" "unit: caelestia.service"
      exit 1
    fi
    ;;
  noctalia)
    if ! "$SYSTEMCTL" --user start noctalia-shell.service; then
      [ -x "$NOTIFY_SEND" ] && "$NOTIFY_SEND" -t 5000 "Failed to start Noctalia" "unit: noctalia-shell.service"
      exit 1
    fi
    ;;
  dms)
    if ! "$SYSTEMCTL" --user start quickshell-dms.service; then
      [ -x "$NOTIFY_SEND" ] && "$NOTIFY_SEND" -t 5000 "Failed to start DankMaterialShell" "unit: quickshell-dms.service"
      exit 1
    fi
    ;;
esac

printf '%s\n' "$next" > "$STATE_FILE"

# Trigger animated borders update after switching shells
if [ -f "${HOME}/.config/hypr/scripts/animatedborders.sh" ]; then
  bash "${HOME}/.config/hypr/scripts/animatedborders.sh" &
fi

if [ -x "$NOTIFY_SEND" ]; then
  "$NOTIFY_SEND" -t 5000 "Desktop shell switched" "${labels[$next_index]}"
fi

