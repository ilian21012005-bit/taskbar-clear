#Requires -Version 5.1
# Ajoute une exclusion Defender pour bin\ (inject-once = faux positif Bearfoos.A!ml).
#MustRunAsAdmin
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Elevation admin requise pour l exclusion Defender...'
    $self = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$self`"" -Wait
    exit $LASTEXITCODE
}

$here = (Resolve-Path -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$binPath = (Resolve-Path -LiteralPath (Join-Path $here 'bin')).Path
if (-not $binPath.StartsWith($here, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Chemin bin invalide : $binPath"
}

if (-not (Test-Path -LiteralPath $binPath)) {
    throw "Dossier introuvable : $binPath"
}

$pref = Get-MpPreference
if ($pref.ExclusionPath -contains $binPath) {
    Write-Host "Exclusion deja presente : $binPath"
    exit 0
}

Add-MpPreference -ExclusionPath $binPath
Write-Host "Exclusion Defender ajoutee : $binPath"
Write-Host 'inject-once.exe ne sera plus mis en quarantaine au demarrage.'
