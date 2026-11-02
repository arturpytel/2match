# Tworzy skrot "Jarvis" z ikonka na pulpicie i w menu Start (opcjonalnie tez autostart).
# Skrot uruchamia start-jarvis.bat przez cmd.exe - dzieki temu da sie go tez przypiac do paska zadan.
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat = Join-Path $dir 'start-jarvis.bat'
$ico = Join-Path $dir 'jarvis.ico'
if (-not (Test-Path $bat)) { Write-Host "Nie znaleziono start-jarvis.bat w folderze $dir" -ForegroundColor Red; exit 1 }

$wsh = New-Object -ComObject WScript.Shell
function New-JarvisShortcut([string]$folder) {
  $lnk = $wsh.CreateShortcut((Join-Path $folder 'Jarvis.lnk'))
  $lnk.TargetPath = $env:ComSpec
  $lnk.Arguments = '/c "' + $bat + '"'
  $lnk.WorkingDirectory = $dir
  $lnk.IconLocation = "$ico,0"
  $lnk.WindowStyle = 7
  $lnk.Description = 'J.A.R.V.I.S.'
  $lnk.Save()
}

New-JarvisShortcut ([Environment]::GetFolderPath('Desktop'))
New-JarvisShortcut ([Environment]::GetFolderPath('Programs'))
Write-Host ''
Write-Host 'Gotowe! Skrot "Jarvis" jest na pulpicie i w menu Start.' -ForegroundColor Cyan

$a = Read-Host 'Czy Jarvis ma sie wlaczac sam razem z Windowsem? (t/n)'
if ($a -match '^[tTyY]') {
  New-JarvisShortcut ([Environment]::GetFolderPath('Startup'))
  Write-Host 'Autostart wlaczony.' -ForegroundColor Cyan
} else {
  $old = Join-Path ([Environment]::GetFolderPath('Startup')) 'Jarvis.lnk'
  if (Test-Path $old) { Remove-Item $old; Write-Host 'Autostart wylaczony.' }
}
Write-Host ''
Write-Host 'Jesli przeniesiesz folder Jarvisa w inne miejsce, uruchom ten plik jeszcze raz.'
