$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
Set-Location $root
$repo = 'denniswung/GamePadDex'
$tmp = Join-Path $env:TEMP 'v166_api'
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$remoteHead = (gh api "repos/$repo/git/ref/heads/main" --jq '.object.sha').Trim()
$remoteTree = (gh api "repos/$repo/git/commits/$remoteHead" --jq '.tree.sha').Trim()
Write-Output "remoteHead=$remoteHead"
Write-Output "remoteTree=$remoteTree"

$diffLines = git diff --name-status "$remoteHead..HEAD"
$changed = @()
foreach ($l in $diffLines) {
  if (-not $l) { continue }
  $parts = $l -split "`t"
  if ($parts.Count -lt 2) { continue }
  $changed += ,@($parts[0], $parts[1])
}
Write-Output "changed files=$($changed.Count)"

$entries = New-Object System.Collections.ArrayList
$i = 0
foreach ($c in $changed) {
  $i++
  $status = $c[0]; $path = $c[1]
  if ($status -eq 'D') {
    [void]$entries.Add(@{ path = $path; mode = '100644'; type = 'blob'; sha = $null })
    Write-Output "[$i/$($changed.Count)] DEL $path"
    continue
  }
  $full = Join-Path $root ($path -replace '/', '\')
  if (-not (Test-Path $full)) { Write-Output "[$i] SKIP missing $path"; continue }
  $mode = '100644'
  $ls = git ls-tree HEAD -- $path
  if ($ls -match '^(\d+) blob') { $mode = $matches[1] }
  $bytes = [System.IO.File]::ReadAllBytes($full)
  $b64 = [Convert]::ToBase64String($bytes)
  $pf = Join-Path $tmp 'blob.json'
  [System.IO.File]::WriteAllText($pf, (@{ content = $b64; encoding = 'base64' } | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
  $sha = (gh api -X POST "repos/$repo/git/blobs" --input $pf --jq '.sha').Trim()
  if (-not $sha) { throw "blob upload failed: $path" }
  [void]$entries.Add(@{ path = $path; mode = $mode; type = 'blob'; sha = $sha })
  Write-Output "[$i/$($changed.Count)] PUT $path ($($bytes.Length)B, $sha)"
}

$treeFile = Join-Path $tmp 'tree.json'
$treeObj = @{ base_tree = $remoteTree; tree = $entries }
[System.IO.File]::WriteAllText($treeFile, ($treeObj | ConvertTo-Json -Depth 6 -Compress), (New-Object System.Text.UTF8Encoding($false)))
$newTree = (gh api -X POST "repos/$repo/git/trees" --input $treeFile --jq '.sha').Trim()
Write-Output "newTree=$newTree"

$msg = (git log -1 --format=%B).Trim()
$commitFile = Join-Path $tmp 'commit.json'
$commitObj = @{ message = $msg; tree = $newTree; parents = @($remoteHead) }
[System.IO.File]::WriteAllText($commitFile, ($commitObj | ConvertTo-Json -Depth 4 -Compress), (New-Object System.Text.UTF8Encoding($false)))
$newCommit = (gh api -X POST "repos/$repo/git/commits" --input $commitFile --jq '.sha').Trim()
Write-Output "newCommit=$newCommit"

$refFile = Join-Path $tmp 'ref.json'
[System.IO.File]::WriteAllText($refFile, (@{ sha = $newCommit; force = $false } | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
$r = gh api -X PATCH "repos/$repo/git/refs/heads/main" --input $refFile --jq '.object.sha'
Write-Output "refNow=$r"

$localTree = (git show -s --format=%T HEAD).Trim()
$remoteTreeNow = (gh api "repos/$repo/git/commits/$(git rev-parse HEAD)" --jq '.tree.sha').Trim()
Write-Output "localTree=$localTree"
Write-Output "remoteCommitTree=$remoteTreeNow"
if ($localTree -eq $remoteTreeNow) { Write-Output 'TREE MATCH: remote == local HEAD' } else { Write-Output 'TREE MISMATCH' }
