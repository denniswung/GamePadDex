Add-Type -AssemblyName System.Drawing
function D($a,$b){
  $ia=[System.Drawing.Bitmap]::FromFile($a); $ib=[System.Drawing.Bitmap]::FromFile($b)
  $w=[Math]::Min($ia.Width,$ib.Width); $h=[Math]::Min($ia.Height,$ib.Height); $chg=0; $tot=0
  for($y=0;$y -lt $h;$y+=8){ for($x=0;$x -lt $w;$x+=8){ $pa=$ia.GetPixel($x,$y); $pb=$ib.GetPixel($x,$y)
    $d=[Math]::Abs($pa.R-$pb.R)+[Math]::Abs($pa.G-$pb.G)+[Math]::Abs($pa.B-$pb.B); if($d -gt 60){$chg++}; $tot++ } }
  $ia.Dispose(); $ib.Dispose(); return [Math]::Round(100.0*$chg/$tot,2)
}
$b='work\docs\evidence-drag-raw-t37'
"P0->P1: $(D "$b\P0.png" "$b\P1.png")%"
"P1->P2: $(D "$b\P1.png" "$b\P2.png")%"
"P2->P3: $(D "$b\P2.png" "$b\P3.png")%"
"P0->P2: $(D "$b\P0.png" "$b\P2.png")%"
"P0->P3: $(D "$b\P0.png" "$b\P3.png")%"