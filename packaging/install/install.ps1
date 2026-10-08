# Installs Sora on Windows in one command, from PowerShell:
#
#   irm https://github.com/levvs-one/sora-client/releases/latest/download/install.ps1 | iex
#
# It finds the latest release, downloads the installer, checks it against the
# release's SHA256SUMS and runs it without questions; Windows asks once for
# administrator rights, because the core is installed as a service. Nothing
# runs when the checksum does not match.
#
# $env:SORA_VERSION = '1.0.3' installs that release instead of the latest.
# $env:SORA_DIST = '<folder>' installs an installer already in that folder,
# with its SHA256SUMS; CI checks the installer it built this way.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Windows PowerShell 5.1 offers TLS 1.0 by default, which GitHub refuses.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = 'https://github.com/levvs-one/sora-client'

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Sora for Windows needs 64-bit Windows 10 1809 or later.'
}

$version = $env:SORA_VERSION
if ($env:SORA_DIST) {
    if (-not $version) { throw 'SORA_VERSION is needed with SORA_DIST.' }
} elseif (-not $version) {
    $latest = Invoke-RestMethod -UseBasicParsing 'https://api.github.com/repos/levvs-one/sora-client/releases/latest'
    $version = $latest.tag_name -replace '^v', ''
}
if ($version -notmatch '^\d+(\.\d+){2,3}$') { throw "'$version' is not a release of Sora." }

$name = "Sora-Setup-$version-x64.exe"
$work = Join-Path ([IO.Path]::GetTempPath()) ("sora-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
try {
    foreach ($file in @('SHA256SUMS', $name)) {
        $target = Join-Path $work $file
        if ($env:SORA_DIST) {
            Copy-Item (Join-Path $env:SORA_DIST $file) $target
        } else {
            Invoke-WebRequest -UseBasicParsing "$repo/releases/download/v$version/$file" -OutFile $target
        }
    }
    $pattern = "^([0-9a-f]{64})\s+\*?$([regex]::Escape($name))$"
    $line = Get-Content (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if (-not $line -or $line -notmatch $pattern) { throw "$name is not in SHA256SUMS." }
    $expected = $Matches[1]
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $work $name)).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { throw "$name does not match SHA256SUMS; nothing was installed." }

    Write-Output "sora: installing $version"
    $setup = Start-Process (Join-Path $work $name) -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
    if ($setup.ExitCode -ne 0) { throw "The installer ended with code $($setup.ExitCode)." }
    Write-Output 'sora: installed. Sora is in the Start menu; its icon lives in the tray.'
} finally {
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
