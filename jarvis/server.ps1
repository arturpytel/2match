# J.A.R.V.I.S. - lokalny pomocnik (Windows)
# 1) serwuje panel na http://localhost:8765 (przegladarka pamieta zgode na mikrofon)
# 2) wykonuje polecenia z panelu: programy, glosnosc, muzyka, foldery, blokada, wylaczanie
#
# Bezpieczenstwo: nasluchuje tylko na localhost, a kazde polecenie musi miec losowy token,
# ktory serwer wpisuje do panelu przy starcie. Inne strony internetowe go nie znaja.
# Uruchamia tylko programy z menu Start i kilka narzedzi systemowych - nigdy dowolnych komend.

$port = 8765
$self = $MyInvocation.MyCommand.Path
$root = (Split-Path -Parent $self).TrimEnd('\') + '\'
$origin = "http://localhost:$port"
$token = [guid]::NewGuid().ToString('N')

# Zamknij starsza kopie pomocnika (np. po aktualizacji plikow)
try {
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
    Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine.ToLower().Contains($self.ToLower()) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 400
} catch {}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() } catch { exit 0 }

$wsh = New-Object -ComObject WScript.Shell
$types = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.css' = 'text/css'; '.png' = 'image/png'; '.svg' = 'image/svg+xml'; '.json' = 'application/json'; '.md' = 'text/plain; charset=utf-8'; '.mp3' = 'audio/mpeg'; '.m4a' = 'audio/mp4'; '.wav' = 'audio/wav'; '.ogg' = 'audio/ogg'; '.ico' = 'image/x-icon' }

# ---------- pomocnicze ----------
function Normalize([string]$s) {
  if (-not $s) { return '' }
  $d = $s.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $d.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  $r = $sb.ToString().Replace([string][char]0x0142, 'l')
  return (($r -replace '[^a-z0-9 ]', ' ') -replace '\s+', ' ').Trim()
}

function Send-Bytes($ctx, [byte[]]$bytes, [string]$type, [int]$code = 200) {
  $ctx.Response.StatusCode = $code
  $ctx.Response.ContentType = $type
  $ctx.Response.Headers['Cache-Control'] = 'no-store'
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
}
function Send-Json($ctx, $obj, [int]$code = 200) {
  $json = ConvertTo-Json -InputObject $obj -Compress -Depth 4
  Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes($json)) 'application/json; charset=utf-8' $code
}

# ---------- programy ----------
# Narzedzia systemowe po polsku (znormalizowane nazwy -> polecenie)
$builtin = @{
  'notatnik' = 'notepad.exe'; 'kalkulator' = 'calc.exe'; 'paint' = 'mspaint.exe'
  'eksplorator' = 'explorer.exe'; 'eksplorator plikow' = 'explorer.exe'; 'pliki' = 'explorer.exe'; 'mojego komputera' = 'explorer.exe'; 'ten komputer' = 'explorer.exe'
  'menedzer zadan' = 'taskmgr.exe'; 'menadzer zadan' = 'taskmgr.exe'; 'manager zadan' = 'taskmgr.exe'
  'ustawienia' = 'ms-settings:'; 'ustawienia systemu' = 'ms-settings:'; 'panel sterowania' = 'control.exe'
  'wiersz polecen' = 'cmd.exe'; 'terminal' = 'wt.exe'; 'nozyczki' = 'snippingtool.exe'; 'wycinanie' = 'snippingtool.exe'
}
$closeAlias = @{ 'notatnik' = 'notepad'; 'kalkulator' = 'calculatorapp'; 'paint' = 'mspaint'; 'menedzer zadan' = 'taskmgr'; 'przegladarke' = 'msedge'; 'przegladarka' = 'msedge'; 'edge' = 'msedge'; 'chrome' = 'chrome'; 'worda' = 'winword'; 'word' = 'winword'; 'excela' = 'excel'; 'excel' = 'excel' }
$browsers = @('msedge', 'chrome', 'firefox', 'opera', 'brave')
$protected = @('explorer', 'powershell', 'pwsh', 'applicationframehost', 'textinputhost', 'shellexperiencehost', 'searchhost', 'startmenuexperiencehost', 'systemsettings', 'lockapp', 'dwm', 'csrss', 'winlogon')

