param(
    [Alias('SoraExe')]
    [string]$AssemblyPath = (Join-Path $PSScriptRoot '..\v2rayN\v2rayN\bin\x86\Release\net48\win7-x86\Sora.exe'),
    [string]$SubscriptionPath = ''
)

$ErrorActionPreference = 'Stop'
$assembly = [System.Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath))
$handler = $assembly.GetType('v2rayN.Handler.ConfigHandler', $true)
$binding = [System.Reflection.BindingFlags]'Public, NonPublic, Static'
$methods = $handler.GetMethods($binding)
$countMethod = $methods | Where-Object { $_.Name -eq 'CountSoraXrayConfigurations' } | Select-Object -First 1
$endpointMethod = $methods | Where-Object { $_.Name -eq 'TryGetSoraXrayEndpoint' } | Select-Object -First 1
if ($null -eq $countMethod -or $null -eq $endpointMethod) {
    $available = ($methods | Where-Object { $_.Name -like '*Sora*' } | ForEach-Object Name) -join ', '
    throw "Required subscription methods were not found in $AssemblyPath. Available Sora methods: $available"
}

$subscription = @'
[
  {
    "remarks": "Working VLESS",
    "inbounds": [{ "protocol": "socks", "listen": "127.0.0.1", "port": 10808 }],
    "outbounds": [{
      "protocol": "vless",
      "settings": { "vnext": [{ "address": "example.com", "port": 443, "users": [] }] }
    }]
  },
  {
    "remarks": "Unsupported Hysteria",
    "inbounds": [{ "protocol": "socks", "listen": "127.0.0.1", "port": 10808 }],
    "outbounds": [{ "protocol": "hysteria", "settings": { "server": "ignored.example", "port": 8443 } }]
  }
]
'@

$compatibleCount = [int]$countMethod.Invoke($null, @($subscription))
if ($compatibleCount -ne 1) {
    throw "Expected one Xray-compatible profile, got $compatibleCount"
}

$singleProfile = [string](($subscription | ConvertFrom-Json)[0] | ConvertTo-Json -Depth 20 -Compress)
$arguments = [object[]]@($singleProfile, '', 0)
$endpointFound = [bool]$endpointMethod.Invoke($null, $arguments)
if (-not $endpointFound -or $arguments[1] -ne 'example.com' -or $arguments[2] -ne 443) {
    throw "Endpoint detection failed: found=$endpointFound address=$($arguments[1]) port=$($arguments[2])"
}

$invalidCount = [int]$countMethod.Invoke($null, @('not-json'))
if ($invalidCount -ne 0) {
    throw "Malformed input must not be recognized, got $invalidCount"
}

$subItemType = $assembly.GetType('v2rayN.Mode.SubItem', $true)
$subItem = [Activator]::CreateInstance($subItemType)
$interval = [int]$subItemType.GetProperty('updateIntervalMinutes').GetValue($subItem)
if ($interval -ne 720) {
    throw "Expected the default subscription interval to be 720 minutes, got $interval"
}
foreach ($property in 'lastUpdateAttemptUtcTicks', 'lastUpdateSuccessUtcTicks', 'lastUpdateError', 'lastServerCount', 'nameCustomized', 'subscriptionUploadBytes', 'subscriptionDownloadBytes', 'subscriptionTotalBytes', 'subscriptionExpireUnixSeconds') {
    if ($null -eq $subItemType.GetProperty($property)) {
        throw "Subscription lifecycle property is missing: $property"
    }
}

$removeMethod = $methods | Where-Object { $_.Name -eq 'RemoveSubscription' } | Select-Object -First 1
if ($null -eq $removeMethod) {
    throw 'Atomic subscription removal method was not found'
}

$updateType = $assembly.GetType('v2rayN.Handler.UpdateHandle', $true)
$decodeTitle = $updateType.GetMethod('DecodeSoraProfileTitle', [System.Reflection.BindingFlags]'NonPublic, Static')
if ($null -eq $decodeTitle) {
    throw 'Profile-Title decoder was not found'
}
$decodedTitle = [string]$decodeTitle.Invoke($null, @('base64:RHIuIFdhdHNvbiBWUE4='))
if ($decodedTitle -ne 'Dr. Watson VPN') {
    throw "Profile-Title decoding failed: $decodedTitle"
}
$subItemType.GetProperty('url').SetValue($subItem, 'https://s.wrmo.ru/s/example')
$subItemType.GetProperty('remarks').SetValue($subItem, 'wrmo.ru')
$subItemType.GetProperty('nameCustomized').SetValue($subItem, $true)
$shouldApplyTitle = $updateType.GetMethod('ShouldApplySoraProfileTitle', [System.Reflection.BindingFlags]'NonPublic, Static')
if (-not [bool]$shouldApplyTitle.Invoke($null, @($subItem))) {
    throw 'A legacy host fallback must be replaceable by Profile-Title'
}
$parseUserinfo = $updateType.GetMethod('ParseSoraSubscriptionUserinfo', [System.Reflection.BindingFlags]'NonPublic, Static')
$parseUserinfo.Invoke($null, @($subItem, 'upload=10; download=20; total=100; expire=1882779604')) | Out-Null
if ([long]$subItemType.GetProperty('subscriptionDownloadBytes').GetValue($subItem) -ne 20 -or [long]$subItemType.GetProperty('subscriptionTotalBytes').GetValue($subItem) -ne 100) {
    throw 'Subscription-Userinfo parsing failed'
}

$mainFormType = $assembly.GetType('v2rayN.Forms.MainForm', $true)
$instanceBinding = [System.Reflection.BindingFlags]'NonPublic, Instance'
if ($null -ne $mainFormType.GetMethod('BuildHappSubscriptionsPage', $instanceBinding)) {
    throw 'The detached subscriptions page must not return'
}
if ($null -eq $mainFormType.GetMethod('BuildSoraInlineSubscriptionCard', $instanceBinding)) {
    throw 'The inline subscriptions card is missing from the servers screen'
}
if ($null -eq $mainFormType.GetField('_soraTrafficSummary', $instanceBinding)) {
    throw 'The compact traffic summary is missing below the connection button'
}
if ($null -ne $mainFormType.GetField('_soraTrafficTotal', $instanceBinding)) {
    throw 'The layered traffic card must not return to the connection pane'
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionPath)) {
    $realContent = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SubscriptionPath))
    $realCount = [int]$countMethod.Invoke($null, @($realContent))
    if ($realCount -lt 1) {
        throw 'The supplied subscription contains no Xray-compatible profiles'
    }
    Write-Output "Supplied subscription: PASS ($realCount Xray-compatible profiles)"
}

Write-Output 'Sora subscription regression: PASS (parser, lifecycle model, atomic removal, inline management)'
