param(
    [Parameter(Mandatory = $true)]
    [string]$SoraExe,
    [Parameter(Mandatory = $true)]
    [string]$SoraIcon
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$testRoot = Join-Path $env:TEMP ("sora-installer-qa-{0}" -f [Guid]::NewGuid().ToString('N'))
$stage = Join-Path $testRoot 'stage'
$output = Join-Path $testRoot 'output'
$app = Join-Path $testRoot 'app'
$innoHome = Join-Path $testRoot 'inno'
$innoSetup = Join-Path $testRoot 'innosetup-7.1.0-x86.exe'
$innoUrl = 'https://github.com/jrsoftware/issrc/releases/download/is-7_1_0/innosetup-7.1.0-x86.exe'
$innoSha256 = 'F9671174E0D15BA9B4F6B56564C6AED32EA8DB9C3CB9BF6F2AF0850FE7894F60'
$appId = "Sora-Installer-QA-$([Guid]::NewGuid().ToString('N'))"

function Invoke-CheckedProcess {
    param([string]$FilePath, [string[]]$Arguments, [switch]$Visible)

    $start = @{
        FilePath = $FilePath
        ArgumentList = $Arguments
        Wait = $true
        PassThru = $true
    }
    if (-not $Visible) {
        $start.WindowStyle = 'Hidden'
    }
    $process = Start-Process @start
    if ($process.ExitCode -ne 0) {
        throw "$FilePath failed with exit code $($process.ExitCode)."
    }
}

try {
    New-Item -ItemType Directory -Path $stage, $output | Out-Null
    Copy-Item -LiteralPath $SoraExe -Destination (Join-Path $stage 'sora_win7.exe')
    Copy-Item -LiteralPath $SoraIcon -Destination (Join-Path $stage 'sora.ico')
    $sourceDirectory = Split-Path -Parent (Resolve-Path -LiteralPath $SoraExe).Path
    foreach ($culture in 'en-US', 'zh-Hans', 'zh-Hant') {
        Copy-Item -LiteralPath (Join-Path $sourceDirectory $culture) -Destination $stage -Recurse
    }

    Invoke-WebRequest -UseBasicParsing -Uri $innoUrl -OutFile $innoSetup
    $downloadHash = (Get-FileHash -LiteralPath $innoSetup -Algorithm SHA256).Hash
    if ($downloadHash -ne $innoSha256) {
        throw "Inno Setup download hash mismatch: $downloadHash"
    }
    Invoke-CheckedProcess $innoSetup @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER', "/DIR=$innoHome")
    $compiler = Join-Path $innoHome 'ISCC.exe'
    if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
        throw 'Inno Setup compiler was not installed.'
    }

    $compilerArguments = @(
        "/DAppIdValue=$appId",
        "/DStageDir=$stage",
        "/DNdpInstaller=$innoSetup",
        "/DKbInstaller=$innoSetup",
        "/DBuildOutputDir=$output",
        (Join-Path $projectRoot 'installer\Sora.iss')
    )
    & $compiler @compilerArguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Installer compilation failed with exit code $LASTEXITCODE."
    }

    $setup = Get-ChildItem -LiteralPath $output -Filter 'Sora-*-win7-Setup.exe' -File | Select-Object -First 1
    if (-not $setup) {
        throw 'Compiled installer was not found.'
    }
    $silentArguments = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS', '/LANG=english', "/DIR=$app")
    Invoke-CheckedProcess $setup.FullName $silentArguments
    if (-not (Test-Path -LiteralPath (Join-Path $app 'sora_win7.exe') -PathType Leaf)) {
        throw 'Fresh installation did not install Sora.'
    }
    foreach ($culture in 'en-US', 'zh-Hans', 'zh-Hant') {
        $relativeResource = "$culture\sora_win7.resources.dll"
        $installedResource = Join-Path $app $relativeResource
        if (-not (Test-Path -LiteralPath $installedResource -PathType Leaf) -or
            (Get-FileHash -LiteralPath $installedResource).Hash -ne
            (Get-FileHash -LiteralPath (Join-Path $stage $relativeResource)).Hash) {
            throw "Installed translation is missing or damaged: $culture"
        }
    }

    $configPath = Join-Path $app 'guiNConfig.json'
    $statisticsPath = Join-Path $app 'statistics.json'
    [IO.File]::WriteAllText($configPath, '{"subscription":"preserve-me"}')
    [IO.File]::WriteAllText($statisticsPath, '{"bytes":42}')
    Invoke-CheckedProcess $setup.FullName $silentArguments
    if ([IO.File]::ReadAllText($configPath) -ne '{"subscription":"preserve-me"}') {
        throw 'Repair installation changed the user configuration.'
    }
    $backup = Get-ChildItem -LiteralPath (Join-Path $app 'guiBackups\installer') -Filter 'guiNConfig.json.*.bak' -File | Select-Object -First 1
    if (-not $backup -or [IO.File]::ReadAllText($backup.FullName) -ne '{"subscription":"preserve-me"}') {
        throw 'Repair installation did not create a valid configuration backup.'
    }

    Copy-Item -LiteralPath (Join-Path $env:WINDIR 'System32\whoami.exe') -Destination (Join-Path $app 'sora_win7.exe') -Force
    Invoke-CheckedProcess (Join-Path $app 'unins000.exe') @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART')
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw 'Default uninstall removed the user configuration.'
    }

    Invoke-CheckedProcess $setup.FullName $silentArguments
    New-Item -ItemType Directory -Path (Join-Path $app 'guiLogs'), (Join-Path $app 'guiConfigs') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $env:WINDIR 'System32\whoami.exe') -Destination (Join-Path $app 'sora_win7.exe') -Force
    Invoke-CheckedProcess (Join-Path $app 'unins000.exe') @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/PURGEUSERDATA')
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        throw 'Full uninstall kept the user configuration.'
    }
    if (Test-Path -LiteralPath (Join-Path $app 'guiLogs')) {
        throw 'Full uninstall kept the log directory.'
    }

    Write-Output 'Installer fresh install, repair, backup, safe uninstall, and full cleanup: PASS'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = [IO.Path]::GetFullPath($testRoot)
        $tempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
        if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean unexpected path: $resolved"
        }
        [IO.Directory]::Delete($resolved, $true)
    }
}
