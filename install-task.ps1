#Requires -Version 5.1
# Planifie l'injection TaskbarClear a l'ouverture de session (+30 s) et au deverrouillage (+5 s).
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
$taskLogon = 'TransparentTaskbar-Once'
$taskUnlock = 'TransparentTaskbar-Unlock'

function Register-TaskbarClearTask {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [object[]]$Triggers,
        [Parameter(Mandatory)]
        [string]$Description
    )

    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    cmd /c "schtasks /Delete /TN `"$Name`" /F >nul 2>nul"

    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
    $action = New-ScheduledTaskAction `
        -Execute 'powershell.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$wrapper`"" `
        -WorkingDirectory $here
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
        -MultipleInstances IgnoreNew `
        -Hidden

    Register-ScheduledTask `
        -TaskName $Name `
        -Action $action `
        -Trigger $Triggers `
        -Principal $principal `
        -Settings $settings `
        -Description $Description `
        | Out-Null
}

function New-UnlockTriggerXmlTask {
    param(
        [string]$TaskName,
        [string]$Description,
        [string]$Delay = 'PT5S'
    )

    $userId = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
    $wrapperEsc = [Security.SecurityElement]::Escape($wrapper)

    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$Description</Description>
  </RegistrationInfo>
  <Triggers>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <Delay>$Delay</Delay>
      <StateChange>SessionUnlock</StateChange>
      <UserId>$userId</UserId>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userId</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>Limited</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT2M</ExecutionTimeLimit>
    <Hidden>true</Hidden>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$wrapperEsc"</Arguments>
      <WorkingDirectory>$here</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    cmd /c "schtasks /Delete /TN `"$TaskName`" /F >nul 2>nul"
    Register-ScheduledTask -TaskName $TaskName -Xml $xml | Out-Null
}

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

$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$logonTrigger.Delay = 'PT30S'

Register-TaskbarClearTask `
    -Name $taskLogon `
    -Triggers @($logonTrigger) `
    -Description 'Injecte TaskbarClear.dll dans explorer.exe au logon (+30s), puis se termine.'

New-UnlockTriggerXmlTask `
    -TaskName $taskUnlock `
    -Description 'Re-injecte TaskbarClear apres deverrouillage session si necessaire (+5s).'

Write-Host ("Taches installees : {0}, {1}" -f $taskLogon, $taskUnlock)
Write-Host 'Declencheurs    : logon +30s, deverrouillage session +5s'
Write-Host 'RunLevel        : Limited'
Write-Host 'Journal logon   : %LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log'
Write-Host ''
Write-Host 'Si la barre reste opaque au boot :'
Write-Host '  1. .\add-defender-exclusion.ps1   (admin, une fois)'
Write-Host '  2. .\apply.cmd'
