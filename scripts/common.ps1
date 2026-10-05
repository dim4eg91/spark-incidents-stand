$ErrorActionPreference = 'Stop'

function Get-LabConfig {
    $raw = & docker compose config --format json
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось прочитать конфигурацию Compose.' }
    return ($raw | ConvertFrom-Json)
}

function Get-LabUrl {
    param($Config, [string]$Service, [int]$TargetPort)
    $port = @($Config.services.$Service.ports | Where-Object { $_.target -eq $TargetPort })
    if ($port.Count -ne 1) { throw "Не найден опубликованный порт: $Service/$TargetPort" }
    return ('http://localhost:' + $port[0].published)
}
