#!/bin/bash

# Check if a workspace named "settings" exists
if swaymsg -t get_workspaces | jq 'map(select(.name == "settings")) | length > 0' | grep -q true; then
        pkill -x blueman-manager
	pkill -x pavucontrol
	swaymsg "workspace settings"
	swaymsg "kill"
	swaymsg "workspace next"
else
        swaymsg "workspace settings"
	swaymsg "exec blueman-manager &"
        sleep 2
        swaymsg "exec pavucontrol &"
fi
