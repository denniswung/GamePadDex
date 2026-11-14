import io, sys
H = "/mnt/e/Dennis/GamePadDex复刻/project/app/src/main/assets/gpminput.c"
s = io.open(H, encoding="utf-8").read()
fails = []
old = "        case 23:  return 352;  /* DPAD_CENTER -> KEY_OK */"
new = """        /* DPAD_CENTER：Samsung 上 KEY_OK(352) 不会触发确认，KEY_ENTER(28) 可以
         * （实测 KEY_SELECT 353 / KPENTER 96 也可以，取最通用的 ENTER） */
        case 23:  return 28;"""
if old not in s:
    fails.append("case23")
else:
    s = s.replace(old, new, 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(s)
print("FAILS:", fails if fails else "none")
