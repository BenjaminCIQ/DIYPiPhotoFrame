#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sway/kiosk_launcher/config"
BASE_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sway/kiosk_launcher/chromium_profiles"

mkdir -p "$BASE_USER_DIR"

# Read default workspace
default_workspace=$(grep '^default_workspace=' "$CONFIG_FILE" | cut -d'=' -f2)

# Read all workspace=url lines (ignore comments and blank lines)
grep -v '^#' "$CONFIG_FILE" | grep '=' | while IFS='=' read -r workspace url; do
    [[ "$workspace" == "default_workspace" ]] && continue
    [[ -z "$url" ]] && continue

    user_data_dir="${BASE_USER_DIR}/ws${workspace}"

    mkdir -p "$user_data_dir"

    swaymsg "workspace number ${workspace}"
    chromium \
        --kiosk "$url" \
        --user-data-dir="$user_data_dir" \
	--noerrdialogs \
        --disable-session-crashed-bubble &

    sleep 6  # small delay to ensure window appears
done

# Finally, move back to the default workspace
if [[ -n "$default_workspace" ]]; then
    swaymsg "workspace number ${default_workspace}"
fi
