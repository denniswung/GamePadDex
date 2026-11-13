#!/system/bin/sh
# probe DeX window shortcuts: print ConfigActivity frame before/after each combo
D=6
frame() {
    dumpsys window windows 2>/dev/null \
      | grep -o 'com.dennis.dexpad/com.dennis.dexpad.ConfigActivity, frame=\[Rect([^)]*)\]' \
      | head -1
}
echo "base: $(frame)"
input -d $D keycombination 117 19
sleep 1
echo "meta+up: $(frame)"
input -d $D keycombination 117 20
sleep 1
echo "meta+down: $(frame)"
input -d $D keycombination 117 21
sleep 1
echo "meta+left: $(frame)"
input -d $D keycombination 117 22
sleep 1
echo "meta+right: $(frame)"
