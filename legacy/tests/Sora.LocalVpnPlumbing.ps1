param(
    [Parameter(Mandatory = $true)][string]$StagePath,
    [int]$LocalPort = 19080,
    [int]$TimeoutSeconds = 30,
    [string]$ExecutableName = 'sora_win7.exe'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function ConvertFrom-Utf8Base64 {
    param([string]$Value)
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Wait-SoraCondition {
    param([scriptblock]$Condition, [string]$Failure, [int]$Seconds = $TimeoutSeconds)
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    do {
        $result = & $Condition
        if ($result) { return $result }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    throw $Failure
}

function Find-SoraElement {
    param([int]$ProcessId, [string]$Name)
    $processCondition = New-Object Windows.Automation.PropertyCondition(
        [Windows.Automation.AutomationElement]::ProcessIdProperty,
        $ProcessId
    )
    $nameCondition = New-Object Windows.Automation.PropertyCondition(
        [Windows.Automation.AutomationElement]::NameProperty,
        $Name
    )
    $condition = New-Object Windows.Automation.AndCondition($processCondition, $nameCondition)
    return [Windows.Automation.AutomationElement]::RootElement.FindFirst(
        [Windows.Automation.TreeScope]::Descendants,
        $condition
    )
}

function Invoke-SoraElement {
    param([Windows.Automation.AutomationElement]$Element)
    $Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
}

function Stop-SoraProcess {
    param([System.Diagnostics.Process]$Process)
    if ($null -eq $Process -or $Process.HasExited) { return }
    $Process.CloseMainWindow() | Out-Null
    if (-not $Process.WaitForExit(7000)) {
        $Process.Kill()
        $Process.WaitForExit()
    }
}

function Test-LocalPort {
    param([int]$Port)
    try {
        $client = New-Object Net.Sockets.TcpClient
        $task = $client.ConnectAsync('127.0.0.1', $Port)
        $connected = $task.Wait(500) -and $client.Connected
        $client.Dispose()
        return $connected
    }
    catch {
        return $false
    }
}

function Invoke-HttpProxyProbe {
    param([int]$Port)
    $request = [Net.HttpWebRequest]::Create('http://example.com/')
    $request.Proxy = New-Object Net.WebProxy("http://127.0.0.1:$Port")
    $request.Timeout = 20000
    $request.ReadWriteTimeout = 20000
    $request.UserAgent = 'Sora-QA'
    $response = $request.GetResponse()
    try {
        return [int]$response.StatusCode
    }
    finally {
        $response.Dispose()
    }
}

function Read-Exact {
    param([IO.Stream]$Stream, [int]$Count)
    $buffer = New-Object byte[] $Count
    $offset = 0
    while ($offset -lt $Count) {
        $read = $Stream.Read($buffer, $offset, $Count - $offset)
        if ($read -le 0) { throw 'SOCKS stream closed unexpectedly' }
        $offset += $read
    }
    return $buffer
}

function Read-SharedBytes {
    param([string]$Path)
    $stream = New-Object IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $buffer = New-Object byte[] $stream.Length
        $offset = 0
        while ($offset -lt $buffer.Length) { $offset += $stream.Read($buffer, $offset, $buffer.Length - $offset) }
        return $buffer
    }
    finally {
        $stream.Dispose()
    }
}

function Invoke-SocksProbe {
    param([int]$Port)
    $client = New-Object Net.Sockets.TcpClient
    try {
        $client.ReceiveTimeout = 20000
        $client.SendTimeout = 20000
        $client.Connect('127.0.0.1', $Port)
        $stream = $client.GetStream()
        $stream.Write([byte[]](5, 1, 0), 0, 3)
        $greeting = Read-Exact $stream 2
        if ($greeting[0] -ne 5 -or $greeting[1] -ne 0) { throw 'SOCKS authentication negotiation failed' }

        $hostBytes = [Text.Encoding]::ASCII.GetBytes('example.com')
        $connect = New-Object byte[] (7 + $hostBytes.Length)
        $connect[0] = 5
        $connect[1] = 1
        $connect[2] = 0
        $connect[3] = 3
        $connect[4] = [byte]$hostBytes.Length
        [Array]::Copy($hostBytes, 0, $connect, 5, $hostBytes.Length)
        $connect[$connect.Length - 2] = 0
        $connect[$connect.Length - 1] = 80
        $stream.Write($connect, 0, $connect.Length)

        $replyHead = Read-Exact $stream 4
        if ($replyHead[0] -ne 5 -or $replyHead[1] -ne 0) { throw "SOCKS connect failed with code $($replyHead[1])" }
        $addressLength = if ($replyHead[3] -eq 1) { 4 } elseif ($replyHead[3] -eq 4) { 16 } elseif ($replyHead[3] -eq 3) { (Read-Exact $stream 1)[0] } else { throw 'SOCKS returned an unknown address type' }
        Read-Exact $stream ($addressLength + 2) | Out-Null

        $request = [Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.1`r`nHost: example.com`r`nConnection: close`r`nUser-Agent: Sora-QA`r`n`r`n")
        $stream.Write($request, 0, $request.Length)
        $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::ASCII)
        $statusLine = $reader.ReadLine()
        if ($statusLine -notmatch '^HTTP/1\.[01] (200|301|302) ') { throw "Unexpected SOCKS HTTP response: $statusLine" }
        return $statusLine
    }
    finally {
        $client.Dispose()
    }
}

$stage = (Resolve-Path -LiteralPath $StagePath).Path
$soraExe = Join-Path $stage $ExecutableName
$xrayExe = Join-Path $stage 'xray.exe'
$configPath = Join-Path $stage 'guiNConfig.json'
if (-not (Test-Path -LiteralPath $soraExe -PathType Leaf)) { throw "$ExecutableName is missing from the stage" }
if (-not (Test-Path -LiteralPath $xrayExe -PathType Leaf)) { throw 'xray.exe is missing from the stage' }
if (Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -eq $soraExe -or $_.ExecutablePath -eq $xrayExe }) {
    throw 'The QA stage already has a running Sora or Xray process'
}

$internetSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
$proxyBefore = Get-ItemProperty -Path $internetSettings
$languageRegistry = 'HKCU:\Software\Sora'
New-Item -Path $languageRegistry -Force | Out-Null
$oldLanguage = (Get-ItemProperty -Path $languageRegistry -Name CurrentLanguage -ErrorAction SilentlyContinue).CurrentLanguage
$hadLanguage = $null -ne $oldLanguage
$process = $null

try {
    Set-ItemProperty -Path $languageRegistry -Name CurrentLanguage -Value 'ru-RU'
    if (-not (Test-Path -LiteralPath $configPath)) {
        $process = Start-Process -FilePath $soraExe -WorkingDirectory $stage -PassThru
        Wait-SoraCondition { $process.Refresh(); $process.MainWindowHandle -ne 0 } 'Sora did not create its main window' | Out-Null
        Stop-SoraProcess $process
        $process = $null
    }

    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (@($config.vmess).Count -ne 0) { throw 'The QA stage must not contain existing servers' }
    $config.inbound[0].localPort = $LocalPort
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($false)))

    $payload = '{"remarks":"Sora local plumbing","log":{"loglevel":"debug"},"inbounds":[{"protocol":"socks","listen":"127.0.0.1","port":10808,"settings":{"auth":"noauth","udp":true}}],"outbounds":[{"protocol":"freedom","settings":{}}]}'
    [Windows.Forms.Clipboard]::SetText($payload)
    $process = Start-Process -FilePath $soraExe -WorkingDirectory $stage -PassThru
    Wait-SoraCondition { $process.Refresh(); $process.MainWindowHandle -ne 0 } 'Sora main window did not appear' | Out-Null

    $addName = ConvertFrom-Utf8Base64 '0JTQvtCx0LDQstC40YLRjCDQutC+0L3RhNC40LPRg9GA0LDRhtC40Y4='
    $importName = ConvertFrom-Utf8Base64 '0JTQvtCx0LDQstC40YLRjCDRgNCw0YHQv9C+0LfQvdCw0L3QvdGD0Y4g0LrQvtC90YTQuNCz0YPRgNCw0YbQuNGO'
    Invoke-SoraElement (Wait-SoraCondition { Find-SoraElement $process.Id $addName } 'Add configuration button was not exposed')
    $field = Wait-SoraCondition { Find-SoraElement $process.Id 'RichEdit Control' } 'Import field was not exposed'
    $field.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue($payload)
    $import = Wait-SoraCondition { Find-SoraElement $process.Id $importName } 'Import button was not exposed'
    Wait-SoraCondition { $import.Current.IsEnabled } 'Local Xray configuration was not recognized' | Out-Null
    Invoke-SoraElement $import

    Wait-SoraCondition { @((Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).vmess).Count -eq 1 } 'Imported profile was not persisted' | Out-Null
    Wait-SoraCondition { Test-LocalPort $LocalPort } 'Sora SOCKS port did not open' | Out-Null
    Wait-SoraCondition { Test-LocalPort ($LocalPort + 1) } 'Sora HTTP port did not open' | Out-Null
    $xray = Wait-SoraCondition {
        Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'xray.exe' -and $_.ExecutablePath -eq $xrayExe }
    } 'Sora did not start the staged Xray core'

    $httpStatus = Invoke-HttpProxyProbe ($LocalPort + 1)
    if ($httpStatus -ne 200) { throw "HTTP proxy returned status $httpStatus" }
    $socksStatus = Invoke-SocksProbe $LocalPort

    $logPath = Wait-SoraCondition {
        $file = Get-ChildItem -LiteralPath (Join-Path $stage 'guiLogs') -Filter '*.txt' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($file -and (Select-String -LiteralPath $file.FullName -SimpleMatch '[CORE]' -Quiet)) { return $file.FullName }
        return $false
    } 'Persistent CORE log entry was not written'
    $bytes = Read-SharedBytes $logPath
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'The log contains a UTF-8 BOM' }
    $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
    $logContent = $strictUtf8.GetString($bytes)
    if ($logContent -match 'StatisticLogOverall\.json.*(FileNotFound|could not find)') { throw 'Expected first-run statistics state polluted the log' }

    Write-Output "Local VPN plumbing: PASS (HTTP=$httpStatus, SOCKS='$socksStatus', SoraPID=$($process.Id), XrayPID=$($xray.ProcessId))"
    Write-Output "Core logging: PASS (UTF-8 without BOM, persisted [CORE], file=$logPath)"
}
finally {
    Stop-SoraProcess $process
    if ($hadLanguage) {
        Set-ItemProperty -Path $languageRegistry -Name CurrentLanguage -Value $oldLanguage
    }
    else {
        Remove-ItemProperty -Path $languageRegistry -Name CurrentLanguage -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Milliseconds 800
$orphan = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'xray.exe' -and $_.ExecutablePath -eq $xrayExe }
if ($orphan) { throw "Staged Xray remained after Sora exit: $($orphan.ProcessId)" }
$proxyAfter = Get-ItemProperty -Path $internetSettings
if ($proxyAfter.ProxyEnable -ne $proxyBefore.ProxyEnable -or $proxyAfter.ProxyServer -ne $proxyBefore.ProxyServer -or $proxyAfter.ProxyOverride -ne $proxyBefore.ProxyOverride) {
    throw 'Sora changed the system proxy during a warm-core plumbing test'
}
Write-Output "Cleanup: PASS (no orphan core, system proxy preserved at $($proxyAfter.ProxyServer))"
