#!/system/bin/sh
# print the current system mouse pointer position (from the input dump)
dumpsys input 2>/dev/null | grep -m1 -o 'hoveringPointers=\[Pointer(id=0, MOUSE) at ([0-9.]*, [0-9.]*)\]'
