#!/bin/bash

# Apps that need the keyboard
APPS=("chromium" "chromium-browser" "foot" "alacritty" "wofi")

while true; do
    focused_app=$(swaymsg -t get_tree | jq -r '.. | select(.focused?==true).app_id')

    if [[ " ${APPS[*]} " == *" $focused_app "* ]]; then
        # Show keyboard if not running
        if ! pgrep -x wvkbd-mobintl >/dev/null; then
            wvkbd-mobintl &
        fi
    else
        # Hide keyboard if running
        pkill -x wvkbd-mobintl
    fi
    sleep 0.8
done
