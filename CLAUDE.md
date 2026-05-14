# FiiO JM21 — Magisk Root + Spotify SD Card Fix

Device: FiiO x Jade Audio JM21 (Android 13 GKI, A/B partitions).
Firmware: FW1.1.0 — `http://jm21pack.fiio.net/beta/JM21-update-1.1.0.zip`
Magisk: v30.7

## Critical
On Android 13 GKI, `boot.img` has no ramdisk — Magisk must patch `init_boot.img`, **not** `boot.img`. Patching `boot.img` silently fails.

- `init_boot.img` ~8MB, RAMDISK_SZ > 0 ✓  
- `boot.img` ~96MB, RAMDISK_SZ=0 ✗

SELinux is permissive — no policy patches needed.

## Repo contents
- `spotify_sdcard_fix/` — Magisk module source (`service.sh`)
- `spotify_sdcard_fix.zip` — pre-built module
- `build_module.sh` — builds the ZIP from source
- `README.md` — full root + flash guide with all ADB commands

## Common tasks
- **Re-root after OTA**: extract new `init_boot.img` from new firmware ZIP, repeat patch + flash steps (Steps 3–5 in README)
- **Update Spotify module**: edit `spotify_sdcard_fix/service.sh`, run `./build_module.sh`, push ZIP to `/sdcard/Download/`, install via Magisk
- **Verify root**: `adb shell su -c id`
