#!/system/bin/sh
echo "before: $(settings get global display_size_forced) / $(wm size | tr '\n' ' ')"
settings delete global display_size_forced
settings delete global display_density_forced 2>/dev/null
wm size reset
wm density reset
sleep 1
echo "after : $(settings get global display_size_forced) / $(wm size | tr '\n' ' ')"
dumpsys display 2>/dev/null | grep -oE 'real [0-9]+ x [0-9]+' | head -3
