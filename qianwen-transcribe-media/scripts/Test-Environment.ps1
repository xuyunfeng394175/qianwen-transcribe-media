[CmdletBinding()]
param([string]$SkillDirectory = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$checks = [System.Collections.Generic.List[object]]::new()
$actions = [System.Collections.Generic.List[string]]::new()

function Add-Check([string]$Name, [bool]$Ok, [bool]$Required, [string]$Detail, [bool]$Fixable = $false) {
    $checks.Add([ordered]@{ name=$Name; ok=$Ok; required=$Required; fixable=$Fixable; detail=$Detail })
    if (-not $Ok -and $Fixable) { $actions.Add($Name) }
}

$isWindows = $env:OS -eq "Windows_NT"
Add-Check "windows" $isWindows $true "$($env:OS) $([Environment]::OSVersion.Version)"

$is64Bit = [Environment]::Is64BitOperatingSystem
Add-Check "windows-x64" $is64Bit $true $(if ($is64Bit) { "64-bit OS" } else { "32-bit OS is unsupported" })

$psOk = $PSVersionTable.PSVersion.Major -ge 5
Add-Check "powershell-5.1+" $psOk $true $PSVersionTable.PSVersion.ToString()

$clientPatterns = [ordered]@{
    TraeWork = "trae"
    WorkBuddy = "workbuddy"
    Codex = "codex"
    Claude = "claude"
    Cursor = "cursor"
}
$runningProcesses = @(Get-Process -ErrorAction SilentlyContinue)
$detectedClients = @($clientPatterns.GetEnumerator() | Where-Object {
    $pattern = $_.Value
    $null -ne ($runningProcesses | Where-Object { $_.ProcessName -match $pattern } | Select-Object -First 1)
} | ForEach-Object { $_.Key })
$clientDetail = if ($detectedClients.Count -gt 0) {
    "Running client candidates: " + ($detectedClients -join ", ")
} else {
    "No known client process detected; the active AI must report its own capabilities"
}
Add-Check "ai-client-diagnostic" ($detectedClients.Count -gt 0) $false $clientDetail

$requiredFiles = @("SKILL.md", "references\client-capabilities.md", "scripts\Test-Environment.ps1", "scripts\Setup-Environment.ps1", "scripts\Preflight-Media.ps1", "scripts\Finalize-Transcript.ps1")
$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $SkillDirectory $_) -PathType Leaf) })
Add-Check "skill-files" ($missing.Count -eq 0) $true $(if ($missing) { "Missing: " + ($missing -join ", ") } else { $SkillDirectory })

$downloads = Join-Path $HOME "Downloads"
Add-Check "downloads-directory" (Test-Path -LiteralPath $downloads -PathType Container) $true $downloads $true

$writeOk = $false
try {
    if (Test-Path -LiteralPath $downloads -PathType Container) {
        $probe = Join-Path $downloads (".ai-client-env-" + [guid]::NewGuid().ToString("N") + ".tmp")
        [IO.File]::WriteAllText($probe, "ok"); Remove-Item -LiteralPath $probe -Force; $writeOk = $true
    }
} catch {}
Add-Check "downloads-writable" $writeOk $true $downloads $true

$networkOk = $false
try { $networkOk = Test-NetConnection -ComputerName "www.qianwen.com" -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue } catch {}
Add-Check "qianwen-https" $networkOk $true "www.qianwen.com:443"

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
Add-Check "winget" ($null -ne $winget) $false $(if ($winget) { $winget.Source } else { "Optional; needed for automatic FFmpeg installation" })

$ffmpeg = Get-Command ffprobe.exe -ErrorAction SilentlyContinue
Add-Check "ffprobe" ($null -ne $ffmpeg) $false $(if ($ffmpeg) { $ffmpeg.Source } else { "Optional; enables local duration validation" }) ($null -ne $winget)

$requiredFailures = @($checks | Where-Object { $_.required -and -not $_.ok })
$fixableFailures = @($requiredFailures | Where-Object { $_.fixable })
$status = if ($requiredFailures.Count -eq 0) { "ready" } elseif ($requiredFailures.Count -eq $fixableFailures.Count) { "fixable" } else { "blocked" }

[ordered]@{
    schemaVersion = 1
    checkedAt = (Get-Date).ToString("o")
    overallStatus = $status
    checks = @($checks)
    requiredActions = @($actions)
    note = "The active AI client must separately verify command execution, browser navigation, page inspection and interaction, local file upload, bounded waits, local downloads, and user takeover."
} | ConvertTo-Json -Depth 6

if ($status -eq "ready") { exit 0 } elseif ($status -eq "fixable") { exit 10 } else { exit 20 }
