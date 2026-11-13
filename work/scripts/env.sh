#!/bin/bash
echo "=== tools ==="
for t in adb jadx apktool smali baksmali python3 unzip zip git node npm java aapt2 aapt dexdump curl wget; do
  printf '%-12s ' "$t"
  command -v "$t" || echo MISSING
done
echo "=== sdk dirs ==="
ls -1 "$HOME/android-sdk/build-tools" 2>/dev/null
ls -1 "$HOME/android-sdk/platform-tools" 2>/dev/null | head -5
echo "=== tools dir ==="
ls -1 "$HOME/tools" 2>/dev/null
echo "=== uname ==="
uname -a
echo "=== disk ==="
df -h /mnt/e | tail -1
