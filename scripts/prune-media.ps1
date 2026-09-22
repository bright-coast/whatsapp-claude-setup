# Delete downloaded media older than N days from the project's media\ folder (Windows PowerShell).
# Only files inside media\ are touched. Messages stored by wacli are not affected.
# Usage: powershell -File scripts\prune-media.ps1 30
param([int]$Days = 30)
$media = Join-Path (Split-Path -Parent $PSScriptRoot) 'media'
if (-not (Test-Path $media)) { Write-Host 'no media folder yet, nothing to delete'; exit 0 }
$cutoff = (Get-Date).AddDays(-$Days)
$old = Get-ChildItem -Path $media -Recurse -File | Where-Object { $_.LastWriteTime -lt $cutoff }
$count = @($old).Count
$old | Remove-Item -Force
Get-ChildItem -Path $media -Recurse -Directory | Sort-Object FullName -Descending | Where-Object { -not (Get-ChildItem $_.FullName -Force) } | Remove-Item -Force
Write-Host "deleted $count file(s) older than $Days days from media\"
