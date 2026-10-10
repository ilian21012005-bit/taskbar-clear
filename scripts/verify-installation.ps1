#Requires -Version 5.1
# Diagnostic rapide pour utilisateurs / support GitHub Issues.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$here = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$issues = @()

function Add-Issue([string]$Text) { $script:issues += $Text }

Write-Host '=== TaskbarClear - verification ===' -ForegroundColor Cyan
Write-Host "Repo: $here"
Write-Host "Build OS: $([Environment]::OSVersion.VersionString)"

foreach ($rel in @('bin\inject-once.exe', 'bin\TaskbarClear.dll', 'apply-at-logon.ps1')) {
    $p = Join-Path $here $rel
    if (Test-Path -LiteralPath $p) {
        Write-Host "OK  $rel"
    }
    else {
        Add-Issue "Manquant: $rel"
        Write-Host "ERR $rel" -ForegroundColor Red
    }
}

foreach ($taskName in @('TransparentTaskbar-Once', 'VisualClean-Once')) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "SKIP tache absente: $taskName"
        continue
    }
    $info = Get-ScheduledTaskInfo -TaskName $taskName
    Write-Host ("OK  {0} LastRun={1} Result={2}" -f $taskName, $info.LastRunTime, $info.LastTaskResult)
    if ($taskName -eq 'TransparentTaskbar-Once' -and $info.LastTaskResult -ne 0) {
        Add-Issue "Derniere execution TransparentTaskbar-Once en echec: $($info.LastTaskResult)"
    }
}

$log = Join-Path $env:LOCALAPPDATA 'transparent-taskbar\inject-at-logon.log'
if (Test-Path -LiteralPath $log) {
    Write-Host ''
    Write-Host '--- inject-at-logon.log (tail 5) ---'
    Get-Content -LiteralPath $log -Tail 5
}
else {
    Add-Issue 'Log inject-at-logon.log absent'
}

Write-Host ''
if ($issues.Count -eq 0) {
    Write-Host 'Aucun probleme detecte.' -ForegroundColor Green
    exit 0
}

Write-Host 'Problemes detectes:' -ForegroundColor Yellow
$issues | ForEach-Object { Write-Host (' - ' + $_) }
exit 1
