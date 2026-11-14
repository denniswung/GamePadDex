#!/system/bin/sh
KL=/system/usr/keylayout/Generic.kl
for k in 1 14 15 28 59 60 61 62 63 64 65 66 67 68 87 88 99 102 103 104 105 106 107 108 109 111 113 114 115 116 125 126 127 139 158 163 164 165 172 580; do
  printf '%s: ' "$k"
  grep -m1 -E "^key $k " $KL || echo "(none)"
done
