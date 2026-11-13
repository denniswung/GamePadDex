#!/bin/bash
set -eu
export JAVA_HOME="$HOME/tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p "$HOME/gpm"
cp -f "/mnt/e/Dennis/GamePadDex复刻/work/apk/base.apk" "$HOME/gpm/base.apk"
cp -f "/mnt/e/Dennis/GamePadDex复刻/work/apk/split_config.xxhdpi.apk" "$HOME/gpm/split.apk"
rm -rf "$HOME/gpm/out"
cd "$HOME/gpm"
echo "=== jadx version ==="
"$HOME/tools/jadx-1.5.0/bin/jadx" --version
echo "=== decompiling ==="
"$HOME/tools/jadx-1.5.0/bin/jadx" -d "$HOME/gpm/out" --deobf --show-bad-code -j 8 base.apk 2>&1 | tail -40
echo "=== result ==="
find "$HOME/gpm/out" -maxdepth 2 -type d | head -20
echo "=== java files ==="
find "$HOME/gpm/out" -name '*.java' | wc -l
