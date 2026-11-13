#!/bin/bash
set -eu
export JAVA_HOME="$HOME/tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
SDK="$HOME/android-sdk"
cd "$HOME/injector_out"
"$SDK/build-tools/36.0.0/d8" --lib "$SDK/platforms/android-36/android.jar" --min-api 32 \
    --output "$HOME/injector_out" "$HOME/injector_out/classes/ScrollInject.class" 2>&1 | head -10
ls -l "$HOME/injector_out"/*.dex
cp -f "$HOME/injector_out/classes.dex" "$HOME/injector_out/inject.dex"
ls -l "$HOME/injector_out/inject.dex"
