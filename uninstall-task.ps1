#Requires -Version 5.1
# Supprime la tache. Pour restaurer le fond opaque: -RestartExplorer
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($taskName in @('TransparentTaskbar-Once', 'TransparentTaskbar-Unlock')) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    cmd /c "schtasks /Delete /TN `"$taskName`" /F >nul 2>nul"
    Write-Host "Tache supprimee : $taskName"
}

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
