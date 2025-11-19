#!/usr/bin/env bash

STATE_FILE="${HOME}/.local/state/quickshell/active-shell"
CAELESTIA_SCHEME="${HOME}/.local/state/caelestia/scheme.json"
NOCTALIA_COLORS="${HOME}/.config/noctalia/colors.json"
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
elif [[ "$active_shell" == "noctalia" ]] && [[ -r "${NOCTALIA_COLORS}" ]] && [[ -n "${JQ_BIN}" ]]; then
    # Extract colors from Noctalia JSON file
    primary="$("${JQ_BIN}" -r '.mPrimary' "${NOCTALIA_COLORS}")"
    secondary="$("${JQ_BIN}" -r '.mSecondary' "${NOCTALIA_COLORS}")"
    tertiary="$("${JQ_BIN}" -r '.mTertiary' "${NOCTALIA_COLORS}")"
    inactive="$("${JQ_BIN}" -r '.mSurfaceVariant' "${NOCTALIA_COLORS}")"
    outline="$("${JQ_BIN}" -r '.mOutline' "${NOCTALIA_COLORS}")"
elif [[ "$active_shell" == "dms" ]] && [[ -r "${DMS_COLORS}" ]]; then
    # Extract colors from DMS CSS file using @define-color syntax
    primary="$(grep -oP '@define-color accent_bg_color\s+#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "9dcbfb")"
    secondary="$(grep -oP '@define-color accent_fg_color\s+#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "003355")"
    tertiary="$(grep -oP '@define-color sidebar_bg_color\s+#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "1d2024")"
    inactive="$(grep -oP '@define-color window_bg_color\s+#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "101418")"
    outline="$(grep -oP '@define-color window_fg_color\s+#?\K[0-9a-fA-F]{6}' "${DMS_COLORS}" 2>/dev/null | head -1 || echo "e0e2e8")"
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

