param(
    [ValidateSet("core", "storage", "postmortem", "all")]
    [string]$Profile = "core"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common.ps1')
Push-Location $repoRoot

try {
    $composeArguments = @("compose")

    if ($Profile -eq "storage" -or $Profile -eq "all") {
        $composeArguments += @("--profile", "storage")
    }

    if ($Profile -eq "postmortem" -or $Profile -eq "all") {
        $composeArguments += @("--profile", "postmortem")
    }

    $composeArguments += @("up", "-d", "--build")
    & docker @composeArguments

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose завершился с кодом $LASTEXITCODE"
    }

    $config = Get-LabConfig
    Write-Host ('JupyterLab: ' + (Get-LabUrl $config 'spark-incidents-jupyter' 8888))
    Write-Host 'Вход: токен JUPYTER_TOKEN из .env. Дождись статуса healthy в docker compose ps.'
    Write-Host 'Если .env ещё не создан, учебный токен по умолчанию: sparkstudent.'
    Write-Host 'Порты 14040-14050 относятся к Spark UI. Для notebook используй адрес JupyterLab выше.'
    Write-Host 'Помощь: docs/windows-setup.md, docs/files-and-notebooks.md, docs/troubleshooting.md.'
    Write-Host "Для проверки: .\scripts\health.ps1 -Profile $Profile"
} finally {
    Pop-Location
}
