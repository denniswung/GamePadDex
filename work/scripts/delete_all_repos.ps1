param([switch]$DryRun)
$ErrorActionPreference = "Continue"
$repos = gh repo list --limit 200 --json name,isFork,visibility 2>$null | ConvertFrom-Json
if (-not $repos) { Write-Output "no repos (network or permission)"; exit 1 }
Write-Output ("repos to delete: " + $repos.Count)
foreach ($r in $repos) { Write-Output ("  {0,-32} {1}" -f $r.name, $r.visibility) }
if ($DryRun) { Write-Output "DRY RUN"; exit 0 }
$ok = 0; $fail = 0
foreach ($r in $repos) {
    $out = gh repo delete "denniswung/$($r.name)" --yes 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Write-Output ("DELETED  " + $r.name); $ok++ }
    else { Write-Output ("FAILED   " + $r.name + "  " + ($out.Trim() -replace "\r?\n", " ")); $fail++ }
}
Write-Output ("ok=" + $ok + " fail=" + $fail)
$left = gh repo list --limit 200 --json name 2>$null | ConvertFrom-Json
if ($left) { Write-Output ("left=" + $left.Count + ": " + (($left | ForEach-Object { $_.name }) -join ", ")) }
else { Write-Output "left=0" }
