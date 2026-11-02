@echo off
rem J.A.R.V.I.S. - uruchamia pomocnika i otwiera panel jako osobna aplikacje (Microsoft Edge)
rem Osobny profil Edge dla Jarvisa: dzieki temu intro z muzyka i glos startuja same, bez klikania.
cd /d "%~dp0"
start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
timeout /t 1 /nobreak >nul
start "" msedge --app=http://localhost:8765/ --start-maximized --user-data-dir="%LOCALAPPDATA%\JarvisEdge" --autoplay-policy=no-user-gesture-required --no-first-run --no-default-browser-check
