@echo off
cd /d "%~dp0bin"
"%~dp0bin\inject-once.exe"
exit /b %ERRORLEVEL%
