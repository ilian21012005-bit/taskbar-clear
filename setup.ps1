#Requires -Version 5.1
<#
.SYNOPSIS
    Installation guidee TaskbarClear (+ option profil visual-clean).
.DESCRIPTION
    Verifie Windows 11, les binaires, propose l exclusion Defender, installe la tache logon et applique Clear.
#>
[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$SkipVisualClean,
    [switch]$SkipDefenderPrompt,
    [switch]$NoApplyNow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = (Resolve-Path -LiteralPath $PSScriptRoot).Path

function Test-Windows11 {
    $build = [Environment]::OSVersion.Version.Build
    if ($build -lt 22621) {
        throw "Windows 11 build 22621+ requis (detecte: $build)."
    }
}

function Test-Binaries {
    $required = @(
        (Join-Path $here 'bin\inject-once.exe'),
        (Join-Path $here 'bin\TaskbarClear.dll'),
        (Join-Path $here 'apply-at-logon.ps1'),
        (Join-Path $here 'install-task.ps1')
    )
    foreach ($path in $required) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Fichier manquant : $path"
        }
    }
}

if ($Silent) {
    $SkipDefenderPrompt = $true
    $SkipVisualClean = $true
}

Write-Host '=== TaskbarClear — installation ===' -ForegroundColor Cyan
Test-Windows11
Test-Binaries

if (-not $SkipDefenderPrompt) {
    Write-Host ''
    Write-Host 'Defender peut bloquer inject-once.exe (faux positif). Exclusion recommandee (admin, une fois).'
    $answer = Read-Host 'Lancer add-defender-exclusion.ps1 maintenant ? (O/n)'
    if ($answer -eq '' -or $answer -match '^[oOyY]') {
        & (Join-Path $here 'add-defender-exclusion.ps1')
    }
}

& (Join-Path $here 'install-task.ps1') -SkipDefenderExclusion

if (-not $SkipVisualClean) {
    $answer = Read-Host 'Installer aussi visual-clean (animations OFF au logon) ? (o/N)'
    if ($answer -match '^[oOyY]') {
        & (Join-Path $here 'visual-clean\install-visual-clean-task.ps1')
    }
}

if (-not $NoApplyNow) {
    Write-Host ''
    Write-Host 'Application immediate...' -ForegroundColor Cyan
    & (Join-Path $here 'apply.cmd')
}

Write-Host ''
Write-Host 'Termine. Au prochain login : barre Clear automatique (~30 s apres connexion).'
Write-Host 'Log : %LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log'
