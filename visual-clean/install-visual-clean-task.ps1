#Requires -Version 5.1
# Planifie apply-visual-clean.ps1 a l'ouverture de session (+5 s), sans admin.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $here 'apply-visual-clean.ps1'
$taskName = 'VisualClean-Once'

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Script introuvable : $scriptPath"
}

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -SkipBackup"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trigger.Delay = 'PT5S'
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
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Desactive animations et effets visuels superflus (registre HKCU, one-shot au logon).' `
    | Out-Null

$info = Get-ScheduledTask -TaskName $taskName
Write-Host ("Tache installee : {0}" -f $info.TaskName)
Write-Host 'Declencheur     : ouverture de session +5s'
Write-Host ("RunLevel        : {0}" -f $info.Principal.RunLevel)
Write-Host 'Processus       : aucun (script PowerShell puis exit)'
