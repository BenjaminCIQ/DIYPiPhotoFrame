#!/bin/bash

if pgrep -x wvkbd-mobintl>/dev/null; then
	pkill -x wvkbd-mobintl
else
	wvkbd-mobintl -L 300 --fn "DejaVu Sans 20" &
fi
