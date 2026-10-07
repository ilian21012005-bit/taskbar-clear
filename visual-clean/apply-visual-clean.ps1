#Requires -Version 5.1
# Applique un profil visuel "perf" natif : desactive animations et effets superflus.
# Aucun processus resident. Registre HKCU uniquement.
[CmdletBinding()]
param(
    [switch]$RestartExplorer,
    [switch]$SkipBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $env:LOCALAPPDATA 'transparent-taskbar'
$backupPath = Join-Path $stateDir 'visual-clean-backup.json'

$visualEffectKeys = @(
    'AnimateMinMax',
    'ComboBoxAnimation',
    'ControlAnimations',
    'CursorShadow',
    'DragFullWindows',
    'DropShadow',
    'ListBoxSmoothScrolling',
    'ListviewAlphaSelect',
    'ListviewShadow',
    'MenuAnimation',
    'SelectionFade',
    'TaskbarAnimations',
    'TooltipAnimation'
)

function Ensure-StateDir {
    if (-not (Test-Path -LiteralPath $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
}

function Read-RegValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch {
        return $null
    }
}

function ConvertTo-BackupValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [byte[]]) {
        return [Convert]::ToBase64String($Value)
    }

    return $Value
}

function ConvertFrom-BackupValue {
    param(
        $Value,
        [ValidateSet('String', 'DWord', 'Binary')]
        [string]$Type
    )

    if ($null -eq $Value) {
        return $null
    }

    switch ($Type) {
        'Binary' { return [Convert]::FromBase64String([string]$Value) }
        'DWord' { return [int]$Value }
        default { return [string]$Value }
    }
}

function Save-Backup {
    Ensure-StateDir

    $backup = [ordered]@{
        SavedAt = (Get-Date).ToString('o')
        Values = @(
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
                Name = 'VisualFXSetting'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting')
            },
            @{
                Path = 'HKCU:\Control Panel\Desktop'
                Name = 'UserPreferencesMask'
                Type = 'Binary'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask')
            },
            @{
                Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'
                Name = 'MinAnimate'
                Type = 'String'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate')
            },
            @{
                Path = 'HKCU:\Control Panel\Desktop'
                Name = 'DragFullWindows'
                Type = 'String'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows')
            },
            @{
                Path = 'HKCU:\Control Panel\Desktop'
                Name = 'MenuShowDelay'
                Type = 'String'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay')
            },
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Name = 'TaskbarAnimations'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations')
            },
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Name = 'ListviewAlphaSelect'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect')
            },
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
                Name = 'ListviewShadow'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow')
            },
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\DWM'
                Name = 'EnableAeroPeek'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'EnableAeroPeek')
            },
            @{
                Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                Name = 'EnableTransparency'
                Type = 'DWord'
                Value = ConvertTo-BackupValue (Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency')
            }
        )
    }

    $backup | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $backupPath -Encoding UTF8
    Write-Host "Sauvegarde : $backupPath"
}

function Set-Reg {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        $Value,
        [ValidateSet('String', 'DWord', 'Binary')]
        [string]$Type = 'DWord'
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

function Invoke-VisualRefresh {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeVisualRefresh {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@ -ErrorAction SilentlyContinue | Out-Null

    # SPI_SETUIEFFECTS (0x103F) + SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
    [void][NativeVisualRefresh]::SystemParametersInfo(0x103F, 0, [IntPtr]::Zero, 0x03)
    # SPI_SETANIMATION (0x0049) with pvParam=FALSE
    [void][NativeVisualRefresh]::SystemParametersInfo(0x0049, 0, [IntPtr]::Zero, 0x03)
}

function Apply-VisualClean {
    Ensure-StateDir

    if (-not $SkipBackup) {
        Save-Backup
    }

    # Meilleures performances (equivalent Panneau de config > Performances visuelles)
    Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -Type DWord

    # Accessibility > Effets visuels > Effets d'animation (OFF)
    Set-Reg -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90, 0x92, 0x07, 0x80, 0x10, 0x00, 0x00, 0x00)) -Type Binary
    Set-Reg -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value '0' -Type String

    # Moins de travail GPU lors du deplacement de fenetres
    Set-Reg -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Value '0' -Type String
    Set-Reg -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -Type String

    Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 0 -Type DWord
    Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Value 0 -Type DWord
    Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow' -Value 0 -Type DWord

    foreach ($effect in $visualEffectKeys) {
        $effectPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\$effect"
        if (-not (Test-Path -LiteralPath $effectPath)) {
            New-Item -Path $effectPath -Force | Out-Null
        }
        Set-Reg -Path $effectPath -Name 'DefaultApplied' -Value 0 -Type DWord
    }

    # Peek / apercu bureau desactive (DWM)
    Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'EnableAeroPeek' -Value 0 -Type DWord

    # Garde la transparence pour TaskbarClear (pas touche si deja ON)
    $transparency = Read-RegValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency'
    if ($null -eq $transparency -or [int]$transparency -eq 0) {
        Set-Reg -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 1 -Type DWord
    }

    Invoke-VisualRefresh

    Write-Host ''
    Write-Host 'Profil visuel perf applique.'
    Write-Host '- Animations systeme : OFF'
    Write-Host '- Ombres / fades / barre des taches : OFF'
    Write-Host '- Aero Peek : OFF'
    Write-Host '- Transparence (TaskbarClear) : conservee'
    Write-Host ''
    Write-Host 'Aucun processus resident. Impact frametime : gratuit (registre one-shot).'

    if ($RestartExplorer) {
        Write-Host 'Redemarrage Explorer...'
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        Start-Process explorer.exe
    }
    else {
        Write-Host 'Astuce : deconnexion/reconnexion ou -RestartExplorer pour tout appliquer immediatement.'
    }
}

Apply-VisualClean
