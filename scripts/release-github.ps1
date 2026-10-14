#Requires -Version 5.1
# Cree une release GitHub avec les binaires bin/ et CHECKSUMS.sha256 (gh CLI requis).
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Tag,

    [string]$Title,

    [string]$NotesFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root 'bin'

foreach ($name in @('inject-once.exe', 'TaskbarClear.dll', 'CHECKSUMS.sha256')) {
    $path = Join-Path $bin $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Manquant pour release : $path"
    }
}

& (Join-Path $root 'scripts\verify-checksums.ps1')

$zip = Join-Path $env:TEMP ("taskbar-clear-$Tag-win-x64.zip")
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }

Compress-Archive -Path @(
    (Join-Path $bin 'inject-once.exe'),
    (Join-Path $bin 'TaskbarClear.dll'),
    (Join-Path $bin 'CHECKSUMS.sha256')
) -DestinationPath $zip

$releaseTitle = if ($Title) { $Title } else { "TaskbarClear $Tag" }
$notesArg = @()
if ($NotesFile) {
    $notesArg = @('--notes-file', $NotesFile)
}
else {
    $notesArg = @('--generate-notes')
}

gh release create $Tag $zip `
    --repo 'ilian21012005-bit/taskbar-clear' `
    --title $releaseTitle `
    @notesArg

Write-Host "Release publiee : $Tag"
