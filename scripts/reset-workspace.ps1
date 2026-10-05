[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z][a-z0-9_-]{0,63}$')]
    [string]$LabId
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$workspacePath = Join-Path $repoRoot 'workspace'
$outputRoot = Join-Path $workspacePath 'output'
$targetPath = [IO.Path]::GetFullPath((Join-Path $outputRoot $LabId))
$backupRoot = Join-Path $workspacePath '.reset-backups'

foreach ($path in @($workspacePath, $outputRoot, $targetPath, $backupRoot)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing a linked directory: $path"
        }
    }
}
if (-not $targetPath.StartsWith($outputRoot + [IO.Path]::DirectorySeparatorChar)) {
    throw 'Output path is outside the lab workspace.'
}
if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
    Write-Host "No output to reset: $LabId"
    return
}
$linked = @(Get-ChildItem -LiteralPath $targetPath -Recurse -Force |
    Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
if ($linked.Count) { throw 'Output contains links. Move them explicitly before reset.' }
$backupPath = Join-Path $backupRoot ($LabId + '-' + [guid]::NewGuid().ToString('N'))
if (-not ([IO.Path]::GetFullPath($backupPath)).StartsWith($workspacePath + [IO.Path]::DirectorySeparatorChar)) {
    throw 'Backup is outside the workspace.'
}
if ($PSCmdlet.ShouldProcess($targetPath, "Archive lab output to $backupPath")) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Move-Item -LiteralPath $targetPath -Destination $backupPath
    Write-Host "Output archived: $backupPath"
}
