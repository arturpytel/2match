@echo off
rem J.A.R.V.I.S. - uruchamia lokalny serwer i otwiera panel jako osobna aplikacje (Microsoft Edge)
cd /d "%~dp0"
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
timeout /t 1 /nobreak >nul
start "" msedge --app=http://localhost:8765/ --start-maximized
