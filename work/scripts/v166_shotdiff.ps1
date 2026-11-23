param(
  [string]$Shots = "work/docs/evidence-v166-verify/shots",
  [string]$Out   = "work/docs/evidence-v166-verify/shotdiff.txt"
)
# v166_shotdiff.ps1 -- pixel-level diff of <case>_before.png / <case>_after.png
# (PC-side corroboration for the on-device "two independent scroll regions" counters)
#   changed_px / area_KB(changed_px*4/1024) / changed bounding box / top-vs-bottom halves /
#   left-vs-right halves / occupancy of 8 horizontal bands
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File work/scripts/v166_shotdiff.ps1
Add-Type -AssemblyName System.Drawing

function Get-Bytes([string]$path) {
  $bmp = [System.Drawing.Bitmap]::new($path)
  $w = $bmp.Width; $h = $bmp.Height
  $rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
  $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride = [Math]::Abs($data.Stride)
  $len = $stride * $h
  $buf = New-Object byte[] $len
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $len)
  $bmp.UnlockBits($data)
  $bmp.Dispose()
  return @{ w = $w; h = $h; stride = $stride; bytes = $buf }
}

$cases = @()
Get-ChildItem -Path $Shots -Filter "*_before.png" -ErrorAction SilentlyContinue | ForEach-Object {
  $name = $_.Name -replace "_before\.png$", ""
  $after = Join-Path $Shots ("${name}_after.png")
  if (Test-Path $after) { $cases += $name }
}
if ($cases.Count -eq 0) { "no screenshot pairs under $Shots"; exit 0 }

$lines = @()
$lines += "# v1.66 screenshot pixel-diff (PC side)"
$lines += "generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  shots=$Shots"
$lines += ""
$lines += "| case | size | changed_px | area | bbox | top/bottom half px | left/right half px | band occupancy%(8) |"
$lines += "|---|---|---|---|---|---|---|---|"

foreach ($c in $cases) {
  $b = Get-Bytes (Join-Path $Shots "${c}_before.png")
  $a = Get-Bytes (Join-Path $Shots "${c}_after.png")
  if ($b.w -ne $a.w -or $b.h -ne $a.h) { $lines += "| $c | size mismatch | - | - | - | - | - | - |"; continue }
  $w = $b.w; $h = $b.h; $stride = $b.stride
  $changed = 0; $minx = $w; $miny = $h; $maxx = -1; $maxy = -1
  $top = 0; $bottom = 0; $left = 0; $right = 0
  $bandH = [int]($h / 8); $bands = New-Object int[] 8
  for ($y = 0; $y -lt $h; $y++) {
    $ro = $y * $stride
    for ($x = 0; $x -lt $w; $x++) {
      $o = $ro + $x * 4
      if ($b.bytes[$o] -ne $a.bytes[$o] -or $b.bytes[$o + 1] -ne $a.bytes[$o + 1] -or $b.bytes[$o + 2] -ne $a.bytes[$o + 2]) {
        $changed++
        if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }
        if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y }
        if ($y -lt ($h / 2)) { $top++ } else { $bottom++ }
        if ($x -lt ($w / 2)) { $left++ } else { $right++ }
        $bi = [Math]::Min(7, [int][Math]::Floor($y / $bandH)); $bands[$bi]++
      }
    }
  }
  $bbox = if ($maxx -ge 0) { "[$minx,$miny][$maxx,$maxy]" } else { "none" }
  $areaKB = [Math]::Round($changed * 4 / 1024.0, 1)
  $bandTxt = ($bands | ForEach-Object { [Math]::Round($_ * 100.0 / [Math]::Max(1, $changed), 1) }) -join "/"
  $lines += "| $c | ${w}x${h} | $changed | ${areaKB}KB | $bbox | $top / $bottom | $left / $right | $bandTxt |"
}

$lines -join "`r`n" | Out-File -FilePath $Out -Encoding utf8
$lines -join "`r`n" | Write-Output
