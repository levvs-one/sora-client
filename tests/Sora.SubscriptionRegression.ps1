param(
    [Alias('SoraExe')]
    [string]$AssemblyPath = (Join-Path $PSScriptRoot '..\v2rayN\v2rayN\bin\x86\Release\net48\win7-x86\sora_win7.exe'),
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
foreach ($property in 'lastUpdateAttemptUtcTicks', 'lastUpdateSuccessUtcTicks', 'lastUpdateError', 'lastServerCount', 'nameCustomized', 'subscriptionUploadBytes', 'subscriptionDownloadBytes', 'subscriptionTotalBytes', 'subscriptionExpireUnixSeconds', 'subscriptionAnnouncement') {
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
$decodeAnnouncement = $updateType.GetMethod('DecodeSoraAnnouncement', [System.Reflection.BindingFlags]'NonPublic, Static')
$announcementSource = "**Subscription description**`n`n    code  spacing`nChannel: @sora_client"
$announcementHeader = 'base64:' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($announcementSource))
$decodedAnnouncement = [string]$decodeAnnouncement.Invoke($null, @($announcementHeader))
if ($decodedAnnouncement -ne $announcementSource) {
    throw "Announce decoding failed: $decodedAnnouncement"
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
if ($null -ne $mainFormType.GetMethod('BuildSoraInlineSubscriptionCard', $instanceBinding)) {
    throw 'The single flat subscription card must not return'
}
if ($null -eq $mainFormType.GetMethod('BuildSoraSubscriptionAccordion', $instanceBinding)) {
    throw 'Separate collapsible subscription sections are missing from the servers screen'
}
if ($null -eq $mainFormType.GetField('_soraExpandedSubscriptionId', $instanceBinding)) {
    throw 'Subscription expansion state is missing'
}
$staticBinding = [System.Reflection.BindingFlags]'NonPublic, Static'
$addImportContainer = $mainFormType.GetMethod('AddSoraImportContainer', $staticBinding)
if ($null -eq $addImportContainer) {
    throw 'Local imports cannot be assigned to their own subscription container'
}
$importConfig = [Activator]::CreateInstance($assembly.GetType('v2rayN.Mode.Config', $true))
$subItemListType = [System.Collections.Generic.List``1].MakeGenericType($subItemType)
$subItemList = [Activator]::CreateInstance($subItemListType)
$importConfig.GetType().GetProperty('subItem').SetValue($importConfig, $subItemList)
$localContainer = $addImportContainer.Invoke($null, @($importConfig, '', 'Imported VLESS'))
if ([string]::IsNullOrWhiteSpace($subItemType.GetProperty('id').GetValue($localContainer)) -or
    $subItemType.GetProperty('remarks').GetValue($localContainer) -ne 'Imported VLESS' -or
    $subItemType.GetProperty('url').GetValue($localContainer) -ne '' -or
    $subItemList.Count -ne 1) {
    throw 'A direct import was not isolated in a named local subscription'
}
if ($null -eq $mainFormType.GetField('_soraTrafficSummary', $instanceBinding)) {
    throw 'The compact traffic summary is missing below the connection button'
}
foreach ($timer in @{
    SoraTrafficRefreshIntervalMilliseconds = 1000
    SoraSubscriptionRefreshIntervalMilliseconds = 30000
}.GetEnumerator()) {
    $timerField = $mainFormType.GetField($timer.Key, [System.Reflection.BindingFlags]'NonPublic, Static')
    if ($null -eq $timerField -or [int]$timerField.GetRawConstantValue() -ne $timer.Value) {
        throw "Unexpected low-end Windows refresh interval: $($timer.Key)"
    }
}
foreach ($fontField in '_soraServerTitleFont', '_soraServerProtocolFont', '_soraServerDetailFont', '_soraServerResultFont') {
    if ($null -eq $mainFormType.GetField($fontField, $instanceBinding)) {
        throw "Cached server-list font is missing: $fontField"
    }
}
if ($null -ne $mainFormType.GetField('_soraTrafficTotal', $instanceBinding)) {
    throw 'The layered traffic card must not return to the connection pane'
}

$markdownType = $assembly.GetType('v2rayN.Forms.SoraMarkdownView', $true)
$renderMarkdown = $markdownType.GetMethod('RenderToRtf', [System.Reflection.BindingFlags]'NonPublic, Static')
if ($null -eq $renderMarkdown) {
    throw 'The native Markdown renderer is missing'
}
$markdownSample = '**Bold** and ~~removed~~ [safe](https://example.com) [unsafe](javascript:alert(1)) <script>bad()</script>'
$renderedMarkdown = [string]$renderMarkdown.Invoke($null, @($markdownSample, $false))
if (-not $renderedMarkdown.Contains('\b ') -or -not $renderedMarkdown.Contains('\strike ')) {
    throw 'Markdown emphasis was not rendered'
}
if ($renderedMarkdown -notmatch 'HYPERLINK.*https://example\.com') {
    throw 'HTTPS Markdown links were not rendered'
}
if ($renderedMarkdown -match 'javascript:' -or $renderedMarkdown -match '<script>') {
    throw 'Unsafe Markdown content reached the rich-text output'
}
$compactMarkdown = [string]$renderMarkdown.Invoke($null, @("First line`nSecond line", $true))
if (-not $compactMarkdown.Contains('\pard\qc')) {
    throw 'Compact subscription Markdown is not centered line by line'
}

$soraTextType = $assembly.GetType('v2rayN.Tool.SoraText', $true)
$resourceField = $soraTextType.GetField('Standard', [System.Reflection.BindingFlags]'NonPublic, Static')
$preReformField = $soraTextType.GetField('PreReform', [System.Reflection.BindingFlags]'NonPublic, Static')
$resourceManager = $resourceField.GetValue($null)
$preReformManager = $preReformField.GetValue($null)
$settingsKey = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0J3QsNGB0YLRgNC+0LnQutC4'))
$chineseSettings = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('6K6+572u'))
$logKey = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0JbRg9GA0L3QsNC7'))
$preReformLog = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('0JbRg9GA0L3QsNC70Yo='))
if ($resourceManager.GetString($settingsKey, [Globalization.CultureInfo]::GetCultureInfo('en-US')) -ne 'Settings') {
    throw 'English Sora resources are missing'
}
if ($resourceManager.GetString($settingsKey, [Globalization.CultureInfo]::GetCultureInfo('zh-Hans')) -ne $chineseSettings) {
    throw 'Chinese Sora resources are missing'
}
if ($preReformManager.GetString($logKey, [Globalization.CultureInfo]::GetCultureInfo('ru-RU')) -ne $preReformLog) {
    throw 'Pre-reform Russian Sora resources are missing'
}

