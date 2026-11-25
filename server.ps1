$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root = $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
$nodeVersion = '22.16.0'
$runtime = Join-Path $root 'runtime'
$node = Join-Path $runtime 'node.exe'
$child = $null
function Download-File($url, $dest) {
    $wc = New-Object Net.WebClient
    try { $wc.Headers['User-Agent'] = 'CoinGameUpdater/3'; $wc.DownloadFile($url, $dest) } finally { $wc.Dispose() }
}
function Get-Revision {
    $wc = New-Object Net.WebClient
    try { $wc.Headers['User-Agent']='git/2.43.0'; $text=$wc.DownloadString('https://github.com/gymsas50-lgtm/coin-clicker.git/info/refs?service=git-upload-pack') } finally { $wc.Dispose() }
    $m=[regex]::Match($text,'([0-9a-f]{40}) refs/heads/main')
    if (-not $m.Success) { throw 'Cannot resolve game revision' }
    return $m.Groups[1].Value
}
try {
    if (-not (Test-Path $node)) {
        Write-Host 'First launch: downloading portable Node.js. No system installation.' -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $runtime -Force | Out-Null
        $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
        $name = "node-v$nodeVersion-win-$arch.zip"
        $archive = Join-Path $runtime $name
        $checks = Join-Path $runtime 'SHASUMS256.txt'
        Download-File "https://nodejs.org/dist/v$nodeVersion/$name" $archive
        Download-File "https://nodejs.org/dist/v$nodeVersion/SHASUMS256.txt" $checks
        $line = Get-Content $checks | Where-Object { $_ -match ([regex]::Escape($name) + '$') } | Select-Object -First 1
        if (-not $line) { throw 'Runtime checksum not found' }
        $expected=($line -split '\s+')[0]
        if ((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw 'Runtime checksum mismatch' }
        Expand-Archive -Path $archive -DestinationPath $runtime -Force
        Copy-Item (Join-Path $runtime "node-v$nodeVersion-win-$arch/node.exe") $node -Force
        Remove-Item $archive -Force
    }
    $lastRevision = ''
    $nextCheck = [DateTime]::MinValue
    while ($true) {
        if ((Get-Date) -ge $nextCheck) {
            $nextCheck=(Get-Date).AddSeconds(8)
            try {
                $rev=Get-Revision
                if ($rev -ne $lastRevision) {
                    $base="https://raw.githubusercontent.com/gymsas50-lgtm/coin-clicker/$rev"
                    $gameTemp=Join-Path $root 'index.download.html'
                    $codeTemp=Join-Path $root 'server.download.js'
                    Download-File "$base/index.html" $gameTemp
                    Download-File "$base/server.js" $codeTemp
                    $game=[IO.File]::ReadAllText($gameTemp)
                    if (-not $game.Contains('<meta name="app-id" content="arena-coin-clicker">') -or -not $game.Contains('</html>')) { throw 'Invalid game update' }
                    & $node --check $codeTemp
                    if ($LASTEXITCODE -ne 0) { throw 'Invalid server update' }
                    $dest=Join-Path $root 'server.js'
                    $serverChanged=(-not (Test-Path $dest)) -or ((Get-FileHash $dest).Hash -ne (Get-FileHash $codeTemp).Hash)
                    if ($serverChanged -and $child -and -not $child.HasExited) { Stop-Process -Id $child.Id -Force; $child.WaitForExit(); $child=$null }
                    if ($serverChanged) { Copy-Item $codeTemp $dest -Force }
                    $gameDest=Join-Path $root 'index.html'
                    if (-not (Test-Path $gameDest)) { Copy-Item $gameTemp $gameDest -Force } elseif ((Get-FileHash $gameDest).Hash -ne (Get-FileHash $gameTemp).Hash) { [IO.File]::Replace($gameTemp,$gameDest,(Join-Path $root 'index.previous.html')) }
                    Remove-Item $gameTemp,$codeTemp -Force -ErrorAction SilentlyContinue
                    $lastRevision=$rev
                    [IO.File]::WriteAllText((Join-Path $root 'update-status.txt'),('UP TO DATE '+$rev.Substring(0,7)),$utf8)
                    Write-Host ('Updated: '+$rev.Substring(0,7)) -ForegroundColor Green
                }
            } catch {
                Write-Host ('Update offline; keeping local game: '+$_.Exception.Message) -ForegroundColor DarkYellow
            }
        }
        if (-not $child -or $child.HasExited) {
            if (-not (Test-Path (Join-Path $root 'server.js'))) { throw 'server.js is missing. Download the complete server package.' }
            $child=Start-Process -FilePath $node -ArgumentList 'server.js' -WorkingDirectory $root -NoNewWindow -PassThru
            Start-Sleep -Seconds 2
            if ($child.HasExited) { throw 'Server stopped. Close the old server; port 3000 must be free.' }
        }
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host ('SERVER ERROR: '+$_.Exception.Message) -ForegroundColor Red
    Read-Host 'Press Enter to close'
} finally {
    if ($child -and -not $child.HasExited) { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue }
}
