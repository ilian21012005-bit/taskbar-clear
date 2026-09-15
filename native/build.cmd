@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "SRCDIR=%~dp0TaskbarClear"
set "INJDIR=%~dp0inject-once"
set "OUTDIR=%ROOT%\bin"
set "OBJDIR=%~dp0obj"
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

if not exist "%VCVARS%" (
  echo [BUILD] vcvars64.bat introuvable
  echo [BUILD] %VCVARS%
  exit /b 1
)

echo [BUILD] Init x64...
call "%VCVARS%"
if errorlevel 1 exit /b 1

if not exist "%OUTDIR%\" mkdir "%OUTDIR%"
if not exist "%OBJDIR%\" mkdir "%OBJDIR%"

echo [BUILD] TaskbarClear.dll...
cl.exe /nologo /LD /EHsc /O2 /MD /W3 /D_CRT_SECURE_NO_WARNINGS /DWIN32 /DNDEBUG /D_WINDOWS /D_USRDLL /I"%SRCDIR%" "%SRCDIR%\TaskbarClear.cpp" /Fe:"%OUTDIR%\TaskbarClear.dll" /Fo:"%OBJDIR%\\" /link /DEF:"%SRCDIR%\TaskbarClear.def" /DLL /MACHINE:X64 ole32.lib oleaut32.lib uuid.lib user32.lib shlwapi.lib shell32.lib WindowsApp.lib
if errorlevel 1 goto :fail

echo [BUILD] inject-once.exe...
cl.exe /nologo /EHsc /O2 /MD /W3 /D_CRT_SECURE_NO_WARNINGS /DUNICODE /D_UNICODE "%INJDIR%\inject-once.cpp" /Fe:"%OUTDIR%\inject-once.exe" /Fo:"%OBJDIR%\\inject-once.obj" /link /MACHINE:X64 user32.lib
if errorlevel 1 goto :fail

echo [BUILD] SUCCESS
dir "%OUTDIR%\TaskbarClear.dll" "%OUTDIR%\inject-once.exe"
exit /b 0

:fail
echo [BUILD] FAILED
exit /b 1
