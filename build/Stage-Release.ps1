param(
    [Parameter(Mandatory = $true)]
    [string]$SourceBin,
    [Parameter(Mandatory = $true)]
    [string]$StagePath,
    [Parameter(Mandatory = $true)]
    [string]$CompatPayload,
    [Parameter(Mandatory = $true)]
    [string]$XrayArchive
)

function Assert-Sha256 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected
    )
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected) {
        throw "SHA-256 mismatch for $Path. Expected $Expected, got $actual"
    }
}

$resolvedStage = [System.IO.Path]::GetFullPath($StagePath)
if ([System.IO.Path]::GetFileName($resolvedStage) -ne 'stage') {
    throw 'The staging directory must be named stage'
}
$stageParent = [System.IO.Path]::GetDirectoryName($resolvedStage)
if ([string]::IsNullOrWhiteSpace($stageParent) -or $stageParent -eq [System.IO.Path]::GetPathRoot($resolvedStage)) {
    throw 'The staging directory cannot be placed at a drive root'
}

if (Test-Path -LiteralPath $resolvedStage) {
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
}
New-Item -ItemType Directory -Path $resolvedStage | Out-Null

$resolvedBin = (Resolve-Path -LiteralPath $SourceBin).Path
Get-ChildItem -LiteralPath $resolvedBin -File |
    Where-Object { $_.Name -notin @('grpc_csharp_ext.x64.dll', 'guiNConfig.json') -and $_.Extension -ne '.pdb' } |
    Copy-Item -Destination $resolvedStage

$assetsDirectory = Join-Path $resolvedBin 'Assets'
if (-not (Test-Path -LiteralPath $assetsDirectory)) {
    throw 'The build output does not contain the Assets directory'
}
Copy-Item -LiteralPath $assetsDirectory -Destination $resolvedStage -Recurse

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$icon = Join-Path $projectRoot 'v2rayN\v2rayN\Assets\Sora\sora.ico'
Copy-Item -LiteralPath $icon -Destination (Join-Path $resolvedStage 'sora.ico')
$xrayExecutable = Join-Path $CompatPayload 'core\xray.exe'
$singBoxExecutable = Join-Path $CompatPayload 'tun\sing-box.exe'
Assert-Sha256 $xrayExecutable '0F611E1DEB746BB295DE2344A3D1E668F39FDB1818515F631277B1425CE51AB1'
Assert-Sha256 $singBoxExecutable 'E9FDD8B543D494B41923D5D4660E65AC380A14DDDD4D45E7379BE4CCED92D0E1'
Copy-Item -LiteralPath $xrayExecutable -Destination $resolvedStage
Copy-Item -LiteralPath $singBoxExecutable -Destination $resolvedStage

$tunDirectory = Join-Path $resolvedStage 'tun2proxy'
New-Item -ItemType Directory -Path $tunDirectory | Out-Null
$tunFiles = @(
    (Join-Path $CompatPayload 'tun2\tun2proxy-bin.exe'),
    (Join-Path $CompatPayload 'tun2\tun2proxy.dll'),
    (Join-Path $CompatPayload 'tun2\udpgw-server.exe'),
    (Join-Path $CompatPayload 'tun2\wintun.dll')
)
Assert-Sha256 $tunFiles[0] 'DD769D0AC9BD0826B0BFB52C44E8DA87CBDCFB5B1AD9CD45D1B1691D1743D011'
Assert-Sha256 $tunFiles[1] '97001928B30F627C00AD1B128B4EA3F5E0500B2A701E18A4431CE19BAFAAE409'
Assert-Sha256 $tunFiles[2] '203CDF3E78A277B37685E77B02AC04593B52473F8F485532B1312F9121FAC56C'
Assert-Sha256 $tunFiles[3] 'D694FA46AB4CFEBCB2632D094C7AA97278EEF2F8052438621766D863AE98A931'
Copy-Item -LiteralPath $tunFiles -Destination $tunDirectory

$extractDirectory = Join-Path $stageParent ("xray-extract-{0}" -f [Guid]::NewGuid().ToString('N'))
try {
    Assert-Sha256 $XrayArchive 'B23ACCCC3F9BD2591911C31EDB994C117F43C661F4A0CA06CBEEED4465D9C38A'
    New-Item -ItemType Directory -Path $extractDirectory | Out-Null
    tar -xf (Resolve-Path -LiteralPath $XrayArchive).Path -C $extractDirectory
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to extract Xray data files'
    }
    Copy-Item -LiteralPath (Join-Path $extractDirectory 'geoip.dat'), (Join-Path $extractDirectory 'geosite.dat') -Destination $resolvedStage
}
finally {
    if (Test-Path -LiteralPath $extractDirectory) {
        $resolvedExtract = [System.IO.Path]::GetFullPath($extractDirectory)
        if (-not $resolvedExtract.StartsWith($stageParent + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'The temporary extraction directory escaped the staging parent'
        }
        Remove-Item -LiteralPath $resolvedExtract -Recurse -Force
    }
}

Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE'), (Join-Path $projectRoot 'README.md'), (Join-Path $projectRoot 'NOTICE.md'), (Join-Path $projectRoot 'CHANGELOG.md'), (Join-Path $projectRoot 'THIRD-PARTY-NOTICES.md') -Destination $resolvedStage
Copy-Item -LiteralPath (Join-Path $CompatPayload 'licenses') -Destination $resolvedStage -Recurse
$licenseDirectory = Join-Path $resolvedStage 'licenses'
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses\nuget') -Destination $licenseDirectory -Recurse
$phosphorLicenseDirectory = Join-Path $licenseDirectory 'phosphor-icons'
New-Item -ItemType Directory -Path $phosphorLicenseDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'v2rayN\v2rayN\Assets\Phosphor\LICENSE') -Destination $phosphorLicenseDirectory

$requiredFiles = @(
    'Sora.exe',
    'Markdig.dll',
    'xray.exe',
    'sing-box.exe',
    'tun2proxy\tun2proxy-bin.exe',
    'tun2proxy\tun2proxy.dll',
    'tun2proxy\udpgw-server.exe',
    'tun2proxy\wintun.dll',
    'geoip.dat',
    'geosite.dat',
    'LICENSE',
    'NOTICE.md',
    'licenses\nuget\ATTRIBUTIONS.md',
    'licenses\nuget\Apache-2.0.txt',
    'licenses\nuget\BSD-2-Clause.txt',
    'licenses\nuget\BSD-3-Clause.txt',
    'licenses\nuget\MIT.txt',
    'licenses\nuget\NOTICE.txt',
    'licenses\phosphor-icons\LICENSE'
)
$missingFiles = $requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $resolvedStage $_) -PathType Leaf) }
if ($missingFiles.Count -gt 0) {
    throw "Required staging files are missing: $($missingFiles -join ', ')"
}

$files = Get-ChildItem -LiteralPath $resolvedStage -Recurse -File
[pscustomobject]@{
    Files = $files.Count
    Megabytes = [Math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)
    Path = $resolvedStage
}
