#Requires -Version 5.1
# Regenerer bin/CHECKSUMS.sha256 apres rebuild local.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root 'bin'
$out = Join-Path $bin 'CHECKSUMS.sha256'

$files = @('inject-once.exe', 'TaskbarClear.dll')
$lines = foreach ($name in $files) {
    $path = Join-Path $bin $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Manquant: $path"
    }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $name"
}

$lines | Set-Content -LiteralPath $out -Encoding ASCII
Write-Host "Ecrit: $out"
