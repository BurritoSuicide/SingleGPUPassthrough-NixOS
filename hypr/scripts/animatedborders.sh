#!/usr/bin/env bash

STATE_FILE="${HOME}/.local/state/quickshell/active-shell"
CAELESTIA_SCHEME="${HOME}/.local/state/caelestia/scheme.json"
DMS_COLORS="${HOME}/.config/gtk-3.0/dank-colors.css"
JQ_BIN="$(command -v jq || true)"
HYPRCTL_BIN="$(command -v hyprctl || true)"

# Determine active shell
active_shell="$(cat "$STATE_FILE" 2>/dev/null || echo "caelestia")"

# Extract colors based on active shell
if [[ "$active_shell" == "caelestia" ]] && [[ -r "${CAELESTIA_SCHEME}" ]] && [[ -n "${JQ_BIN}" ]]; then
    primary="$("${JQ_BIN}" -r '.colours.primary' "${CAELESTIA_SCHEME}")"
    secondary="$("${JQ_BIN}" -r '.colours.secondaryContainer // .colours.secondary' "${CAELESTIA_SCHEME}")"
    tertiary="$("${JQ_BIN}" -r '.colours.tertiary // .colours.tertiaryContainer // .colours.primaryFixed' "${CAELESTIA_SCHEME}")"
    inactive="$("${JQ_BIN}" -r '.colours.surfaceContainerHigh // .colours.surfaceVariant' "${CAELESTIA_SCHEME}")"
    outline="$("${JQ_BIN}" -r '.colours.outline' "${CAELESTIA_SCHEME}")"
elif [[ "$active_shell" == "dms" ]] && [[ -r "${DMS_COLORS}" ]]; then
    # Extract colors from DMS CSS file (fallback to defaults if parsing fails)
    primary="$(grep -oP '--accent:\s*#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "ffb0ca")"
    secondary="$(grep -oP '--secondary:\s*#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "e2bdc7")"
    tertiary="$(grep -oP '--tertiary:\s*#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "f0bc95")"
    inactive="31282a"
    outline="9e8c91"
else
    # Default colors (fallback)
    primary="ffb0ca"
    secondary="e2bdc7"
    tertiary="f0bc95"
    inactive="31282a"
    outline="9e8c91"
fi

# Remove # prefix if present
primary="${primary#\#}"
secondary="${secondary#\#}"
tertiary="${tertiary#\#}"
inactive="${inactive#\#}"
outline="${outline#\#}"

if [[ -n "${HYPRCTL_BIN}" ]]; then
    "${HYPRCTL_BIN}" keyword general:col.active_border "rgb(${primary})" "rgb(${secondary})" "rgb(${tertiary})" 270deg
    "${HYPRCTL_BIN}" keyword general:col.inactive_border "rgb(${inactive})" "rgb(${outline})" 270deg
fi

