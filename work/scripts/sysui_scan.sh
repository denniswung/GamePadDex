#!/bin/bash
set -u
export JAVA_HOME="$HOME/tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
APK="/mnt/e/Dennis/GamePadDex复刻/work/apk/SystemUI.apk"
cd "$HOME"
rm -rf sysui_x && mkdir -p sysui_x
unzip -o -q "$APK" "classes*.dex" -d sysui_x 2>/dev/null
ls -l sysui_x | head
echo "=== which dex has dextouchpad ==="
for d in sysui_x/classes*.dex; do
  n=$(strings -a "$d" 2>/dev/null | grep -ci dextouchpad)
  echo "$(basename "$d") $n"
done
echo "=== class descriptors ==="
for d in sysui_x/classes*.dex; do
  strings -a "$d" 2>/dev/null | grep -oE 'Lcom/android/systemui/dextouchpad/[A-Za-z0-9/$_]+;' | sort -u
done | head -40
