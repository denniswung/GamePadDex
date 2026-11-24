import sys
p = 'project/app/src/main/assets/gpminput.c'
raw = open(p, 'rb').read()
print('bom=', raw[:3] == b'\xef\xbb\xbf')
t = raw.decode('utf-8')
print('utf8=ok')
clues = set('锛銆鈥鎸鍚鐨缁瀹浠鏄鍦韬绯缂绋寮鍙涓闃鍧閿骞鎴浣鏂鏃鏋鏍鐢鍒鍔鍛鍜鍝鍞鍟鍢鍤鍥鍨鍩鍫鍬鍮鍰鍲鍴鍶鍸鍺鍼鍾鐀鐂鐄鐆鐈鐊鐌鐎鐓鐕鐗鐙鐝鐟鐡鐣鐥鐧鐩鐫鐭鐯鐱鐳鐵鐷鐹鐻鐽鐿鑺锟斤拷')
bad = [(i + 1, l) for i, l in enumerate(t.split('\n')) if any(c in clues for c in l)]
print('mojibake_lines=', len(bad))
for i, l in bad[:5]:
    print(i, l[:80])
