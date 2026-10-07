#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$RestoreDefaults,
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskName = 'VisualClean-Once'

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Tache supprimee : $taskName"

if ($RestoreDefaults) {
    $restoreScript = Join-Path $here 'restore-visual-clean.ps1'
    if (-not (Test-Path -LiteralPath $restoreScript)) {
        throw "Script introuvable : $restoreScript"
    }

    $args = @('-File', $restoreScript)
    if ($RestartExplorer) {
        $args += '-RestartExplorer'
    }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass @args
}
