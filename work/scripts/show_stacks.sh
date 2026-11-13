#!/system/bin/sh
PID=$(pidof com.dennis.dexpad | awk '{print $1}')
echo "pid=$PID"
for d in /proc/$PID/task/*; do
    n=$(cat "$d/comm" 2>/dev/null)
    case "$n" in
        dexpad-link|dexpad-engine)
            echo "== $n ($d)"
            cat "$d/wchan" 2>/dev/null; echo
            cat "$d/stack" 2>/dev/null | head -8
            ;;
    esac
done
