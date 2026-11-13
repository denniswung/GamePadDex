#!/system/bin/sh
# nudge the pointer: $1 = axis (0=X, 1=Y), $2 = value (-32768..32767), $3 = ms
/data/local/tmp/vgpad stick "$1" "$2" "$3" 2600 >/dev/null 2>&1
sleep 1
dumpsys input 2>/dev/null | grep -m1 -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)\]'
