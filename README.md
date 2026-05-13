# FiiO JM21 — Magisk Root + Spotify SD Card Fix

Rooting guide for the **FiiO x Jade Audio JM21** DAP (Android 13 GKI) and a Magisk module that fixes Spotify wiping its SD card data folder on every boot.

## The Problem

On the JM21, Spotify launches before the SD card is fully mounted at boot. When it can't find its data folder on the SD card, it wipes it and falls back to internal storage — losing your downloaded music.

## The Fix

A Magisk module (`spotify_sdcard_fix`) that:
1. Disables Spotify at boot
2. Waits until the SD card is fully mounted
3. Re-enables Spotify

---

## Requirements

- FiiO JM21 with USB debugging enabled
- Mac/Linux with `adb`, `fastboot`, and [`payload-dumper-go`](https://github.com/ssut/payload-dumper-go) installed
- [Magisk v30.7 APK](https://github.com/topjohnwu/Magisk/releases/tag/v30.7)
- JM21 firmware ZIP (FW1.1.0): `http://jm21pack.fiio.net/beta/JM21-update-1.1.0.zip`

---

## Rooting the JM21

### Key fact — Android 13 GKI

On Android 13 GKI devices, `boot.img` has no ramdisk. The ramdisk lives in `init_boot.img`. **Magisk must patch `init_boot.img`, not `boot.img`.** Patching the wrong image results in Magisk silently not working.

---

### Step 1 — Extract init_boot.img from firmware

```bash
# Download firmware
curl -L "http://jm21pack.fiio.net/beta/JM21-update-1.1.0.zip" -o JM21-update-1.1.0.zip
unzip JM21-update-1.1.0.zip payload.bin

# Extract init_boot partition only (~8MB, not boot.img which is ~96MB)
payload-dumper-go -partitions init_boot payload.bin
# Output: extracted_XXXXXX/init_boot.img
```

Verify you have the right image — `init_boot.img` should be ~8MB with a non-zero ramdisk. `boot.img` is ~96MB with RAMDISK_SZ=0 and is the wrong target.

---

### Step 2 — Extract Magisk binaries from APK

```bash
unzip Magisk-v30.7.apk -d magisk_extracted
```

The APK contains the arm64 binaries named with a `lib` prefix and `.so` suffix. `boot_patch.sh` expects specific names — rename them exactly as shown below.

---

### Step 3 — Patch init_boot.img on the device

```bash
adb shell mkdir -p /data/local/tmp/magisk

# Push binaries with the exact names boot_patch.sh expects
adb push magisk_extracted/lib/arm64-v8a/libmagiskboot.so  /data/local/tmp/magisk/magiskboot
adb push magisk_extracted/lib/arm64-v8a/libmagisk.so      /data/local/tmp/magisk/magisk
adb push magisk_extracted/lib/arm64-v8a/libmagiskinit.so  /data/local/tmp/magisk/magiskinit
adb push magisk_extracted/lib/arm64-v8a/libinit-ld.so     /data/local/tmp/magisk/init-ld
adb push magisk_extracted/assets/stub.apk                 /data/local/tmp/magisk/stub.apk
adb push magisk_extracted/assets/boot_patch.sh            /data/local/tmp/magisk/boot_patch.sh
adb push magisk_extracted/assets/util_functions.sh        /data/local/tmp/magisk/util_functions.sh

# Push the init_boot image (adjust path to match your extraction output)
adb push extracted_XXXXXX/init_boot.img /data/local/tmp/magisk/init_boot.img

adb shell chmod -R 755 /data/local/tmp/magisk

# Run the patcher
adb shell "cd /data/local/tmp/magisk && ./boot_patch.sh init_boot.img"

# Pull the patched image
adb pull /data/local/tmp/magisk/new-boot.img magisk_patched_init_boot.img
```

---

### Step 4 — Flash the patched image

```bash
adb reboot bootloader
# Wait for fastboot prompt
fastboot flash init_boot magisk_patched_init_boot.img
fastboot reboot
```

---

### Step 5 — Complete Magisk setup

1. After the first boot, open the Magisk app — it may show **"Requires additional setup"**. Tap OK and let it reboot again.
2. Open Magisk → Settings → **Superuser access** → set to **Apps and ADB**. You must tap this explicitly; just seeing it selected is not enough to commit it to the database.

---

## Installing the Spotify SD Card Fix Module

### Option A — Build and push the ZIP yourself

```bash
# From this repo
chmod +x build_module.sh
./build_module.sh
adb push spotify_sdcard_fix.zip /sdcard/Download/
```

Then in the Magisk app: **Modules → Install from storage**.

> **Tip:** The "Downloads" filter in the file picker won't show ADB-pushed files. Tap the hamburger menu → **FiiO JM21** → **Download** folder, or use the search icon and type `spotify_sdcard`.

### Option B — Download the pre-built ZIP

Download `spotify_sdcard_fix.zip` from [Releases](../../releases) and push it to `/sdcard/Download/`.

---

### How the module works

`service.sh` runs as root at late-start boot via Magisk:

```sh
# Disable Spotify immediately after boot completes
pm disable com.spotify.music

# Wait until /storage/ has 3 entries (emulated + SD card UUID + self)
while [ "$(find /storage/* -maxdepth 0 2>/dev/null | wc -l)" != "3" ]; do
  sleep 8
done

# Ensure WiFi interface is up so Spotify doesn't stall on its network check
svc wifi enable
sleep 2

# Re-enable Spotify
pm enable com.spotify.music
```

---

## Updating Firmware

OTA updates overwrite `init_boot` on the new slot, removing root. To re-root after an update:

1. Let the firmware update install and reboot (you'll be unrooted on the new firmware)
2. Download the new firmware ZIP and extract the new `init_boot.img`
3. Repeat Steps 3–5 above
4. The Spotify fix module survives firmware updates — it will be active again automatically after re-rooting

---

---

## Notes

- Tested on FW1.1.0, Magisk v30.7, boot slot `_b`
- SELinux is permissive on the JM21 — no policy patches needed
- The JM21 uses an A/B partition scheme
