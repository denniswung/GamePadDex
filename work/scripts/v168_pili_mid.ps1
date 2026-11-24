Add-Type -AssemblyName System.Drawing
function D($a,$b){
  $ia=[System.Drawing.Bitmap]::FromFile($a); $ib=[System.Drawing.Bitmap]::FromFile($b)
  $w=[Math]::Min($ia.Width,$ib.Width); $h=[Math]::Min($ia.Height,$ib.Height); $chg=0; $tot=0
  for($y=0;$y -lt $h;$y+=8){ for($x=0;$x -lt $w;$x+=8){ $pa=$ia.GetPixel($x,$y); $pb=$ib.GetPixel($x,$y)
    $d=[Math]::Abs($pa.R-$pb.R)+[Math]::Abs($pa.G-$pb.G)+[Math]::Abs($pa.B-$pb.B); if($d -gt 60){$chg++}; $tot++ } }
  $ia.Dispose(); $ib.Dispose(); return [Math]::Round(100.0*$chg/$tot,2)
}
$b='work\docs\evidence-drag-raw-t37'
"PiliPlus before->mid(1.15s): $(D "$b\P_before.png" "$b\P_mid12.png")%"
"PiliPlus mid(1.15s)->after:  $(D "$b\P_mid12.png" "$b\P_after.png")%"
"PiliPlus before->after:      $(D "$b\P_before.png" "$b\P_after.png")%"