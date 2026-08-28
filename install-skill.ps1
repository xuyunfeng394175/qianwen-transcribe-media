[CmdletBinding()]
param(
    [ValidateSet("Auto", "TraeWork", "WorkBuddy", "Codex", "Claude", "Cursor", "Agents", "Custom")]
    [string]$Client = "Auto",
    [string]$DestinationRoot
)

$ErrorActionPreference = "Stop"
$source = Join-Path $PSScriptRoot "qianwen-transcribe-media"

if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md") -PathType Leaf)) {
    throw "Package is incomplete: qianwen-transcribe-media\SKILL.md was not found."
}

$knownRoots = [ordered]@{
    TraeWork = (Join-Path $HOME ".trae\skills")
    WorkBuddy = (Join-Path $HOME ".workbuddy\skills")
    Codex = (Join-Path $HOME ".codex\skills")
    Claude = (Join-Path $HOME ".claude\skills")
    Cursor = (Join-Path $HOME ".cursor\skills")
    Agents = (Join-Path $HOME ".agents\skills")
}

if ($Client -eq "Custom") {
    if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
        throw "Custom installation requires -DestinationRoot."
    }
} elseif (-not [string]::IsNullOrWhiteSpace($DestinationRoot)) {
    # An explicit destination always wins over a known default.
} elseif ($Client -eq "Auto") {
    $detected = @($knownRoots.GetEnumerator() | Where-Object {
        Test-Path -LiteralPath (Split-Path -Parent $_.Value) -PathType Container
    })
    if ($detected.Count -eq 0) {
        throw "No supported AI client directory was detected. Rerun with -Client Custom -DestinationRoot <skills-directory>."
    }
    if ($detected.Count -gt 1) {
        $choices = ($detected | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "
        throw "Multiple AI clients were detected: $choices. Select one with -Client or pass -DestinationRoot."
    }
    $Client = [string]$detected[0].Key
    $DestinationRoot = [string]$detected[0].Value
} else {
    $DestinationRoot = [string]$knownRoots[$Client]
}

$destination = Join-Path $DestinationRoot "qianwen-transcribe-media"
New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

if (Test-Path -LiteralPath $destination) {
    $backup = "$destination.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse -Force
    Write-Host "Existing skill backed up to: $backup"
    Remove-Item -LiteralPath $destination -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
if (-not (Test-Path -LiteralPath (Join-Path $destination "SKILL.md") -PathType Leaf)) {
    throw "Installation verification failed."
}

Write-Host "Installed for client: $Client"
Write-Host "Installed skill: $destination"
Write-Host "Restart or reload the AI client, then run the environment initialization template."
