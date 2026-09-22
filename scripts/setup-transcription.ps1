# One-time setup of local voice-note transcription on Windows (PowerShell).
# Creates a private Python environment at %USERPROFILE%\.wa-agent-venv, installs faster-whisper, downloads the model.
$ErrorActionPreference = 'Stop'
$venv = if ($env:WA_VENV) { $env:WA_VENV } else { Join-Path $env:USERPROFILE '.wa-agent-venv' }
$model = if ($env:WA_WHISPER_MODEL) { $env:WA_WHISPER_MODEL } else { 'small' }

$pyExe = $null
foreach ($cand in @('py', 'python', 'python3')) {
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if ($cmd) { $pyExe = $cmd.Source; break }
}
if (-not $pyExe) { throw 'Python 3 was not found. Install it from https://www.python.org/downloads/ (tick "Add python.exe to PATH"), then run this again.' }
$pyArgs = @(); if ((Split-Path $pyExe -Leaf) -like 'py*') { $pyArgs = @('-3') }
& $pyExe @pyArgs -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'
if ($LASTEXITCODE -ne 0) { throw 'Python 3.9 or newer is needed.' }

if (-not (Test-Path (Join-Path $venv 'Scripts\python.exe'))) {
    Write-Host "Creating a private Python environment at $venv ..."
    & $pyExe @pyArgs -m venv $venv
}
$py = Join-Path $venv 'Scripts\python.exe'

Write-Host 'Installing faster-whisper (pinned to the version tested on Windows) ...'
& $py -m pip install --quiet --upgrade pip
& $py -m pip install --quiet 'faster-whisper==1.2.1'

Write-Host "Downloading the '$model' speech model the first time (small is about 460 MB) ..."
$env:WA_WHISPER_MODEL = $model
& $py -c "import os; from faster_whisper import WhisperModel; WhisperModel(os.environ['WA_WHISPER_MODEL'], device='cpu', compute_type='int8'); print('model ready')"
if ($LASTEXITCODE -ne 0) { throw 'Model download failed.' }

Write-Host 'Transcription is ready. Test it with: powershell -File scripts\transcribe.ps1 <audio file>'
