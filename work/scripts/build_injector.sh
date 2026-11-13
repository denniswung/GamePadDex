#!/bin/bash
set -eu
JDK="$HOME/tools/jdk-17.0.20.1+1"
SDK="$HOME/android-sdk"
SRC="/mnt/e/Dennis/GamePadDex复刻/project/tools/injector"
OUT="$HOME/injector_out"
mkdir -p "$OUT"
cd "$OUT"
# Android API 36 jar for the framework classes (compile only, hidden API via reflection)
"$JDK/bin/javac" -source 8 -target 8 -bootclasspath "$SDK/platforms/android-36/android.jar" \
    -d "$OUT/classes" "$SRC/ScrollInject.java" 2>&1 | head -20
ls "$OUT/classes"
# dex it
"$SDK/build-tools/36.0.0/d8" --lib "$SDK/platforms/android-36/android.jar" \
    --min-api 32 --output "$OUT" "$OUT/classes/ScrollInject.class" 2>&1 | head -20
ls -l "$OUT"/*.dex
cp -f "$OUT/classes.dex" "$OUT/inject.dex"
ls -l "$OUT/inject.dex"
