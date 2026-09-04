param([Parameter(Mandatory = $true)][string]$LogsExe)

$ErrorActionPreference = 'Stop'
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $LogsExe).Path)
$catalogType = $assembly.GetType('Sora.Centers.LogCatalog', $true)
$flags = [Reflection.BindingFlags]'NonPublic, Public, Static, Instance'
$parse = $catalogType.GetMethod('Parse', $flags)
$fallback = [datetime]'2026-09-01T00:00:00'
function Parse-Log([string]$text) {
    $reader = [IO.StringReader]::new($text)
    try { return ,$parse.Invoke($null, @($reader, 'test.txt', $fallback, 1)) }
    finally { $reader.Dispose() }
}

$entries = Parse-Log @"
2026-09-05 10:20:30,123 [main] ERROR Sora - [CORE] Failed
System.InvalidOperationException: test
   at Connect()
2026-09-05 10:20:31,456 [12] INFO  Sora - [SUBSCRIPTION] Updated
"@
if ($entries.Count -ne 2) { throw 'Named threads or multiline errors are parsed incorrectly.' }
if ($entries[0].Source -ne 'CORE' -or $entries[0].Level -ne 'ERROR' -or $entries[0].Message -notmatch 'at Connect') { throw 'Error details were lost.' }
if ($entries[1].Source -ne 'SUBSCRIPTION' -or $entries[1].Line -ne 4) { throw 'Source or line number was lost.' }
$unicode = Parse-Log '2026-09-05 10:20:30,123 [1] INFO Sora - Подписка 日本語 العربية'
if ($unicode[0].Message -ne 'Подписка 日本語 العربية') { throw 'Unicode was altered.' }
$invalidDate = Parse-Log '2026-99-99 10:20:30,123 [1] WARN Sora - Bad timestamp'
if ($invalidDate[0].Time -ne $fallback) { throw 'Invalid timestamps need a stable fallback.' }
$oversized = Parse-Log ('2026-09-05 10:20:30,123 [1] INFO Sora - ' + ('x' * 100000) + "`n" + ('y' * 100000))
if ($oversized[0].Message.Length -gt 65536) { throw 'An oversized event exceeded the memory bound.' }
$lines = [Text.StringBuilder]::new()
for ($index = 0; $index -lt 21000; $index++) { [void]$lines.AppendLine("2026-09-05 10:20:30,123 [1] INFO Sora - event $index") }
$bounded = Parse-Log $lines.ToString()
if ($bounded.Count -ne 20000 -or $bounded[0].Message -ne 'event 1000') { throw 'The catalog did not retain the newest 20,000 events.' }

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('sora-logs-qa-' + [guid]::NewGuid().ToString('N'))
$logDirectory = Join-Path $testRoot 'guiLogs'
[void][IO.Directory]::CreateDirectory($logDirectory)
try {
    $logPath = Join-Path $logDirectory '2026-09-05.txt'
    $utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($logPath, "2026-09-05 10:20:30,123 [1] INFO Sora - first`r`n", $utf8)
    $constructor = $catalogType.GetConstructor($flags, $null, [type[]]@([string]), $null)
    $catalog = $constructor.Invoke([object[]]@([string]$testRoot))
    $read = $catalogType.GetMethod('Read', $flags)
    $first = @($read.Invoke($catalog, @()) | Where-Object { $_.File -eq $logPath })
    if ($first.Count -ne 1) { throw 'Initial file read failed.' }
    [IO.File]::AppendAllText($logPath, "2026-09-05 10:20:31,123 [1] INFO Sora - appended`r`n", $utf8)
    $second = @($read.Invoke($catalog, @()) | Where-Object { $_.File -eq $logPath })
    if ($second.Count -ne 2) { throw 'Appended events were not detected.' }
    [IO.File]::WriteAllText($logPath, "2026-09-05 10:20:32,123 [1] INFO Sora - rotated`r`n", $utf8)
    $rotated = @($read.Invoke($catalog, @()) | Where-Object { $_.File -eq $logPath })
    if ($rotated.Count -ne 1 -or $rotated[0].Message -ne 'rotated') { throw 'Truncated file retained stale events.' }
    $lock = [IO.File]::Open($logPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $lock.SetLength($lock.Length + 1)
        [void]$read.Invoke($catalog, @())
        if (-not $catalogType.GetProperty('LastWarning', $flags).GetValue($catalog)) { throw 'A locked file did not produce a recoverable warning.' }
    } finally { $lock.Dispose() }
    $writer = [IO.StreamWriter]::new($logPath, $false, $utf8)
    try { for ($index = 0; $index -lt 80000; $index++) { $writer.WriteLine("2026-09-05 10:20:33,123 [1] INFO Sora - long event $index padding padding") } }
    finally { $writer.Dispose() }
    $large = @($read.Invoke($catalog, @()) | Where-Object { $_.File -eq $logPath })
    if ($large.Count -gt 20000 -or -not ($large | Where-Object { $_.Message -match 'long event 79999' })) { throw 'Large-file tail read failed.' }
    Remove-Item -LiteralPath $logPath
    $deleted = @($read.Invoke($catalog, @()) | Where-Object { $_.File -eq $logPath })
    if ($deleted.Count) { throw 'Deleted files remained cached.' }
} finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notlike 'sora-logs-qa-*') { throw 'Unsafe test cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Output 'PASS: multiline, named threads, Unicode, invalid timestamps, bounded messages, 20k retention, append, truncate, file lock, large tail, deleted-file eviction.'
