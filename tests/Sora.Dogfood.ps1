param(
    [Parameter(Mandatory = $true)][string]$StagePath,
    [string]$SubscriptionUrl = '',
    [string]$SubscriptionPayloadPath = '',
    [int]$ExpectedProfiles = 10,
    [int]$TimeoutSeconds = 90
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Wait-Until {
    param([scriptblock]$Condition, [string]$Failure, [int]$Seconds = $TimeoutSeconds)
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    do {
        $result = & $Condition
        if ($result) { return $result }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    throw $Failure
}

function Find-Element {
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

function Invoke-Element {
    param([Windows.Automation.AutomationElement]$Element)
    $pattern = $Element.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)
    $pattern.Invoke()
}

$resolvedStage = (Resolve-Path -LiteralPath $StagePath).Path
$executable = Join-Path $resolvedStage 'Sora.exe'
$configPath = Join-Path $resolvedStage 'guiNConfig.json'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Sora.exe not found in $resolvedStage" }
if (Test-Path -LiteralPath $configPath) { throw "Dogfood stage is not clean: $configPath already exists" }
if ([string]::IsNullOrWhiteSpace($SubscriptionUrl) -eq [string]::IsNullOrWhiteSpace($SubscriptionPayloadPath)) {
    throw 'Supply either SubscriptionUrl or SubscriptionPayloadPath'
}
$importValue = if ([string]::IsNullOrWhiteSpace($SubscriptionPayloadPath)) {
    $SubscriptionUrl
} else {
    [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SubscriptionPayloadPath))
}

[System.Windows.Forms.Clipboard]::SetText($importValue)
$process = Start-Process -FilePath $executable -WorkingDirectory $resolvedStage -PassThru
try {
    Wait-Until { $process.Refresh(); $process.MainWindowHandle -ne 0 } 'Sora main window did not appear' | Out-Null
    $addConfiguration = Wait-Until { Find-Element $process.Id 'Добавить конфигурацию' } 'Add configuration button was not exposed to UI Automation'
    Invoke-Element $addConfiguration

    $importButton = Wait-Until { Find-Element $process.Id 'Добавить распознанную конфигурацию' } 'Sora import dialog did not appear'
    $importField = Wait-Until { Find-Element $process.Id 'RichEdit Control' } 'Import field was not exposed to UI Automation'
    $valuePattern = $importField.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)
    $valuePattern.SetValue($importValue)
    Wait-Until { $importButton.Current.IsEnabled } 'Imported content was not recognized by the import dialog' | Out-Null
    Invoke-Element $importButton

    $importedCount = Wait-Until {
        if (-not (Test-Path -LiteralPath $configPath)) { return $false }
        try {
            $saved = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            if ([string]::IsNullOrWhiteSpace($SubscriptionPayloadPath)) {
                $subscription = @($saved.subItem | Where-Object { $_.url -eq $SubscriptionUrl }) | Select-Object -First 1
                if ($null -eq $subscription) { return $false }
                $count = @($saved.vmess | Where-Object { $_.subid -eq $subscription.id }).Count
            } else {
                $count = @($saved.vmess).Count
            }
            if ($count -ge $ExpectedProfiles) { return $count }
        }
        catch { }
        return $false
    } "Sora did not persist $ExpectedProfiles profiles from the subscription"

    $pingButton = Wait-Until { Find-Element $process.Id 'Измерить задержку' } 'Latency button was not found after import'
    Invoke-Element $pingButton
    $fullRoutePing = Wait-Until { Find-Element $process.Id 'Через прокси — полный маршрут' } 'Full-route latency method was not found'
    Invoke-Element $fullRoutePing
    $pingResult = Wait-Until {
        $processCondition = New-Object Windows.Automation.PropertyCondition(
            [Windows.Automation.AutomationElement]::ProcessIdProperty,
            $process.Id
        )
        $elements = [Windows.Automation.AutomationElement]::RootElement.FindAll(
            [Windows.Automation.TreeScope]::Descendants,
            $processCondition
        )
        foreach ($element in $elements) {
            $name = $element.Current.Name
            if ($name -match '(?<!\d)(\d+)\s*(?:ms|мс)(?!\w)') { return $matches[0] }
        }
        return $false
    } 'No numeric TCP ping appeared in the Sora UI'

    $duplicateResult = 'not-applicable'
    if (-not [string]::IsNullOrWhiteSpace($SubscriptionUrl)) {
        Invoke-Element (Wait-Until { Find-Element $process.Id 'Добавить конфигурацию' } 'Add configuration button was not exposed for duplicate check')
        $duplicateField = Wait-Until { Find-Element $process.Id 'RichEdit Control' } 'Import field was not exposed for duplicate check'
        $duplicateField.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue($SubscriptionUrl)
        $duplicateButton = Wait-Until { Find-Element $process.Id 'Добавить распознанную конфигурацию' } 'Import button was not exposed for duplicate check'
        Invoke-Element $duplicateButton

        Wait-Until { Find-Element $process.Id 'Эта подписка уже добавлена.' } 'Duplicate subscription warning did not appear' | Out-Null
        Invoke-Element (Wait-Until { Find-Element $process.Id 'ОК' } 'Duplicate subscription warning could not be closed')
        Start-Sleep -Milliseconds 750
        if (Find-Element $process.Id 'Sora не нашла ни одной рабочей конфигурации. Проверьте ссылку или содержимое подписки.') {
            throw 'Duplicate subscription triggered a second invalid-configuration warning'
        }
        [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
        $duplicateResult = 'single-warning'
    }

    Write-Output "Sora dogfood: PASS (imported=$importedCount, ping=$pingResult, duplicate=$duplicateResult, persisted=yes)"
}
finally {
    if (-not $process.HasExited) {
        $process.Kill()
        $process.WaitForExit()
    }
}
