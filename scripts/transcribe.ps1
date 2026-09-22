# Transcribe one or more audio/video files locally on Windows (PowerShell).
# Usage: powershell -File scripts\transcribe.ps1 media\2026-09-19\<MsgID>.ogg
# Set up once with: powershell -File scripts\setup-transcription.ps1
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Files)
$venv = if ($env:WA_VENV) { $env:WA_VENV } else { Join-Path $env:USERPROFILE '.wa-agent-venv' }
$py = Join-Path $venv 'Scripts\python.exe'
if (-not (Test-Path $py)) {
    Write-Error 'Transcription is not set up yet. Run: powershell -File scripts\setup-transcription.ps1'
    exit 2
}
& $py (Join-Path $PSScriptRoot 'transcribe.py') @Files
exit $LASTEXITCODE
