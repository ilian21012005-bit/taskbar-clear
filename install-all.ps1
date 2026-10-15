#Requires -Version 5.1
# Installe TaskbarClear (+ option visual-clean) en une commande.
[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$WithVisualClean,
    [switch]$SkipDefenderPrompt
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$setupArgs = @()
if ($Silent) { $setupArgs += '-Silent' }
if ($WithVisualClean) {
    if ($Silent) {
        throw 'Combinaison invalide : -Silent implique deja SkipVisualClean. Utilise -WithVisualClean sans -Silent.'
    }
}
else {
    $setupArgs += '-SkipVisualClean'
}
if ($SkipDefenderPrompt) { $setupArgs += '-SkipDefenderPrompt' }

& (Join-Path $here 'setup.ps1') @setupArgs

if ($WithVisualClean -and -not $Silent) {
    & (Join-Path $here 'visual-clean\install-visual-clean-task.ps1')
}
