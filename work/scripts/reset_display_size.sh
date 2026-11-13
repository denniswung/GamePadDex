#!/system/bin/sh
echo "before:"; wm size; wm density
for d in 0 1 2; do
  wm size reset -d $d 2>&1 | head -2
  wm density reset -d $d 2>&1 | head -2
done
sleep 1
echo "after:"; wm size; wm density
echo "--- 各 display 覆盖 ---"
dumpsys display 2>/dev/null | grep -oE 'mOverrideDisplayInfo=DisplayInfo\{[^}]*' | head -4
