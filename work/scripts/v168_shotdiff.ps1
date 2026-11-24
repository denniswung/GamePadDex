Add-Type -AssemblyName System.Drawing
function Diff-Pct($a,$b){
  $ia=[System.Drawing.Bitmap]::FromFile($a); $ib=[System.Drawing.Bitmap]::FromFile($b)
  $w=[Math]::Min($ia.Width,$ib.Width); $h=[Math]::Min($ia.Height,$ib.Height)
  $step=8; $tot=0; $chg=0
  for($y=0;$y -lt $h;$y+=$step){
    for($x=0;$x -lt $w;$x+=$step){
      $pa=$ia.GetPixel($x,$y); $pb=$ib.GetPixel($x,$y)
      $d=[Math]::Abs($pa.R-$pb.R)+[Math]::Abs($pa.G-$pb.G)+[Math]::Abs($pa.B-$pb.B)
      if($d -gt 60){$chg++}
      $tot++
    }
  }
  $ia.Dispose(); $ib.Dispose()
  return [pscustomobject]@{Pct=[Math]::Round(100.0*$chg/$tot,2); Samples=$tot}
}
$pairs=@(
  @('E_before.png','E_mid.png','PiliPlus before->mid'),
  @('E_mid.png','E_after.png','PiliPlus mid->after'),
  @('E_before.png','E_after.png','PiliPlus before->after'),
  @('C_release0.png','C_release500.png','C 松手 0->500ms'),
  @('E_lbtop_before.png','E_lbtop_after.png','E 页顶 LB 1s')
)
foreach($p in $pairs){
  $r=Diff-Pct "work\docs\evidence-drag-raw-final\$($p[0])" "work\docs\evidence-drag-raw-final\$($p[1])"
  "{0}: changed={1}% (samples={2})" -f $p[2],$r.Pct,$r.Samples
}
