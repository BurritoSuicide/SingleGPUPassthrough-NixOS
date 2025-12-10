#!/usr/bin/env bash

HYPRCTL_BIN="$(command -v hyprctl || true)"

# Default colors for Illogical Impulse (fallback)
# These can be customized based on your Illogical Impulse theme
primary="ffb0ca"
secondary="e2bdc7"
tertiary="f0bc95"
inactive="31282a"
outline="9e8c91"

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

