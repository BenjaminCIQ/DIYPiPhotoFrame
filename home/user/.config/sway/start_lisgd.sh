#!/bin/bash
# Wrapper that waits for the touch device then execs lisgd (so lisgd is the service main process).

# Optional: source Sway session env if present (for Wayland/swaymsg in gesture commands)
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/sway/session-env" ]; then
  set -a
  source "${XDG_CONFIG_HOME:-$HOME/.config}/sway/session-env"
  set +a
fi

TIMEOUT=30
INTERVAL=1
elapsed=0
DEVICE=""

while [ -z "$DEVICE" ] && [ "$elapsed" -lt "$TIMEOUT" ]; do  
  DEVICE=$(ls /dev/input/by-id/*ILITEK* 2>/dev/null | head -n1 || true)
  [ -n "$DEVICE" ] && break
  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

if [ -z "$DEVICE" ]; then
  echo "Error: ILITEK device not found after ${TIMEOUT}s" >&2
  exit 1
fi

# exec so this process is replaced by lisgd and systemd tracks lisgd
exec lisgd -d "$DEVICE" \
  -g "2,RL,*,*,R,wtype -M logo -M ctrl -k right" \
  -g "2,LR,*,*,R,wtype -M logo -M ctrl -k left" \
  -g "3,DU,*,*,R,swaymsg exec '~/.config/sway/settings-toggle.sh'" \
  -g "3,UD,*,*,R,swaymsg exec '~/.config/sway/settings-toggle.sh'" \
  -g "2,DU,*,*,R,swaymsg exec '~/.config/sway/wvkbd-toggle.sh'" \
  -g "2,UD,*,*,R,swaymsg exec '~/.config/sway/wvkbd-toggle.sh'"
