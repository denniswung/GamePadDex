param([string]$RunFile = "work\docs\evidence-v169\all_t39.out", [string]$Out = "work\docs\V169-BASELINE.md")
$pri = @{}
(Get-Content "work\docs\_priorities.json" -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $pri[$_.ID] = $_.Pri }
$lines = Get-Content $RunFile -Encoding UTF8
$rows = @()
foreach ($l in $lines) {
  if ($l -match '^([A-Z]+-\d{3}) (PASS|FAIL|BLOCKED|NOTRUN) \| 阈值: (.*?) \| 实测: (.*?) \| 证据: (.*)$') {
    $rows += [pscustomobject]@{ ID=$Matches[1]; V=$Matches[2]; Thr=$Matches[3]; Mea=$Matches[4]; Ev=$Matches[5] }
  }
}
$groups = $rows | Group-Object { ($_.ID -split '-')[0] }
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# V169-BASELINE · v1.68 发布字节全量执行与 FAIL 归因")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> 用例基准：``docs/TEST-CASES-v1.69.md``（142 条，SHA256 2DD0D7EE…1D3B3）")
[void]$sb.AppendLine("> 套件：``work/scripts/v169_suite.sh all``；原始输出：``work/docs/evidence-v169/all_final.out`` / ``v169_all_final.log``")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 0 发布字节绑定（采样期间未变）")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 项 | 值 |")
[void]$sb.AppendLine("|---|---|")
[void]$sb.AppendLine("| APK | ``c8b002880c70dedc1fc6ddbc047bcf87503a6539b8d72693ae32b7e925bbc998``（设备 base.apk） |")
[void]$sb.AppendLine("| helper | ``a1d06e2e9ee03f282cdacb119c5bbad1bc4e5adaaa573a500aacbeb2263bd06d``（/data/adb/gpm = 模块目录） |")
[void]$sb.AppendLine("| 版本 | 1.68 / 70（module v1.68/70） |")
[void]$sb.AppendLine("| 设备 | SM-F9360，2560×1600，Awake，rotation=1，accel=0，无 vgpad |")
[void]$sb.AppendLine("")
# summary
$pass = ($rows | Where-Object V -eq 'PASS').Count; $fail = ($rows | Where-Object V -eq 'FAIL').Count; $blk = ($rows | Where-Object V -eq 'BLOCKED').Count
[void]$sb.AppendLine("## 1 总览")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 项 | 数 |")
[void]$sb.AppendLine("|---|---|")
[void]$sb.AppendLine("| 用例行 | $($rows.Count) |")
[void]$sb.AppendLine("| PASS | $pass |")
[void]$sb.AppendLine("| FAIL | $fail |")
[void]$sb.AppendLine("| BLOCKED | $blk |")
[void]$sb.AppendLine("")
foreach ($p in 'P0','P1','P2') {
  $pr = $rows | Where-Object { $pri[$_.ID] -eq $p }
  $pp = ($pr | Where-Object V -eq 'PASS').Count; $pf = ($pr | Where-Object V -eq 'FAIL').Count; $pb = ($pr | Where-Object V -eq 'BLOCKED').Count
  $rate = if ($pr.Count) { [math]::Round(100.0*$pp/$pr.Count,1) } else { 0 }
  [void]$sb.AppendLine("**$p**：共 $($pr.Count) 条，PASS $pp / FAIL $pf / BLOCKED $pb，PASS 率 **$rate%**")
  [void]$sb.AppendLine("")
}
[void]$sb.AppendLine("## 2 分组明细（ID | 优先级 | 判定 | 阈值 | 实测 | 证据）")
foreach ($g in $groups) {
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("### $($g.Name)（$($g.Count) 条）")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("| ID | 优先级 | 判定 | 阈值 | 实测 | 证据 |")
  [void]$sb.AppendLine("|---|---|---|---|---|---|")
  foreach ($r in $g.Group) {
    $e = $r.Ev; if ($e.Length -gt 70) { $e = $e.Substring($e.Length-70) }
    [void]$sb.AppendLine("| $($r.ID) | $($pri[$r.ID]) | $($r.V) | $($r.Thr) | $($r.Mea) | ``…$e`` |")
  }
}
$sb.ToString() | Set-Content $Out -Encoding UTF8
"wrote $Out rows=$($rows.Count) pass=$pass fail=$fail blk=$blk"
