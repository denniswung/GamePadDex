import zipfile

apk = "/mnt/e/Dennis/GamePadDex复刻/project/lsp-dexpad/app/build/outputs/apk/debug/app-debug.apk"
z = zipfile.ZipFile(apk)
for n in z.namelist():
    if n.endswith(".dex"):
        data = z.read(n)
        print(n, len(data), "EngineV2:", data.count(b"EngineV2"), "DexPadV2:", data.count(b"DexPadV2"))
