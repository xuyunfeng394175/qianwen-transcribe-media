[CmdletBinding()]
param(
    [string]$SkillDirectory = (Split-Path -Parent $PSScriptRoot),
    [switch]$InstallFFmpeg
)

$ErrorActionPreference = "Stop"
$actions = [System.Collections.Generic.List[object]]::new()

function Record([string]$Name, [string]$Status, [string]$Detail) {
    $actions.Add([ordered]@{ name=$Name; status=$Status; detail=$Detail })
}

if ($env:OS -ne "Windows_NT") { throw "This setup script only supports Windows." }
if ($PSVersionTable.PSVersion.Major -lt 5) { throw "PowerShell 5.1 or later is required." }

$downloads = Join-Path $HOME "Downloads"
if (-not (Test-Path -LiteralPath $downloads -PathType Container)) {
    New-Item -ItemType Directory -Path $downloads -Force | Out-Null
    Record "downloads-directory" "created" $downloads
} else { Record "downloads-directory" "unchanged" $downloads }

if ($InstallFFmpeg -and -not (Get-Command ffprobe.exe -ErrorAction SilentlyContinue)) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        Record "ffmpeg" "blocked" "winget is unavailable; install App Installer from Microsoft Store or install FFmpeg manually."
    } else {
        & winget install --id Gyan.FFmpeg --exact --scope user --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0) { throw "winget failed to install FFmpeg (exit $LASTEXITCODE)." }
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")
        Record "ffmpeg" "installed" "Gyan.FFmpeg via winget (current user scope)"
    }
} elseif ($InstallFFmpeg) { Record "ffmpeg" "unchanged" "ffprobe already available" }

$testScript = Join-Path $SkillDirectory "scripts\Test-Environment.ps1"
$currentPowerShell = Join-Path $PSHOME "powershell.exe"
if (-not (Test-Path -LiteralPath $currentPowerShell -PathType Leaf)) {
    $currentPowerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
}
$raw = & $currentPowerShell -ExecutionPolicy Bypass -File $testScript -SkillDirectory $SkillDirectory
$testExit = $LASTEXITCODE

[ordered]@{
    setupAt = (Get-Date).ToString("o")
    actions = @($actions)
    verificationExitCode = $testExit
    verification = ($raw -join "`n" | ConvertFrom-Json)
} | ConvertTo-Json -Depth 8

exit $testExit
