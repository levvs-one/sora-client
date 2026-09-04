param([Parameter(Mandatory = $true)][string]$UpdaterExe)

$ErrorActionPreference = 'Stop'
$directory = Split-Path -Parent (Resolve-Path -LiteralPath $UpdaterExe).Path
foreach ($dll in 'Chaos.NaCl.dll', 'NetSparkle.dll', 'log4net.dll') { [void][Reflection.Assembly]::LoadFrom((Join-Path $directory $dll)) }
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $UpdaterExe).Path)
$window = $assembly.GetType('Sora.Centers.UpdateWindow', $true)
$policy = $window.GetMethod('IsAllowedDownload', [Reflection.BindingFlags]'Static, NonPublic')
$good = 'https://github.com/levvs-one/sora-client/releases/download/v0.2.4/sora_win7.exe'
if (-not $policy.Invoke($null, @($good, 'win7'))) { throw 'Official target download was rejected.' }
foreach ($bad in @(
    $good.Replace('https:', 'http:'),
    $good.Replace('github.com', 'github.com.attacker.example'),
    $good.Replace('levvs-one', 'someone-else'),
    $good.Replace('sora_win7', 'sora_win11'),
    $good.Replace('github.com', 'name@github.com'),
    $good.Replace('github.com', 'github.com:8443'),
    ($good + '?redirect=elsewhere'),
    ($good + '#ignored'),
    'file:///C:/installer.exe'
)) { if ($policy.Invoke($null, @($bad, 'win7'))) { throw "Unsafe download policy accepted $bad" } }
if ($policy.Invoke($null, @($good, '../win7'))) { throw 'Unknown target accepted.' }

$seed = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($seed)
$rng.Dispose()
$public = [Chaos.NaCl.Ed25519]::PublicKeyFromSeed($seed)
$expanded = [Chaos.NaCl.Ed25519]::ExpandedPrivateKeyFromSeed($seed)
$verifier = [NetSparkleUpdater.SignatureVerifiers.Ed25519Checker]::new([NetSparkleUpdater.Enums.SecurityMode]::Strict, [Convert]::ToBase64String($public), $null, $true, 65536)
$payload = [Text.Encoding]::UTF8.GetBytes(('signed test payload' * 100000))
$signature = [Convert]::ToBase64String([Chaos.NaCl.Ed25519]::Sign($payload, $expanded))
if ($verifier.VerifySignature($signature, $payload).ToString() -ne 'Valid') { throw 'Valid signature rejected.' }
$payload[0] = $payload[0] -bxor 1
if ($verifier.VerifySignature($signature, $payload).ToString() -ne 'Invalid') { throw 'Tampered payload accepted.' }
if ($verifier.VerifySignature('', $payload).ToString() -ne 'Invalid') { throw 'Unsigned payload accepted.' }
$missing = [NetSparkleUpdater.SignatureVerifiers.Ed25519Checker]::new([NetSparkleUpdater.Enums.SecurityMode]::Strict, $null, $null, $true, 65536)
if ($missing.VerifySignature($signature, $payload).ToString() -ne 'Invalid') { throw 'Missing trust anchor accepted.' }
$payload[0] = $payload[0] -bxor 1
$path = Join-Path ([IO.Path]::GetTempPath()) ('sora-update-qa-' + [guid]::NewGuid().ToString('N') + '.bin')
try {
    [IO.File]::WriteAllBytes($path, $payload)
    if ($verifier.VerifySignatureOfFile($signature, $path).ToString() -ne 'Valid') { throw 'Chunked file verification rejected valid data.' }
    [IO.File]::AppendAllText($path, 'tampered')
    if ($verifier.VerifySignatureOfFile($signature, $path).ToString() -ne 'Invalid') { throw 'File changed after download was accepted.' }
} finally {
    [Array]::Clear($seed, 0, $seed.Length)
    [Array]::Clear($expanded, 0, $expanded.Length)
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}
$logDirectory = Join-Path ([IO.Path]::GetTempPath()) ('sora-update-log-qa-' + [guid]::NewGuid().ToString('N'))
try {
    $setup = $assembly.GetType('Sora.Centers.Program', $true).GetMethod('ConfigureLogging', [Reflection.BindingFlags]'Static, NonPublic')
    [void]$setup.Invoke($null, [object[]]@([string]$logDirectory))
    $message = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0J/RgNC+0LLQtdGA0LrQsCDQvtCx0L3QvtCy0LvQtdC90LjQuQ=='))
    [log4net.LogManager]::GetLogger('EncodingTest').Warn($message)
    [log4net.LogManager]::Shutdown()
    $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
    $content = $strictUtf8.GetString([IO.File]::ReadAllBytes((Join-Path $logDirectory 'updates.txt')))
    if (-not $content.Contains($message) -or -not $content.Contains('[UPDATE]')) { throw 'Updater log lost Unicode or source information.' }
} finally {
    [log4net.LogManager]::Shutdown()
    $resolved = [IO.Path]::GetFullPath($logDirectory)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notlike 'sora-update-log-qa-*') { throw 'Unsafe log test cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
Write-Output 'PASS: official origin and target, scheme, hostname, credentials, port, query, fragment, missing key, missing signature, valid signature, tampering, chunked file verification, UTF-8 log output.'
