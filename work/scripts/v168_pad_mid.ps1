Add-Type -AssemblyName System.Drawing
function D($a,$b){
  $ia=[System.Drawing.Bitmap]::FromFile($a); $ib=[System.Drawing.Bitmap]::FromFile($b)
  $w=[Math]::Min($ia.Width,$ib.Width); $h=[Math]::Min($ia.Height,$ib.Height); $chg=0; $tot=0
  for($y=0;$y -lt $h;$y+=8){ for($x=0;$x -lt $w;$x+=8){ $pa=$ia.GetPixel($x,$y); $pb=$ib.GetPixel($x,$y)
    $d=[Math]::Abs($pa.R-$pb.R)+[Math]::Abs($pa.G-$pb.G)+[Math]::Abs($pa.B-$pb.B); if($d -gt 60){$chg++}; $tot++ } }
  $ia.Dispose(); $ib.Dispose(); return [Math]::Round(100.0*$chg/$tot,2)
}
$b='work\docs\evidence-drag-raw-t37'
"padtest before->mid(1.1s): $(D "$b\T_before.png" "$b\T_mid.png")%"
"padtest mid(1.1s)->after:  $(D "$b\T_mid.png" "$b\T_after.png")%"
"padtest before->after:     $(D "$b\T_before.png" "$b\T_after.png")%"