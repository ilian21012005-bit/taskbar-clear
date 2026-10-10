# Build TaskbarClear.dll + inject-once.exe (requires VS 2022 Build Tools C++)
$ErrorActionPreference = 'Stop'
$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat introuvable" }

$root = Split-Path -Parent $PSScriptRoot
if ((Split-Path -Leaf $PSScriptRoot) -ne 'native') {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Path
    $native = Join-Path $root 'native'
} else {
    $native = $PSScriptRoot
    $root = Split-Path -Parent $native
}

$src = Join-Path $native 'TaskbarClear'
$inj = Join-Path $native 'inject-once'
$out = Join-Path $root 'bin'
$obj = Join-Path $native 'obj'
New-Item -ItemType Directory -Force -Path $out, $obj | Out-Null

$tmp = Join-Path $env:TEMP 'build-taskbarclear.cmd'
@"
@echo off
call "$vcvars"
if errorlevel 1 exit /b 1
cl.exe /nologo /LD /EHsc /O2 /MD /W3 /D_CRT_SECURE_NO_WARNINGS /DWIN32 /DNDEBUG /D_WINDOWS /D_USRDLL /I"$src" "$src\TaskbarClear.cpp" /Fe:"$out\TaskbarClear_new.dll" /Fo:"$obj\\" /link /DEF:"$src\TaskbarClear.def" /DLL /MACHINE:X64 ole32.lib oleaut32.lib uuid.lib user32.lib shlwapi.lib shell32.lib WindowsApp.lib
if errorlevel 1 exit /b 1
if exist "$out\TaskbarClear.dll" del /f "$out\TaskbarClear.dll" 2>nul
if exist "$out\TaskbarClear.dll" (
  echo [BUILD] WARN TaskbarClear.dll verrouillee - binaire dans TaskbarClear_new.dll
) else (
  move /y "$out\TaskbarClear_new.dll" "$out\TaskbarClear.dll" >nul
)
cl.exe /nologo /EHsc /O2 /MD /W3 /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE "$inj\inject-once.cpp" /Fe:"$out\inject-once_new.exe" /Fo:"$obj\inject-once.obj" /link /MACHINE:X64 user32.lib psapi.lib shlwapi.lib
if errorlevel 1 exit /b 1
move /y "$out\inject-once_new.exe" "$out\inject-once.exe" >nul
if errorlevel 1 exit /b 1
echo BUILD_OK
"@ | Set-Content -Path $tmp -Encoding ASCII

cmd /c $tmp
if ($LASTEXITCODE -ne 0) { throw "Build failed: $LASTEXITCODE" }
Get-Item "$out\TaskbarClear.dll", "$out\inject-once.exe" | Format-Table Name, Length, LastWriteTime
