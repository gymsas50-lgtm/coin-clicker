$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, 3000)
$job = $null
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Get-Version {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes((Join-Path $root 'index.html'))))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
}
try {
    $listener.Start()
    $job = Start-Job -ArgumentList $root -ScriptBlock {
        param($root)
        $ErrorActionPreference = 'Stop'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $dest = Join-Path $root 'index.html'
        $temp = Join-Path $root 'download.tmp'
        $backup = Join-Path $root 'index.previous.html'
        $statusFile = Join-Path $root 'update-status.txt'
        $enc = New-Object Text.UTF8Encoding($false)
        $lastRevision = $null
        while ($true) {
            $web = $null
            try {
                $url = [IO.File]::ReadAllText((Join-Path $root 'source-url.txt')).Trim()
                $uri = [Uri]$url
                if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'raw.githubusercontent.com' -or $uri.AbsolutePath -ne '/gymsas50-lgtm/coin-clicker/main/index.html') { throw 'Invalid update URL. Expected this game on raw.githubusercontent.com.' }
                # Read Git's branch advertisement, then fetch an immutable revision.
                # No REST API token or 60 requests/hour API quota is involved.
                $refsRequest = [Net.HttpWebRequest]::Create('https://github.com/gymsas50-lgtm/coin-clicker.git/info/refs?service=git-upload-pack')
                $refsRequest.Timeout = 10000
                $refsRequest.ReadWriteTimeout = 10000
                $refsRequest.UserAgent = 'git/2.43.0'
                $refsRequest.Headers['Cache-Control'] = 'no-cache'
                $refsResponse = $refsRequest.GetResponse()
                try {
                    $refsReader = New-Object IO.StreamReader($refsResponse.GetResponseStream())
                    try { $advertisement = $refsReader.ReadToEnd() } finally { $refsReader.Dispose() }
                } finally { $refsResponse.Dispose() }
                $match = [regex]::Match($advertisement, '([0-9a-f]{40}) refs/heads/main')
                if (-not $match.Success) { throw 'Cannot determine latest game revision' }
                $revision = $match.Groups[1].Value
                if ($revision -eq $lastRevision) {
                    [IO.File]::WriteAllText($statusFile, ('UP TO DATE ' + (Get-Date -Format 'HH:mm:ss') + ' rev ' + $revision.Substring(0,7)), $enc)
                    Start-Sleep -Seconds 2
                    continue
                }
                $uri = [Uri]('https://raw.githubusercontent.com/gymsas50-lgtm/coin-clicker/' + $revision + '/index.html')
                $builder = New-Object UriBuilder($uri)
                $builder.Query = 'check=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                $request = [Net.HttpWebRequest]::Create($builder.Uri)
                $request.Timeout = 12000
                $request.ReadWriteTimeout = 12000
                $request.UserAgent = 'CoinClickerUpdater/2.0'
                $request.Headers['Cache-Control'] = 'no-cache'
                $web = $request.GetResponse()
                $inputStream = $web.GetResponseStream()
                $memory = New-Object IO.MemoryStream
                try { $inputStream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $inputStream.Dispose(); $memory.Dispose() }
                if ($bytes.Length -lt 300 -or $bytes.Length -gt 2097152) { throw 'Unexpected update size' }
                $html = [Text.Encoding]::UTF8.GetString($bytes)
                if (-not $html.Contains('<meta name="app-id" content="arena-coin-clicker">') -or -not $html.Contains('</html>') -or -not $html.Contains('simple-coin-clicker.v1')) { throw 'Not a clicker update. Keeping current game.' }
                $old = [Convert]::ToBase64String([IO.File]::ReadAllBytes($dest))
                if ($old -ne [Convert]::ToBase64String($bytes)) {
                    [IO.File]::WriteAllBytes($temp, $bytes)
                    [IO.File]::Replace($temp, $dest, $backup)
                    [IO.File]::WriteAllText($statusFile, ('UPDATED ' + (Get-Date -Format 'HH:mm:ss')), $enc)
                } else {
                    [IO.File]::WriteAllText($statusFile, ('UP TO DATE ' + (Get-Date -Format 'HH:mm:ss')), $enc)
                }
                $lastRevision = $revision
            } catch {
                try { [IO.File]::WriteAllText($statusFile, ('OFFLINE - keeping local game. ' + $_.Exception.GetBaseException().Message), $enc) } catch {}
            } finally {
                if ($web) { $web.Dispose() }
                if (Test-Path $temp) { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
            }
            Start-Sleep -Seconds 2
        }
    }
    Write-Host ''
    Write-Host 'COIN CLICKER - AUTO UPDATE SERVER' -ForegroundColor Yellow
    Write-Host 'PC: http://localhost:3000'
    Write-Host 'iPhone: open your home network address below in Safari:'
    foreach ($ip in [Net.Dns]::GetHostAddresses([Net.Dns]::GetHostName())) {
        if ($ip.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and -not [Net.IPAddress]::IsLoopback($ip)) {
            Write-Host ('  http://' + $ip.IPAddressToString + ':3000') -ForegroundColor Green
        }
    }
    Write-Host 'Allow PRIVATE networks in Windows Firewall. Keep this window open.'
    Write-Host 'Updates: automatic. Status: update-status.txt in this folder.'
    Write-Host 'FAST UPDATE: immutable Git revision; check every 2 seconds.'
    Write-Host ''
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 3000
            $client.SendTimeout = 3000
            $stream = $client.GetStream()
            $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            $first = $reader.ReadLine()
            if (-not $first) { continue }
            $total = 0
            while ($true) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { break }
                $total += $line.Length
                if ($total -gt 16384) { throw 'Headers too large' }
            }
            $parts = $first.Split(' ')
            $method = $parts[0]
            $path = ($parts[1] -split '\?', 2)[0]
            $code = '200 OK'
            $type = 'text/plain; charset=utf-8'
            if ($method -notin @('GET','HEAD')) {
                $code = '405 Method Not Allowed'; $body = $utf8.GetBytes('Method not allowed')
            } elseif ($path -eq '/version') {
                $body = $utf8.GetBytes((Get-Version))
            } elseif ($path -eq '/' -or $path -eq '/index.html') {
                # Embed the version of exactly these bytes, avoiding a load/update race.
                $raw = [IO.File]::ReadAllBytes((Join-Path $root 'index.html'))
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $version = ([BitConverter]::ToString($sha.ComputeHash($raw))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
                $html = [Text.Encoding]::UTF8.GetString($raw)
                $reloadScript = @'
<script>
(()=>{const initial='__VERSION__';let checking=false,down=0;addEventListener('pointerdown',()=>down++);addEventListener('pointerup',()=>down=Math.max(0,down-1));addEventListener('pointercancel',()=>down=0);addEventListener('blur',()=>down=0);async function check(){if(checking||document.hidden)return;checking=true;try{const r=await fetch('/version?t='+Date.now(),{cache:'no-store'});if(!r.ok)return;const v=(await r.text()).trim();if(/^[a-f0-9]{64}$/.test(v)&&v!==initial&&down===0)location.reload();}catch(e){}finally{checking=false;}}setInterval(check,1000);document.addEventListener('visibilitychange',()=>{if(!document.hidden){down=0;check();}});})();
</script>
'@
                $reloadScript = $reloadScript.Replace('__VERSION__', $version)
                $body = $utf8.GetBytes($html.Replace('</body>', ($reloadScript + '</body>')))
                $type = 'text/html; charset=utf-8'
            } else {
                $code = '404 Not Found'; $body = $utf8.GetBytes('Not found')
            }
            $headers = "HTTP/1.1 $code`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
            $b = [Text.Encoding]::ASCII.GetBytes($headers)
            $stream.Write($b,0,$b.Length)
            if ($method -ne 'HEAD') { $stream.Write($body,0,$body.Length) }
            $stream.Flush()
        } catch {
            # Abandoned browser connections are harmless; keep serving requests.
        } finally { $client.Close() }
    }
} catch {
    Write-Host ('SERVER ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Close the old server first: port 3000 must be free.'
    Read-Host 'Press Enter to close'
} finally {
    $listener.Stop()
    if ($job) { Stop-Job $job; Remove-Job $job -Force }
}
