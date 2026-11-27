$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root = $PSScriptRoot
$child = $null
$lastRevision = ''
$utf8 = New-Object Text.UTF8Encoding($false)
function Get-Text([string]$url) {
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    try {
        $wc.Headers['User-Agent'] = 'RobloxStudioSync/1'
        $wc.Headers['Cache-Control'] = 'no-cache'
        return $wc.DownloadString($url)
    } finally { $wc.Dispose() }
}
function Sync-Project {
    $refs = Get-Text 'https://github.com/gymsas50-lgtm/coin-clicker.git/info/refs?service=git-upload-pack'
    $match = [regex]::Match($refs, '([0-9a-f]{40}) refs/heads/main')
    if (-not $match.Success) { throw 'Cannot resolve GitHub revision' }
    $revision = $match.Groups[1].Value
    if ($revision -eq $script:lastRevision) { return }
    $base = "https://raw.githubusercontent.com/gymsas50-lgtm/coin-clicker/$revision/roblox-sync"
    $manifest = (Get-Text "$base/manifest.json") | ConvertFrom-Json
    $downloads = @()
    foreach ($entry in $manifest.files) {
        $name = [string]$entry
        if ($name.Contains('..') -or $name.Contains('\') -or $name.Contains(':') -or ($name -ne 'default.project.json' -and $name -notmatch '^src/[a-zA-Z0-9_./-]+$')) { throw 'Unsafe update path' }
        $content = Get-Text "$base/$name"
        if ($name.EndsWith('.json')) { $null = $content | ConvertFrom-Json }
        $dest = Join-Path $root $name
        $parent = Split-Path $dest -Parent
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        $temp = $dest + '.download'
        [IO.File]::WriteAllText($temp, $content, $utf8)
        $downloads += @{ Dest = $dest; Temp = $temp; Content = $content }
    }
    foreach ($item in $downloads) {
        if ((Test-Path $item.Dest) -and [IO.File]::ReadAllText($item.Dest) -eq $item.Content) {
            Remove-Item $item.Temp -Force
        } elseif (Test-Path $item.Dest) {
            $backup = $item.Dest + '.sync-backup'
            [IO.File]::Replace([string]$item.Temp, [string]$item.Dest, [string]$backup)
            Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
        } else { [IO.File]::Move($item.Temp, $item.Dest) }
    }
    $script:lastRevision = $revision
    Write-Host ('SYNCED: ' + $revision.Substring(0,7)) -ForegroundColor Green
}
try {
    $exe = Join-Path $root 'runtime/rojo.exe'
    if (-not (Test-Path $exe)) { throw 'rojo.exe missing. Extract the entire ZIP first.' }
    Write-Host 'ROJO AUTO UPDATE - keep this window open' -ForegroundColor Cyan
    Write-Host 'Studio plugin: localhost  port 34872'
    try { Sync-Project } catch { Write-Host ('Offline; using bundled project: ' + $_.Exception.Message) -ForegroundColor Yellow }
    $child = Start-Process -FilePath $exe -ArgumentList @('serve', 'default.project.json') -WorkingDirectory $root -NoNewWindow -PassThru
    while (-not $child.HasExited) {
        Start-Sleep -Milliseconds 1200
        try { Sync-Project } catch { Write-Host ('Update retry: ' + $_.Exception.Message) -ForegroundColor DarkYellow }
    }
    throw 'Rojo stopped. Check that another sync window is not already running.'
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Read-Host 'Press Enter to close'
} finally {
    if ($child -and -not $child.HasExited) { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue }
}
