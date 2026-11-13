#!/bin/bash
set -e
rm -rf /tmp/secdex
mkdir -p /tmp/secdex
cd /tmp/secdex
unzip -o "/mnt/e/Dennis/GamePadDex复刻/work/apk/SecSettings.apk" 'classes*.dex' >/dev/null 2>&1
ls -la
for f in classes*.dex; do
  strings -a "$f" | grep -oE 'L?[A-Za-z0-9_/$]+DexModeSettingsFragment[A-Za-z0-9_$]*' || true
done | sort -u | head -30
