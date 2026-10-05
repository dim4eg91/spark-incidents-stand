param(
    [switch]$Volumes
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    $composeArguments = @("compose", "--profile", "storage", "--profile", "postmortem", "down", "--remove-orphans")
    if ($Volumes) {
        $composeArguments += "--volumes"
    }

    & docker @composeArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose завершился с кодом $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
