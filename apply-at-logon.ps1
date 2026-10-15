#Requires -Version 5.1
# Wrapper logon : attend Explorer, lance inject-once, journalise le resultat.
[CmdletBinding()]
param(
    [int]$MaxAttempts = 3,
    [int]$RetryDelaySeconds = 12
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = (Resolve-Path -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$exe = Join-Path $here 'bin\inject-once.exe'
$expectedBin = Join-Path $here 'bin'
$stateDir = Join-Path $env:LOCALAPPDATA 'transparent-taskbar'
$logPath = Join-Path $stateDir 'inject-at-logon.log'

function Write-Log([string]$Message) {
    Ensure-StateDir
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Ensure-StateDir {
    if (-not (Test-Path -LiteralPath $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
}

try {
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "inject-once.exe introuvable : $exe (Defender en quarantaine ?)"
    }

    $resolvedExe = (Resolve-Path -LiteralPath $exe).Path
    if (-not $resolvedExe.StartsWith($expectedBin, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Chemin inject-once.exe inattendu : $resolvedExe"
    }

    $lastCode = 1
    $lastOutput = ''

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $lastOutput = (& $resolvedExe 2>&1 | Out-String).Trim()
        $lastCode = $LASTEXITCODE
        Write-Log ("attempt={0}/{1} exit={2} {3}" -f $attempt, $MaxAttempts, $lastCode, ($lastOutput -replace '\s+', ' '))

        if ($lastCode -eq 0) {
            exit 0
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    exit $lastCode
}
catch {
    Write-Log ("ERREUR: {0}" -f $_.Exception.Message)
    exit 1
}
