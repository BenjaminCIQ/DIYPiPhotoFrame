#!/usr/bin/env bash
# Launch one Chromium kiosk per workspace from kiosk_launcher/config.
# Each window is moved to its workspace by con_id once it maps, so a slow start can't
# land it on the wrong workspace or stack two kiosks on one.
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sway/kiosk_launcher/config"
BASE_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sway/kiosk_launcher/chromium_profiles"
WINDOW_TIMEOUT=60

mkdir -p "$BASE_USER_DIR"

# A second launch with the same profile only opens another window in the running
# Chromium, which then lands on whatever workspace is focused.
if pgrep -f -- "--user-data-dir=$BASE_USER_DIR/" >/dev/null; then
    echo "Kiosks already running; not launching again." >&2
    exit 0
fi

window_ids() {
    swaymsg -t get_tree | jq -r '.. | objects | select(.type? == "con" or .type? == "floating_con") | select(.pid != null) | .id' | sort
}

default_workspace=$(grep '^default_workspace=' "$CONFIG_FILE" | cut -d'=' -f2)

# Read all workspace=url lines (ignore comments and blank lines)
grep -v '^#' "$CONFIG_FILE" | grep '=' | while IFS='=' read -r workspace url; do
    [[ "$workspace" == "default_workspace" ]] && continue
    [[ -z "$url" ]] && continue

    user_data_dir="${BASE_USER_DIR}/ws${workspace}"
    mkdir -p "$user_data_dir"
    # Stale locks survive power loss; after reboot the stored PID can be another kiosk's Chromium.
    # Safe to remove: the pgrep guard above ensures no kiosk is running.
    rm -f "$user_data_dir"/Singleton{Lock,Socket,Cookie}

    before=$(window_ids)
    chromium \
        --kiosk "$url" \
        --user-data-dir="$user_data_dir" \
        --noerrdialogs \
        --disable-session-crashed-bubble &

    new_id=""
    for ((i = 0; i < WINDOW_TIMEOUT; i++)); do
        new_id=$(comm -13 <(echo "$before") <(window_ids) | head -n1)
        [[ -n "$new_id" ]] && break
        sleep 1
    done
    if [[ -z "$new_id" ]]; then
        echo "No window for workspace ${workspace} (${url}) after ${WINDOW_TIMEOUT}s" >&2
        continue
    fi
    swaymsg "[con_id=${new_id}] move container to workspace number ${workspace}" >/dev/null
done

# Finally, move to the default workspace
if [[ -n "$default_workspace" ]]; then
    swaymsg "workspace number ${default_workspace}"
fi
