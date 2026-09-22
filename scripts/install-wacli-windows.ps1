<#
.SYNOPSIS
  Installs the latest wacli on Windows, with a SHA-256 check.

.DESCRIPTION
  Tested on Windows 11 (PowerShell 7 host) on 19 Sep 2026, in a temporary folder, with wacli 0.18.2.
  1. Asks GitHub which wacli release is the latest (it never assumes a version).
  2. Downloads wacli_<version>_windows_amd64.zip and checksums.txt.
  3. Checks the SHA-256. A mismatch deletes the download and stops.
  4. Unzips wacli.exe into -InstallDir and (unless -NoPath) adds that folder to the user PATH.
  5. Prints lines that start with "RESULT:" so the outcome is easy to read.
  It never changes the machine PATH and never touches the .wacli store folder.

.PARAMETER InstallDir
  Where wacli.exe goes. Default: %LOCALAPPDATA%\wacli\bin

.PARAMETER DownloadDir
  Where the zip and checksums.txt are kept. Default: %LOCALAPPDATA%\wacli\download

.PARAMETER NoPath
  Do not add InstallDir to the user PATH (used for testing).

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File install-wacli-windows.ps1
#>
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'wacli\bin'),
  [string]$DownloadDir = (Join-Path $env:LOCALAPPDATA 'wacli\download'),
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

$Repo = 'openclaw/wacli'

function Get-LatestTag {
  $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'wacli-setup' }
  return $rel.tag_name
}

# Test-Sha256: true only if the expected hash is not empty and matches the file.
function Test-Sha256([string]$File, [string]$Expected) {
  if ([string]::IsNullOrWhiteSpace($Expected)) { return $false }
  $actual = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLower()
  return ($actual -eq $Expected.Trim().ToLower())
}

function Install-Wacli {
  $tag = Get-LatestTag
  if ([string]::IsNullOrWhiteSpace($tag)) { throw 'Could not read the latest wacli release from GitHub.' }
  $ver = $tag.TrimStart('v')
  Write-Output "Latest wacli release: $tag"

  $zip  = "wacli_${ver}_windows_amd64.zip"
  $base = "https://github.com/$Repo/releases/download/$tag"
  New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null
  $zipPath  = Join-Path $DownloadDir $zip
  $sumsPath = Join-Path $DownloadDir 'checksums.txt'

  Write-Output "Downloading $zip and checksums.txt ..."
  Invoke-WebRequest -Uri "$base/$zip" -OutFile $zipPath -UseBasicParsing
  Invoke-WebRequest -Uri "$base/checksums.txt" -OutFile $sumsPath -UseBasicParsing

  $line = Get-Content -LiteralPath $sumsPath | Where-Object { $_.EndsWith($zip) } | Select-Object -First 1
  $expected = ''
  if ($line) { $expected = $line.Split(' ')[0].ToLower() }
  $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLower()
  Write-Output "expected SHA-256: $(if ($expected) { $expected } else { '<none found>' })"
  Write-Output "actual SHA-256:   $actual"
  if (-not (Test-Sha256 -File $zipPath -Expected $expected)) {
    Remove-Item -LiteralPath $zipPath -Force
    throw 'STOP: the SHA-256 does not match the release checksums.txt. The download was deleted and nothing was installed.'
  }
  Write-Output 'SHA-256 matches.'

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $InstallDir -Force
  } catch {
    throw "Could not write wacli.exe into $InstallDir. If a background wacli sync is running, stop it first (see docs\background-sync.md). Details: $($_.Exception.Message)"
  }
  $exe = Join-Path $InstallDir 'wacli.exe'
  if (-not (Test-Path -LiteralPath $exe)) { throw "The zip did not contain wacli.exe." }

  $pathState = 'not changed (-NoPath)'
  if (-not $NoPath) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $InstallDir) {
      [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $InstallDir), 'User')
      $pathState = 'added to the user PATH (only programs started from now on will see it)'
    } else {
      $pathState = 'already on the user PATH'
    }
  }

  $installed = (& $exe --version 2>&1 | Out-String).Trim()
  $match = if ($installed -like "*$ver*") { 'yes' } else { 'no' }

  Write-Output ''
  Write-Output "RESULT: latest_release=$tag"
  Write-Output "RESULT: installed_path=$exe"
  Write-Output "RESULT: installed_version=$installed"
  Write-Output "RESULT: installed_matches_latest=$match"
  Write-Output 'RESULT: checksum=verified'
  Write-Output "RESULT: user_path=$pathState"
}

# Run only when executed, not when dot-sourced (so the functions can be tested).
if ($MyInvocation.InvocationName -ne '.') { Install-Wacli }
