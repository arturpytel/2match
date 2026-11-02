@echo off
rem Tworzy skrot Jarvisa z ikonka na pulpicie i w menu Start
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0utworz-skrot.ps1"
pause
