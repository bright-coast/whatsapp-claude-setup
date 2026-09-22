<#
.SYNOPSIS
  What is publicly known right now about wacli pairing problems (Windows version of preflight.sh).

.DESCRIPTION
  Reads public GitHub pages only (no login) and prints short, filtered output.
  Tested on Windows 11 (Windows PowerShell 5.1 and PowerShell 7 hosts) on 19 Sep 2026.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File preflight.ps1
#>
$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

function Get-Api([string]$Path) {
  try { return Invoke-RestMethod -Uri "https://api.github.com/$Path" -Headers @{ 'User-Agent' = 'wacli-setup' } } catch { return $null }
}
# Format-Day: GitHub gives UTC times. Show the date in this computer's own timezone.
function Format-Day($Value) {
  try {
    if ($Value -is [DateTime]) { $dt = $Value.ToUniversalTime() }
    else {
      $styles = [Globalization.DateTimeStyles]::AdjustToUniversal -bor [Globalization.DateTimeStyles]::AssumeUniversal
      $dt = [DateTime]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture, $styles)
    }
    return $dt.ToLocalTime().ToString('yyyy-MM-dd')
  } catch { return "$Value" }
}
function Write-Issue($Issue) {
  if ($Issue) { Write-Output ("#{0}  {1}  (updated {2})  {3}" -f $Issue.number, $Issue.state, (Format-Day $Issue.updated_at), $Issue.title) }
  else { Write-Output '(could not reach GitHub)' }
}

Write-Output '== wacli installed on this computer'
$cmd = Get-Command wacli -ErrorAction SilentlyContinue
if ($cmd) { & wacli --version } else { Write-Output "(wacli is not on this shell's PATH)" }

Write-Output ''
Write-Output '== Latest wacli release on GitHub'
$rel = Get-Api 'repos/openclaw/wacli/releases/latest'
if ($rel) {
  Write-Output ("tag: {0}   published: {1}   prerelease: {2}" -f $rel.tag_name, (Format-Day $rel.published_at), $rel.prerelease)
  Write-Output ''
  Write-Output '== Lines of the release notes that mention pairing, auth, passkey, QR or login'
  $hits = @(($rel.body -split "`r?`n") | Where-Object { $_ -match 'auth|pair|passkey|link|qr|login' })
  if ($hits.Count -gt 0) { $hits } else { Write-Output '(none)' }
} else {
  Write-Output '(could not reach GitHub)'
}

foreach ($term in 'pair', 'passkey', 'QR') {
  Write-Output ''
  Write-Output "== Open wacli issues that mention: $term  (number, state, last updated, title)"
  $res = Get-Api "search/issues?q=repo:openclaw/wacli+is:issue+is:open+$term&per_page=10"
  if ($res) {
    if ($res.items.Count -eq 0) { Write-Output '(none)' }
    foreach ($i in $res.items) { Write-Issue $i }
  } else { Write-Output '(could not reach GitHub)' }
}

Write-Output ''
Write-Output '== wacli issue 355 (passkey-gated accounts cannot pair)'
Write-Issue (Get-Api 'repos/openclaw/wacli/issues/355')
Write-Output ''
Write-Output '== wacli issue 365 (some groups have little or no text after a fresh link)'
Write-Issue (Get-Api 'repos/openclaw/wacli/issues/365')
Write-Output ''
Write-Output '== whatsmeow issue 1267 (source of: unsupported QR pairing state)'
Write-Issue (Get-Api 'repos/tulir/whatsmeow/issues/1267')
