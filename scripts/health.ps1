param(
    [ValidateSet('core', 'storage', 'postmortem', 'all')]
    [string]$Profile = 'core'
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common.ps1')
Push-Location $repoRoot

try {
    & docker compose ps
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось получить состояние контейнеров"
    }

    $config = Get-LabConfig
    $endpoints = @(
        ((Get-LabUrl $config 'spark-incidents-jupyter' 8888) + '/login'),
        (Get-LabUrl $config 'spark-incidents-master' 8080),
        (Get-LabUrl $config 'spark-incidents-worker-1' 8081),
        (Get-LabUrl $config 'spark-incidents-worker-2' 8081)
    )
    if ($Profile -in @('storage', 'all')) {
        # Profile services are present in the complete resolved configuration.
        $raw = & docker compose --profile storage --profile postmortem config --format json
        if ($LASTEXITCODE -ne 0) { throw 'Не удалось прочитать профили Compose.' }
        $full = $raw | ConvertFrom-Json
        $endpoints += ((Get-LabUrl $full 'spark-incidents-minio' 9000) + '/minio/health/live')
    }
    if ($Profile -in @('postmortem', 'all')) {
        $raw = & docker compose --profile postmortem config --format json
        if ($LASTEXITCODE -ne 0) { throw 'Не удалось прочитать профиль истории.' }
        $historyConfig = $raw | ConvertFrom-Json
        $endpoints += (Get-LabUrl $historyConfig 'spark-incidents-history' 18080)
    }

    foreach ($endpoint in $endpoints) {
        $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -NoProxy -TimeoutSec 10
        if ($response.StatusCode -ne 200) {
            throw "Проверка $endpoint вернула HTTP $($response.StatusCode)"
        }
        Write-Host "OK $endpoint"
    }

    # A public login page alone does not prove that the token and Lab work.
    $jupyterBase = Get-LabUrl $config 'spark-incidents-jupyter' 8888
    $jupyterToken = $config.services.'spark-incidents-jupyter'.environment.JUPYTER_TOKEN
    $headers = @{ Authorization = ('token ' + $jupyterToken) }
    try {
        $status = Invoke-RestMethod -Uri ($jupyterBase + '/api/status') -Headers $headers -NoProxy -TimeoutSec 10
        if ($null -eq $status.kernels) { throw 'Missing Jupyter status fields' }
        $lab = Invoke-WebRequest -Uri ($jupyterBase + '/lab') -Headers $headers -UseBasicParsing -NoProxy -TimeoutSec 10
        if ($lab.StatusCode -ne 200 -or $lab.Content -notmatch 'jupyter-config-data') {
            throw 'Lab page was not returned'
        }
        Write-Host 'OK Jupyter authenticated API and Lab HTML (browser rendering requires a separate check)'
    } catch {
        throw 'Jupyter: не пройдена проверка входа. Проверь JUPYTER_TOKEN и docs/troubleshooting.md. Токен в журнал не выводится.'
    }

    $smokeArguments = @('compose', 'exec', '-T', 'spark-incidents-jupyter',
        'python', '/opt/spark-incidents/scripts/smoke_check.py')
    if ($Profile -in @('storage', 'all')) { $smokeArguments += '--storage' }
    if ($Profile -in @('postmortem', 'all')) { $smokeArguments += '--history' }
    & docker @smokeArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Spark smoke check завершился с кодом $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
