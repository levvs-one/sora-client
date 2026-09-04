param(
    [Parameter(Mandatory = $true)]
    [string]$StagePath,
    [Parameter(Mandatory = $true)]
    [string]$NdpInstaller,
    [Parameter(Mandatory = $true)]
    [string]$KbInstaller,
    [ValidateSet('win7', 'win8', 'win10', 'win11')]
    [string]$WindowsTarget = 'win7',
    [string]$WindowsDisplayName = 'Windows 7 SP1',
    [string]$MinimumWindowsVersion = '6.1sp1',
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\installer-output'),
    [string]$InnoCompiler,
    [string]$SignToolName
)

$ErrorActionPreference = 'Stop'

function Assert-Sha256 {
    param([string]$Path, [string]$Expected)

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected) {
        throw "SHA-256 mismatch for $Path. Expected $Expected, got $actual"
    }
}

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$resolvedStage = (Resolve-Path -LiteralPath $StagePath).Path
$resolvedNdp = (Resolve-Path -LiteralPath $NdpInstaller).Path
$resolvedKb = (Resolve-Path -LiteralPath $KbInstaller).Path
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$expectedExecutable = Join-Path $resolvedStage "sora_$WindowsTarget.exe"
$requiredFiles = @(
    $expectedExecutable,
    (Join-Path $resolvedStage "en-US\sora_$WindowsTarget.resources.dll"),
    (Join-Path $resolvedStage "zh-Hans\sora_$WindowsTarget.resources.dll"),
    (Join-Path $resolvedStage "zh-Hant\sora_$WindowsTarget.resources.dll"),
    (Join-Path $resolvedStage 'sora.ico'),
    (Join-Path $resolvedStage 'tools\logs\sora_logs.exe'),
    (Join-Path $resolvedStage 'tools\update\sora_update.exe'),
    (Join-Path $resolvedStage 'Markdig.dll'),
    (Join-Path $resolvedStage 'xray.exe'),
    (Join-Path $resolvedStage 'sing-box.exe'),
    (Join-Path $resolvedStage 'tun2proxy\tun2proxy-bin.exe'),
    (Join-Path $resolvedStage 'tun2proxy\tun2proxy.dll'),
    (Join-Path $resolvedStage 'tun2proxy\udpgw-server.exe'),
    (Join-Path $resolvedStage 'tun2proxy\wintun.dll'),
    (Join-Path $resolvedStage 'geoip.dat'),
    (Join-Path $resolvedStage 'geosite.dat'),
    (Join-Path $resolvedStage 'LICENSE')
)
$missing = $requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }
if ($missing.Count -gt 0) {
    throw "Installer stage is incomplete: $($missing -join ', ')"
}
$keyCheck = Start-Process -FilePath (Join-Path $resolvedStage 'tools\update\sora_update.exe') -ArgumentList '--verify-release-key' -WindowStyle Hidden -Wait -PassThru
if ($keyCheck.ExitCode -ne 0) { throw 'Installer release blocked: the updater signing key is missing or invalid.' }

Assert-Sha256 $resolvedNdp '0A3A390C47E639D0F7FC65B21195FEE6B7F65B066F80F70C60FAB191D14B7E40'
Assert-Sha256 $resolvedKb '246C300A6AE6DCA99453F6839745AC0015953528A7065BED1B015F91B80CF64D'

if ([string]::IsNullOrWhiteSpace($InnoCompiler)) {
    $compilerRoots = @($env:LOCALAPPDATA, ${env:ProgramFiles(x86)}, $env:ProgramFiles) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $candidates = foreach ($root in $compilerRoots) {
        if ($root -eq $env:LOCALAPPDATA) {
            Join-Path $root 'Programs\Inno Setup 7\ISCC.exe'
        }
        else {
            Join-Path $root 'Inno Setup 7\ISCC.exe'
        }
    }
    $InnoCompiler = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($InnoCompiler) -or -not (Test-Path -LiteralPath $InnoCompiler -PathType Leaf)) {
    throw 'Inno Setup 7.1.0 is required: https://github.com/jrsoftware/issrc/releases/tag/is-7_1_0'
}

New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$definitions = @(
    "/DStageDir=$resolvedStage",
    "/DNdpInstaller=$resolvedNdp",
    "/DKbInstaller=$resolvedKb",
    "/DBuildOutputDir=$resolvedOutput",
    "/DWindowsTarget=$WindowsTarget",
    "/DWindowsDisplayName=$WindowsDisplayName",
    "/DMinimumWindowsVersion=$MinimumWindowsVersion"
)
if (-not [string]::IsNullOrWhiteSpace($SignToolName)) {
    $definitions += "/DSignToolName=$SignToolName"
}

& $InnoCompiler @definitions (Join-Path $projectRoot 'installer\Sora.iss')
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compiler failed with exit code $LASTEXITCODE."
}

$setup = Get-ChildItem -LiteralPath $resolvedOutput -Filter "Sora-*-Setup.exe" -File |
    Where-Object { $_.Name -like "*-$WindowsTarget-Setup.exe" } |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
if (-not $setup) {
    throw 'Inno Setup did not produce the expected installer.'
}

$signature = Get-AuthenticodeSignature -LiteralPath $setup.FullName
[pscustomobject]@{
    File = $setup.FullName
    Bytes = $setup.Length
    SHA256 = (Get-FileHash -LiteralPath $setup.FullName -Algorithm SHA256).Hash
    Signature = $signature.Status
}
