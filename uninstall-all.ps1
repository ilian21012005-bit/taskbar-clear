#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$RestartExplorer,
    [switch]$RestoreVisualDefaults
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot

$taskParams = @{}
if ($RestartExplorer) {
    $taskParams['RestartExplorer'] = $true
}
& (Join-Path $here 'uninstall-task.ps1') @taskParams

$visualUninstall = Join-Path $here 'visual-clean\uninstall-visual-clean-task.ps1'
if (Test-Path -LiteralPath $visualUninstall) {
    if ($RestoreVisualDefaults) {
        & $visualUninstall -RestoreDefaults -RestartExplorer:$RestartExplorer
    }
    else {
        & $visualUninstall
    }
}

Write-Host 'Desinstallation terminee (taches planifiees).'
