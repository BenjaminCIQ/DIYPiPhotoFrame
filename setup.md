# Installed

After cloning this repo on the Pi, run `./scripts/install.sh` to copy Sway files to `~/.config/sway/`. With `sudo ./scripts/install.sh --systemd`, unit files are installed under `/etc/systemd/system/` with `User=` / `Group=` set to your login UID/GID (uses `SUDO_USER` when invoked with sudo). Add `--enable` to enable `home-gallery`, `lisgd`, `display-toggle.timer`, and `photoframe-sync.timer`.

# Installed (packages)
- sway
- nextcloud
- lisgd (advanced touch actions)
- wtype (keypress executor)
- wbkbd
- Thunar
- pavucontrol (sound)
- blueman (bluetooth)

**Multi-touch (ILITEK panels and similar):** On Raspberry Pi OS, the default **labwc** stack enables **mouse emulation** for touch, which **disables multi-touch**. **This setup required** setting **`mouseEmulation="no"`** in **`~/.config/labwc/rc.xml`** on the `<touch .../>` line for the panel (e.g. `ILITEK ILITEK-TP`), with **`mapToOutput`** set to your connector (e.g. `HDMI-A-1`). Step-by-step: [CNX Software — Tips to use a touchscreen display with Raspberry Pi OS in 2025](https://www.cnx-software.com/2025/03/12/tips-to-use-a-touchscreen-display-with-raspberry-pi-os-in-2025/).

The kiosk uses **Sway** (`~/.config/sway/`); **`rc.xml` is read by labwc**, not Sway. Keep the **`mouseEmulation="no"`** change anyway: it applies whenever you use the **stock Pi desktop (labwc)** session, and matches what was needed for multi-touch on this hardware. For **Sway-only** logins, touch behaviour is driven by **libinput** / Sway—if multi-touch is wrong there too, use `swaymsg -t get_inputs` and [libinput troubleshooting](https://wayland.freedesktop.org/libinput/doc/latest/troubleshooting.html) in addition to the above.

make /media/ExtPhotos, mount photo drive there
Add external_storage app in nextcloud and add drive to nextcloud using occ

**Recommended fix (current Nextcloud):** External storage can block the behaviour you want for shared folders (e.g. PublicUpload) until you adjust password handling. Comment out the line in `apps/files_external/lib/Controller/StoragesController.php` that sets `Authentication` to `true` (same path under your install, e.g. `/var/www/html/nextcloud/...`). **Re-check after each Nextcloud upgrade**—a future release may fix this upstream, in which case you can drop the edit and rely on the default behaviour.

Now you can enable sharing of folders in photo drive, for example PublicUpload

pull https://github.com/BenjaminCIQ/home-gallery, go to packages/folder-sync, install requirements, run setup.sh, check if sync is working by systemctl status photoframe-sync@.service and photoframe-sync.timer
build proj, call ./gallery.js run server to test (will start automatically with sway config)
