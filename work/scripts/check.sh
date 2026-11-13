#!/bin/bash
set -u
bash /mnt/e/Dennis/GamePadDex复刻/work/scripts/env.sh
echo "=== latest jadx tag ==="
curl -s --max-time 30 https://api.github.com/repos/skylot/jadx/releases/latest | grep -m1 '"tag_name"'
