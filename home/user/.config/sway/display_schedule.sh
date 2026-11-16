#!/bin/bash
# Set the display on or off for the current time of day, and start/stop lisgd with it.
# Idempotent: missed or repeated runs (reboots, timer catch-up) can't invert the state.
# Run by display-schedule.timer and once at Sway startup.
set -euo pipefail

# Keep in sync with OnCalendar= in display-schedule.timer. Assumes ON_TIME < OFF_TIME (no midnight wrap).
ON_TIME="${ON_TIME:-07:00}"
OFF_TIME="${OFF_TIME:-22:30}"
OUTPUT="${OUTPUT:-HDMI-A-1}"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -z "${SWAYSOCK:-}" ]]; then
    SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -n1 || true)
    export SWAYSOCK
fi
if [[ -z "$SWAYSOCK" ]]; then
    echo "Sway is not running; nothing to do." >&2
    exit 0
fi

now=$(date +%H:%M)
if [[ ! "$now" < "$ON_TIME" && "$now" < "$OFF_TIME" ]]; then
    swaymsg "output $OUTPUT power on" >/dev/null
    # Started via Sway so lisgd gets the session environment
    pgrep -x lisgd >/dev/null || swaymsg exec "$HOME/.config/sway/start_lisgd.sh" >/dev/null
else
    # No gestures while the screen is dark
    pkill -x lisgd || true
    swaymsg "output $OUTPUT power off" >/dev/null
fi
