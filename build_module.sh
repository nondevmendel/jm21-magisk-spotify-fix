#!/bin/bash
# Builds spotify_sdcard_fix.zip from the module source directory
cd "$(dirname "$0")"
rm -f spotify_sdcard_fix.zip
cd spotify_sdcard_fix
zip -r ../spotify_sdcard_fix.zip .
cd ..
echo "Built: spotify_sdcard_fix.zip ($(du -sh spotify_sdcard_fix.zip | cut -f1))"
