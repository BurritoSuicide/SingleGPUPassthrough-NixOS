#!/usr/bin/env bash
set -euo pipefail

SYSTEMCTL_BIN="$(command -v systemctl || echo '/run/current-system/sw/bin/systemctl')"
STATE_ROOT="${HOME}/.local/state/quickshell"
STATE_FILE="${STATE_ROOT}/active-shell"
DEFAULT_SHELL="ii"
MAX_WAIT=30  # Maximum seconds to wait for Wayland

declare -A SHELL_SERVICES=(
  [ii]="quickshell-ii.service"
)

mkdir -p "${STATE_ROOT}"

# Wait for Wayland socket to be available
wait_for_wayland() {
  local wait_time=0
  while [ $wait_time -lt $MAX_WAIT ]; do
    if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY}" ]; then
      return 0
    fi
    # Check for any wayland socket in runtime directory
    RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [ -d "$RUNTIME_DIR" ] && [ -n "$(find "$RUNTIME_DIR" -maxdepth 1 -name "wayland-*" -type s 2>/dev/null | head -1)" ]; then
      return 0
    fi
    sleep 1
    wait_time=$((wait_time + 1))
  done
  echo "Warning: Wayland socket not found after ${MAX_WAIT}s, proceeding anyway" >&2
  return 0
}

# Wait for Hyprland to be running
wait_for_hyprland() {
  local wait_time=0
  while [ $wait_time -lt $MAX_WAIT ]; do
    if pgrep -x Hyprland >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    wait_time=$((wait_time + 1))
  done
  echo "Warning: Hyprland process not found after ${MAX_WAIT}s, proceeding anyway" >&2
  return 0
}

# Wait for environment to be ready
wait_for_wayland
wait_for_hyprland

requested_shell="${1:-}"

if [ -z "$requested_shell" ] && [ -f "$STATE_FILE" ]; then
  requested_shell="$(tr -d '\n' < "$STATE_FILE")"
fi

if [ -z "$requested_shell" ]; then
  requested_shell="$DEFAULT_SHELL"
fi

if [ -z "${SHELL_SERVICES[$requested_shell]+x}" ]; then
  requested_shell="$DEFAULT_SHELL"
fi

for svc in "${SHELL_SERVICES[@]}"; do
  "${SYSTEMCTL_BIN}" --user stop "$svc" >/dev/null 2>&1 || true
done

target_unit="${SHELL_SERVICES[$requested_shell]}"

echo "Desktop shell autostart: ${requested_shell} (${target_unit})"
if ! "${SYSTEMCTL_BIN}" --user start "$target_unit"; then
  if [ "$requested_shell" != "$DEFAULT_SHELL" ]; then
    echo "Failed to start ${requested_shell}. Falling back to ${DEFAULT_SHELL}."
    requested_shell="$DEFAULT_SHELL"
    target_unit="${SHELL_SERVICES[$requested_shell]}"
    "${SYSTEMCTL_BIN}" --user start "$target_unit" >/dev/null 2>&1 || true
  fi
fi

printf '%s\n' "$requested_shell" > "$STATE_FILE"

