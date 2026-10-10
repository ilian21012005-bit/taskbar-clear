#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root 'bin'
$manifest = Join-Path $bin 'CHECKSUMS.sha256'

if (-not (Test-Path -LiteralPath $manifest)) {
    throw "Manifeste introuvable: $manifest"
}

$failed = $false
Get-Content -LiteralPath $manifest | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $parts = $line -split '\s+', 2
    if ($parts.Count -lt 2) { return }
    $expected = $parts[0].ToLowerInvariant()
    $name = $parts[1]
    $path = Join-Path $bin $name
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "[FAIL] manquant: $name" -ForegroundColor Red
        $failed = $true
        return
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -eq $expected) {
        Write-Host "[OK] $name"
    }
    else {
        Write-Host "[FAIL] $name (hash mismatch)" -ForegroundColor Red
        $failed = $true
    }
}

if ($failed) { exit 1 }
