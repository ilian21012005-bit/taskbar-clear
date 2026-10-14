#Requires -Version 5.1
# Planifie l'injection TaskbarClear a l'ouverture de session (+30 s).
# RunLevel = Limited (meme integrite qu'Explorer).
[CmdletBinding()]
param(
    [switch]$SkipDefenderExclusion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$wrapper = Join-Path $here 'apply-at-logon.ps1'
$exe = Join-Path $here 'bin\inject-once.exe'
$dll = Join-Path $here 'bin\TaskbarClear.dll'
$taskName = 'TransparentTaskbar-Once'

if (-not (Test-Path -LiteralPath $exe)) {
    throw "inject-once.exe introuvable : $exe. Restaure depuis git ou lance native\build.cmd."
}
if (-not (Test-Path -LiteralPath $dll)) {
    throw "TaskbarClear.dll introuvable : $dll"
}
if (-not (Test-Path -LiteralPath $wrapper)) {
    throw "apply-at-logon.ps1 introuvable : $wrapper"
}

if (-not $SkipDefenderExclusion) {
    Write-Host 'Important : Windows Defender peut mettre inject-once.exe en quarantaine (faux positif).'
    Write-Host 'Lance add-defender-exclusion.ps1 en admin avant le prochain reboot.'
    Write-Host ''
}

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
cmd /c "schtasks /Delete /TN `"$taskName`" /F >nul 2>nul"

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$wrapper`"" `
    -WorkingDirectory $here
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$logonTrigger.Delay = 'PT30S'
# Re-injecte si Explorer a redemarre apres verrouillage (zero processus resident).
$unlockTrigger = New-ScheduledTaskTrigger -AtSessionUnlock -User $env:USERNAME
$unlockTrigger.Delay = 'PT5S'
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -MultipleInstances IgnoreNew `
    -Hidden

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger @($logonTrigger, $unlockTrigger) `
    -Principal $principal `
    -Settings $settings `
    -Description 'Injecte TaskbarClear.dll dans explorer.exe au logon (+30s), puis se termine.' `
    | Out-Null

$info = Get-ScheduledTask -TaskName $taskName
Write-Host ("Tache installee : {0}" -f $info.TaskName)
Write-Host 'Declencheurs    : logon +30s, deverrouillage session +5s'
Write-Host ("RunLevel        : {0}" -f $info.Principal.RunLevel)
Write-Host 'Journal logon   : %LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log'
Write-Host ''
Write-Host 'Si la barre reste opaque au boot :'
Write-Host '  1. .\add-defender-exclusion.ps1   (admin, une fois)'
Write-Host '  2. .\apply.cmd'
