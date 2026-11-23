#!/system/bin/sh
# measure dumpsys latency (for app-side closed-loop cursor query frequency)
N=3
for c in "dumpsys input" "dumpsys SurfaceFlinger" "dumpsys power"; do
    for i in 1 2 3; do
        t0=$(date +%s%N 2>/dev/null)
        if [ -z "$t0" ] || [ "${t0%N}" != "$t0" ]; then
            # no ns support: fallback to seconds
            t0=$(date +%s)
        fi
        $c >/dev/null 2>&1
        t1=$(date +%s%N 2>/dev/null)
        echo "$c run$i start=$t0 end=$t1"
    done
done
