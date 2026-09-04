param(
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [string]$UpdatePublicKeyFile
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$resolvedOutput = [IO.Path]::GetFullPath($OutputRoot)
foreach ($tool in @(@{ Project = 'Sora.Logs'; Folder = 'logs' }, @{ Project = 'Sora.Update'; Folder = 'update' })) {
    $project = Join-Path $projectRoot "clients\windows-tools\$($tool.Project)\$($tool.Project).csproj"
    $destination = Join-Path $resolvedOutput "tools\$($tool.Folder)"
    $arguments = @('build', $project, '--configuration', $Configuration, '--output', $destination, '--nologo', '-m:1', '-nr:false', '-p:DebugType=None')
    if ($tool.Folder -eq 'update' -and $UpdatePublicKeyFile) {
        $keyPath = (Resolve-Path -LiteralPath $UpdatePublicKeyFile).Path
        if ([Convert]::FromBase64String([IO.File]::ReadAllText($keyPath).Trim()).Length -ne 32) { throw 'The Ed25519 public key must contain 32 bytes.' }
        $arguments += "-p:SoraUpdatePublicKeyFile=$keyPath"
    }
    & dotnet @arguments
    if ($LASTEXITCODE -ne 0) { throw "Failed to build $($tool.Project)." }
    $licenses = Join-Path $destination 'licenses'
    New-Item -ItemType Directory -Path $licenses -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $licenses -Force
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'licenses\nuget') -File | Copy-Item -Destination $licenses -Force
}
