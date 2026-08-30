param(
    [Parameter(Mandatory = $true)][string]$StagePath,
    [Parameter(Mandatory = $true)][string]$CorePath,
    [int]$LocalPort = 18080,
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = 'Stop'
$stage = (Resolve-Path -LiteralPath $StagePath).Path
$core = (Resolve-Path -LiteralPath $CorePath).Path
$config = [IO.File]::ReadAllText((Join-Path $stage 'guiNConfig.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

foreach ($item in @($config.vmess)) {
    $path = Join-Path (Join-Path $stage 'guiConfigs') ([string]$item.address)
    $process = $null
    $failure = $null
    $diagnosticPath = Join-Path ([IO.Path]::GetTempPath()) ("sora-xray-{0}.log" -f [Guid]::NewGuid().ToString('N'))
    try {
        $profile = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json
        if (-not $profile.inbounds) { throw 'Profile has no local inbound' }

        $socksPort = $null
        for ($index = 0; $index -lt @($profile.inbounds).Count; $index++) {
            $profile.inbounds[$index].listen = '127.0.0.1'
            $profile.inbounds[$index].port = $LocalPort + $index
            if ($profile.inbounds[$index].protocol -eq 'socks' -and $null -eq $socksPort) {
                $socksPort = $LocalPort + $index
            }
        }
        if ($null -eq $socksPort) { throw 'Profile has no SOCKS inbound' }

        if ($profile.PSObject.Properties.Name -contains 'log') {
            $profile.log = [pscustomobject]@{ loglevel = 'debug'; error = $diagnosticPath }
        }
        else {
            $profile | Add-Member -NotePropertyName log -NotePropertyValue ([pscustomobject]@{ loglevel = 'debug'; error = $diagnosticPath })
        }

        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $core
        $startInfo.Arguments = 'run -c stdin:'
        $startInfo.WorkingDirectory = [System.IO.Path]::GetDirectoryName($core)
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        if (-not $process.Start()) { throw 'Core did not start' }
        $process.StandardInput.Write(($profile | ConvertTo-Json -Depth 100 -Compress))
        $process.StandardInput.Close()

        $ready = $false
        $deadline = [DateTime]::UtcNow.AddSeconds(12)
        do {
            Start-Sleep -Milliseconds 200
            try {
                $client = [System.Net.Sockets.TcpClient]::new()
                $connection = $client.ConnectAsync('127.0.0.1', $socksPort)
                if ($connection.Wait(300) -and $client.Connected) { $ready = $true }
                $client.Dispose()
            }
            catch { }
        } while (-not $ready -and -not $process.HasExited -and [DateTime]::UtcNow -lt $deadline)
        if (-not $ready) {
            if ($process.HasExited) {
                $coreError = ($process.StandardError.ReadToEnd() + [Environment]::NewLine + $process.StandardOutput.ReadToEnd()).Trim()
                $diagnosticLines = @($coreError -split "`r?`n" | Where-Object { $_ -match '(?i)reality|invalid|failed|error|unknown' })
                if ($diagnosticLines.Count -gt 0) {
                    $coreError = ($diagnosticLines | Select-Object -Last 3) -join ' | '
                }
                elseif ($coreError.Length -gt 600) {
                    $coreError = $coreError.Substring($coreError.Length - 600)
                }
                throw "Core exited with code $($process.ExitCode): $coreError"
            }
            throw 'Core did not open its local port'
        }

        $metric = & curl.exe `
            --silent `
            --output NUL `
            --proxy "socks5h://127.0.0.1:$socksPort" `
            --write-out '%{http_code} %{time_starttransfer} %{time_total}' `
            --max-time $TimeoutSeconds `
            https://www.gstatic.com/generate_204
        $curlExitCode = $LASTEXITCODE
        $parts = [string]$metric -split ' '
        $httpStatus = if ($parts.Count -ge 1) { $parts[0] } else { '000' }
        $firstByte = if ($parts.Count -ge 2) {
            [math]::Round([double]::Parse($parts[1], [Globalization.CultureInfo]::InvariantCulture) * 1000)
        } else { $null }
        $total = if ($parts.Count -ge 3) {
            [math]::Round([double]::Parse($parts[2], [Globalization.CultureInfo]::InvariantCulture) * 1000)
        } else { $null }
        if ($curlExitCode -ne 0 -or $httpStatus -ne '204') {
            Start-Sleep -Milliseconds 400
            if (-not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
            $diagnosticSources = @($process.StandardError.ReadToEnd(), $process.StandardOutput.ReadToEnd())
            if (Test-Path -LiteralPath $diagnosticPath) {
                $diagnosticSources += [IO.File]::ReadAllText($diagnosticPath, [Text.Encoding]::UTF8)
            }
            $lines = @($diagnosticSources -split "`r?`n" | Where-Object { $_ -match '(?i)reality|invalid|failed|error|unknown' })
            $diagnostic = ($lines | Select-Object -Last 3) -join ' | '
            $failure = "curl exit $curlExitCode, HTTP $httpStatus"
            if ($diagnostic) { $failure += ": $diagnostic" }
        }

        $results.Add([pscustomobject]@{
            Server = [string]$item.remarks
            Http = $httpStatus
            FirstByteMs = $firstByte
            TotalMs = $total
            Success = $curlExitCode -eq 0 -and $httpStatus -eq '204'
            Failure = $failure
        })
    }
    catch {
        $failure = $_.Exception.Message
        $results.Add([pscustomobject]@{
            Server = [string]$item.remarks
            Http = '000'
            FirstByteMs = $null
            TotalMs = $null
            Success = $false
            Failure = $failure
        })
    }
    finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
            $process.Dispose()
        }
        Remove-Item -LiteralPath $diagnosticPath -Force -ErrorAction SilentlyContinue
    }
}

$successful = @($results | Where-Object Success)
[pscustomobject]@{
    Results = $results
    Summary = [pscustomobject]@{
        Tested = $results.Count
        Succeeded = $successful.Count
        Failed = $results.Count - $successful.Count
        FastestFirstByteMs = if ($successful.Count) { ($successful.FirstByteMs | Measure-Object -Minimum).Minimum } else { $null }
        MedianFirstByteMs = if ($successful.Count) { ($successful.FirstByteMs | Sort-Object)[[math]::Floor($successful.Count / 2)] } else { $null }
    }
} | ConvertTo-Json -Depth 5
