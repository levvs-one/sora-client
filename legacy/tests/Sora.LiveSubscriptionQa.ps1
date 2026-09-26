param(
    [Parameter(Mandatory = $true)][string]$StagePath,
    [Parameter(Mandatory = $true)][string]$SubscriptionUrl,
    [Parameter(Mandatory = $true)][string]$ScreenshotDirectory,
    [int]$TimeoutSeconds = 120,
    [string]$ExecutableName = 'sora_win7.exe'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class SoraQaNative {
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
}
'@

function Wait-Until {
    param([scriptblock]$Condition, [string]$Failure)
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $result = & $Condition
        if ($result) { return $result }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    throw $Failure
}

function Find-Element {
    param([int]$ProcessId, [string]$Name)
    $processCondition = [Windows.Automation.PropertyCondition]::new(
        [Windows.Automation.AutomationElement]::ProcessIdProperty,
        $ProcessId
    )
    $nameCondition = [Windows.Automation.PropertyCondition]::new(
        [Windows.Automation.AutomationElement]::NameProperty,
        $Name
    )
    $condition = [Windows.Automation.AndCondition]::new($processCondition, $nameCondition)
    [Windows.Automation.AutomationElement]::RootElement.FindFirst(
        [Windows.Automation.TreeScope]::Descendants,
        $condition
    )
}

function Invoke-Element {
    param([Windows.Automation.AutomationElement]$Element)
    $Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
}

function Save-WindowScreenshot {
    param([System.Diagnostics.Process]$Process, [string]$Path)
    $Process.Refresh()
    $rect = [System.Drawing.Rectangle]::FromLTRB(0, 0, 1000, 680)
    $bitmap = [System.Drawing.Bitmap]::new($rect.Width, $rect.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $hdc = $graphics.GetHdc()
        try {
            if (-not [SoraQaNative]::PrintWindow($Process.MainWindowHandle, $hdc, 0)) {
                throw 'PrintWindow failed'
            }
        }
        finally {
            $graphics.ReleaseHdc($hdc)
        }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$stage = (Resolve-Path -LiteralPath $StagePath).Path
$executable = Join-Path $stage $ExecutableName
$configPath = Join-Path $stage 'guiNConfig.json'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "$ExecutableName not found" }
if (Test-Path -LiteralPath $configPath) { throw 'QA stage must be clean' }
[System.IO.Directory]::CreateDirectory($ScreenshotDirectory) | Out-Null

$process = Start-Process -FilePath $executable -WorkingDirectory $stage -PassThru
try {
    Wait-Until { $process.Refresh(); $process.MainWindowHandle -ne 0 } 'Sora window did not appear' | Out-Null
    Invoke-Element (Wait-Until { Find-Element $process.Id 'Добавить конфигурацию' } 'Add button not found')

    $input = Wait-Until { Find-Element $process.Id 'RichEdit Control' } 'Import field not found'
    $input.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue($SubscriptionUrl)
    $import = Wait-Until { Find-Element $process.Id 'Добавить распознанную конфигурацию' } 'Import button not found'
    Wait-Until { $import.Current.IsEnabled } 'Subscription was not recognized' | Out-Null
    Invoke-Element $import

    try {
        $state = Wait-Until {
            if (-not (Test-Path -LiteralPath $configPath)) { return $false }
            try {
                $saved = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
                $subscription = @($saved.subItem | Where-Object url -eq $SubscriptionUrl) | Select-Object -First 1
                if ($null -eq $subscription) { return $false }
                $servers = @($saved.vmess | Where-Object subid -eq $subscription.id)
                if ($servers.Count -lt 1) { return $false }
                return [pscustomobject]@{ Name = $subscription.remarks; Id = $subscription.id; Servers = $servers }
            }
            catch { return $false }
        } 'Subscription did not produce any servers'
    }
    catch {
        $failureShot = Join-Path $ScreenshotDirectory 'sora-live-import-error.png'
        Save-WindowScreenshot $process $failureShot
        [pscustomobject]@{
            Subscription = ([Uri]$SubscriptionUrl).Host
            Servers = 0
            Failure = 'Сервер подписки не вернул конфигурации'
            ImportScreenshot = $failureShot
        } | ConvertTo-Json -Compress
        return
    }

    $importShot = Join-Path $ScreenshotDirectory 'sora-live-import.png'
    Save-WindowScreenshot $process $importShot

    Invoke-Element (Wait-Until { Find-Element $process.Id 'Серверы' } 'Servers navigation button not found')
    $baselineWrite = (Get-Item -LiteralPath $configPath).LastWriteTimeUtc
    Invoke-Element (Wait-Until { Find-Element $process.Id 'Измерить задержку' } 'Latency button not found')
    Invoke-Element (Wait-Until { Find-Element $process.Id 'Через прокси — полный маршрут' } 'Full-route latency method not found')

    $results = Wait-Until {
        try {
            if ((Get-Item -LiteralPath $configPath).LastWriteTimeUtc -le $baselineWrite) { return $false }
            $saved = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            $servers = @($saved.vmess | Where-Object subid -eq $state.Id)
            $measured = @($servers | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.testResult) -and $_.testResult -ne 'Проверка…'
            })
            if ($measured.Count -lt $servers.Count) { return $false }
            return $measured
        }
        catch { return $false }
    } 'Latency measurement did not finish'

    $pingShot = Join-Path $ScreenshotDirectory 'sora-live-latency.png'
    Save-WindowScreenshot $process $pingShot

    $latencies = @($results | ForEach-Object {
        if ($_.testResult -match '(\d+)') { [int]$matches[1] }
    })
    [pscustomobject]@{
        Subscription = $state.Name
        Servers = $state.Servers.Count
        Measured = $results.Count
        Responded = $latencies.Count
        NoResponse = $results.Count - $latencies.Count
        FastestMs = if ($latencies.Count) { ($latencies | Measure-Object -Minimum).Minimum } else { $null }
        MedianMs = if ($latencies.Count) { ($latencies | Sort-Object)[[math]::Floor($latencies.Count / 2)] } else { $null }
        ImportScreenshot = $importShot
        LatencyScreenshot = $pingShot
    } | ConvertTo-Json -Compress
}
finally {
    if (-not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        if (-not $process.WaitForExit(5000)) { $process.Kill(); $process.WaitForExit() }
    }
}
