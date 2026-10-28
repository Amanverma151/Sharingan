# Watchful Wallpaper launcher
# Listens only on this computer (127.0.0.1) and opens the apps listed below
# when you click them on the wallpaper's dock. Nothing else can be launched.

$Port = 47823

# id (must match the wallpaper's APPS list) -> what to open
$Apps = @{
  settings = @{ Target = 'ms-settings:' }
  gmail    = @{ Target = 'https://mail.google.com' }
  spotify  = @{ Target = 'spotify:' }
  youtube  = @{ Target = 'https://www.youtube.com' }
  chrome   = @{ Paths = @(
                 "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                 "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                 "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") }
  brave    = @{ Paths = @(
                 "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
                 "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
                 "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe") }
  recycle  = @{ Exe = 'explorer.exe'; Args = 'shell:RecycleBinFolder' }
}

function Start-App([string]$id) {
  $a = $Apps[$id]
  if (-not $a) { return $false }
  try {
    if ($a.Paths) {
      $exe = $a.Paths | Where-Object { Test-Path $_ } | Select-Object -First 1
      if (-not $exe) { return $false }
      Start-Process -FilePath $exe
    } elseif ($a.Exe) {
      Start-Process -FilePath $a.Exe -ArgumentList $a.Args
    } else {
      Start-Process $a.Target
    }
    return $true
  } catch { return $false }
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try { $listener.Start() } catch {
  Write-Host "Port $Port is busy - the launcher is probably already running."
  exit
}
Write-Host "Watchful Wallpaper launcher running on http://127.0.0.1:$Port"

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $line   = $reader.ReadLine()
    $status = '404 Not Found'
    if ($line -match '^GET /launch/([A-Za-z0-9_-]+) ') {
      if (Start-App $Matches[1]) { $status = '204 No Content' }
    }
    $resp  = "HTTP/1.1 $status`r`nAccess-Control-Allow-Origin: *`r`nContent-Length: 0`r`nConnection: close`r`n`r`n"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($resp)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
  } catch { } finally { $client.Close() }
}
