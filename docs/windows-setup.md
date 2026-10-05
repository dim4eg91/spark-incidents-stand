# Первый запуск на Windows

Этот справочник помогает пройти 1.2, если Docker или PowerShell раньше не
использовал. Все команды ниже вводи в PowerShell на Windows. Python-ячейки
появятся позже, когда ты откроешь notebook в Jupyter.

## Подготовь компьютер

Проверенная платформа курса: Windows x86_64, Docker Desktop с Linux containers,
WSL 2 и PowerShell 7. Предварительный ориентир по ресурсам: 16 ГБ RAM компьютера,
около 8 ГБ для Docker, 4 CPU и 15 ГБ свободного диска. Минимальная конфигурация
и ARM пока не проверены. Точный состав проверенной машины указан в README.

Установи [Docker Desktop для Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
по инструкции производителя. Перед установкой сверь поддерживаемую версию Windows,
требования WSL и виртуализации. На рабочем компьютере сначала согласуй установку
с администратором. Условия использования Docker Desktop зависят от организации;
сам факт учебной задачи не отменяет её правил.

Если WSL ещё нет, следуй [инструкции Microsoft](https://learn.microsoft.com/en-us/windows/wsl/install).
При запросе установщика перезагрузи компьютер. Если Docker сообщает
`WSL needs updating`, выполни в терминале с необходимыми правами:

```powershell
wsl --version
wsl --update
```

Дождись завершения и перезапусти Docker Desktop. Если ошибка остаётся, сохрани
её текст и проверь требования производителя. Команды удаления дистрибутива WSL
или сброс Docker здесь не нужны: они могут затронуть другие проекты.

Установи [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows).
Открой приложение PowerShell 7 или выполни `pwsh` в терминале. Проверь:

```powershell
$PSVersionTable.PSVersion
```

В колонке `Major` должно быть `7`. Windows PowerShell 5.1 может оставаться
установленным рядом. Скрипт проверки курса использует возможности PowerShell 7.

## Проверь Docker до скачивания образов

Запусти Docker Desktop, дождись состояния `Engine running` и выполни:

```powershell
docker version
docker compose version
docker info --format '{{.OSType}}'
```

В первой команде нужны разделы `Client` и `Server`. Вторая должна показать Compose v2,
третья должна вернуть `linux`. Если доступен только Client, команда установлена,
но подключение к Engine ещё не работает. При результате `windows` переключись
на Linux containers через меню Docker Desktop.

Вход в Docker-аккаунт может потребоваться по политике организации или при
ограничениях скачивания образов. Не делай вывод о готовности Engine по наличию
аватарки или успешной авторизации. Проверка здесь конкретная: доступен Server.

## Получи файлы и подготовь настройки

Проверь Git в PowerShell:

```powershell
git --version
```

Если команда не найдена, установи [Git for Windows](https://git-scm.com/install/windows)
и открой новое окно PowerShell. GitHub-аккаунт для публичного репозитория не нужен.
Открой [репозиторий стенда](https://github.com/dim4eg91/spark-incidents-stand)
и выполни команды ниже. `D:` здесь только пример: если такого диска нет,
выбери существующий диск с достаточным свободным местом и измени путь в первых
двух строках.

```powershell
New-Item -ItemType Directory -Path 'D:\spark-course' -Force | Out-Null
Set-Location 'D:\spark-course'
git clone --branch course-2026-10 --single-branch https://github.com/dim4eg91/spark-incidents-stand.git spark_incidents_stand
Set-Location '.\spark_incidents_stand'
git branch --show-current
Get-Location
Get-ChildItem
Test-Path .\compose.yaml
```

Ветка должна быть `course-2026-10`, а последняя команда должна вернуть `True`.
В этой же папке находятся `.env.example`, `scripts`, `docker`, `data`,
`workspace`. Не клонируй ветку `main`: для уроков закреплена
`course-2026-10`. Порядок работы с файлами описан в
[files-and-notebooks.md](files-and-notebooks.md).

Создай `.env` только при его отсутствии:

```powershell
if (-not (Test-Path -LiteralPath .env)) {
    Copy-Item -LiteralPath .env.example -Destination .env
}
```

Открой `.env` текстовым редактором. На первом запуске оставь версии и порты
из поставки. Строка `JUPYTER_TOKEN` задаёт токен входа. Сохрани файл под именем
`.env`, без добавленного расширения `.txt`. Пароли и токен не отправляй в чат.

## Запусти базовый профиль

```powershell
.\scripts\start.ps1 -Profile core
docker compose ps
```

Первый запуск скачивает образы и библиотеки. JAR для S3A уже включены в сборку,
скачивать их вручную в `/jars` не нужно. Если скачивание прервалось, найди
первую ошибку и адрес ресурса; смотри [troubleshooting.md](troubleshooting.md).

В списке нужны четыре сервиса: `spark-incidents-master`,
`spark-incidents-worker-1`, `spark-incidents-worker-2`, `spark-incidents-jupyter`.
Дождись `healthy`. MinIO и History Server в профиле `core` не обязательны.

Если PowerShell запрещает запуск `.ps1`, проверь `Get-ExecutionPolicy -List`.
Для скачанного доверенного файла можно посмотреть его свойства в Проводнике
и отметку блокировки. Не отключай политику безопасности всей машины ради курса.
На корпоративной машине согласуй решение с администратором. Для запуска
контейнеров без `.ps1` доступна команда `docker compose up -d --build`,
но полную проверку `health.ps1` всё равно нужно выполнить в разрешённой среде.

## Открой Jupyter и проверь расчёт

Открой [http://localhost:18888/lab](http://localhost:18888/lab).
Если порт менял, используй адрес из `start.ps1`. В поле `Password or token`
вставь только значение `JUPYTER_TOKEN`, без имени переменной и знака `=`.
Нажми `Log in`. Нижняя форма `Setup a Password` для курса не нужна.

В Docker Desktop у Jupyter первым может быть показан `14040:4040`.
Это Spark UI. Найди `18888:8888` через `Show all ports` или используй адрес выше.
Адрес `http://127.0.0.1:8888` в логах относится к контейнеру.

После входа должны появиться файловая панель и Launcher с Python 3.
Затем выполни в PowerShell:

```powershell
.\scripts\health.ps1 -Profile core
```

Проверка обращается к веб-интерфейсам, проверяет токен и страницу JupyterLab,
запускает приложение с двумя Executor, читает CSV и проверяет запись Parquet.
В конце ищи `SMOKE_JSON`, `executors: 2`, `csv_rows: 30` и
`local_read_write_readback: "passed"`. До запуска закрой другие Spark-сессии.

Вернись к шагу 4 1.2, скачай `01_02_environment_check.ipynb`, открой его
по [инструкции работы с файлами](files-and-notebooks.md) и получи
`ENVIRONMENT CHECK: OK`. Это завершает подготовку к 1.3.