$script:apps = $null
function Get-AppList {
  if ($script:apps) { return $script:apps }
  $list = New-Object System.Collections.ArrayList
  try {
    foreach ($a in (Get-StartApps)) { [void]$list.Add([pscustomobject]@{ Name = $a.Name; Key = (Normalize $a.Name); Target = 'shell:AppsFolder\' + $a.AppID }) }
  } catch {}
  if ($list.Count -eq 0) {
    $dirs = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
    foreach ($lnk in (Get-ChildItem $dirs -Recurse -Filter *.lnk -ErrorAction SilentlyContinue)) {
      [void]$list.Add([pscustomobject]@{ Name = $lnk.BaseName; Key = (Normalize $lnk.BaseName); Target = $lnk.FullName })
    }
  }
  $script:apps = @($list | Where-Object { $_.Key -and $_.Key -notmatch 'uninstall|odinstaluj|readme|release notes|help|pomoc techniczna' })
  return $script:apps
}
function Find-App([string]$query) {
  $k = Normalize $query
  if (-not $k) { return $null }
  $best = $null; $bestScore = 0
  foreach ($a in (Get-AppList)) {
    $s = 0
    if ($a.Key -eq $k) { $s = 100 }
    elseif ($a.Key.StartsWith($k + ' ')) { $s = 85 - [Math]::Min(25, $a.Key.Length - $k.Length) }
    elseif ($k.Length -ge 3 -and $a.Key.StartsWith($k)) { $s = 70 - [Math]::Min(25, $a.Key.Length - $k.Length) }
    elseif ($k.Length -ge 4 -and $a.Key -match ('(^| )' + [regex]::Escape($k) + '( |$)')) { $s = 55 - [Math]::Min(20, $a.Key.Length - $k.Length) }
    elseif ($k.Length -ge 5 -and $a.Key.Contains($k)) { $s = 25 }
    if ($s -gt $bestScore) { $best = $a; $bestScore = $s }
  }
  return $best
}
# Polska odmiana: "uruchom Discorda", "wlacz Steama" -> probujemy tez bez koncowki
function Get-Variants([string]$k) {
  $v = New-Object System.Collections.ArrayList
  [void]$v.Add($k)
  foreach ($end in @('ie', 'em', 'a', 'e', 'u', 'y', 'i')) {
    if ($k.Length -gt ($end.Length + 3) -and $k.EndsWith($end)) { [void]$v.Add($k.Substring(0, $k.Length - $end.Length)) }
  }
  return $v
}
function Find-AppAny([string]$k) {
  foreach ($q in (Get-Variants $k)) { $a = Find-App $q; if ($a) { return $a } }
  return $null
}
function Open-App([string]$query) {
  $k = Normalize $query
  if ($builtin.ContainsKey($k)) {
    try { Start-Process $builtin[$k]; return @{ ok = $true; name = $query } } catch {}
  }
  $app = Find-AppAny $k
  if (-not $app) { $script:apps = $null; $app = Find-AppAny $k }   # odswiez liste (nowo zainstalowane programy)
  if (-not $app) { return @{ ok = $false; error = 'not_found' } }
  if ($app.Target.StartsWith('shell:')) { Start-Process explorer.exe -ArgumentList $app.Target } else { Start-Process $app.Target }
  return @{ ok = $true; name = $app.Name }
}
function Close-App([string]$query) {
  $k = Normalize $query
  if ($closeAlias.ContainsKey($k)) { $k = $closeAlias[$k] }
  if ($k.Length -lt 3) { return @{ ok = $false; error = 'not_found' } }
  $vars = Get-Variants $k
  # po tytule okna szukamy tylko w zwyklych programach - w przegladarce mozna by trafic w okno Jarvisa
  $procs = @()
  foreach ($v in $vars) {
    $procs = @(Get-Process | Where-Object {
      $_.MainWindowHandle -ne 0 -and ($protected -notcontains $_.ProcessName.ToLower()) -and (
        (Normalize $_.ProcessName).Contains($v) -or ($v.Length -ge 4 -and ($browsers -notcontains $_.ProcessName.ToLower()) -and (Normalize $_.MainWindowTitle).Contains($v)))
    })
    if ($procs.Count -gt 0) { break }
  }
  if ($procs.Count -eq 0) { return @{ ok = $false; error = 'not_running' } }
  foreach ($p in $procs) { [void]$p.CloseMainWindow() }
  return @{ ok = $true; name = $procs[0].ProcessName; count = $procs.Count }
}

# ---------- system ----------
function Press([int]$code, [int]$times) { for ($i = 0; $i -lt $times; $i++) { $wsh.SendKeys([string][char]$code) } }
$cpuName = ''
try { $cpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim() } catch {}

function Get-Stats {
  $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
  $os = Get-CimInstance Win32_OperatingSystem
  $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  return @{
    ok = $true
    cpu = [int]$cpu
    cpuName = $cpuName
    ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
    diskTotal = [math]::Round($disk.Size / 1GB)
    diskFree = [math]::Round($disk.FreeSpace / 1GB)
    uptime = [int]((Get-Date) - $os.LastBootUpTime).TotalSeconds
    host = $env:COMPUTERNAME
    os = $os.Caption
  }
}

function Run-Action([string]$action, $data) {
  switch ($action) {
    'ping'     { return @{ ok = $true; host = $env:COMPUTERNAME; version = 2 } }
    'stats'    { return Get-Stats }
    'open_app' { return Open-App ([string]$data.target) }
    'close_app' { return Close-App ([string]$data.target) }
    'open_folder' {
      $f = @{ 'pulpit' = [Environment]::GetFolderPath('Desktop'); 'dokumenty' = [Environment]::GetFolderPath('MyDocuments')
              'obrazy' = [Environment]::GetFolderPath('MyPictures'); 'zdjecia' = [Environment]::GetFolderPath('MyPictures')
              'muzyka' = [Environment]::GetFolderPath('MyMusic'); 'muzyke' = [Environment]::GetFolderPath('MyMusic')
              'wideo' = [Environment]::GetFolderPath('MyVideos'); 'filmy' = [Environment]::GetFolderPath('MyVideos')
              'pobrane' = (Join-Path $env:USERPROFILE 'Downloads') }
      $k = Normalize ([string]$data.target)
      if (-not $f.ContainsKey($k)) { return @{ ok = $false; error = 'not_found' } }
      Start-Process explorer.exe -ArgumentList ('"' + $f[$k] + '"')
      return @{ ok = $true }
    }
    'volume' {
      $steps = [Math]::Max(1, [Math]::Min(50, [int]$data.steps))
      switch ([string]$data.mode) {
        'up'   { Press 175 $steps }
        'down' { Press 174 $steps }
        'mute' { Press 173 1 }
        'set'  { Press 174 50; Press 175 ([int]([Math]::Max(0, [Math]::Min(100, [int]$data.level)) / 2)) }
        default { return @{ ok = $false; error = 'bad_mode' } }
      }
      return @{ ok = $true }
    }
    'media' {
      $codes = @{ 'playpause' = 179; 'next' = 176; 'prev' = 177; 'stop' = 178 }
      if (-not $codes.ContainsKey([string]$data.key)) { return @{ ok = $false; error = 'bad_key' } }
      Press $codes[[string]$data.key] 1
      return @{ ok = $true }
    }
    'open_url' {
      # tylko adresy http/https - otwiera je domyslna przegladarka (bez blokady wyskakujacych okien)
      $uri = $null
      if (-not [Uri]::TryCreate([string]$data.url, [UriKind]::Absolute, [ref]$uri) -or ($uri.Scheme -ne 'https' -and $uri.Scheme -ne 'http')) {
        return @{ ok = $false; error = 'bad_url' }
      }
      Start-Process $uri.AbsoluteUri
      return @{ ok = $true }
    }
    'lock'     { Start-Process rundll32.exe -ArgumentList 'user32.dll,LockWorkStation'; return @{ ok = $true } }
    'shutdown' { Start-Process shutdown.exe -ArgumentList '/s /t 30' -WindowStyle Hidden; return @{ ok = $true; delay = 30 } }
    'restart'  { Start-Process shutdown.exe -ArgumentList '/r /t 30' -WindowStyle Hidden; return @{ ok = $true; delay = 30 } }
    'cancel_shutdown' { Start-Process shutdown.exe -ArgumentList '/a' -WindowStyle Hidden; return @{ ok = $true } }
    'sleep'    { Start-Process rundll32.exe -ArgumentList 'powrprof.dll,SetSuspendState 0,1,0'; return @{ ok = $true } }
    default    { return @{ ok = $false; error = 'unknown_action' } }
  }
}

# ---------- petla serwera ----------
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $req = $ctx.Request
    $path = $req.Url.AbsolutePath
    if ($path.StartsWith('/api/')) {
      $o = $req.Headers['Origin']
      if ($req.HttpMethod -ne 'POST' -or $req.Headers['X-Jarvis-Token'] -ne $token -or ($o -and $o -ne $origin)) {
        Send-Json $ctx @{ ok = $false; error = 'forbidden' } 403
      } else {
        $reader = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
        $raw = $reader.ReadToEnd()
        $data = if ($raw) { $raw | ConvertFrom-Json } else { $null }
        Send-Json $ctx (Run-Action $path.Substring(5) $data)
      }
    } else {
      $rel = [Uri]::UnescapeDataString($path.TrimStart('/'))
      if ($rel -eq '') { $rel = 'index.html' }
      $full = [IO.Path]::GetFullPath((Join-Path $root $rel))
      if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $full -PathType Leaf)) {
        $ext = [IO.Path]::GetExtension($full).ToLower()
        $type = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
        if ($ext -eq '.html') {
          $html = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8).Replace('__JARVIS_TOKEN__', $token)
          Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes($html)) $type
        } else {
          Send-Bytes $ctx ([IO.File]::ReadAllBytes($full)) $type
        }
      } else {
        Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes('404')) 'text/plain' 404
      }
    }
  } catch {
    try { Send-Json $ctx @{ ok = $false; error = 'server_error'; detail = $_.Exception.Message } 500 } catch {}
  }
  try { $ctx.Response.Close() } catch {}
}
