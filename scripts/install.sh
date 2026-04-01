#!/usr/bin/env bash
# Copy Pi photo frame configs from this repo into place and align systemd UID/GID
# with the target user (defaults to SUDO_USER when root, else current user).
#
# Usage:
#   ./scripts/install.sh              # ~/.config/sway only
#   sudo ./scripts/install.sh --systemd # above + /etc/systemd/system/*.service|timer
#   ./scripts/install.sh --dry-run    # print actions only
# Optional: sudo ./scripts/install.sh --systemd --enable  # enable home-gallery, lisgd, timers, photoframe-sync.timer

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
DO_SYSTEMD=0
DO_ENABLE=0

if [[ "${*:-}" == *--enable* ]] && [[ "${*:-}" != *--systemd* ]]; then
  echo "Note: --enable only applies together with --systemd" >&2
fi

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --systemd) DO_SYSTEMD=1 ;;
    --enable) DO_ENABLE=1 ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

TARGET_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "$TARGET_USER" ]]; then
  echo "Cannot determine target user (empty USER)." >&2
  exit 1
fi

TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GID="$(id -g "$TARGET_USER")"
if command -v getent >/dev/null 2>&1; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
else
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  echo "Home directory for '$TARGET_USER' not found: $TARGET_HOME" >&2
  exit 1
fi

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

SRC_SWAY="$REPO_ROOT/home/user/.config/sway"
DEST_SWAY="$TARGET_HOME/.config/sway"

if [[ ! -d "$SRC_SWAY" ]]; then
  echo "Missing $SRC_SWAY" >&2
  exit 1
fi

echo "Target user: $TARGET_USER (uid=$TARGET_UID gid=$TARGET_GID) home=$TARGET_HOME"

run mkdir -p "$DEST_SWAY"
run cp -a "$SRC_SWAY/." "$DEST_SWAY/"
for f in "$DEST_SWAY"/*.sh; do
  [[ -e "$f" ]] || continue
  run chmod +x "$f"
done

rewrite_service() {
  local src="$1" dest="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] sed User/Group -> uid/gid $TARGET_UID/$TARGET_GID < $(basename "$src") > $(basename "$dest")"
    return
  fi
  sed -E \
    -e "s/^User=[0-9]+/User=$TARGET_UID/" \
    -e "s/^Group=[0-9]+/Group=$TARGET_GID/" \
    "$src" >"$dest"
}

if [[ "$DO_SYSTEMD" -eq 1 ]]; then
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Use root/sudo for --systemd" >&2
    exit 1
  fi
  UNIT_DIR="$REPO_ROOT/etc/systemd/system"
  for src in "$UNIT_DIR"/*.service; do
    [[ -e "$src" ]] || continue
    base="$(basename "$src")"
    rewrite_service "$src" "/etc/systemd/system/$base"
    run chmod 644 "/etc/systemd/system/$base"
  done
  for src in "$UNIT_DIR"/*.timer; do
    [[ -e "$src" ]] || continue
    base="$(basename "$src")"
    run cp -a "$src" "/etc/systemd/system/$base"
    run chmod 644 "/etc/systemd/system/$base"
  done
  run systemctl daemon-reload

  if [[ "$DO_ENABLE" -eq 1 ]]; then
    run systemctl enable --now home-gallery.service
    run systemctl enable --now lisgd.service
    run systemctl enable --now display-toggle.timer
    run systemctl enable --now photoframe-sync.timer
  fi
fi

echo "Done. Sway configs -> $DEST_SWAY"
if [[ "$DO_SYSTEMD" -eq 0 ]]; then
  echo "For systemd units: sudo $0 --systemd"
fi
