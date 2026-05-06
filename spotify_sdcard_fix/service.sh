#!/system/bin/sh

# Wait for boot to complete
A=$(getprop sys.boot_completed | tr -d '\r')
while [ "$A" != "1" ]; do
  sleep 2
  A=$(getprop sys.boot_completed | tr -d '\r')
done

# Disable Spotify immediately so it can't run before SD card mounts
pm disable com.spotify.music

# Wait until SD card is mounted (/storage/ has 3 entries: emulated, SD UUID, self)
A=$(find /storage/* -maxdepth 0 2>/dev/null | wc -l)
while [ "$A" != "3" ]; do
  sleep 8
  A=$(find /storage/* -maxdepth 0 2>/dev/null | wc -l)
done

# SD card is mounted — re-enable Spotify
pm enable com.spotify.music
