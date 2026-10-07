#Requires -Version 5.1
# Restaure les reglages visuels depuis la sauvegarde locale.
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stateDir = Join-Path $env:LOCALAPPDATA 'transparent-taskbar'
$backupPath = Join-Path $stateDir 'visual-clean-backup.json'

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

function Invoke-VisualRefresh {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeVisualRefresh {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@ -ErrorAction SilentlyContinue | Out-Null

    [void][NativeVisualRefresh]::SystemParametersInfo(0x103F, 0, [IntPtr]::Zero, 0x03)
    [void][NativeVisualRefresh]::SystemParametersInfo(0x0049, 0, [IntPtr]::Zero, 0x03)
}

if (-not (Test-Path -LiteralPath $backupPath)) {
    throw "Sauvegarde introuvable : $backupPath. Lance apply-visual-clean.ps1 d'abord."
}

$backup = Get-Content -LiteralPath $backupPath -Raw -Encoding UTF8 | ConvertFrom-Json
$restored = 0

foreach ($entry in $backup.Values) {
    if ($null -eq $entry.Value) {
        continue
    }

    $value = ConvertFrom-BackupValue -Value $entry.Value -Type $entry.Type
    Set-Reg -Path $entry.Path -Name $entry.Name -Value $value -Type $entry.Type
    $restored++
}

Invoke-VisualRefresh

Write-Host "Restaure $restored valeur(s) depuis $($backup.SavedAt)."

if ($RestartExplorer) {
    Write-Host 'Redemarrage Explorer...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    Start-Process explorer.exe
}
