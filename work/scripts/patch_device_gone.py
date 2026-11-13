import io, sys
R = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/RootInput.kt"
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"

r = io.open(R, encoding="utf-8").read()
old = """        /** the physical d-pad was forwarded to the system (native navigation) */
        fun onPadKey(key: Int)"""
new = """        /** the physical d-pad was forwarded to the system (native navigation) */
        fun onPadKey(key: Int)
        /** a grabbed gamepad disappeared: its held keys will never send an up */
        fun onDeviceGone()"""
if old not in r:
    print("MISS iface"); sys.exit(1)
r = r.replace(old, new, 1)

old2 = """            line.startsWith("GONE ") -> {
                val name = line.removePrefix("GONE ").substringAfter(' ', "")
                devices.remove(name)
                listener.onDevicesChanged(devices.toList())
            }"""
new2 = """            line.startsWith("GONE ") -> {
                val name = line.removePrefix("GONE ").substringAfter(' ', "")
                devices.remove(name)
                listener.onDevicesChanged(devices.toList())
                listener.onDeviceGone()
            }"""
if old2 not in r:
    print("MISS gone"); sys.exit(1)
r = r.replace(old2, new2, 1)
io.open(R, "w", encoding="utf-8", newline="\n").write(r)
print("rootinput ok")

e = io.open(E, encoding="utf-8").read()
anchor = "    override fun onPadKey(key: Int) {"
if anchor not in e:
    anchor = "    override fun onPadKey(key: Int)"
if anchor not in e:
    print("MISS onPadKey"); sys.exit(1)
idx = e.index(anchor)
# 在 onPadKey 之后插入 onDeviceGone 实现：找到该函数的结束（下一个 '    override fun' 或 '    private fun'）
nxt = e.index("\n    override fun ", idx + 10)
impl = """
    /** 手柄掉线：它的 up 事件永远不会来了，必须清状态，否则组合会卡在“已触发” */
    override fun onDeviceGone() {
        clearPressedState("device gone")
    }
"""
e = e[:nxt] + "\n" + impl + e[nxt:]
io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("engine ok")
