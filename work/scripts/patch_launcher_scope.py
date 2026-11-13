import io
E = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/src/main/java/com/dennis/dexpad/EngineService.kt"
e = io.open(E, encoding="utf-8").read()
old = '''        val p = EngineState.topPackage.lowercase()
        return p.contains("launcher") || p.endsWith(".home") || p.contains("flauncher")'''
new = '''        val p = EngineState.topPackage.lowercase()
        // 桌面、系统弹窗（ResolverActivity 之类）、SystemUI 都没有可滚动内容，
        // 在这些界面上发触摸滑动只会触发系统手势，改成方向键更安全。
        return p.contains("launcher") || p.endsWith(".home") || p.contains("flauncher") ||
            p == "android" || p.contains("systemui")'''
if old not in e:
    print("MISS"); raise SystemExit(1)
e = e.replace(old, new, 1)
io.open(E, "w", encoding="utf-8", newline="\n").write(e)
print("ok")