$configType = $assembly.GetType('v2rayN.Mode.Config', $true)
$inboundType = $assembly.GetType('v2rayN.Mode.InItem', $true)
$testConfig = [Activator]::CreateInstance($configType)
$testInbound = [Activator]::CreateInstance($inboundType)
$inboundType.GetProperty('protocol').SetValue($testInbound, 'socks')
$inboundType.GetProperty('localPort').SetValue($testInbound, 19080)
$inboundType.GetProperty('allowLANConn').SetValue($testInbound, $false)
$inboundListType = [System.Collections.Generic.List``1].MakeGenericType($inboundType)
$inboundList = [Activator]::CreateInstance($inboundListType)
$inboundList.Add($testInbound)
$configType.GetProperty('inbound').SetValue($testConfig, $inboundList)
$normalizer = $assembly.GetType('v2rayN.Handler.V2rayHandler', $true).GetMethod('NormalizeCustomXrayInbounds', [System.Reflection.BindingFlags]'NonPublic, Static')
$temporaryConfig = Join-Path ([IO.Path]::GetTempPath()) ('sora-xray-' + [Guid]::NewGuid().ToString('N') + '.json')
try {
    [IO.File]::WriteAllText($temporaryConfig, '{"inbounds":[{"protocol":"socks","port":10808}],"outbounds":[{"protocol":"freedom"}]}', [Text.UTF8Encoding]::new($false))
    $normalizeArguments = [object[]]@($testConfig, [string]$temporaryConfig)
    $normalizer.Invoke($null, $normalizeArguments) | Out-Null
    $normalized = [IO.File]::ReadAllText($temporaryConfig) | ConvertFrom-Json
    $socks = @($normalized.inbounds | Where-Object protocol -eq 'socks') | Select-Object -First 1
    $http = @($normalized.inbounds | Where-Object protocol -eq 'http') | Select-Object -First 1
    if ($socks.port -ne 19080 -or $http.port -ne 19081 -or $socks.listen -ne '127.0.0.1' -or $http.listen -ne '127.0.0.1') {
        throw 'Custom Xray inbounds were not normalized to the Sora local proxy ports'
    }
}
finally {
    Remove-Item -LiteralPath $temporaryConfig -Force -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionPath)) {
    $realContent = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SubscriptionPath))
    $realCount = [int]$countMethod.Invoke($null, @($realContent))
    if ($realCount -lt 1) {
        throw 'The supplied subscription contains no Xray-compatible profiles'
    }
    Write-Output "Supplied subscription: PASS ($realCount Xray-compatible profiles)"
}

Write-Output 'Sora regression: PASS (separate subscriptions, local Xray ports, localization, Markdown, inline management)'
