#Requires -Version 5.1
# Supprime la tache. Pour restaurer le fond opaque: -RestartExplorer
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Unregister-ScheduledTask -TaskName 'TransparentTaskbar-Once' -Confirm:$false -ErrorAction SilentlyContinue
Write-Host 'Tache TransparentTaskbar-Once supprimee.'

if ($RestartExplorer) {
    Write-Host 'Redemarrage Explorer...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    Write-Host 'Explorer relance. TaskbarClear.dll dechargee.'
}
else {
    Write-Host 'Pour enlever le Clear: .\uninstall-task.ps1 -RestartExplorer'
}
