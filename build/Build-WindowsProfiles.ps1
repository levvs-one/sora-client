param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\artifacts\windows')
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\v2rayN\v2rayN\v2rayN.csproj')).Path
$resolvedOutput = [IO.Path]::GetFullPath($OutputRoot)
$targets = 'win7', 'win8', 'win10', 'win11'

& dotnet restore $project --runtime win7-x86
if ($LASTEXITCODE -ne 0) { throw 'Не удалось восстановить зависимости Windows-клиента.' }

foreach ($target in $targets) {
    $targetOutput = Join-Path $resolvedOutput $target
    New-Item -ItemType Directory -Path $targetOutput -Force | Out-Null
    & dotnet build $project --configuration $Configuration --runtime win7-x86 --no-restore --property:Platform=x86 --property:SoraWindowsTarget=$target --output $targetOutput
    if ($LASTEXITCODE -ne 0) { throw "Не удалось собрать профиль $target." }
    $executable = Join-Path $targetOutput "sora_$target.exe"
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Сборка не создала $executable." }
    Get-Item -LiteralPath $executable | Select-Object Name, Length, FullName
}
