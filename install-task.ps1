#Requires -Version 5.1
# Planifie inject-once.exe a l'ouverture de session (LoadLibrary dans explorer, puis exit).
# RunLevel = Limited obligatoire (meme integrite qu'Explorer).
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $here 'bin\inject-once.exe'
$dll = Join-Path $here 'bin\TaskbarClear.dll'
$taskName = 'TransparentTaskbar-Once'

if (-not (Test-Path -LiteralPath $exe)) {
    throw "inject-once.exe introuvable : $exe. Lance native\build.cmd d'abord."
}
if (-not (Test-Path -LiteralPath $dll)) {
    throw "TaskbarClear.dll introuvable : $dll"
}

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$action = New-ScheduledTaskAction -Execute $exe
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trigger.Delay = 'PT15S'
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
    -Description 'Injecte TaskbarClear.dll dans explorer.exe une fois a la session, puis se termine.' `
    | Out-Null

$info = Get-ScheduledTask -TaskName $taskName
Write-Host ("Tache installee : {0}" -f $info.TaskName)
Write-Host 'Declencheur     : ouverture de session +15s'
Write-Host ("RunLevel        : {0}" -f $info.Principal.RunLevel)
Write-Host 'Apres injection : seul TaskbarClear.dll reste dans explorer.exe.'
