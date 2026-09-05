param([Parameter(Mandatory = $true)][string]$UpdaterExe)

$ErrorActionPreference = 'Stop'
$executable = (Resolve-Path -LiteralPath $UpdaterExe).Path
$directory = Split-Path -Parent $executable
$root = Join-Path ([IO.Path]::GetTempPath()) ('sora-update-scenarios-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
try {
    $references = @('System.dll', 'System.Core.dll', 'System.Net.Http.dll')
    foreach ($dll in 'Chaos.NaCl.dll', 'NetSparkle.dll') {
        $references += Join-Path $directory $dll
        [void][Reflection.Assembly]::LoadFrom((Join-Path $directory $dll))
    }
    $assembly = [Reflection.Assembly]::LoadFrom($executable)
    $flags = [Reflection.BindingFlags]'Instance, NonPublic, Public'
    $windowType = $assembly.GetType('Sora.Centers.UpdateWindow', $true)
    $constructor = $windowType.GetConstructor($flags, $null, [type[]]@([string[]]), $null)
    $window = $constructor.Invoke([object[]]@(,[string[]]@()))
    try {
        $finish = $windowType.GetMethod('FinishDownload', $flags)
        if ($null -eq $finish) { throw 'The updater has no terminal download-event guard.' }
        $history = $windowType.GetField('_history', $flags).GetValue($window)
        $install = $windowType.GetField('_install', $flags).GetValue($window)
        [void]$finish.Invoke($window, [object[]]@($null, 'signature rejected'))
        $first = $history.Text
        [void]$finish.Invoke($window, [object[]]@($null, 'duplicate error'))
        if ($history.Text -ne $first -or $install.Enabled) { throw 'Failure was duplicated or enabled installation.' }
        $windowType.GetField('_downloadCompleted', $flags).SetValue($window, $false)
        $windowType.GetField('_cancelRequested', $flags).SetValue($window, $true)
        [void]$finish.Invoke($window, [object[]]@($null, 'network error after cancel'))
        if ($history.Text.Contains('network error after cancel') -or $install.Enabled) { throw 'Cancellation was presented as a network failure.' }
        $windowType.GetField('_downloadCompleted', $flags).SetValue($window, $false)
        [void]$finish.Invoke($window, [object[]]@('canceled.exe', $null))
        if ($install.Enabled) { throw 'Late success after cancellation enabled installation.' }
        Write-Output 'PASS: one terminal message, cancellation wording, late success after cancellation blocked.'
    } finally { $window.Dispose() }
    [Threading.SynchronizationContext]::SetSynchronizationContext($null)
    Add-Type -Path (Join-Path $PSScriptRoot 'Sora.UpdateScenarios.cs') -ReferencedAssemblies $references
    [SoraUpdateScenarios]::Run($executable, $root).GetAwaiter().GetResult()
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notlike 'sora-update-scenarios-*') { throw 'Unsafe test cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
