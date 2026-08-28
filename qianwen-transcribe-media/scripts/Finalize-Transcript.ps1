[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SourceFile,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [Parameter(Mandatory = $true)][datetime]$NotBefore,
    [string]$DownloadDirectory = (Join-Path $HOME "Downloads"),
    [int]$WaitSeconds = 120
)

$ErrorActionPreference = "Stop"
function Emit([object]$Value, [int]$Code) { $Value | ConvertTo-Json -Depth 5; exit $Code }

try {
    $source = Get-Item -LiteralPath $SourceFile -ErrorAction Stop
    if ($source.PSIsContainer) { throw "SourceFile must be a file." }
    $downloadRoot = (Resolve-Path -LiteralPath $DownloadDirectory).Path
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $outputRoot = (Resolve-Path -LiteralPath $OutputDirectory).Path
} catch {
    Emit @{ status = "error"; reason = "invalid-path"; detail = $_.Exception.Message } 2
}

$stem = [regex]::Escape($source.BaseName)
$pattern = "^$stem(?:\s*\(\d+\))?_原文(?:\s*\(\d+\))?\.md$"
$deadline = (Get-Date).AddSeconds([Math]::Max(0, $WaitSeconds))
$matches = @()
do {
    $matches = @(Get-ChildItem -LiteralPath $downloadRoot -File -Filter "*.md" |
        Where-Object { $_.Name -match $pattern -and $_.LastWriteTime -ge $NotBefore } |
        Sort-Object LastWriteTime -Descending)
    if ($matches.Count -gt 0) { break }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)

if ($matches.Count -eq 0) {
    Emit @{ status = "missing-download"; source = $source.FullName; downloadDirectory = $downloadRoot } 4
}
if ($matches.Count -gt 1) {
    Emit @{ status = "ambiguous-download"; candidates = @($matches.FullName) } 5
}

$download = $matches[0]
$destination = Join-Path $outputRoot ($source.BaseName + "_原文.md")
if (Test-Path -LiteralPath $destination -PathType Leaf) {
    Emit @{ status = "collision"; downloadedFile = $download.FullName; destination = $destination } 6
}
if ($download.Length -le 0) {
    Emit @{ status = "invalid-download"; reason = "empty-file"; downloadedFile = $download.FullName } 7
}

try {
    $null = Get-Content -LiteralPath $download.FullName -TotalCount 1 -ErrorAction Stop
    Move-Item -LiteralPath $download.FullName -Destination $destination -ErrorAction Stop
    $verified = Get-Item -LiteralPath $destination -ErrorAction Stop
    if ($verified.Length -le 0) { throw "Destination file is empty." }
} catch {
    Emit @{ status = "error"; reason = "move-or-verify-failed"; detail = $_.Exception.Message } 8
}

Emit ([ordered]@{
    status = "completed"
    source = $source.FullName
    finalPath = $verified.FullName
    bytes = $verified.Length
    modifiedAt = $verified.LastWriteTime.ToString("o")
}) 0
