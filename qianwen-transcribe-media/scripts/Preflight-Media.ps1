[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$videoExtensions = @(".mp4", ".wmv", ".m4v", ".flv", ".rmvb", ".dat", ".mov", ".mkv", ".webm", ".avi", ".mpeg", ".3gp", ".ogg")
$audioExtensions = @(".mp3", ".wav", ".m4a", ".wma", ".aac", ".ogg", ".amr", ".flac", ".aiff")

function Emit([object]$Value, [int]$Code) {
    $Value | ConvertTo-Json -Depth 6
    exit $Code
}

try {
    $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
} catch {
    Emit @{ status = "error"; reason = "source-not-found"; source = $SourcePath } 2
}

try {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $resolvedOutput = (Resolve-Path -LiteralPath $OutputDirectory).Path
    $probe = Join-Path $resolvedOutput (".write-" + [guid]::NewGuid().ToString("N") + ".tmp")
    [IO.File]::WriteAllText($probe, "ok")
    Remove-Item -LiteralPath $probe -Force
} catch {
    Emit @{ status = "error"; reason = "output-not-writable"; detail = $_.Exception.Message } 3
}

$sourceItem = Get-Item -LiteralPath $resolvedSource
$files = if ($sourceItem.PSIsContainer) {
    @(Get-ChildItem -LiteralPath $resolvedSource -File | Sort-Object Name)
} else {
    @($sourceItem)
}
$ffprobe = Get-Command ffprobe.exe -ErrorAction SilentlyContinue

$items = foreach ($file in $files) {
    $extension = $file.Extension.ToLowerInvariant()
    $isVideo = $videoExtensions -contains $extension
    $isAudio = $audioExtensions -contains $extension
    $isOgg = $extension -eq ".ogg"
    $expectedOutput = Join-Path $resolvedOutput ($file.BaseName + "_原文.md")
    $status = "ready"
    $reason = $null
    $duration = $null

    if (-not ($isVideo -or $isAudio)) {
        $status = "unsupported"; $reason = "unsupported-extension"
    } elseif ($isOgg -and $file.Length -gt 500MB) {
        $status = "unsupported"; $reason = "ogg-over-conservative-500MB-limit"
    } elseif ($isVideo -and $file.Length -gt 6GB) {
        $status = "unsupported"; $reason = "video-over-6GB"
    } elseif ((-not $isVideo) -and $isAudio -and $file.Length -gt 500MB) {
        $status = "unsupported"; $reason = "audio-over-500MB"
    } elseif (Test-Path -LiteralPath $expectedOutput -PathType Leaf) {
        $status = "existing-output"; $reason = "destination-exists"
    }

    if ($ffprobe -and $status -eq "ready") {
        try {
            $duration = [double](& $ffprobe.Source -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file.FullName)
            if ($isVideo -and $duration -gt 21600) {
                $status = "unsupported"; $reason = "video-over-6-hours"
            }
        } catch {
            $duration = $null
        }
    }

    [ordered]@{
        source = $file.FullName
        fileName = $file.Name
        bytes = $file.Length
        durationSeconds = $duration
        expectedOutput = $expectedOutput
        status = $status
        reason = $reason
    }
}

Emit ([ordered]@{ status = "ok"; source = $resolvedSource; outputDirectory = $resolvedOutput; items = @($items) }) 0
