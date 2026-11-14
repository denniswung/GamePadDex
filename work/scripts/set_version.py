import io, re, sys
G = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/build.gradle.kts"
M = "/mnt/e/Dennis/GamePadDex复刻/project/ksu-module/module.prop"

VER = "1.65"
CODE = 67

g = io.open(G, encoding="utf-8").read()
g2 = re.sub(r"versionCode\s*=\s*\d+", f"versionCode = {CODE}", g, count=1)
g2 = re.sub(r'versionName\s*=\s*"[^"]*"', f'versionName = "{VER}"', g2, count=1)
if g2 == g:
    print("gradle unchanged?!")
io.open(G, "w", encoding="utf-8", newline="\n").write(g2)

m = io.open(M, encoding="utf-8").read()
m2 = re.sub(r"^version=.*$", f"version=v{VER}", m, count=1, flags=re.M)
m2 = re.sub(r"^versionCode=.*$", f"versionCode={CODE}", m2, count=1, flags=re.M)
io.open(M, "w", encoding="utf-8", newline="\n").write(m2)

print("gradle:", [l.strip() for l in g2.splitlines() if "version" in l][:2])
print("module:", [l.strip() for l in m2.splitlines() if "version" in l][:2])
