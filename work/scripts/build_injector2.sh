#!/bin/bash
set -eu
export JAVA_HOME="$HOME/tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
SDK="$HOME/android-sdk"
SRC="/mnt/e/Dennis/GamePadDex复刻/project/tools/injector/ScrollInject.java"
OUT="$HOME/injector_out"
rm -rf "$OUT"
mkdir -p "$OUT/classes"
"$JAVA_HOME/bin/javac" -source 8 -target 8 -bootclasspath "$SDK/platforms/android-36/android.jar" \
    -d "$OUT/classes" "$SRC"
echo "javac ok"
"$SDK/build-tools/36.0.0/d8" --lib "$SDK/platforms/android-36/android.jar" --min-api 32 \
    --output "$OUT" "$OUT/classes/ScrollInject.class"
cp -f "$OUT/classes.dex" "$OUT/inject.dex"
ls -l "$OUT/inject.dex"
