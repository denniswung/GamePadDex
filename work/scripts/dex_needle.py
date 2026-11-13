import zipfile, sys

apk = sys.argv[1]
z = zipfile.ZipFile(apk)
needle = sys.argv[2].encode()
total = 0
for n in z.namelist():
    if n.endswith(".dex"):
        c = z.read(n).count(needle)
        if c:
            print(n, c)
            total += c
print("total", total)
