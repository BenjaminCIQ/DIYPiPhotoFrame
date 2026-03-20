#!/bin/bash

# Environment for Wayland (match the login user running Sway)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -n1)

OUTPUT="${OUTPUT:-HDMI-A-1}"

# Check current output status
STATE=$(wlr-randr | awk -v out="$OUTPUT" '
    $0 ~ out {inblock=1}
    inblock && /Enabled:/ {print $2; exit}
')

if [ "$STATE" = "yes" ]; then
    # Currently ON → turn OFF
    systemctl stop lisgd.service
    wlr-randr --output HDMI-A-1 --off
else
    # Currently OFF → turn ON (example: auto mode)
    wlr-randr --output HDMI-A-1 --on
    systemctl start lisgd.service
fi